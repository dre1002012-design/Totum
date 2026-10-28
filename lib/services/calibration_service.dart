// lib/services/calibration_service.dart
//
// Profil 2.0 — Couche 3 : auto-calibration adaptative.
// Principe (inspiré de la méthode publiée de MacroFactor, simplifiée) :
// compare le poids RÉELLEMENT mesuré à l'évolution ATTENDUE par les
// calories réellement loguées, pour en déduire le métabolisme réel de
// l'utilisateur — plus fiable qu'une formule figée, et sans dépendre
// d'aucune montre connectée.
//
// Reste invisible pour l'utilisateur : aucune nouvelle question, on
// exploite juste ce qu'il donne déjà (son poids, son journal alimentaire).

import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pause_service.dart';
import 'profile.dart' show effectiveEnergyDensityKcalPerKg;
import 'supabase_paging.dart';

/// Un point de l'historique de poids.
class WeighIn {
  final DateTime date;
  final double weightKg;
  const WeighIn(this.date, this.weightKg);
}

/// Lissage exponentiel du poids ("Poids tendance", formule popularisée par
/// Trendweight/Happy Scale) : trend[j] = trend[j-1] + α·(scale[j] − trend[j-1]).
/// Filtre le bruit jour-à-jour (rétention d'eau, hydratation, horaire de
/// pesée) pour ne garder que la tendance de fond. `data` doit être triée par
/// date croissante ; trend[0] = scale[0] (rien à lisser sur le 1er point).
///
/// Priorité 59 (14/08/2026, audit des graphiques) : `alpha` est calibré pour
/// un pas ~quotidien entre pesées. Un utilisateur ne se pèse pas forcément
/// tous les jours — sans ajustement, un écart de plusieurs jours entre 2
/// pesées appliquait EXACTEMENT le même lissage qu'un écart d'1 jour,
/// faisant traîner la tendance très en retard après un trou de suivi. Alpha
/// composé sur le nombre de jours réellement écoulés entre les 2 points
/// (`1 − (1 − alpha)^gap`) : le même taux de décroissance "par jour"
/// s'applique quel que soit l'espacement réel des pesées.
List<double> emaTrend(List<WeighIn> data, {double alpha = 0.1}) {
  if (data.isEmpty) return const [];
  final out = <double>[data.first.weightKg];
  for (int i = 1; i < data.length; i++) {
    final gapDays = data[i].date.difference(data[i - 1].date).inDays;
    final effectiveAlpha =
        gapDays > 1 ? 1 - math.pow(1 - alpha, gapDays).toDouble() : alpha;
    out.add(out.last + effectiveAlpha * (data[i].weightKg - out.last));
  }
  return out;
}

/// Un point de l'historique de dépense énergétique estimée.
class ExpenditurePoint {
  final DateTime date;
  final double estimateKcal;
  final double lowKcal;
  final double highKcal;
  // Ajoutés le 19/08/2026 (demande d'Alex — "une fiche d'information" au tap
  // sur un point, façon MacroFactor) : les 2 ingrédients RÉELS qui ont produit
  // cette estimation, sur la fenêtre d'analyse de ce point précis — jamais un
  // texte d'explication inventé, seulement les 2 nombres qui alimentent
  // directement l'équation d'équilibre énergétique (voir expenditureHistory
  // ci-dessous). `daysWithFoodLogged`/`loggableDays` renseignent la couverture
  // réelle de cette fenêtre (déjà ce qui pilote `lowKcal`/`highKcal`).
  final double avgKcalLogged;
  final double weightChangeKg;
  final int daysWithFoodLogged;
  final int windowDays;
  // BUG CORRIGÉ (18/09/2026, retour d'Alex — "je ne dépasse jamais 19/20
  // jours de journal couverts, même après 3 mois à peser et loguer tous les
  // jours sans exception") : vérifié à la main sur son export réel
  // `weight_log` (aucune lacune de pesée récente n'expliquait le plafond) —
  // la VRAIE cause est que la boucle ci-dessous exclut TOUJOURS le jour en
  // cours du décompte `daysWithFoodLogged` (correctif légitime du
  // 01/09/2026 : un repas seul sur une journée pas terminée fausserait la
  // moyenne) mais l'affichage utilisait encore le `windowDays` CONFIGURÉ (20)
  // comme dénominateur — pour le point le plus récent (fenêtre qui inclut
  // "aujourd'hui"), 20/20 est donc mathématiquement IMPOSSIBLE quel que soit
  // le sérieux du suivi, alors que rien ne manque réellement. `loggableDays`
  // est le VRAI plafond atteignable pour CE point précis (jours de la
  // fenêtre réellement éligibles à être logués : jour en cours et jours de
  // pause exclus) — toujours ≥ `daysWithFoodLogged`, et un suivi parfait
  // atteint désormais 100 % à l'affichage, comme il le devrait.
  final int loggableDays;
  const ExpenditurePoint({
    required this.date,
    required this.estimateKcal,
    required this.lowKcal,
    required this.highKcal,
    this.avgKcalLogged = 0,
    this.weightChangeKg = 0,
    this.daysWithFoodLogged = 0,
    this.windowDays = 0,
    int? loggableDays,
  }) : loggableDays = loggableDays ?? windowDays;
}

/// Résultat d'une tentative de calibration.
class CalibrationResult {
  final bool hasEnoughData;
  final double? empiricalTdee;   // TDEE déduit de tes résultats réels
  final double blendWeight;      // 0 = ignore, 1 = fait pleinement confiance
  final int daysOfWeightData;
  final int daysOfFoodData;
  const CalibrationResult({
    required this.hasEnoughData,
    this.empiricalTdee,
    this.blendWeight = 0.0,
    this.daysOfWeightData = 0,
    this.daysOfFoodData = 0,
  });

  static const none = CalibrationResult(hasEnoughData: false);
}

/// Compte de jours de pause dans `[start, end]`, à partir d'une liste de
/// [PausePeriod] déjà chargée — version synchrone de
/// [PauseService.pausedDaysInRange], pour éviter un appel réseau par
/// itération dans la boucle de fenêtre glissante d'[expenditureHistory].
/// Publique (comme [emaTrend]) uniquement pour être testable sans dépendance
/// réseau/SharedPreferences.
int pausedDaysInRangeSync(List<PausePeriod> pauses, DateTime start, DateTime end) {
  if (pauses.isEmpty) return 0;
  var count = 0;
  for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    if (pauses.any((p) => p.contains(d))) count++;
  }
  return count;
}

/// Jours de "stabilisation" après la fin d'une pause : les pesées de ces
/// jours-là sont écartées du calcul (25/10/2026, retour d'Alex — "quand on
/// revient de pause avec quasiment 3 kg de plus, rétention d'eau ou repas
/// plaisir, ça doit être considéré"). Au retour d'une coupure (voyage, sel,
/// glucides, horaires), le poids est gonflé par de l'eau et du glycogène
/// qui s'éliminent en quelques jours — les compter ferait lire une PERTE
/// rapide (donc une dépense surestimée) juste après le retour. 3 jours :
/// recommandation publiée par MacroFactor ("attendre 3-4 jours que le poids
/// se stabilise" au retour de vacances, macrofactor.com/tracking-vacation).
const int kPostPauseWashoutDays = 3;

/// Résultat de l'équation d'équilibre énergétique sur une fenêtre.
class EnergyBalanceEstimate {
  final double tdee;
  final double avgKcal;
  /// Variation de poids TENDANCE attribuée aux jours suivis (somme des
  /// segments continus, jamais à travers une pause).
  final double weightChangeKg;
  final int effectiveDays;
  final int daysWithFood;
  final int loggableDays;
  final int weighInsUsed;
  final int segments;
  const EnergyBalanceEstimate({
    required this.tdee,
    required this.avgKcal,
    required this.weightChangeKg,
    required this.effectiveDays,
    required this.daysWithFood,
    required this.loggableDays,
    required this.weighInsUsed,
    required this.segments,
  });
}

/// Pesées réellement exploitables : hors jours de pause ET hors jours de
/// stabilisation qui suivent la fin d'une pause (voir
/// [kPostPauseWashoutDays]). Pure (testable sans réseau).
List<WeighIn> usableWeighIns(List<WeighIn> history, List<PausePeriod> pauses,
    {int washoutDays = kPostPauseWashoutDays}) {
  if (pauses.isEmpty) return List.of(history);
  bool inWashout(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    for (final p in pauses) {
      final e = p.end;
      if (e == null || e.isBefore(p.start)) continue; // en cours / annulée
      final end = DateTime(e.year, e.month, e.day);
      if (day.isAfter(end) && !day.isAfter(end.add(Duration(days: washoutDays)))) return true;
    }
    return false;
  }
  return history.where((w) => !pauses.any((p) => p.contains(w.date)) && !inWashout(w.date)).toList();
}

/// CŒUR UNIQUE du calcul de dépense empirique — partagé par
/// [CalibrationService.computeCalibration] (cible calorique réelle) ET
/// [CalibrationService.expenditureHistory] (graphique), pour qu'ils ne
/// puissent plus jamais diverger (cause n°1 des incidents passés de ce
/// fichier, Priorités 52/53/59, 19/08 et 24/08/2026).
///
/// BUG CORRIGÉ (25/10/2026, retour d'Alex — "je m'étais bien mis en pause,
/// si tu ne l'as pas vu c'est que le calcul n'est pas cohérent") : les
/// pesées de pause étaient bien exclues, mais le lissage reliait encore le
/// DERNIER poids avant la pause au PREMIER poids après — tout l'écart de
/// part et d'autre (repas non notés, rétention d'eau du retour) était donc
/// attribué aux jours suivis, comme si ces kilos venaient des calories
/// loguées. Vérifié sur les données réelles d'Alex : +1,4 kg en 4 jours de
/// pause (72,7 -> 74,1 kg, puis redescente : de l'eau) faisaient attribuer
/// jusqu'à +1,07 kg aux jours suivis au lieu de ~+0,3 kg, sous-estimant sa
/// dépense de 100 à 150 kcal/j. Même logique que MacroFactor ("l'estimation
/// est gelée pendant la période non suivie, puis reprend là où elle
/// s'était arrêtée") : la fenêtre est découpée en SEGMENTS CONTINUS entre
/// les pauses, chaque segment a son propre lissage et sa propre variation
/// (début/fin 30 %, comme avant), et seules ces variations intra-segment
/// entrent dans l'équation. La pesée de retour n'est jamais comparée à
/// celle d'avant la pause.
///
/// [weighIns] : pesées de la fenêtre, triées, déjà passées par
/// [usableWeighIns]. Renvoie `null` si aucune variation exploitable.
EnergyBalanceEstimate? estimateEnergyBalance({
  required List<WeighIn> weighIns,
  required Map<String, double> kcalByDay,
  required List<PausePeriod> pauses,
  required DateTime today,
}) {
  if (weighIns.length < 2) return null;
  bool paused(DateTime d) => pauses.any((p) => p.contains(d));
  final todayKey = _dateKey(today);

  // Découpage en segments : une coupure dès qu'un jour de pause (ou de
  // stabilisation, déjà retiré des pesées) sépare 2 pesées consécutives.
  final segments = <List<WeighIn>>[];
  var current = <WeighIn>[weighIns.first];
  for (var i = 1; i < weighIns.length; i++) {
    final a = weighIns[i - 1].date, b = weighIns[i].date;
    var crossesPause = false;
    for (var d = DateTime(a.year, a.month, a.day).add(const Duration(days: 1));
        d.isBefore(DateTime(b.year, b.month, b.day));
        d = d.add(const Duration(days: 1))) {
      if (paused(d)) { crossesPause = true; break; }
    }
    if (crossesPause) {
      segments.add(current);
      current = <WeighIn>[];
    }
    current.add(weighIns[i]);
  }
  segments.add(current);

  double avgWeight(List<WeighIn> pts) => pts.fold<double>(0, (a, w) => a + w.weightKg) / pts.length;
  double avgEpochDay(List<WeighIn> pts) =>
      pts.fold<double>(0, (a, w) => a + w.date.millisecondsSinceEpoch / 86400000.0) / pts.length;

  var totalChange = 0.0, totalEffDays = 0.0;
  double? baseWeight;
  var used = 0, usedSegments = 0;
  double totalKcal = 0;
  var daysWithFood = 0, loggableDays = 0;
  for (final seg in segments) {
    if (seg.length < 2) continue;
    // Lissage propre au segment (jamais à travers une pause).
    final trend = emaTrend(seg);
    final trended = List<WeighIn>.generate(seg.length, (i) => WeighIn(seg[i].date, trend[i]));
    final spanDays = seg.last.date.difference(seg.first.date).inDays;
    final segmentSpan = (spanDays * 0.3).round().clamp(0, spanDays);
    final earlyEnd = seg.first.date.add(Duration(days: segmentSpan));
    final lateStart = seg.last.date.subtract(Duration(days: segmentSpan));
    final early = trended.where((w) => !w.date.isAfter(earlyEnd)).toList();
    final late = trended.where((w) => !w.date.isBefore(lateStart)).toList();
    final eff = avgEpochDay(late) - avgEpochDay(early);
    if (eff < 1) continue;
    totalChange += avgWeight(late) - avgWeight(early);
    totalEffDays += eff;
    baseWeight ??= avgWeight(early);
    used += seg.length;
    usedSegments++;
    // Calories des jours couverts par CE segment (jour en cours et jours
    // de pause exclus, comme avant).
    for (var j = 0; j <= spanDays; j++) {
      final d = seg.first.date.add(Duration(days: j));
      final key = _dateKey(d);
      if (key == todayKey || paused(d)) continue;
      loggableDays++;
      final k = kcalByDay[key] ?? 0.0;
      if (k > 0) {
        totalKcal += k;
        daysWithFood++;
      }
    }
  }
  if (usedSegments == 0 || daysWithFood == 0 || baseWeight == null) return null;

  final effectiveDays = totalEffDays.round();
  if (effectiveDays <= 0) return null;
  final avgKcal = totalKcal / daysWithFood;
  final rateBwPerWeek = (totalChange / baseWeight) / (effectiveDays / 7.0);
  final density = effectiveEnergyDensityKcalPerKg(rateBwPerWeek.abs());
  return EnergyBalanceEstimate(
    tdee: avgKcal - (totalChange * density) / effectiveDays,
    avgKcal: avgKcal,
    weightChangeKg: totalChange,
    effectiveDays: effectiveDays,
    daysWithFood: daysWithFood,
    loggableDays: loggableDays,
    weighInsUsed: used,
    segments: usedSegments,
  );
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class CalibrationService {
  CalibrationService._();
  static final CalibrationService instance = CalibrationService._();

  static const _historyKey = 'weight_history_v1';
  // 20 jours — alignement exact sur le "Change Rate" documenté par
  // MacroFactor (variation de la tendance de poids sur 20 jours, exprimée en
  // rythme hebdomadaire ; audit du 09/08/2026, tasks/026-08-09_Audit
  // scientifique de Macro factor.md), auparavant 21 (valeur proche mais pas
  // littéralement identique).
  static const _windowDays = 20;      // fenêtre d'analyse
  // BUG CORRIGÉ (19/08/2026, retour d'Alex — "je ne veux pas de faille") :
  // ce seuil s'appelait `_minSpanDays` et gatait sur l'ÉCART DE DATES entre
  // la 1re et la dernière pesée de la fenêtre — un utilisateur pouvait donc
  // "réussir" ce seuil avec seulement 2 pesées espacées de 10 jours (aucune
  // entre les deux), une base bien trop faible pour une vraie régression de
  // tendance. Redéfini en NOMBRE DE JOURS DISTINCTS PESÉS dans la fenêtre —
  // même unité, même échelle (0-20) que `_minFoodDays` juste en dessous, ce
  // qui les rend directement comparables à l'écran (retour d'Alex : "10/10 j"
  // et "18/8 j" affichés côte à côte se lisaient comme deux fractions
  // incohérentes, l'une sur une base de dates, l'autre sur un compte de
  // jours). 10 jours pesés sur 20 implique mathématiquement un écart de
  // dates d'au moins 9 jours — ce seuil couvre donc aussi, de fait, l'ancien
  // critère de span.
  static const _minWeighDays = 10;    // jours distincts pesés minimum, sur _windowDays
  // 8 jours = (windowDays * 0.4).round() — Priorité 59 (14/08/2026, audit
  // des graphiques) : c'était 5 jusqu'ici, alors qu'`expenditureReadiness()`
  // et `expenditureHistory()` exigent déjà 8 jours minimum (même règle des
  // 40 % de la fenêtre) pour la MÊME méthode de calcul. Avec 5, la cible
  // calorique pouvait déjà être ajustée silencieusement par la calibration
  // "live" pendant que le tableau de bord affichait encore "pas encore
  // assez de données" — 2 implémentations proches du même calcul qui
  // avaient dérivé l'une de l'autre (déjà la cause des bugs des Priorités
  // 52/53). Alignées ici sur le même seuil.
  static const _minFoodDays = 8;      // minimum de jours de journal loggés

  SupabaseClient get _client => Supabase.instance.client;

  // Priorité 66 (audit global — "3 à 5 fois la même requête weight_log au
  // chargement du Tableau de bord") : recentHistory(), expenditureHistory()
  // et computeCalibration() appellent chacune _readHistory() indépendamment,
  // et ProfileScreenState._refreshCharts() lance les trois en parallèle au
  // chargement de l'onglet — donc jusqu'à 3 allers-retours Supabase
  // identiques quasi simultanés (5 en comptant un "Confirmer mes objectifs"
  // qui recalcule aussi les objectifs). Cache mémoire très court (quelques
  // secondes) : sert exactement ce cas — plusieurs appels dans la même
  // "vague" de chargement — sans jamais risquer d'afficher une pesée
  // vieille de plusieurs minutes.
  List<WeighIn>? _cachedHistory;
  DateTime? _cachedHistoryAt;
  static const _historyCacheTtl = Duration(seconds: 5);

  /// Invalide tous les caches mémoire de ce service — à appeler à chaque
  /// changement de compte détecté (voir `account_guard.dart`). Sans ça, un
  /// changement de compte SANS redémarrage de l'app (web notamment) pouvait
  /// encore servir jusqu'à 5s de données de l'ancien compte depuis ce cache
  /// mémoire, même après la purge du cache disque (SharedPreferences).
  void resetInMemoryCache() {
    _cachedHistory = null;
    _cachedHistoryAt = null;
    _cachedFoodEntries = null;
    _cachedFoodEntriesAt = null;
  }

  /// Enregistre une pesée (à appeler à chaque sauvegarde de profil).
  /// N'ajoute pas de doublon si une pesée existe déjà pour aujourd'hui —
  /// la remplace, pour ne pas polluer l'historique si l'utilisateur
  /// sauvegarde plusieurs fois le même jour. Synchronisée sur Supabase
  /// (table `weight_log`) — avant, l'historique de poids n'existait qu'en
  /// SharedPreferences local, donc disparaissait à la désinstallation de
  /// l'app ou en changeant d'appareil (bug confirmé signalé par Alex).
  Future<void> logWeighIn(double weightKg) async {
    if (weightKg <= 0) return;
    final sp = await SharedPreferences.getInstance();
    final history = await _readHistory(sp);
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    history.removeWhere((w) => _dateKey(w.date) == todayKey);
    history.add(WeighIn(today, weightKg));
    history.sort((a, b) => a.date.compareTo(b.date));

    // On ne garde que la fenêtre utile + une marge, pour ne pas grossir indéfiniment.
    final cutoff = today.subtract(const Duration(days: _windowDays + 30));
    history.removeWhere((w) => w.date.isBefore(cutoff));

    await sp.setString(
      _historyKey,
      jsonEncode(history
          .map((w) => {'date': _dateKey(w.date), 'weight': w.weightKg})
          .toList()),
    );
    // Le cache mémoire doit refléter cette pesée immédiatement (pas
    // attendre expiration du TTL), sinon un `recentHistory()` appelé juste
    // après ce `logWeighIn()` pourrait renvoyer l'ancienne liste.
    _cachedHistory = history;
    _cachedHistoryAt = DateTime.now();

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('weight_log').upsert(
            {'user_id': user.id, 'date': todayKey, 'weight_kg': weightKg});
      }
    } catch (e) {
      // Table absente ou hors-ligne : le poids reste utilisable en local
      // (même filet de sécurité que les autres stores perso de l'app).
    }
  }

  /// Historique local, fusionné avec Supabase (`weight_log`) — jamais
  /// d'écrasement, une pesée loguée localement mais pas encore synchronisée
  /// ne doit jamais disparaître. Repli silencieux (local uniquement) si la
  /// table n'existe pas encore côté projet ou hors-ligne.
  Future<List<WeighIn>> _readHistory(SharedPreferences sp) async {
    final cached = _cachedHistory;
    final cachedAt = _cachedHistoryAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _historyCacheTtl) {
      return cached;
    }

    final raw = sp.getString(_historyKey);
    List<WeighIn> local = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        local = list.map((e) {
          final m = e as Map<String, dynamic>;
          final parts = (m['date'] as String).split('-');
          final d = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          return WeighIn(d, (m['weight'] as num).toDouble());
        }).toList();
      } catch (_) {}
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _cachedHistory = local;
        _cachedHistoryAt = DateTime.now();
        return local;
      }
      // Priorité 66 (audit global) : un échec réseau ponctuel ici fait
      // silencieusement retomber le calcul sur "pas assez de données" —
      // indiscernable pour l'utilisateur d'un compte réellement neuf, alors
      // que la calibration adaptative peut représenter un écart de
      // centaines de kcal vs la formule générique. Un essai supplémentaire
      // après un court délai absorbe l'immense majorité des ratés
      // transitoires (blip réseau, coupure Wi-Fi/4G) sans complexifier
      // l'appelant.
      // Audit 27/10/2026 (F3) : même plafond serveur que food_entries (1000
      // lignes ≈ 2,7 ans de pesées quotidiennes) — lecture par pages.
      Future<List<dynamic>> fetch() => fetchAllPages((rangeFrom, rangeTo) =>
          _client
              .from('weight_log')
              .select()
              .eq('user_id', user.id)
              .order('date', ascending: false)
              .range(rangeFrom, rangeTo));
      List<dynamic> rows;
      try {
        rows = await fetch();
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 800));
        rows = await fetch();
      }
      final remote = rows.map((r) {
        final m = Map<String, dynamic>.from(r);
        final parts = (m['date'] as String).split('-');
        final d = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return WeighIn(d, (m['weight_kg'] as num).toDouble());
      }).toList();
      final remoteDates = remote.map((w) => _dateKey(w.date)).toSet();
      final localOnly =
          local.where((w) => !remoteDates.contains(_dateKey(w.date))).toList();
      final merged = [...remote, ...localOnly]
        ..sort((a, b) => a.date.compareTo(b.date));

      await sp.setString(
        _historyKey,
        jsonEncode(merged
            .map((w) => {'date': _dateKey(w.date), 'weight': w.weightKg})
            .toList()),
      );
      for (final w in localOnly) {
        try {
          await _client.from('weight_log').upsert({
            'user_id': user.id,
            'date': _dateKey(w.date),
            'weight_kg': w.weightKg,
          });
        } catch (_) {}
      }
      _cachedHistory = merged;
      _cachedHistoryAt = DateTime.now();
      return merged;
    } catch (e) {
      // Ne met PAS en cache un résultat issu d'un échec réseau : la
      // prochaine tentative doit vraiment réessayer plutôt que resservir un
      // repli obsolète pendant le TTL (voir finding audit #4 — distinguer
      // "pas de données" d'un "échec de lecture" transitoire).
      return local;
    }
  }

  // BUG CORRIGÉ (21/08/2026, retour d'Alex — TDEE encore aberrant, 1244
  // kcal/j / "8/20 j", APRÈS le correctif du 20/08/2026, alors que
  // l'algorithme rejoué à la main sur son export Supabase réel donnait
  // ~2780 kcal/j pour la même fenêtre) : la version précédente de
  // `_kcalByDay` n'interrogeait Supabase QUE pour les jours ABSENTS du
  // cache local `history_snapshots` — un jour PRÉSENT dans ce cache, même
  // avec une valeur ancienne/incomplète/à 0 écrite par une session ou un
  // appareil antérieur, n'était alors plus JAMAIS revérifié contre Supabase.
  // Plus insidieux que le trou de cache déjà corrigé la veille : celui-ci
  // nécessite un cache local NON vide mais PÉRIMÉ pour se déclencher — un
  // simple réinstall (qui vide le cache) ne suffisait plus à l'expliquer,
  // ce qui a fait persister le bug malgré le premier correctif.
  //
  // Bascule de principe : pour un compte connecté, Supabase (seule source
  // d'autorité côté serveur) est maintenant interrogé EN PREMIER pour toute
  // la fenêtre utile, jamais seulement pour "les trous" du cache local — le
  // cache local ne sert plus qu'en repli hors-ligne/non connecté, jamais
  // comme source silencieusement prioritaire sur des données fraîches.
  // Même architecture que [_readHistory] (poids) : liste brute mise en
  // cache MÉMOIRE 5s (Priorité 66 — déduplique les 3 appels quasi
  // simultanés de la même vague de chargement : computeCalibration/
  // expenditureHistory/expenditureReadiness), jamais un cache disque qui
  // pourrait rester obsolète d'une session à l'autre. Fenêtre de fetch
  // volontairement large (100 jours) : couvre la plus ancienne fenêtre
  // réellement utilisée par un appelant (computeCalibration élargie jusqu'à
  // 80 jours en cas de longues pauses).
  List<Map<String, dynamic>>? _cachedFoodEntries;
  DateTime? _cachedFoodEntriesAt;
  static const _foodEntriesCacheTtl = Duration(seconds: 5);
  static const _foodEntriesFetchDays = 100;

  // BUG CORRIGÉ #2 (21/08/2026, même jour — persistait "8/8 j" malgré le
  // correctif ci-dessus, alors qu'Alex a fourni un export SQL direct
  // confirmant 20 jours réels sur 22 avec 2500-3300 kcal/j) : la requête
  // Supabase juste en dessous n'avait NI `.order()` NI `.limit()` explicite
  // — pour un utilisateur qui logue chaque ALIMENT séparément (20-31 lignes
  // `food_entries`/jour d'après l'export SQL d'Alex), une fenêtre de 100
  // jours représente ~2000 lignes, très probablement au-dessus du plafond
  // par défaut de lignes que PostgREST/Supabase renvoie par requête (souvent
  // 1000). Sans `.order()`, les lignes conservées après troncature ne sont
  // pas garanties être les plus récentes — exactement le symptôme observé :
  // un sous-ensemble de jours arbitraire et bien en dessous du vrai total.
  // `.order(entry_date DESC)` + `.limit()` généreux garantit que, même en
  // cas de troncature côté serveur, ce sont les lignes les PLUS RÉCENTES qui
  // sont conservées — celles dont dépendent les 3 fenêtres glissantes
  // (20-80 jours) utilisées par ce moteur.
  static const _foodEntriesFetchLimit = 6000;

  /// Récupère TOUTES les entrées `food_entries` des `_foodEntriesFetchDays`
  /// derniers jours pour l'utilisateur connecté. Retourne `null` si la
  /// requête a échoué après réessai (offline/blip réseau) — distinct d'une
  /// liste vide (compte connecté mais réellement aucune entrée), pour que
  /// l'appelant sache s'il doit se replier sur le cache local ou faire
  /// confiance à "vraiment zéro repas loggé".
  Future<List<Map<String, dynamic>>?> _fetchFoodEntries() async {
    final cached = _cachedFoodEntries;
    final cachedAt = _cachedFoodEntriesAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _foodEntriesCacheTtl) {
      return cached;
    }

    final user = _client.auth.currentUser;
    if (user == null) return null;

    final fetchStart =
        _dateKey(DateTime.now().subtract(const Duration(days: _foodEntriesFetchDays)));
    try {
      // Audit 27/10/2026 (E3) : `.limit()` ne lève PAS le plafond serveur
      // (1000 lignes par défaut, ~40 jours pour Alex) alors que
      // expenditureHistory() a besoin de ~80 jours — lecture par pages
      // (supabase_paging.dart), ordre total entry_date puis id.
      Future<List<dynamic>> fetch() => fetchAllPages(
            (rangeFrom, rangeTo) => _client
                .from('food_entries')
                .select('entry_date, energy_kcal')
                .eq('user_id', user.id)
                .gte('entry_date', fetchStart)
                .order('entry_date', ascending: false)
                .order('id', ascending: false)
                .range(rangeFrom, rangeTo),
            maxPages: _foodEntriesFetchLimit ~/ kSupabasePageSize,
          );
      List<dynamic> rows;
      try {
        rows = await fetch();
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 800));
        rows = await fetch();
      }
      final list = rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
      _cachedFoodEntries = list;
      _cachedFoodEntriesAt = DateTime.now();
      return list;
    } catch (_) {
      // Ne met PAS en cache un échec — la prochaine tentative doit vraiment
      // réessayer (même principe que [_readHistory] pour le poids).
      return null;
    }
  }

  /// Kcal loguées, jour par jour, sur une période — voir le correctif du
  /// 21/08/2026 ci-dessus pour le raisonnement. Supabase fait foi pour un
  /// compte connecté ; le cache local `history_snapshots` n'est consulté
  /// qu'en repli (hors-ligne, ou compte non connecté), et est réécrit à
  /// partir de la vérité Supabase à chaque succès (auto-réparation d'un
  /// cache local périmé, pas seulement complété).
  Future<Map<String, double>> _kcalByDay(
      SharedPreferences sp, DateTime start, DateTime end) async {
    final entries = await _fetchFoodEntries();

    if (entries != null) {
      final byDay = <String, double>{};
      for (final r in entries) {
        final d = (r['entry_date'] ?? '').toString();
        if (d.isEmpty) continue;
        final k = (r['energy_kcal'] as num?)?.toDouble() ?? 0.0;
        byDay[d] = (byDay[d] ?? 0.0) + k;
      }

      final result = <String, double>{};
      final raw = sp.getString('history_snapshots');
      Map<String, dynamic> hist = {};
      if (raw != null && raw.isNotEmpty) {
        try { hist = jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
      }
      bool changed = false;
      for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final key = _dateKey(d);
        final k = byDay[key] ?? 0.0;
        result[key] = k;
        // Réécrit systématiquement (jamais seulement si absent) : un
        // ancien snapshot périmé pour ce jour doit être écrasé par la
        // vérité Supabase, pas conservé tel quel.
        final existing = hist[key];
        final existingK = existing is Map ? (existing['kcal'] as num?)?.toDouble() : null;
        if (existingK != k) {
          hist[key] = {'kcal': k};
          changed = true;
        }
      }
      if (changed) {
        await sp.setString('history_snapshots', jsonEncode(hist));
      }
      return result;
    }

    // Repli hors-ligne / non connecté : cache local seul disponible, tel quel.
    final raw = sp.getString('history_snapshots');
    Map<String, dynamic> hist = {};
    if (raw != null && raw.isNotEmpty) {
      try { hist = jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
    }
    final result = <String, double>{};
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = _dateKey(d);
      final entry = hist[key];
      result[key] = entry is Map ? ((entry['kcal'] as num?)?.toDouble() ?? 0.0) : 0.0;
    }
    return result;
  }

  /// Calcule la calibration à partir de l'historique disponible.
  /// Ne modifie rien : renvoie juste le résultat, à combiner avec la
  /// formule par l'appelant (profile_screen.dart).
  ///
  /// Priorité 71 (retour d'Alex : "la personne part en vacances... est-ce
  /// que ça n'impacte pas le calcul global") — les jours déclarés en pause
  /// ([PauseService]) sont exclus de l'analyse : ni les pesées prises
  /// pendant une pause (souvent gonflées par le sel/l'hydratation/les
  /// horaires de voyage, pas représentatives de la masse grasse réelle), ni
  /// les jours eux-mêmes dans le calcul de calories moyennes. Une simple
  /// absence de repas loguée pendant ces jours était déjà silencieusement
  /// ignorée par la boucle ci-dessous (`if (k > 0)`) — mais si l'utilisateur
  /// avait malgré tout loggé un jour de vacances avec une alimentation
  /// atypique, ce jour polluait la moyenne "vie normale" sans qu'on le
  /// sache. Le fenêtre d'analyse est élargie en arrière d'autant de jours
  /// que la pause en a "mangé", pour ne pas perdre des semaines de
  /// calibration à cause d'une coupure ponctuelle.
  Future<CalibrationResult> computeCalibration() async {
    final sp = await SharedPreferences.getInstance();
    final history = await _readHistory(sp);
    final now = DateTime.now();
    final baseWindowStart = now.subtract(const Duration(days: _windowDays));
    // Élargissement borné à 60 jours de plus : une pause ponctuelle (week-end,
    // vacances de 1-3 semaines) doit être totalement absorbée, sans pour
    // autant faire remonter indéfiniment dans le passé si l'utilisateur a été
    // en pause très longtemps (l'ancienneté des données redevient alors elle-
    // même une raison légitime de retomber sur "pas assez de données").
    final pausedInBaseWindow =
        await PauseService.instance.pausedDaysInRange(baseWindowStart, now);
    final windowStart = baseWindowStart
        .subtract(Duration(days: pausedInBaseWindow.clamp(0, 60)));

    final pauses = await PauseService.instance.load();
    final inWindow = usableWeighIns(history, pauses)
        .where((w) => !w.date.isBefore(windowStart))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Seuil COMPTE de jours distincts pesés (jamais l'écart de dates seul —
    // voir `_minWeighDays`) : critère de suffisance ET chiffre affiché.
    if (inWindow.length < _minWeighDays) {
      return CalibrationResult(hasEnoughData: false, daysOfWeightData: inWindow.length);
    }

    // Kcal loguées jour par jour : Supabase fait foi (voir _kcalByDay).
    final kcalByDay = await _kcalByDay(sp, inWindow.first.date, inWindow.last.date);
    final est = estimateEnergyBalance(
      weighIns: inWindow, kcalByDay: kcalByDay, pauses: pauses, today: now,
    );
    // Segments moyennés trop rapprochés pour être fiables (pesées groupées
    // sur une portion étroite de la fenêtre malgré un compte suffisant).
    if (est == null || est.effectiveDays < (_minWeighDays * 0.6).round()) {
      return CalibrationResult(hasEnoughData: false, daysOfWeightData: inWindow.length);
    }
    if (est.daysWithFood < _minFoodDays) {
      return CalibrationResult(
        hasEnoughData: false,
        daysOfWeightData: inWindow.length,
        daysOfFoodData: est.daysWithFood,
      );
    }
    final empiricalTdee = est.tdee;
    final daysWithFood = est.daysWithFood;

    // Confiance croissante avec le VOLUME de données réellement disponible
    // (jours pesés, même métrique que le seuil de suffisance ci-dessus —
    // avant, ce calcul repartait sur `rawSpanDays`, l'écart de dates, une
    // base différente de celle qui avait servi à décider si on avait
    // "assez" de données) : minimum tout juste atteint = prudence (0.25),
    // fenêtre pleine (20/20 j pesés) = on fait davantage confiance au réel
    // qu'à la formule (0.65) — jamais 1.0, la formule anthropométrique
    // reste toujours un plancher de sécurité, même à confiance maximale.
    final blend = ((inWindow.length - _minWeighDays) / (_windowDays - _minWeighDays))
        .clamp(0.25, 0.65);

    return CalibrationResult(
      hasEnoughData: true,
      empiricalTdee: empiricalTdee,
      blendWeight: blend,
      daysOfWeightData: inWindow.length,
      daysOfFoodData: daysWithFood,
    );
  }

  /// Historique de poids récent, pour affichage en courbe (Bloc évolution).
  Future<List<WeighIn>> recentHistory(int days) async {
    final sp = await SharedPreferences.getInstance();
    final history = await _readHistory(sp);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = history.where((w) => !w.date.isBefore(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return recent;
  }

  /// Historique de dépense énergétique estimée, façon "Expenditure" de
  /// MacroFactor — approximation dérivée des données déjà disponibles
  /// (poids + calories loguées), PAS une reproduction de leur algorithme
  /// propriétaire. Rejoue la même régression fenêtre-glissante que
  /// [computeCalibration] à chaque jour disponible des `days` derniers
  /// jours, sur une fenêtre arrière de `windowDays` jours. La bande
  /// [ExpenditurePoint.lowKcal]/[highKcal] traduit l'incertitude : plus
  /// resserrée quand le volume de données loguées dans la fenêtre est
  /// important, plus large sinon — même logique de confiance que
  /// [CalibrationResult.blendWeight], aucune valeur inventée. `windowDays`
  /// par défaut aligné sur les 20 jours du Change Rate (voir _windowDays).
  Future<List<ExpenditurePoint>> expenditureHistory({int days = 60, int windowDays = 20}) async {
    final sp = await SharedPreferences.getInstance();
    final rawHistory = await _readHistory(sp);
    if (rawHistory.length < 2) return const [];
    // Priorité 71 : même exclusion des jours de pause que [computeCalibration]
    // (pesées ET calories), une fois pour toute la fenêtre plutôt qu'à
    // chaque itération de la boucle glissante ci-dessous.
    final pauses = await PauseService.instance.load();
    // Même filtrage que computeCalibration (pause + stabilisation au retour).
    final history = usableWeighIns(rawHistory, pauses);
    if (history.length < 2) return const [];

    final now = DateTime.now();
    // BUG CORRIGÉ (30/08/2026, retour d'Alex — chute brutale et trompeuse du
    // graphique (-476 kcal en 2 jours) dès le déclenchement d'une pause,
    // reproduite au kg près sur son export réel `weight_log` : dès qu'aucune
    // nouvelle pesée n'arrive pour remplacer celle qui sort de la fenêtre de
    // `windowDays` jours, la fenêtre glissante perd purement et simplement
    // sa pesée la plus ancienne à chaque jour qui passe — sans qu'aucune
    // vraie donnée nouvelle ne vienne compenser. Ça déplace artificiellement
    // la moyenne du segment "début de fenêtre" et fait dériver l'estimation,
    // de plus en plus fort à mesure que la pause dure, alors qu'aucune
    // information réelle n'a changé. [computeCalibration] élargit déjà sa
    // fenêtre en arrière du nombre de jours de pause pour neutraliser
    // exactement ce mécanisme (voir son commentaire, Priorité 71) — cette
    // fonction, qui alimente le GRAPHIQUE affiché à l'écran, avait été
    // oubliée lors de ce correctif : même famille de bug que les incidents
    // précédents où `computeCalibration`/`expenditureHistory` divergeaient.
    // Chaque point de la courbe élargit maintenant sa PROPRE fenêtre du
    // nombre de jours de pause qu'elle contient (même plafond de 60 jours),
    // pour ne plus jamais perdre de signal réel simplement parce qu'aucune
    // nouvelle pesée n'est arrivée pendant une pause déclarée.
    final maxPauseWidening = pauses.isEmpty ? 0 : 60;
    final rangeStart = now.subtract(Duration(days: days + windowDays + maxPauseWidening));

    // Pré-lecture unique des kcal loguées jour par jour (évite des lectures
    // SharedPreferences répétées à chaque itération de la fenêtre glissante)
    // — avec repli Supabase groupé sur les jours absents du cache local
    // (voir _kcalByDay). Fenêtre de fetch élargie d'autant que l'élargissement
    // maximal possible par pause (ci-dessus), pour que `kcalByDay` couvre
    // bien toute fenêtre effectivement élargie plus bas.
    final kcalByDay = await _kcalByDay(sp, rangeStart, now);

    final points = <ExpenditurePoint>[];
    final firstPlottable = now.subtract(Duration(days: days));

    for (int i = 0; i <= days; i++) {
      final windowEnd = firstPlottable.add(Duration(days: i));
      final baseWindowStart = windowEnd.subtract(Duration(days: windowDays));
      final pausedInBaseWindow =
          pausedDaysInRangeSync(pauses, baseWindowStart, windowEnd);
      final windowStart = baseWindowStart
          .subtract(Duration(days: pausedInBaseWindow.clamp(0, 60)));

      final inWindow = history
          .where((w) => !w.date.isBefore(windowStart) && !w.date.isAfter(windowEnd))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (inWindow.length < 2) continue;

      // Seuil COMPTE (jours distincts pesés dans la fenêtre) — même
      // critère que [computeCalibration]/[expenditureReadiness].
      final minWeighCount = (windowDays * 0.5).round();
      if (inWindow.length < minWeighCount) continue;

      // Cœur unique partagé avec computeCalibration (voir
      // estimateEnergyBalance) : le point le plus récent de ce graphique
      // correspond, au jour près, au TDEE qui alimente réellement la cible.
      final est = estimateEnergyBalance(
        weighIns: inWindow, kcalByDay: kcalByDay, pauses: pauses, today: now,
      );
      if (est == null) continue;
      if (est.daysWithFood < (windowDays * 0.4).round()) continue;
      if (est.effectiveDays < (minWeighCount * 0.6).round()) continue;
      final estimate = est.tdee;
      final avgKcal = est.avgKcal;
      final weightChangeKg = est.weightChangeKg;
      final daysWithFood = est.daysWithFood;
      final loggableDays = est.loggableDays;

      // Bande d'incertitude : resserrée avec le volume de données (jamais
      // sous ±3%, aucune estimation empirique n'étant jamais parfaitement
      // certaine ; jusqu'à ±15% quand la fenêtre est peu couverte).
      // BUG CORRIGÉ (18/09/2026, même audit que `loggableDays` ci-dessus) :
      // utilisait `windowDays` (20, constant) au lieu de `loggableDays` (le
      // vrai nombre de jours logeables de la fenêtre) — un suivi PARFAIT sur
      // le point du jour même (jour en cours toujours exclu) plafonnait donc
      // `coverage` à 19/20 = 0.95 au lieu de 1.0, gonflant légèrement la
      // marge d'incertitude sans raison réelle.
      final coverage = loggableDays > 0
          ? (daysWithFood / loggableDays).clamp(0.0, 1.0)
          : 0.0;
      final uncertainty = estimate.abs() * (0.15 - 0.10 * coverage).clamp(0.03, 0.15);

      points.add(ExpenditurePoint(
        date: windowEnd,
        estimateKcal: estimate,
        lowKcal: estimate - uncertainty,
        highKcal: estimate + uncertainty,
        avgKcalLogged: avgKcal,
        weightChangeKg: weightChangeKg,
        daysWithFoodLogged: daysWithFood,
        windowDays: windowDays,
        loggableDays: loggableDays,
      ));
    }
    return points;
  }

  /// État d'avancement vers le premier point de dépense énergétique
  /// affichable — retour d'Alex (12/08/2026) : "un utilisateur qui vient de
  /// commencer va se dire qu'on lui vend du rêve" en voyant un graphique
  /// vide sans explication. Reprend EXACTEMENT les mêmes seuils que
  /// [computeCalibration]/[expenditureHistory] (voir `_minWeighDays`,
  /// `_minFoodDays`) pour que le message affiché soit toujours honnête
  /// vis-à-vis du graphique et de la calibration réelle.
  ///
  /// BUG CORRIGÉ (19/08/2026, audit "je ne veux pas de faille") : cette
  /// méthode ne passait PAS l'historique par [_excludePaused], contrairement
  /// à [computeCalibration] et [expenditureHistory] juste au-dessus — un
  /// utilisateur pouvait donc voir "prêt" ici (pesées de pause comptées)
  /// alors que le calcul réel, lui, les exclut et conclut "pas assez de
  /// données" — exactement la même famille de bug que "chart pas prêt mais
  /// chiffre affiché quand même" déjà corrigée ce même jour. Repasse
  /// maintenant par [_excludePaused] pour les pesées, et exclut les jours de
  /// pause du comptage de repas via [PauseService], comme les deux autres
  /// méthodes.
  Future<ExpenditureReadiness> expenditureReadiness({int windowDays = 20}) async {
    final sp = await SharedPreferences.getInstance();
    final rawHistory = await _readHistory(sp);
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(days: windowDays));

    // Même filtrage que computeCalibration/expenditureHistory (pause +
    // stabilisation au retour, voir usableWeighIns) — compteur affiché et
    // calcul réel ne peuvent pas diverger.
    final inWindow = usableWeighIns(rawHistory, await PauseService.instance.load())
        .where((w) => !w.date.isBefore(windowStart) && !w.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Repli Supabase groupé (Priorité 53, 14/08/2026) sur les jours absents
    // du cache local `history_snapshots` — voir _kcalByDay. Compte les
    // repas sur les `windowDays` derniers jours entiers, indépendamment des
    // pesées (métrique volontairement distincte, voir _minFoodDays) — mais
    // en excluant les jours de pause, comme [computeCalibration].
    final kcalByDay = await _kcalByDay(sp, now.subtract(Duration(days: windowDays - 1)), now);
    final pauses = await PauseService.instance.load();
    int daysWithFood = 0;
    for (final entry in kcalByDay.entries) {
      if (entry.value <= 0) continue;
      final parts = entry.key.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (pauses.any((p) => p.contains(d))) continue;
      daysWithFood++;
    }

    // Seuils identiques (même ratio de `windowDays`) à ceux qui gatent
    // réellement [computeCalibration] (`_minWeighDays`/`_minFoodDays` sur
    // `_windowDays` = 20) et [expenditureHistory] — voir leurs commentaires.
    final minWeighDays = (windowDays * 0.5).round();
    final minFoodDays = (windowDays * 0.4).round();

    return ExpenditureReadiness(
      weighInsCount: inWindow.length,
      minWeighDays: minWeighDays,
      daysWithFoodLogged: daysWithFood,
      minFoodDays: minFoodDays,
      windowDays: windowDays,
    );
  }
}

/// Voir [CalibrationService.expenditureReadiness]. Les deux compteurs
/// partagent volontairement la MÊME fenêtre (`windowDays`, 20 jours par
/// défaut) et la MÊME unité ("jours sur windowDays") — jamais un écart de
/// dates d'un côté et un compte de jours de l'autre (bug corrigé le
/// 19/08/2026 : "10/10 j" et "18/8 j" se lisaient comme deux fractions
/// incohérentes entre elles alors qu'elles ne mesuraient pas la même chose).
class ExpenditureReadiness {
  final int weighInsCount;
  final int minWeighDays;
  final int daysWithFoodLogged;
  final int minFoodDays;
  final int windowDays;
  const ExpenditureReadiness({
    required this.weighInsCount,
    required this.minWeighDays,
    required this.daysWithFoodLogged,
    required this.minFoodDays,
    required this.windowDays,
  });

  bool get ready => weighInsCount >= minWeighDays && daysWithFoodLogged >= minFoodDays;

  double get weighDaysProgress => (weighInsCount / minWeighDays).clamp(0.0, 1.0);
  double get foodProgress => (daysWithFoodLogged / minFoodDays).clamp(0.0, 1.0);
}