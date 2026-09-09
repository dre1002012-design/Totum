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
  // ci-dessous). `daysWithFoodLogged`/`windowDays` renseignent la couverture
  // réelle de cette fenêtre (déjà ce qui pilote `lowKcal`/`highKcal`).
  final double avgKcalLogged;
  final double weightChangeKg;
  final int daysWithFoodLogged;
  final int windowDays;
  const ExpenditurePoint({
    required this.date,
    required this.estimateKcal,
    required this.lowKcal,
    required this.highKcal,
    this.avgKcalLogged = 0,
    this.weightChangeKg = 0,
    this.daysWithFoodLogged = 0,
    this.windowDays = 0,
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

  /// Retire de l'historique toute pesée prise pendant une période de pause
  /// déclarée — voir [computeCalibration] pour le raisonnement.
  Future<List<WeighIn>> _excludePaused(List<WeighIn> history) async {
    final pauses = await PauseService.instance.load();
    if (pauses.isEmpty) return history;
    return history.where((w) => !pauses.any((p) => p.contains(w.date))).toList();
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
      List<dynamic> rows;
      try {
        rows = await _client
            .from('food_entries')
            .select('entry_date, energy_kcal')
            .eq('user_id', user.id)
            .gte('entry_date', fetchStart)
            .order('entry_date', ascending: false)
            .limit(_foodEntriesFetchLimit);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 800));
        rows = await _client
            .from('food_entries')
            .select('entry_date, energy_kcal')
            .eq('user_id', user.id)
            .gte('entry_date', fetchStart)
            .order('entry_date', ascending: false)
            .limit(_foodEntriesFetchLimit);
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

    final inWindow = (await _excludePaused(history))
        .where((w) => !w.date.isBefore(windowStart))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Seuil COMPTE de jours distincts pesés (jamais l'écart de dates seul —
    // voir le commentaire sur `_minWeighDays`) : à la fois le critère de
    // suffisance ET le chiffre affiché à l'écran (`daysOfWeightData`), pour
    // qu'il n'y ait plus jamais d'écart entre "ce que dit la barre de
    // progression" et "ce qu'exige réellement le calcul" — exactement la
    // classe de bug déjà rencontrée (Priorités 52/53/59).
    if (inWindow.length < _minWeighDays) {
      return CalibrationResult(hasEnoughData: false, daysOfWeightData: inWindow.length);
    }

    final rawFirst = inWindow.first;
    final rawLast = inWindow.last;
    final rawSpanDays = rawLast.date.difference(rawFirst.date).inDays;

    // ── Robustesse : on moyenne les pesées du DÉBUT et de la FIN de la
    // période (premiers/derniers 30 %), au lieu de ne comparer que 2 points
    // isolés qui peuvent être faussés par la rétention d'eau, un repas
    // salé ou une pesée à une heure inhabituelle. Si une seule pesée existe
    // dans un segment, la "moyenne" est simplement cette pesée — la méthode
    // devient automatiquement plus fiable si l'utilisateur pèse plus souvent.
    //
    // BUG CORRIGÉ (19/08/2026, retour d'Alex — TDEE calibré aberrant après
    // une simple fluctuation de poids en fin de fenêtre) : cette moyenne
    // portait jusqu'ici sur le poids BRUT (`w.weightKg`), alors que
    // [emaTrend] (juste au-dessus dans ce même fichier, déjà utilisé pour la
    // courbe "Poids tendance") existe précisément pour filtrer le bruit
    // jour-à-jour (eau/sel/glycogène/horaire de pesée) avant toute analyse.
    // Sur une fenêtre minimale de 10 jours, un simple pic d'eau de 1-2kg en
    // fin de période (rétention passagère, PAS un vrai changement de masse
    // grasse) était lu comme un "gain" ou une "perte" réels et se propageait
    // tel quel dans l'équation d'équilibre énergétique (×7700 kcal/kg) —
    // produisant un TDEE empirique déconnecté de la réalité (observé : chute
    // de plusieurs centaines de kcal). On calcule maintenant la moyenne des
    // segments sur le poids TENDANCE (lissé), jamais sur le brut — même
    // principe que la courbe affichée à l'utilisateur, qu'il reconnaît et
    // comprend déjà.
    final trend = emaTrend(inWindow);
    final trended = List<WeighIn>.generate(
        inWindow.length, (i) => WeighIn(inWindow[i].date, trend[i]));

    final segmentSpan = (rawSpanDays * 0.3).round().clamp(0, rawSpanDays);
    final earlyEnd = rawFirst.date.add(Duration(days: segmentSpan));
    final lateStart = rawLast.date.subtract(Duration(days: segmentSpan));

    final earlyPoints = trended.where((w) => !w.date.isAfter(earlyEnd)).toList();
    final latePoints = trended.where((w) => !w.date.isBefore(lateStart)).toList();

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

    if (effectiveSpanDays < (_minWeighDays * 0.6).round()) {
      // Les segments moyennés sont trop rapprochés pour être fiables (cas
      // marginal : jours pesés groupés sur une courte portion de la
      // fenêtre malgré un compte suffisant, ex. 10 jours pesés d'affilée
      // suivis d'un long trou).
      return CalibrationResult(hasEnoughData: false, daysOfWeightData: inWindow.length);
    }

    // Moyenne des calories loguées sur la période couverte par les pesées —
    // les jours de pause sont exclus même si, exceptionnellement, quelque
    // chose a été loggé ce jour-là (voyage/repas de fête atypiques, pas
    // représentatifs de l'alimentation "normale" qu'on cherche à mesurer).
    //
    // BUG CORRIGÉ (20/08/2026, retour d'Alex — TDEE empirique de 1273 kcal/j
    // alors que son journal réel, sur Supabase, tourne à 2500-3100 kcal/j) :
    // ce calcul lisait via `_kcalForDate`, qui n'interroge QUE le cache local
    // `history_snapshots` (SharedPreferences, jamais synchronisé — voir son
    // commentaire). `expenditureHistory`/`expenditureReadiness` avaient déjà
    // été corrigées (Priorité 53, 14/08/2026) pour utiliser `_kcalByDay`, qui
    // complète les jours manquants du cache local par une requête groupée
    // Supabase (`food_entries`) — mais `computeCalibration`, la fonction qui
    // alimente directement le TDEE empirique utilisé pour la cible calorique
    // réelle, avait été oubliée lors de cette correction. Un cache local
    // troué (réinstall, changement d'appareil, purge) faisait donc paraître
    // le journal quasi vide à CE seul calcul, malgré un historique Supabase
    // complet — produisant un TDEE empirique aberrant et dangereusement bas.
    final kcalByDay = await _kcalByDay(sp, rawFirst.date, rawLast.date);
    final todayKey = _dateKey(now);
    double totalKcal = 0;
    int daysWithFood = 0;
    for (int i = 0; i <= rawSpanDays; i++) {
      final d = rawFirst.date.add(Duration(days: i));
      // BUG CORRIGÉ (01/09/2026, retour d'Alex — "j'ai renseigné mon petit-
      // déjeuner et la dépense a chuté") : la journée EN COURS (aujourd'hui)
      // entrait dans cette moyenne dès le premier aliment loggé, avec un
      // total forcément PARTIEL (petit-déjeuner seul, ex. 597 kcal, contre
      // 3000+ kcal une fois la journée complète) — noyée au même titre
      // qu'un vrai jour terminé, elle tirait mécaniquement la moyenne vers
      // le bas à chaque repas ajouté, jusqu'à ce que la journée se termine.
      // Une journée ne peut être jugée "loguée" qu'une fois TERMINÉE — la
      // journée du jour ne doit donc jamais entrer dans cette moyenne, quel
      // que soit ce qui y a déjà été saisi (même principe que
      // [expenditureHistory] ci-dessous, qui alimente le graphique).
      if (_dateKey(d) == todayKey) continue;
      if (await PauseService.instance.isPausedOn(d)) continue;
      final k = kcalByDay[_dateKey(d)] ?? 0.0;
      if (k > 0) {
        totalKcal += k;
        daysWithFood++;
      }
    }

    if (daysWithFood < _minFoodDays) {
      return CalibrationResult(
        hasEnoughData: false,
        daysOfWeightData: inWindow.length,
        daysOfFoodData: daysWithFood,
      );
    }

    final avgKcal = totalKcal / daysWithFood;
    final weightChangeKg = avgLateWeight - avgEarlyWeight;
    // BUG CORRIGÉ (19/08/2026, audit "aucune faille") : utilisait une
    // constante fixe de 7700 kcal/kg — alors que le reste du moteur
    // (`_goalEnergyAdjustmentKcal`/`effectiveEnergyDensityKcalPerKg` dans
    // profile.dart) applique déjà un modèle de densité énergétique VARIABLE
    // selon la vitesse du changement de poids (rapide = plus d'eau/glycogène,
    // lent = plus proche de graisse pure — voir la doc de la fonction). Une
    // même incohérence de fond que celle déjà corrigée pour le poids
    // brut/tendance : appliquer une seule densité fixe partout revient à
    // ignorer que 2-3kg gagnés en un week-end (cheat meal, sel) ne "pèsent"
    // pas la même chose en kcal que 2-3kg perdus sur plusieurs semaines.
    final rateBwPerWeek = (effectiveSpanDays > 0 && avgEarlyWeight > 0)
        ? (weightChangeKg / avgEarlyWeight) / (effectiveSpanDays / 7.0)
        : 0.0;
    final density = effectiveEnergyDensityKcalPerKg(rateBwPerWeek.abs());
    // Équation d'équilibre énergétique : le TDEE réel est ce qu'il aurait
    // fallu manger pour rester stable, compte tenu du poids gagné/perdu,
    // calculé sur l'écart EFFECTIF entre les 2 segments moyennés.
    final empiricalTdee = avgKcal - (weightChangeKg * density) / effectiveSpanDays;

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
    final history = pauses.isEmpty
        ? rawHistory
        : rawHistory.where((w) => !pauses.any((p) => p.contains(w.date))).toList();
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

      // Seuil COMPTE (jours distincts pesés dans la fenêtre), pas l'écart de
      // dates — même critère que [computeCalibration]/[expenditureReadiness]
      // (voir `_minWeighDays`), pour que ce graphique ne puisse jamais
      // afficher un point que la calibration elle-même refuserait.
      final spanDays = inWindow.last.date.difference(inWindow.first.date).inDays;
      final minWeighCount = (windowDays * 0.5).round();
      if (inWindow.length < minWeighCount) continue;

      double totalKcal = 0;
      int daysWithFood = 0;
      final todayKey = _dateKey(now);
      for (int j = 0; j <= spanDays; j++) {
        final d = inWindow.first.date.add(Duration(days: j));
        // BUG CORRIGÉ (01/09/2026, retour d'Alex — "j'ai renseigné mon
        // petit-déjeuner et la dépense a chuté") : même correctif que
        // [computeCalibration] ci-dessus — la journée EN COURS ne peut pas
        // entrer dans cette moyenne, son total est par nature partiel tant
        // qu'elle n'est pas terminée (un petit-déjeuner seul, ex. 597 kcal,
        // noyé au même titre qu'un jour complet à 3000+ kcal, tirait
        // l'estimation vers le bas à chaque repas ajouté).
        if (_dateKey(d) == todayKey) continue;
        if (pauses.any((p) => p.contains(d))) continue;
        final k = kcalByDay[_dateKey(d)] ?? 0.0;
        if (k > 0) {
          totalKcal += k;
          daysWithFood++;
        }
      }
      if (daysWithFood < (windowDays * 0.4).round()) continue;

      final avgKcal = totalKcal / daysWithFood;

      // BUG CORRIGÉ (24/08/2026, audit "revérifie tout" — retour d'Alex)
      // : ce point utilisait encore une comparaison à 2 POINTS (1er/dernier
      // du poids TENDANCE de la fenêtre), alors que [computeCalibration] —
      // la fonction qui calcule et sauvegarde la VRAIE cible calorique —
      // était déjà passée à une moyenne des segments début/fin (30 %
      // chacun, voir son commentaire du 19/08/2026) pour rester robuste à
      // un seul point de fin de fenêtre bruité. Les deux méthodes
      // coexistaient sans que rien à l'écran ne le précise : sur les
      // données réelles d'Alex, ça produisait 2841 kcal/j ici contre 2783
      // kcal/j réellement utilisés pour la cible — 2 chiffres corrects
      // chacun pour sa propre méthode, mais lisibles comme un désaccord
      // interne. Reprend maintenant EXACTEMENT le même calcul que
      // [computeCalibration] (segments début/fin sur le poids tendance,
      // écart effectif entre les 2 centroïdes de segment) : le point le
      // plus récent de ce graphique correspond désormais, au jour près, au
      // TDEE empirique qui alimente réellement la cible.
      final trend = emaTrend(inWindow);
      final trended = List<WeighIn>.generate(
          inWindow.length, (k) => WeighIn(inWindow[k].date, trend[k]));

      final segmentSpan = (spanDays * 0.3).round().clamp(0, spanDays);
      final earlyEnd = inWindow.first.date.add(Duration(days: segmentSpan));
      final lateStart = inWindow.last.date.subtract(Duration(days: segmentSpan));
      final earlyPoints = trended.where((w) => !w.date.isAfter(earlyEnd)).toList();
      final latePoints = trended.where((w) => !w.date.isBefore(lateStart)).toList();

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

      // Même garde-fou que [computeCalibration] : segments moyennés trop
      // rapprochés pour être fiables (pesées groupées sur une portion
      // étroite de la fenêtre malgré un compte suffisant).
      if (effectiveSpanDays < (minWeighCount * 0.6).round()) continue;

      final weightChangeKg = avgLateWeight - avgEarlyWeight;
      // Même densité énergétique VARIABLE que [computeCalibration] (voir son
      // commentaire) — jamais 7700 kcal/kg fixe — pour rester cohérent avec
      // le reste du moteur.
      final rateBwPerWeek = (avgEarlyWeight > 0)
          ? (weightChangeKg / avgEarlyWeight) / (effectiveSpanDays / 7.0)
          : 0.0;
      final density = effectiveEnergyDensityKcalPerKg(rateBwPerWeek.abs());
      final estimate = avgKcal - (weightChangeKg * density) / effectiveSpanDays;

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
        avgKcalLogged: avgKcal,
        weightChangeKg: weightChangeKg,
        daysWithFoodLogged: daysWithFood,
        windowDays: windowDays,
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

    final inWindow = (await _excludePaused(rawHistory))
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