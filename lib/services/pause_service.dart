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

  /// `end` antérieur à `start` = intervalle délibérément VIDE (sentinelle
  /// "pause annulée", voir `PauseService.endActivePause()`) — ne contient
  /// jamais aucune date. Utilisé au lieu d'une suppression en base
  /// (`.delete()` non autorisé par la RLS de `pause_periods`, seulement
  /// select/insert/update) : une mise à jour vers un intervalle vide est
  /// strictement équivalente à une suppression du point de vue de
  /// `contains()`, sans nécessiter de nouvelle permission.
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

  /// Invalide le cache mémoire — à appeler à chaque changement de compte
  /// détecté (voir `account_guard.dart`). Même raisonnement que
  /// `CalibrationService.resetInMemoryCache()`.
  void resetInMemoryCache() {
    _cached = null;
    _cachedAt = null;
  }

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
  ///
  /// BUG CORRIGÉ (19/08/2026, retour d'Alex — bouton pause activé puis
  /// désactivé aussitôt, et son compteur "jours pesés" a silencieusement
  /// perdu 1 jour, faisant retomber son objectif calorique calibré (2660)
  /// sur la formule pure (3090)) : une pause démarrée ET terminée le MÊME
  /// jour calendaire produisait `PausePeriod(start: aujourd'hui, end:
  /// aujourd'hui)`. `PausePeriod.contains()` compare des DATES (pas des
  /// horodatages précis), donc cette période "contient" la journée entière,
  /// pour toujours — alors qu'aucune vraie pause n'a eu lieu (quelques
  /// secondes entre les deux taps). Ce jour se retrouvait donc exclu de
  /// TOUTE calibration future de façon permanente, silencieuse et
  /// irréversible pour l'utilisateur (aucun moyen de le "dé-exclure" dans
  /// l'UI).
  ///
  /// BUG CORRIGÉ #2 (19/08/2026, même jour, retour d'Alex — "il me remet
  /// tout le temps en pause, même après avoir mis 'je suis de retour'") : le
  /// 1er correctif ci-dessus supprimait la ligne via `.delete()` — mais la
  /// migration `20260817c_pause_periods.sql` n'accorde AUCUNE politique RLS
  /// pour DELETE (seulement select/insert/update), donc cet appel échouait
  /// silencieusement côté serveur (avalé par le `catch` ci-dessous). La
  /// ligne restait donc active dans Supabase (`end_date` toujours `null`) ;
  /// au prochain chargement de l'app, `load()` la re-fusionnait depuis le
  /// serveur et ressuscitait la pause — en boucle à chaque réouverture.
  /// Corrigé pour de bon : au lieu de supprimer la ligne, on la met à jour
  /// (`upsert`, une opération déjà autorisée par la RLS existante) avec une
  /// date de fin ANTÉRIEURE à sa date de début — un intervalle mathématiquement
  /// vide qu'aucune date ne peut jamais "contenir" (voir `PausePeriod
  /// .contains()`), sans avoir besoin d'une nouvelle permission ni d'une
  /// intervention manuelle dans Supabase. Purement local, la ligne aurait pu
  /// être retirée de la liste ; gardée ici pour que la MÊME logique
  /// (upsert) s'applique identiquement en local et à distance.
  Future<void> endActivePause() async {
    final periods = await load();
    final idx = periods.indexWhere((p) => p.isActive);
    if (idx == -1) return;
    final sp = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());
    final active = periods[idx];
    final user = _client.auth.currentUser;

    if (_dateOnly(active.start) == today) {
      final invalidated = active.copyWith(end: today.subtract(const Duration(days: 1)));
      final updated = List<PausePeriod>.from(periods)..[idx] = invalidated;
      _cached = updated;
      _cachedAt = DateTime.now();
      await _saveLocal(sp, updated);
      if (user != null) await _upsertRemote(user.id, invalidated);
      return;
    }

    // BUG CORRIGÉ (31/08/2026, retour d'Alex — revenu de pause le 31/8 après
    // une pause du 29 au 30/8, "on a attaqué un nouveau jour, on devrait
    // être à 19/20 jours") : `end: today` incluait le jour où l'utilisateur
    // appuie sur "Je suis de retour" DANS la période de pause elle-même
    // (`PausePeriod.contains` est inclusif des deux bornes) — alors que ce
    // jour-là est précisément celui où le suivi normal REPREND. Résultat :
    // peser/loguer le jour du retour n'aurait silencieusement compté pour
    // rien tant qu'on n'attendait pas le lendemain. La pause doit couvrir
    // les jours RÉELLEMENT absents (`start` à la veille du retour), jamais
    // le jour de la reprise.
    final updated = List<PausePeriod>.from(periods);
    updated[idx] =
        updated[idx].copyWith(end: today.subtract(const Duration(days: 1)));
    _cached = updated;
    _cachedAt = DateTime.now();
    await _saveLocal(sp, updated);
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
