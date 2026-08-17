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

const double _kKcalPerKgFat = 7700.0;

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
  const ExpenditurePoint({
    required this.date,
    required this.estimateKcal,
    required this.lowKcal,
    required this.highKcal,
  });
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
  static const _minSpanDays = 10;     // écart minimum entre 1re et dernière pesée
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
      List<dynamic> rows;
      try {
        rows = await _client.from('weight_log').select().eq('user_id', user.id);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 800));
        rows = await _client.from('weight_log').select().eq('user_id', user.id);
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

  /// Lit les calories loguées un jour donné.
  ///
  /// Bug corrigé (retour d'Alex, 13/08/2026 : "j'ai un gros doute sur les
  /// estimations... je le fais tous les jours") : cette méthode lisait la
  /// clé `journal_<date>`, qui n'est en réalité écrite QUE par le flux
  /// "ajouter un aliment à une date passée" (`_addEntryToDate` dans
  /// journal_screen.dart) — jamais par le flux normal "ajouter à
  /// aujourd'hui" (`_addToJournal`), qui écrit uniquement dans
  /// `history_snapshots`. Résultat concret : un utilisateur qui logue ses
  /// repas au jour le jour (le cas normal) voyait ses jours quasiment
  /// jamais comptés comme "jours avec repas renseignés" ici, faussant à la
  /// fois l'indicateur d'avancement et le calcul de dépense énergétique
  /// lui-même. `history_snapshots` est désormais tenue à jour dans LES DEUX
  /// flux (journal_screen.dart, `_saveDailySnapshot`) — c'est la source
  /// fiable pour n'importe quelle date.
  Future<double> _kcalForDate(SharedPreferences sp, DateTime day) async {
    final raw = sp.getString('history_snapshots');
    if (raw == null || raw.isEmpty) return 0.0;
    try {
      final hist = jsonDecode(raw) as Map<String, dynamic>;
      final entry = hist[_dateKey(day)];
      if (entry is! Map) return 0.0;
      return (entry['kcal'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Kcal loguées, jour par jour, sur une période — Priorité 53 (14/08/2026,
  /// retour d'Alex : "je suis toujours à 1 sur 8 alors que je logue tous
  /// les jours"). Cause trouvée : `history_snapshots` est un cache 100%
  /// LOCAL (`SharedPreferences`), jamais synchronisé — un réinstall de
  /// l'app (fréquent en phase de test, comme cette session) le vide
  /// entièrement, alors que les repas eux-mêmes (`food_entries`) SONT bien
  /// sauvegardés côté Supabase. Sans repli, l'indicateur "repas renseignés"
  /// retombait silencieusement à zéro à chaque réinstall, même avec un
  /// historique réel complet côté serveur.
  ///
  /// Lit d'abord le cache local (rapide, hors-ligne) ; pour les seuls jours
  /// manquants, UNE requête groupée vers `food_entries` (jamais une requête
  /// par jour) reconstruit le total, et réalimente le cache local au passage
  /// (auto-réparation : plus besoin de re-interroger Supabase la prochaine
  /// fois pour ces mêmes jours).
  Future<Map<String, double>> _kcalByDay(
      SharedPreferences sp, DateTime start, DateTime end) async {
    final raw = sp.getString('history_snapshots');
    Map<String, dynamic> hist = {};
    if (raw != null && raw.isNotEmpty) {
      try { hist = jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
    }

    final result = <String, double>{};
    final missingDays = <DateTime>[];
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = _dateKey(d);
      final entry = hist[key];
      if (entry is Map) {
        result[key] = (entry['kcal'] as num?)?.toDouble() ?? 0.0;
      } else {
        missingDays.add(d);
      }
    }
    if (missingDays.isEmpty) return result;

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        for (final d in missingDays) { result[_dateKey(d)] = 0.0; }
        return result;
      }
      final rows = await _client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .gte('entry_date', _dateKey(missingDays.first))
          .lte('entry_date', _dateKey(missingDays.last));

      final byDay = <String, double>{};
      for (final row in (rows as List)) {
        final r = Map<String, dynamic>.from(row as Map);
        final d = (r['entry_date'] ?? '').toString();
        if (d.isEmpty) continue;
        final k = (r['energy_kcal'] as num?)?.toDouble() ?? 0.0;
        byDay[d] = (byDay[d] ?? 0.0) + k;
      }

      bool changed = false;
      for (final d in missingDays) {
        final key = _dateKey(d);
        final k = byDay[key] ?? 0.0;
        result[key] = k;
        if (k > 0) {
          hist[key] = {'kcal': k};
          changed = true;
        }
      }
      if (changed) {
        await sp.setString('history_snapshots', jsonEncode(hist));
      }
    } catch (e) {
      for (final d in missingDays) { result[_dateKey(d)] = result[_dateKey(d)] ?? 0.0; }
    }
    return result;
  }

  /// Calcule la calibration à partir de l'historique disponible.
  /// Ne modifie rien : renvoie juste le résultat, à combiner avec la
  /// formule par l'appelant (profile_screen.dart).
  Future<CalibrationResult> computeCalibration() async {
    final sp = await SharedPreferences.getInstance();
    final history = await _readHistory(sp);
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: _windowDays));

    final inWindow = history.where((w) => !w.date.isBefore(windowStart)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (inWindow.length < 2) {
      return CalibrationResult(
        hasEnoughData: false,
        daysOfWeightData: inWindow.length,
      );
    }

    final rawFirst = inWindow.first;
    final rawLast = inWindow.last;
    final rawSpanDays = rawLast.date.difference(rawFirst.date).inDays;
    if (rawSpanDays < _minSpanDays) {
      return CalibrationResult(hasEnoughData: false, daysOfWeightData: rawSpanDays);
    }

    // ── Robustesse : on moyenne les pesées du DÉBUT et de la FIN de la
    // période (premiers/derniers 30 %), au lieu de ne comparer que 2 points
    // isolés qui peuvent être faussés par la rétention d'eau, un repas
    // salé ou une pesée à une heure inhabituelle. Si une seule pesée existe
    // dans un segment, la "moyenne" est simplement cette pesée — la méthode
    // devient automatiquement plus fiable si l'utilisateur pèse plus souvent.
    final segmentSpan = (rawSpanDays * 0.3).round().clamp(0, rawSpanDays);
    final earlyEnd = rawFirst.date.add(Duration(days: segmentSpan));
    final lateStart = rawLast.date.subtract(Duration(days: segmentSpan));

    final earlyPoints = inWindow.where((w) => !w.date.isAfter(earlyEnd)).toList();
    final latePoints = inWindow.where((w) => !w.date.isBefore(lateStart)).toList();

    double avgWeight(List<WeighIn> pts) =>
        pts.fold<double>(0, (a, w) => a + w.weightKg) / pts.length;
    double avgEpochDay(List<WeighIn> pts) =>
        pts.fold<double>(0, (a, w) => a + w.date.millisecondsSinceEpoch / 86400000.0) /
        pts.length;

    final avgEarlyWeight = avgWeight(earlyPoints);
    final avgLateWeight = avgWeight(latePoints);
    final avgEarlyDay = avgEpochDay(earlyPoints);
    final avgLateDay = avgEpochDay(latePoints);
    final effectiveSpanDays = (avgLateDay - avgEarlyDay).round();

    if (effectiveSpanDays < (_minSpanDays * 0.6).round()) {
      // Les segments moyennés sont trop rapprochés pour être fiables.
      return CalibrationResult(hasEnoughData: false, daysOfWeightData: rawSpanDays);
    }

    // Moyenne des calories loguées sur la période couverte par les pesées.
    double totalKcal = 0;
    int daysWithFood = 0;
    for (int i = 0; i <= rawSpanDays; i++) {
      final d = rawFirst.date.add(Duration(days: i));
      final k = await _kcalForDate(sp, d);
      if (k > 0) {
        totalKcal += k;
        daysWithFood++;
      }
    }

    if (daysWithFood < _minFoodDays) {
      return CalibrationResult(
        hasEnoughData: false,
        daysOfWeightData: rawSpanDays,
        daysOfFoodData: daysWithFood,
      );
    }

    final avgKcal = totalKcal / daysWithFood;
    final weightChangeKg = avgLateWeight - avgEarlyWeight;
    // Équation d'équilibre énergétique : le TDEE réel est ce qu'il aurait
    // fallu manger pour rester stable, compte tenu du poids gagné/perdu,
    // calculé sur l'écart EFFECTIF entre les 2 segments moyennés.
    final empiricalTdee =
        avgKcal - (weightChangeKg * _kKcalPerKgFat) / effectiveSpanDays;

    // Confiance croissante avec la durée de suivi : 10j = prudence,
    // 21j+ = on fait davantage confiance au réel qu'à la formule.
    final blend = ((rawSpanDays - _minSpanDays) / (_windowDays - _minSpanDays))
        .clamp(0.25, 0.65);

    return CalibrationResult(
      hasEnoughData: true,
      empiricalTdee: empiricalTdee,
      blendWeight: blend,
      daysOfWeightData: rawSpanDays,
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
    final history = await _readHistory(sp);
    if (history.length < 2) return const [];

    final now = DateTime.now();
    final rangeStart = now.subtract(Duration(days: days + windowDays));

    // Pré-lecture unique des kcal loguées jour par jour (évite des lectures
    // SharedPreferences répétées à chaque itération de la fenêtre glissante)
    // — avec repli Supabase groupé sur les jours absents du cache local
    // (voir _kcalByDay).
    final kcalByDay = await _kcalByDay(sp, rangeStart, now);

    final points = <ExpenditurePoint>[];
    final firstPlottable = now.subtract(Duration(days: days));

    for (int i = 0; i <= days; i++) {
      final windowEnd = firstPlottable.add(Duration(days: i));
      final windowStart = windowEnd.subtract(Duration(days: windowDays));

      final inWindow = history
          .where((w) => !w.date.isBefore(windowStart) && !w.date.isAfter(windowEnd))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (inWindow.length < 2) continue;

      final spanDays = inWindow.last.date.difference(inWindow.first.date).inDays;
      if (spanDays < (windowDays * 0.5).round()) continue;

      double totalKcal = 0;
      int daysWithFood = 0;
      for (int j = 0; j <= spanDays; j++) {
        final d = inWindow.first.date.add(Duration(days: j));
        final k = kcalByDay[_dateKey(d)] ?? 0.0;
        if (k > 0) {
          totalKcal += k;
          daysWithFood++;
        }
      }
      if (daysWithFood < (windowDays * 0.4).round()) continue;

      final avgKcal = totalKcal / daysWithFood;
      final weightChangeKg = inWindow.last.weightKg - inWindow.first.weightKg;
      final estimate = avgKcal - (weightChangeKg * _kKcalPerKgFat) / spanDays;

      // Bande d'incertitude : resserrée avec le volume de données (jamais
      // sous ±3%, aucune estimation empirique n'étant jamais parfaitement
      // certaine ; jusqu'à ±15% quand la fenêtre est peu couverte).
      final coverage = (daysWithFood / windowDays).clamp(0.0, 1.0);
      final uncertainty = estimate.abs() * (0.15 - 0.10 * coverage).clamp(0.03, 0.15);

      points.add(ExpenditurePoint(
        date: windowEnd,
        estimateKcal: estimate,
        lowKcal: estimate - uncertainty,
        highKcal: estimate + uncertainty,
      ));
    }
    return points;
  }

  /// État d'avancement vers le premier point de dépense énergétique
  /// affichable — retour d'Alex (12/08/2026) : "un utilisateur qui vient de
  /// commencer va se dire qu'on lui vend du rêve" en voyant un graphique
  /// vide sans explication. Reprend exactement les mêmes seuils que la
  /// fenêtre la plus récente de [expenditureHistory] (span ≥ 10j sur 2
  /// pesées, ≥ 8 jours de journal renseigné sur ces 20 derniers jours) pour
  /// que le message affiché soit toujours honnête vis-à-vis du graphique.
  Future<ExpenditureReadiness> expenditureReadiness({int windowDays = 20}) async {
    final sp = await SharedPreferences.getInstance();
    final history = await _readHistory(sp);
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(days: windowDays));

    final inWindow = history
        .where((w) => !w.date.isBefore(windowStart) && !w.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final spanDays = inWindow.length >= 2
        ? inWindow.last.date.difference(inWindow.first.date).inDays
        : 0;

    // Bug corrigé (14/08/2026, retour d'Alex : "je suis repassé à 1/8 alors
    // qu'hier j'étais à 3/8, alors que je logue tous les jours") : cette
    // boucle bornait le comptage des repas sur `spanDays` — l'écart entre la
    // 1re et la dernière PESÉE dans la fenêtre — au lieu des 20 derniers
    // jours annoncés par le libellé ("Repas renseignés (20 derniers
    // jours)"). Si les pesées elles-mêmes ne couvrent pas toute la fenêtre
    // de 20 jours (span plus court), le comptage des repas se retrouvait
    // silencieusement raccourci d'autant — deux métriques indépendantes
    // (écart entre pesées / régularité du journal) accidentellement
    // couplées par une seule et même boucle. `computeCalibration()` (juste
    // au-dessus) fait la même chose mais À DESSEIN : ce calcul-là moyenne
    // les calories SPÉCIFIQUEMENT sur la période couverte par les 2 pesées
    // comparées, ça n'a rien à voir ici — cet indicateur d'avancement doit
    // couvrir la fenêtre de 20 jours entière, indépendamment des pesées.
    // Repli Supabase groupé (Priorité 53, 14/08/2026) sur les jours absents
    // du cache local `history_snapshots` — voir _kcalByDay.
    final kcalByDay = await _kcalByDay(sp, now.subtract(Duration(days: windowDays - 1)), now);
    final daysWithFood = kcalByDay.values.where((k) => k > 0).length;

    final minSpanDays = (windowDays * 0.5).round();
    final minFoodDays = (windowDays * 0.4).round();

    return ExpenditureReadiness(
      weighInsCount: inWindow.length,
      spanDays: spanDays,
      minSpanDays: minSpanDays,
      daysWithFoodLogged: daysWithFood,
      minFoodDays: minFoodDays,
      windowDays: windowDays,
    );
  }
}

/// Voir [CalibrationService.expenditureReadiness].
class ExpenditureReadiness {
  final int weighInsCount;
  final int spanDays;
  final int minSpanDays;
  final int daysWithFoodLogged;
  final int minFoodDays;
  final int windowDays;
  const ExpenditureReadiness({
    required this.weighInsCount,
    required this.spanDays,
    required this.minSpanDays,
    required this.daysWithFoodLogged,
    required this.minFoodDays,
    required this.windowDays,
  });

  bool get ready =>
      weighInsCount >= 2 && spanDays >= minSpanDays && daysWithFoodLogged >= minFoodDays;

  double get spanProgress => (spanDays / minSpanDays).clamp(0.0, 1.0);
  double get foodProgress => (daysWithFoodLogged / minFoodDays).clamp(0.0, 1.0);
}