// lib/services/pause_service.dart
//
// Priorité 71 (retour d'Alex : "la personne part en vacances, elle ne va
// pas se peser... est-ce que ça va impacter le calcul global... qu'on est
// tout le temps aligné avec [la calibration façon MacroFactor], sans
// culpabiliser la personne") — période de pause explicite (vacances,
// week-end, événement) que l'utilisateur déclare lui-même. Deux effets :
// 1. Un signal visuel neutre ("en pause", jamais un manque/une faute) tant
//    qu'elle est active.
// 2. [CalibrationService] exclut les jours de pause de son calcul (pesées ET
//    calories loguées) au lieu de les traiter comme un simple trou de
//    données — voir le commentaire de _isPausedOn dans calibration_service.dart
//    pour le raisonnement complet sur pourquoi un trou non-signalé peut
//    fausser le TDEE empirique alors qu'une pause explicite ne le peut pas.
//
// Stockage local + Supabase (table `pause_periods`), même architecture que
// weight_log/goal_snapshots/holistic_log cette session : repli local
// silencieux si la table n'existe pas encore ou hors-ligne.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Une période de pause. `end == null` = pause en cours (pas encore terminée
/// par l'utilisateur) — délibéré : en vacances, on ne connaît pas toujours
/// la date de retour exacte à l'avance.
class PausePeriod {
  final DateTime start;
  final DateTime? end;
  const PausePeriod({required this.start, this.end});

  bool get isActive => end == null;

  bool contains(DateTime d) {
    final day = _dateOnly(d);
    final s = _dateOnly(start);
    if (day.isBefore(s)) return false;
    if (end == null) return true;
    return !day.isAfter(_dateOnly(end!));
  }

  PausePeriod copyWith({DateTime? end}) => PausePeriod(start: start, end: end);
}

class PauseService {
  PauseService._();
  static final PauseService instance = PauseService._();

  static const _key = 'pause_periods_v1';

  SupabaseClient get _client => Supabase.instance.client;

  // Court cache mémoire (même principe que CalibrationService._cachedHistory)
  // — évite de relire plusieurs fois de suite pendant une même vague de
  // chargement (Conseils + Bilan + Profil peuvent tous vérifier l'état pause
  // au même moment).
  List<PausePeriod>? _cached;
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(seconds: 5);

  Future<List<PausePeriod>> load() async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    List<PausePeriod> local = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        local = list.map((e) {
          final m = e as Map<String, dynamic>;
          final s = DateTime.parse(m['start'] as String);
          final endRaw = m['end'] as String?;
          return PausePeriod(start: s, end: endRaw == null ? null : DateTime.parse(endRaw));
        }).toList();
      } catch (_) {}
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _cached = local;
        _cachedAt = DateTime.now();
        return local;
      }
      final rows = await _client.from('pause_periods').select().eq('user_id', user.id);
      final remote = (rows as List).map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        final s = DateTime.parse(m['start_date'] as String);
        final endRaw = m['end_date'] as String?;
        return PausePeriod(start: s, end: endRaw == null ? null : DateTime.parse(endRaw));
      }).toList();

      final remoteStarts = remote.map((p) => _dateKey(p.start)).toSet();
      final localOnly = local.where((p) => !remoteStarts.contains(_dateKey(p.start))).toList();
      final merged = [...remote, ...localOnly]
        ..sort((a, b) => a.start.compareTo(b.start));

      await _saveLocal(sp, merged);
      for (final p in localOnly) {
        await _upsertRemote(user.id, p);
      }
      _cached = merged;
      _cachedAt = DateTime.now();
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> _saveLocal(SharedPreferences sp, List<PausePeriod> periods) async {
    await sp.setString(
      _key,
      jsonEncode(periods
          .map((p) => {
                'start': _dateKey(p.start),
                'end': p.end == null ? null : _dateKey(p.end!),
              })
          .toList()),
    );
  }

  Future<void> _upsertRemote(String userId, PausePeriod p) async {
    try {
      await _client.from('pause_periods').upsert({
        'user_id': userId,
        'start_date': _dateKey(p.start),
        'end_date': p.end == null ? null : _dateKey(p.end!),
      }, onConflict: 'user_id,start_date');
    } catch (_) {}
  }

  /// La pause en cours, s'il y en a une (`end == null`).
  Future<PausePeriod?> activePause() async {
    final periods = await load();
    for (final p in periods) {
      if (p.isActive) return p;
    }
    return null;
  }

  /// Démarre une pause à partir d'aujourd'hui. Sans effet si une pause est
  /// déjà en cours (jamais deux pauses actives superposées).
  Future<void> startPause() async {
    final existing = await activePause();
    if (existing != null) return;
    final sp = await SharedPreferences.getInstance();
    final periods = await load();
    final today = _dateOnly(DateTime.now());
    final updated = [...periods, PausePeriod(start: today)];
    _cached = updated;
    _cachedAt = DateTime.now();
    await _saveLocal(sp, updated);
    final user = _client.auth.currentUser;
    if (user != null) await _upsertRemote(user.id, PausePeriod(start: today));
  }

  /// Termine la pause en cours (fixe sa date de fin à aujourd'hui). Sans
  /// effet si aucune pause n'est active.
  Future<void> endActivePause() async {
    final periods = await load();
    final idx = periods.indexWhere((p) => p.isActive);
    if (idx == -1) return;
    final sp = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());
    final updated = List<PausePeriod>.from(periods);
    updated[idx] = updated[idx].copyWith(end: today);
    _cached = updated;
    _cachedAt = DateTime.now();
    await _saveLocal(sp, updated);
    final user = _client.auth.currentUser;
    if (user != null) await _upsertRemote(user.id, updated[idx]);
  }

  Future<bool> isPausedOn(DateTime d) async {
    final periods = await load();
    return periods.any((p) => p.contains(d));
  }

  /// Nombre de jours de `start` à `end` (inclus) qui tombent dans une
  /// période de pause — pour permettre à [CalibrationService] d'élargir sa
  /// fenêtre d'analyse d'autant plutôt que de simplement perdre ces jours.
  Future<int> pausedDaysInRange(DateTime start, DateTime end) async {
    final periods = await load();
    if (periods.isEmpty) return 0;
    var count = 0;
    for (DateTime d = _dateOnly(start); !d.isAfter(_dateOnly(end)); d = d.add(const Duration(days: 1))) {
      if (periods.any((p) => p.contains(d))) count++;
    }
    return count;
  }
}
