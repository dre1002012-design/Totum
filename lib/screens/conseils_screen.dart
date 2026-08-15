// lib/screens/conseils_screen.dart
// TOTUM – Onglet CONSEILS (chargement contenu depuis assets/advices.json)
// - Garde la forme/ordre/visuel existants
// - Ajoute grosse rotation (HÉRO, mindset, coach, recettes) via JSON externe
// - Anti-répétition + rotation 6x/jour
// - Fallback interne si l’asset est absent/corrompu
//
// Dépendances: flutter (SDK), shared_preferences (déjà), services (rootBundle)
// Aucune autre dépendance.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'sun_vitamin_d_screen.dart';
import '../services/breath_audio_engine.dart';
import '../services/breath_background_session.dart';
import '../services/breath_stats.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/totum_score.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bilan_screen.dart'
    show computeTodayTotumScore, BilanScreen, showNutrientFiche, NutrientFicheRepo;

import '../services/foods_loader.dart' as foods_loader;
import '../services/nutrient_labels.dart';
import 'account_screen.dart';
import '../theme/totum_style.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';

// === THEME =========================================================
const Color kTotumOrange = TotumColors.accent;

/// Traduit une catégorie de recette (`TotumRecipe.category`, `_cats`) pour
/// l'affichage — cette valeur sert aussi de CLÉ DE COMPARAISON directe avec
/// les données JSON (`r.category == _filter`) : jamais modifiée à la
/// source, uniquement traduite au moment du rendu (même principe que
/// nutrientDisplayLabel, voir services/nutrient_labels.dart).
String _recipeCategoryLabel(String cat, AppLocalizations l10n) => switch (cat) {
      'Toutes' => l10n.consCatAll,
      'Petit-déjeuner' => l10n.consCatBreakfast,
      'Déjeuner' => l10n.consCatLunch,
      'Dîner' => l10n.consCatDinner,
      'Collation' => l10n.consCatSnack,
      'Pré-workout' => l10n.consCatPreworkout,
      _ => cat,
    };

/// Traduit un tag de filtre rapide (`_quickFilters`, `TotumRecipe.tags`/
/// `.goalTags`) pour l'affichage — même principe : la clé stable (1er
/// élément du tuple, ex. 'perte_poids') reste inchangée, seul le libellé
/// affiché est traduit ici.
String _quickFilterLabel(String tagKey, AppLocalizations l10n) => switch (tagKey) {
      'perte_poids' => l10n.consTagLight,
      'hyperproteine' => l10n.consTagHighProtein,
      'rapide' => l10n.consTagQuick,
      'sans_gluten' => l10n.consTagGlutenFree,
      'sans_lactose' => l10n.consTagLactoseFree,
      'vegetarien' => l10n.profileDietVegetarian,
      'vegetalien' => l10n.profileDietVegan,
      'post_workout' => l10n.consTagPostWorkout,
      _ => tagKey,
    };
// === MODELES =======================================================
class AdviceScript {
  final String cardTitle;
  final String focusTheme;
  final String scienceInsight;

  final String deficitCritique;
  final TotumScore? score;
  final String? coachMessage;
  final String? deficitKey; // clé du micronutriment le plus déficitaire
  final CoachAdvice? advNutrition;
  final CoachAdvice? advMouvement;
  final CoachAdvice? advSommeil;
  final CoachAdvice? advStress;
  final CoachAdvice? advMindset;
  final List<TotumRecipe> suggestedRecipes;
  final List<DeficitInfo> deficits;
  final String beneficeAssocie;
  final String sourcePremium;
  final String astuceAbsorption;
  final List<String> extraMicronutrientHints;
  final List<String> recipeIdeas;

  final String chronoAnalyse;
  final String actionLifestyle;

  final String logTitle;
  final List<String> logFields;

  final String defi24h;
  final String quotePremium;

  final String macroSummaryTitle;
  final String macroSummaryBody;

  final String activityCoachTitle;
  final String activityCoachBody;

  final String mindsetTitle;
  final String mindsetBody;

  final double? hydrationRatio;
  final double? sleepHours;
  final int? stressLevel;
  final double? energyRatio;
  final double? proteinRatio;

  const AdviceScript({
    required this.cardTitle,
    required this.focusTheme,
    required this.scienceInsight,
    required this.deficitCritique,
    this.score,
    this.coachMessage,
    this.deficitKey,
    this.advNutrition,
    this.advMouvement,
    this.advSommeil,
    this.advStress,
    this.advMindset,
    this.suggestedRecipes = const [],
    this.deficits = const [],
    required this.beneficeAssocie,
    required this.sourcePremium,
    required this.astuceAbsorption,
    required this.extraMicronutrientHints,
    required this.recipeIdeas,
    required this.chronoAnalyse,
    required this.actionLifestyle,
    required this.logTitle,
    required this.logFields,
    required this.defi24h,
    required this.quotePremium,
    required this.macroSummaryTitle,
    required this.macroSummaryBody,
    required this.activityCoachTitle,
    required this.activityCoachBody,
    required this.mindsetTitle,
    required this.mindsetBody,
    this.hydrationRatio,
    this.sleepHours,
    this.stressLevel,
    this.energyRatio,
    this.proteinRatio,
  });
}

class _HolisticLog {
  final double? sleepHours;
  final double? waterLiters;
  final int? stress;
  const _HolisticLog({this.sleepHours, this.waterLiters, this.stress});
}

class _AdviceGoalsRaw {
  final double kcal, prot, weightKg;
  final String sex;
  final int activityIdx;
  final int goalIndex;
  const _AdviceGoalsRaw({
    required this.kcal,
    required this.prot,
    required this.sex,
    required this.weightKg,
    required this.activityIdx,
    required this.goalIndex,
  });
}

class _AdviceDayTotals {
  final double kcal, prot, carb, fat, fiber;
  final Map<String, double> micros;
  final double waterMlFromJournal;
  final List<String> waterSources;
  final bool hasData;
  _AdviceDayTotals({
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.micros,
    required this.waterMlFromJournal,
    required this.waterSources,
    required this.hasData,
  });
  factory _AdviceDayTotals.empty() => _AdviceDayTotals(
        kcal: 0,
        prot: 0,
        carb: 0,
        fat: 0,
        fiber: 0,
        micros: const <String, double>{},
        waterMlFromJournal: 0,
        waterSources: const [],
        hasData: false,
      );
}

class _AdviceHydration {
  final double journalMl, manualMl, targetMl;
  final List<String> sources;
  const _AdviceHydration({
    required this.journalMl,
    required this.manualMl,
    required this.targetMl,
    required this.sources,
  });
  double get totalMl => journalMl + manualMl;
  double get ratio => targetMl > 0 ? (totalMl / targetMl) : 0.0;
}

class _AdviceTargets {
  final double goalKcal, goalProt, goalCarb, goalFat, goalFiber;
  final double goalO9, goalLA, goalALA, goalEPA, goalDHA;
  final Map<String, double> vitTargets;
  final Map<String, double> minTargets;
  const _AdviceTargets({
    required this.goalKcal,
    required this.goalProt,
    required this.goalCarb,
    required this.goalFat,
    required this.goalFiber,
    required this.goalO9,
    required this.goalLA,
    required this.goalALA,
    required this.goalEPA,
    required this.goalDHA,
    required this.vitTargets,
    required this.minTargets,
  });
}

class _ThemeDecision {
  final String primaryTopic;
  final String microTopic;
  final double hydrationRatio, energyRatio, proteinRatio;
  final Map<String, double> microRatios;
  _ThemeDecision({
    required this.primaryTopic,
    required this.microTopic,
    required this.hydrationRatio,
    required this.microRatios,
    required this.energyRatio,
    required this.proteinRatio,
  });
}

// === UTILS TEMPS/HISTO ============================================
String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _journalKeyForDate(DateTime d) => 'journal_${_dateKey(d)}';
String _hydrationManualKeyForDate(DateTime d) =>
    'hydration_manual_ml_${_dateKey(d)}';
String _holisticSleepKey(DateTime d) => 'holistic_sleep_h_${_dateKey(d)}';
String _holisticWaterKey(DateTime d) => 'holistic_water_l_${_dateKey(d)}';
String _holisticStressKey(DateTime d) => 'holistic_stress_${_dateKey(d)}';

const String _adviceHistoryKey = 'advice_history_topics';
const String _packHistoryKey = 'advice_history_packs';

int _dayOfYearIndex(DateTime now, int modulo) {
  final start = DateTime(now.year, 1, 1);
  final dayIndex = now.difference(start).inDays;
  if (modulo <= 0) return 0;
  return dayIndex % modulo;
}

int _hourSlot6(DateTime now) => now.hour ~/ 4; // 0..5

Future<List<String>> _readHistory(
    SharedPreferences sp, String key) async {
  final raw = sp.getString(key);
  if (raw == null || raw.isEmpty) return <String>[];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => e.toString())
        .toList();
  } catch (_) {
    return <String>[];
  }
}

Future<void> _pushHistory(
  SharedPreferences sp,
  String key,
  String value, {
  int keep = 6,
}) async {
  final hist = await _readHistory(sp, key);
  final updated = <String>[value, ...hist.where((t) => t != value)];
  await sp.setString(
    key,
    jsonEncode(updated.take(keep).toList()),
  );
}

// === CONTENU EXTERNE (JSON) =======================================

class AdviceContentRepo {
  AdviceContentRepo._();
  static final AdviceContentRepo instance = AdviceContentRepo._();

  List<Map<String, String>> mindsetPacks = [];
  Map<String, List<String>> coach = {};
  Map<String, List<Map<String, String>>> heroPool = {};
  Map<String, List<String>> recipesByKey = {};

  bool get isLoaded => heroPool.isNotEmpty;

  Future<void> loadFromAsset(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;

      // Mindset
      final ms = (jsonMap['mindsetPacks'] as List?) ?? const [];
      mindsetPacks = ms
          .map<Map<String, String>>(
            (e) => {
              'title': e['title']?.toString() ?? '',
              'body': e['body']?.toString() ?? '',
            },
          )
          .toList();

      // Coach
      final c = (jsonMap['coach'] as Map?) ?? const {};
      coach = c.map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List).map((e) => e.toString()).toList(),
        ),
      );

      // Hero
      final hp = (jsonMap['heroPool'] as Map?) ?? const {};
      heroPool = hp.map((k, v) {
        final list = (v as List)
            .map<Map<String, String>>(
              (m) => {
                'title': m['title']?.toString() ?? '',
                'theme': m['theme']?.toString() ?? '',
                'insight': m['insight']?.toString() ?? '',
              },
            )
            .toList();
        return MapEntry(k.toString(), list);
      });

      // Recettes
      final rbk = (jsonMap['recipesByKey'] as Map?) ?? const {};
      recipesByKey = rbk.map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List).map((e) => e.toString()).toList(),
        ),
      );
    } catch (_) {
      _loadFallback(); // si asset KO → on garde une base interne
    }
  }

  void _loadFallback() {
    // === Fallback minimal (extraits) pour garantir le fonctionnement sans asset ===
    mindsetPacks = [
      {
        'title': '🧠 Progression > perfection',
        'body':
            'Chaque repas aligné avec ton objectif est un vote pour l’identité que tu construis.'
      },
      {
        'title': '💪 Constance antifragile',
        'body':
            'Les écarts ne te définissent pas. C’est la moyenne de la semaine qui compte.'
      },
    ];
    coach = {
      'sedentaire': [
        '2–3×/semaine 20–30 min…',
        '6–8k pas/j…',
      ],
      'perte': ['Déficit léger + protéines…'],
      'masse': ['Surplus +10–15 %, protéines 1.6–2.2 g/kg…'],
      'maintien': ['3–4 séances variées/sem…'],
    };
    heroPool = {
      'hydration': [
        {
          'title': '💧 Hydratation : ton boost silencieux',
          'theme': 'Clarté mentale',
          'insight': 'Répartis l’eau + tisane le soir.'
        }
      ],
      'omega3': [
        {
          'title': '🐟 Oméga-3 : cerveau & membranes',
          'theme': 'Inflammation & humeur',
          'insight': '2 poissons gras/sem.'
        }
      ],
      'fibers': [
        {
          'title': '🌱 Fibres : microbiote',
          'theme': 'Satiété',
          'insight': 'Légumineuses + légumes + fruits entiers.'
        }
      ],
    };
    recipesByKey = {
      'omega3': [
        'Bowl sardines-citron-avocat',
        'Salade maquereau + lentilles',
      ],
      'fibers': [
        'Buddha bowl légumineuses + céréale complète',
      ],
    };
  }
}

// === FOODS / JOURNAL ==============================================
Future<void> _ensureFoodsLoadedForAdvice() async {
  final repo = foods_loader.FoodsRepository.instance;
  try {
    final items = (repo.items as List);
    if (items.isNotEmpty) return;
  } catch (_) {}
  try {
    await repo.loadFromAsset('assets/foods.csv');
  } catch (_) {}
  try {
    await repo.loadCustomFoods();
  } catch (_) {}
}

bool _looksLikeWaterForAdvice(String name) {
  final lower = name.toLowerCase();
  if (lower.startsWith('eau ')) return true;
  const brands = [
    'evian',
    'badoit',
    'vittel',
    'volvic',
    'contrex',
    'perrier',
    'hépar',
    'hepar',
    'st yorre',
    'saint-yorre',
    'saint yorre',
    'st-yorre',
    'quézac',
    'quezac',
    'wattwiller',
  ];
  return brands.any((b) => lower.contains(b));
}

Future<_AdviceDayTotals> _computeDayTotalsForAdviceDate(
  DateTime day,
  SharedPreferences sp,
) async {
  await _ensureFoodsLoadedForAdvice();
  final repo = foods_loader.FoodsRepository.instance;

  final raw = sp.getString(_journalKeyForDate(day));
  if (raw == null || raw.isEmpty) return _AdviceDayTotals.empty();

  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return _AdviceDayTotals.empty();
  }

  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
  final microTotals = <String, double>{};
  double waterMl = 0;
  final waterNames = <String>{};

  // Lookup indexé O(1) (Priorité 31) : reconstruire et scanner linéairement
  // une liste fusionnée de ~3500 aliments par entrée journalière rendait ce
  // calcul coûteux, d'autant qu'il est répété pour chaque jour d'un bilan.
  foods_loader.FoodItem? findFood(String id) => repo.findById(id);

  for (final mealList in decoded.values) {
    if (mealList is! List) continue;
    for (final entry in mealList) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final id = (m['id'] ?? '').toString();
      final name = (m['name'] ?? '').toString();
      final grams = (m['grams'] as num?)?.toDouble() ?? 0.0;

      kcal += (m['kcal'] as num?)?.toDouble() ?? 0.0;
      prot += (m['prot'] as num?)?.toDouble() ?? 0.0;
      carb += (m['carb'] as num?)?.toDouble() ?? 0.0;
      fat += (m['fat'] as num?)?.toDouble() ?? 0.0;
      fiber += (m['fiber'] as num?)?.toDouble() ?? 0.0;

      final food = findFood(id);
      if (food != null) {
        final mic = food.microsFor(grams);
        mic.forEach(
          (k, v) => microTotals[k] = (microTotals[k] ?? 0) + v,
        );
      }

      if (_looksLikeWaterForAdvice(name)) {
        waterMl += grams;
        waterNames.add(name);
      }
    }
  }

  // Cohérence avec le Bilan : la vitamine D du soleil compte le jour courant.
  final nowSun = DateTime.now();
  if (day.year == nowSun.year && day.month == nowSun.month && day.day == nowSun.day) {
    final sunD = await readSunVitD(nowSun);
    if (sunD > 0) {
      microTotals['Vitamine_D_µg_100g'] =
          (microTotals['Vitamine_D_µg_100g'] ?? 0) + sunD;
    }
  }

  return _AdviceDayTotals(
    kcal: kcal,
    prot: prot,
    carb: carb,
    fat: fat,
    fiber: fiber,
    micros: microTotals,
    waterMlFromJournal: waterMl,
    waterSources: waterNames.toList(),
    hasData: (kcal + prot + carb + fat + fiber) > 0,
  );
}

// === GOALS/TARGETS ================================================
Future<_AdviceGoalsRaw> _readGoalsForAdvice() async {
  final sp = await SharedPreferences.getInstance();
  return _AdviceGoalsRaw(
    kcal: sp.getDouble('goals_kcal') ?? 2000.0,
    prot: sp.getDouble('goals_prot') ?? 120.0,
    sex: (sp.getString('profile_sex') ?? 'male') == 'female'
        ? 'female'
        : 'male',
    weightKg: sp.getDouble('profile_weight') ?? 70.0,
    activityIdx: sp.getInt('profile_activity') ?? 0,
    goalIndex: sp.getInt('profile_goal') ?? 1,
  );
}

double _hydrationTargetForAdvice(double weightKg, int activityIdx) {
  int level = activityIdx.clamp(0, 4);
  int bonus = 0;
  if (level == 1) {
    bonus = 300;
  } else if (level == 2) {
    bonus = 600;
  } else if (level >= 3) {
    bonus = 900;
  }
  return (weightKg * 30.0 + bonus).clamp(1000, 6000).toDouble();
}

Future<_AdviceHydration> _computeHydrationForAdviceToday(
  _AdviceGoalsRaw goals,
  SharedPreferences sp, {
  _AdviceDayTotals? dayTotals,
}) async {
  await _ensureFoodsLoadedForAdvice();
  final now = DateTime.now();
  // Réutilise le total du jour déjà calculé par l'appelant plutôt que de le
  // reconstruire (Priorité 31) : ce recalcul redondant, doublé du scan
  // linéaire des aliments, était une des causes de la latence perçue sur cet
  // onglet.
  dayTotals ??= await _computeDayTotalsForAdviceDate(now, sp);
  final manual = sp.getDouble(_hydrationManualKeyForDate(now)) ?? 0.0;
  final target = sp.getDouble('goals_water_ml') ??
      _hydrationTargetForAdvice(goals.weightKg, goals.activityIdx);
  return _AdviceHydration(
    journalMl: dayTotals.waterMlFromJournal,
    manualMl: manual,
    targetMl: target,
    sources: dayTotals.waterSources,
  );
}

/// Lit les cibles EXACTES calculées par profile.dart (âge+sexe+poids+activité),
/// stockées en SharedPreferences sous les mêmes clés que le Bilan.
/// Ainsi les pourcentages des Conseils sont strictement alignés sur le Bilan.
Future<_AdviceTargets> _buildAdviceTargets(_AdviceGoalsRaw goals) async {
  final sp = await SharedPreferences.getInstance();
  final isF = goals.sex == 'female';

  final goalKcal = goals.kcal <= 0 ? 2000.0 : goals.kcal;
  final goalProt = goals.prot <= 0 ? 120.0 : goals.prot;
  final goalCarb = (goalKcal * 0.55) / 4.0;
  final goalFat = (goalKcal * 0.35) / 9.0;
  final goalFiber = sp.getDouble('goals_fiber') ?? 30.0;

  final goalO9 = sp.getDouble('goals_o9') ?? 15.0;
  final goalLA = sp.getDouble('goals_o6') ?? 10.0;
  final goalALA = sp.getDouble('goals_o3') ?? 2.0;
  final goalEPA = sp.getDouble('goals_epa') ?? 0.25;
  final goalDHA = sp.getDouble('goals_dha') ?? 0.25;

  // Mêmes clés que le Bilan (_readGoalsRaw) → cibles personnalisées identiques.
  final vitTargets = <String, double>{
    'Vit A': sp.getDouble('goals_vita_ug') ?? (isF ? 650.0 : 750.0),
    'Vit D': sp.getDouble('goals_vitd_ug') ?? 15.0,
    'Vit E': sp.getDouble('goals_vite_mg') ?? (isF ? 9.0 : 10.0),
    'Vit K': sp.getDouble('goals_vitk_ug') ?? 79.0,
    'Vit C': sp.getDouble('goals_vitc_mg') ?? 110.0,
    'B1': sp.getDouble('goals_b1_mg') ?? 1.6,
    'B2': sp.getDouble('goals_b2_mg') ?? 1.6,
    'B3': sp.getDouble('goals_b3_mg') ?? 10.0,
    'B5': sp.getDouble('goals_b5_mg') ?? (isF ? 5.0 : 6.0),
    'B6': sp.getDouble('goals_b6_mg') ?? (isF ? 1.6 : 1.7),
    'B9': sp.getDouble('goals_b9_ug') ?? 330.0,
    'B12': sp.getDouble('goals_b12_ug') ?? 2.5,
  };
  final minTargets = <String, double>{
    'Calcium': sp.getDouble('goals_ca_mg') ?? 950.0,
    'Cuivre': sp.getDouble('goals_cu_mg') ?? (isF ? 1.5 : 1.9),
    'Fer': sp.getDouble('goals_fe_mg') ?? 11.0,
    'Iode': sp.getDouble('goals_i_ug') ?? 150.0,
    'Magnésium': sp.getDouble('goals_mg_mg') ?? (isF ? 300.0 : 380.0),
    // Cible EFSA (Adequate Intake) = 3.0 ; 8.0 était l'ancienne LIMITE DE
    // SÉCURITÉ réutilisée par erreur comme repli (voir profile.dart:377,
    // seule source de vérité pour cette valeur).
    'Manganèse': sp.getDouble('goals_mn_mg') ?? 3.0,
    'Phosphore': sp.getDouble('goals_p_mg') ?? 550.0,
    'Potassium': sp.getDouble('goals_k_mg') ?? 3500.0,
    'Sélénium': sp.getDouble('goals_se_ug') ?? 70.0,
    'Sodium': sp.getDouble('goals_na_mg') ?? 1500.0,
    'Zinc': sp.getDouble('goals_zn_mg') ?? (isF ? 11.0 : 14.0),
  };

  return _AdviceTargets(
    goalKcal: goalKcal,
    goalProt: goalProt,
    goalCarb: goalCarb,
    goalFat: goalFat,
    goalFiber: goalFiber,
    goalO9: goalO9,
    goalLA: goalLA,
    goalALA: goalALA,
    goalEPA: goalEPA,
    goalDHA: goalDHA,
    vitTargets: vitTargets,
    minTargets: minTargets,
  );
}

/// Reste-à-consommer aujourd'hui — base du Smart Match Score des recettes.
/// Réutilise l'infrastructure déjà en place pour les Conseils (mêmes
/// fonctions que le coach), aucune nouvelle source de données.
class RemainingToday {
  final double kcal, prot, carb, fat;
  final bool hasTargets;
  const RemainingToday({
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.hasTargets,
  });
}

Future<RemainingToday> computeRemainingToday() async {
  try {
    final sp = await SharedPreferences.getInstance();
    final goalsRaw = await _readGoalsForAdvice();
    final targets = await _buildAdviceTargets(goalsRaw);
    final today = await _computeDayTotalsForAdviceDate(DateTime.now(), sp);

    return RemainingToday(
      kcal: (targets.goalKcal - today.kcal).clamp(0, double.infinity),
      prot: (targets.goalProt - today.prot).clamp(0, double.infinity),
      carb: (targets.goalCarb - today.carb).clamp(0, double.infinity),
      fat: (targets.goalFat - today.fat).clamp(0, double.infinity),
      hasTargets: true,
    );
  } catch (_) {
    return const RemainingToday(
        kcal: 0, prot: 0, carb: 0, fat: 0, hasTargets: false);
  }
}

/// Normalise une chaîne pour la recherche par ingrédient (minuscules, sans
/// accents) — permet à "epinard" de matcher "Épinard, cuit".
String _normalizeSearch(String s) {
  const from = 'àâäáãåèéêëìíîïòóôõöùúûüçñÀÂÄÁÃÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑ';
  const to = 'aaaaaaeeeeiiiiooooouuuucnAAAAAAEEEEIIIIOOOOOUUUUCN';
  var out = s.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out;
}

/// Part réaliste de ce qu'il reste aujourd'hui qu'un repas de cette
/// catégorie devrait raisonnablement représenter — évite de comparer une
/// collation ou un petit-déjeuner au budget calorique de la JOURNÉE ENTIÈRE
/// (ce qui écrasait le score dès qu'il restait beaucoup à manger, tôt dans
/// la journée, quelle que soit la pertinence réelle de la recette).
const Map<String, double> _kCategoryShare = {
  'Petit-déjeuner': 0.28,
  'Déjeuner': 0.38,
  'Dîner': 0.38,
  'Collation': 0.14,
  'Pré-workout': 0.10,
};

/// Smart Match Score /100 : à quel point cette recette est une taille de
/// portion cohérente pour CE type de repas, compte tenu de ce qu'il te
/// reste à consommer aujourd'hui — donc du moment de la journée où tu
/// regardes. Pondéré calories (40%), protéines (30%), glucides (15%),
/// lipides (15%) — pénalité si la recette dépasse largement ton reste
/// calorique réel du jour, tous repas confondus.
int smartMatchScore(TotumRecipe r, RemainingToday remaining) {
  if (!remaining.hasTargets) return 50; // neutre si pas de contexte
  final portion = r.totalWeightG;
  double perPortion(double? per100) => (per100 ?? 0) * portion / 100;

  final rKcal = perPortion(r.kcal100);
  final rProt = perPortion(r.prot100);
  final rCarb = perPortion(r.carb100);
  final rFat = perPortion(r.fat100);

  final share = _kCategoryShare[r.category] ?? 0.30;
  final idealKcal = remaining.kcal * share;
  final idealProt = remaining.prot * share;
  final idealCarb = remaining.carb * share;
  final idealFat = remaining.fat * share;

  double closeness(double ideal, double recipeVal) {
    if (ideal <= 0) return recipeVal <= 5 ? 100 : 0;
    final diff = (recipeVal - ideal).abs() / ideal;
    return (100 - diff * 100).clamp(0, 100);
  }

  var score = closeness(idealKcal, rKcal) * 0.40 +
      closeness(idealProt, rProt) * 0.30 +
      closeness(idealCarb, rCarb) * 0.15 +
      closeness(idealFat, rFat) * 0.15;

  if (rKcal > remaining.kcal + 100) score -= 35;
  return score.round().clamp(0, 100);
}

// === HISTO HOLISTIQUE =============================================
Future<_HolisticLog> _readHolisticLog(
  SharedPreferences sp,
  DateTime day,
) async {
  return _HolisticLog(
    sleepHours: sp.getDouble(_holisticSleepKey(day)),
    waterLiters: sp.getDouble(_holisticWaterKey(day)),
    stress: sp.getInt(_holisticStressKey(day)),
  );
}

Future<void> _saveHolisticLog(
  SharedPreferences sp,
  DateTime day, {
  double? sleepHours,
  double? waterLiters,
  int? stress,
}) async {
  if (sleepHours != null) {
    await sp.setDouble(_holisticSleepKey(day), sleepHours);
  }
  if (waterLiters != null) {
    await sp.setDouble(_holisticWaterKey(day), waterLiters);
    await sp.setDouble(
      _hydrationManualKeyForDate(day),
      (waterLiters * 1000).clamp(0, 20000).toDouble(),
    );
  }
  if (stress != null) {
    await sp.setInt(_holisticStressKey(day), stress.clamp(1, 10));
  }
}

// === ROTATION/CHOIX ===============================================
T _pickRotating<T>(
  List<T> items, {
  required int slot,
  List<T>? avoid,
}) {
  if (items.isEmpty) throw StateError('empty items');
  final filtered =
      (avoid == null || avoid.isEmpty)
          ? items
          : items.where((e) => !avoid.contains(e)).toList();
  if (filtered.isEmpty) return items[slot % items.length];
  return filtered[slot % filtered.length];
}

_ThemeDecision _decideTheme({
  required _AdviceDayTotals day,
  required _AdviceHydration hyd,
  required _AdviceTargets targets,
}) {
  final micros = day.micros;
  double m(String key) => micros[key] ?? 0.0;

  final double o9 = m('Acide_oléique_W9_g_100g');
  final double la = m('Acide_linoléique_W6_LA_g_100g');
  final double ala = m('Acide_alpha-linolénique_W3_ALA_g_100g');
  final double epa = m('EPA_g_100g');
  final double dha = m('DHA_g_100g');

  final double vitA = m('Rétinol_µg_100g');
  final double vitD = m('Vitamine_D_µg_100g');
  final double vitE = m('Vitamine_E_mg_100g');
  final double vitK = m('Vitamine_K1_µg_100g') + m('Vitamine_K2_µg_100g');
  final double vitC = m('Vitamine_C_mg_100g');
  final double b1 = m('Vitamine_B1_mg_100g');
  final double b2 = m('Vitamine_B2_mg_100g');
  final double b3 = m('Vitamine_B3_mg_100g');
  final double b5 = m('Vitamine_B5_mg_100g');
  final double b6 = m('Vitamine_B6_mg_100g');
  final double b9 = m('Vitamine_B9_µg_100g');
  final double b12 = m('Vitamine_B12_µg_100g');

  final double calcium = m('Calcium_mg_100g');
  final double copper = m('Cuivre_mg_100g');
  final double iron = m('Fer_mg_100g');
  final double iodine = m('Iode_µg_100g');
  final double magnesium = m('Magnésium_mg_100g');
  final double manganese = m('Manganèse_mg_100g');
  final double phosphorus = m('Phosphore_mg_100g');
  final double potassium = m('Potassium_mg_100g');
  final double selenium = m('Sélénium_µg_100g');
  final double sodium = m('Sodium_mg_100g');
  final double zinc = m('Zinc_mg_100g');

  final double fibers = day.fiber;

  // On utilise les CIBLES PERSONNALISÉES (targets), plus les valeurs en dur,
  // pour que les pourcentages soient cohérents avec le reste de l'app.
  double safeDiv(double val, double? target, double fallback) {
    final t = (target == null || target <= 0) ? fallback : target;
    return val / t;
  }
  final vt = targets.vitTargets;
  final mt = targets.minTargets;
  final ratios = <String, double>{
    'omega9': safeDiv(o9, targets.goalO9, 15.0),
    'omega6': safeDiv(la, targets.goalLA, 10.0),
    'omega3_ALA': safeDiv(ala, targets.goalALA, 2.0),
    'omega3': safeDiv(ala, targets.goalALA, 2.0),
    'omega3_marins': safeDiv(epa + dha, targets.goalEPA + targets.goalDHA, 0.5),
    'EPA': safeDiv(epa, targets.goalEPA, 0.25),
    'DHA': safeDiv(dha, targets.goalDHA, 0.25),
    'vitA': safeDiv(vitA, vt['Vit A'], 700.0),
    'vitD': safeDiv(vitD, vt['Vit D'], 15.0),
    'vitE': safeDiv(vitE, vt['Vit E'], 10.0),
    'vitK': safeDiv(vitK, vt['Vit K'], 79.0),
    'vitC': safeDiv(vitC, vt['Vit C'], 110.0),
    'B1': safeDiv(b1, vt['B1'], 1.6),
    'B2': safeDiv(b2, vt['B2'], 1.6),
    'B3': safeDiv(b3, vt['B3'], 10.0),
    'B5': safeDiv(b5, vt['B5'], 6.0),
    'B6': safeDiv(b6, vt['B6'], 1.7),
    'B9': safeDiv(b9, vt['B9'], 330.0),
    'B12': safeDiv(b12, vt['B12'], 2.5),
    'calcium': safeDiv(calcium, mt['Calcium'], 950.0),
    'copper': safeDiv(copper, mt['Cuivre'], 1.8),
    'iron': safeDiv(iron, mt['Fer'], 11.0),
    'iodine': safeDiv(iodine, mt['Iode'], 150.0),
    'magnesium': safeDiv(magnesium, mt['Magnésium'], 360.0),
    'manganese': safeDiv(manganese, mt['Manganèse'], 8.0),
    'phosphorus': safeDiv(phosphorus, mt['Phosphore'], 550.0),
    'potassium': safeDiv(potassium, mt['Potassium'], 3500.0),
    'selenium': safeDiv(selenium, mt['Sélénium'], 70.0),
    'sodium': safeDiv(sodium, mt['Sodium'], 1500.0),
    'zinc': safeDiv(zinc, mt['Zinc'], 12.5),
    'fibers': safeDiv(fibers, targets.goalFiber, 30.0),
  };

  // ✅ ici on utilise bien les objectifs de l’utilisateur
  final energyRatio =
      targets.goalKcal > 0 ? day.kcal / targets.goalKcal : 1.0;
  final proteinRatio =
      targets.goalProt > 0 ? day.prot / targets.goalProt : 1.0;

  String worstKey = 'omega3';
  double worst = 999;
  ratios.forEach((k, v) {
    final r = v.isFinite ? v : 999.0;
    if (r < worst) {
      worst = r;
      worstKey = k;
    }
  });

  final hydRatio = hyd.ratio;
  String primary = worstKey;
  if (hydRatio < 0.7 && hydRatio < worst + 0.1) {
    primary = 'hydration';
  }

  return _ThemeDecision(
    primaryTopic: primary,
    microTopic: worstKey,
    hydrationRatio: hydRatio,
    microRatios: ratios,
    energyRatio: energyRatio,
    proteinRatio: proteinRatio,
  );
}

String _shortMicroHint(String key, double ratio) {
  final pct = (ratio * 100).round();
  final ptxt = pct <= 120 ? '$pct %' : '>120 %';
  switch (key) {
    case 'omega9':
      return 'Oméga-9 : $ptxt → huile d’olive, avocat, amandes/noisettes.';
    case 'omega6':
      return 'Oméga-6 (LA) : $ptxt → huiles vierges, noix, graines.';
    case 'omega3_ALA':
      return 'Oméga-3 ALA : $ptxt → lin/chia moulus, noix, huile de colza.';
    case 'omega3':
      return 'Oméga-3 EPA/DHA : $ptxt → sardines, maquereau, hareng.';
    case 'EPA':
      return 'EPA : $ptxt → 1–2 portions poisson gras/sem.';
    case 'DHA':
      return 'DHA : $ptxt → sardines, maquereau, œufs enrichis.';
    case 'vitA':
      return 'Vit A : $ptxt → carotte/patate douce + œufs/abats.';
    case 'vitD':
      return 'Vit D : $ptxt → lumière matin + sardines/œufs.';
    case 'vitE':
      return 'Vit E : $ptxt → huiles vierges, amandes/noisettes.';
    case 'vitK':
      return 'Vit K : $ptxt → verts + un peu d’huile.';
    case 'vitC':
      return 'Vit C : $ptxt → kiwi, agrumes, poivron cru, persil.';
    case 'B1':
      return 'B1 : $ptxt → céréales complètes, légumineuses, porc.';
    case 'B2':
      return 'B2 : $ptxt → lait, œufs, amandes, champignons.';
    case 'B3':
      return 'B3 : $ptxt → volailles, poisson, arachides.';
    case 'B5':
      return 'B5 : $ptxt → abats, champignons, avocat.';
    case 'B6':
      return 'B6 : $ptxt → banane, pois chiches, volailles.';
    case 'B9':
      return 'B9 : $ptxt → verts feuillus, légumineuses.';
    case 'B12':
      return 'B12 : $ptxt → produits animaux / enrichis.';
    case 'calcium':
      return 'Calcium : $ptxt → laitiers/alternatives, eaux calciques, tahini.';
    case 'copper':
      return 'Cuivre : $ptxt → fruits de mer, cacao, noix/graines.';
    case 'iron':
      return 'Fer : $ptxt → légumineuses/abats + vitamine C.';
    case 'iodine':
      return 'Iode : $ptxt → poissons, fruits de mer, sel iodé.';
    case 'magnesium':
      return 'Magnésium : $ptxt → amandes, chocolat noir, verts.';
    case 'manganese':
      return 'Manganèse : $ptxt → céréales complètes, noix, thé vert.';
    case 'phosphorus':
      return 'Phosphore : $ptxt → poisson, œufs, oléagineux.';
    case 'potassium':
      return 'Potassium : $ptxt → banane, avocat, verts, patate douce.';
    case 'selenium':
      return 'Sélénium : $ptxt → poisson, fruits de mer, œufs.';
    case 'sodium':
      return 'Sodium : $ptxt → sel de qualité si transpiration.';
    case 'zinc':
      return 'Zinc : $ptxt → fruits de mer, bœuf, graines de courge.';
    case 'fibers':
      return 'Fibres : $ptxt → +légumes, légumineuses, fruits entiers.';
    default:
      return 'Micros : $ptxt → assiette colorée & brute.';
  }
}

// === HERO depuis ASSET ============================================
Map<String, String> _pickHeroFromAsset(
  String topic,
  DateTime now,
  List<String> history,
) {
  final repo = AdviceContentRepo.instance;
  String topicKey = topic;
  if (['EPA', 'DHA', 'omega3'].contains(topic)) topicKey = 'omega3';
  if ([
    'B1',
    'B2',
    'B3',
    'B5',
    'B6',
    'B9',
    'B12',
  ].contains(topic)) {
    topicKey = 'Bgroup';
  }

  final list =
      repo.heroPool[topicKey] ?? (repo.heroPool['fibers'] ?? const []);
  if (list.isEmpty) {
    return {
      'title': 'Conseil du jour',
      'theme': 'Vitalité',
      'insight': 'Varie les aliments bruts colorés.',
    };
  }

  final slot = _hourSlot6(now);
  final idx = (slot + history.length) % list.length;
  return list[idx];
}

// === RECETTES depuis ASSET ========================================
final Map<String, List<String>> _recipesFallback = {
  'fibers': ['Buddha bowl légumineuses + céréale complète'],
};

List<String> _buildRecipesFromAsset(
  Map<String, double> ratios,
  DateTime now,
  List<String> history,
) {
  final repo = AdviceContentRepo.instance;
  final sorted = ratios.entries
      .where((e) => e.value.isFinite)
      .toList()
    ..sort((a, b) => a.value.compareTo(b.value));

  final candidates = <String>[];
  for (final e in sorted) {
    if (e.value >= 0.95) break;
    if (repo.recipesByKey.containsKey(e.key)) {
      candidates.add(e.key);
    }
    if (candidates.length >= 4) break;
  }

  if (candidates.isEmpty) {
    return _recipesFallback['fibers'] ?? const [];
  }

  final avoid = history.take(3).toList();
  String primary = candidates.firstWhere(
    (c) => !avoid.contains(c),
    orElse: () => candidates.first,
  );

  final ideas = <String>[];
  final base = repo.recipesByKey[primary]!;
  final slot = _hourSlot6(now);

  ideas.add(base[slot % base.length]);
  for (final k in candidates.where((k) => k != primary)) {
    final list = repo.recipesByKey[k];
    if (list == null) continue;
    ideas.add(list[(slot + ideas.length) % list.length]);
    if (ideas.length >= 3) break;
  }

  while (ideas.length < 3) {
    ideas.add(base[(slot + ideas.length) % base.length]);
  }
  return ideas;
}

// === GENERATION PRINCIPALE ========================================
Future<AdviceScript> _buildAdviceScript(AppLocalizations l10n) async {
  final now = DateTime.now();
  final sp = await SharedPreferences.getInstance();

  // charge l’asset au premier appel (idempotent)
  if (!AdviceContentRepo.instance.isLoaded) {
    await AdviceContentRepo.instance
        .loadFromAsset('assets/advices.json');
  }
  await CoachAdvicesRepo.instance.load();
  await TotumRecipesRepo.instance.load();
  await NutrientFicheRepo.instance.load();

  final goals = await _readGoalsForAdvice();
  final targets = await _buildAdviceTargets(goals);
  final day = await _computeDayTotalsForAdviceDate(now, sp);
  final hyd = await _computeHydrationForAdviceToday(goals, sp, dayTotals: day);
  final hol = await _readHolisticLog(sp, now);
  final hist = await _readHistory(sp, _adviceHistoryKey);
  final packHist = await _readHistory(sp, _packHistoryKey);

  final isSportif = goals.activityIdx >= 2;
  final goalIdx = goals.goalIndex;

  if (!day.hasData) {
    final ms = AdviceContentRepo.instance.mindsetPacks;
    final idx =
        ms.isNotEmpty ? _dayOfYearIndex(now, ms.length) : 0;
    final mTitle = (ms.isNotEmpty
            ? ms[idx]['title']
            : '🧠 Progression > perfection') ??
        '🧠 Progression > perfection';
    final mBody = (ms.isNotEmpty
            ? ms[idx]['body']
            : 'Chaque repas aligné est un vote pour ton identité.') ??
        'Chaque repas aligné est un vote pour ton identité.';

    return AdviceScript(
      cardTitle: '🎯 Premier levier : nourrir ton TOTUM',
      focusTheme: 'Construire ta base de données personnelle',
      scienceInsight:
          'Plus tu enregistres tes repas, plus les conseils deviennent précis, utiles et motivants.',
      deficitCritique: 'Impossible de détecter des déficits sans journal.',
      beneficeAssocie:
          'Tu construis ton Totem alimentaire : vision claire de ce que tu offres à ton corps.',
      sourcePremium:
          'Enregistre petit-déj + repas principal, avec quantités & aliments détaillés.',
      astuceAbsorption:
          'Commence par tes repas « typiques », on raffinera ensuite sur les micronutriments.',
      extraMicronutrientHints: const [],
      recipeIdeas: const [],
      chronoAnalyse:
          'Sans sommeil/eau/stress renseignés, le lien sensations ↔ hygiène de vie reste flou.',
      actionLifestyle:
          'Ce soir, note heure de coucher, durée, stress (1–10). Demain matin : humeur/énergie.',
      logTitle: '📝 Active ton suivi holistique',
      logFields: const [
        'Durée de sommeil (heures)',
        'Litres d’eau (hors café/alcool)',
        'Stress ressenti (1–10)',
      ],
      defi24h:
          'Défi 24h : renseigne 2 repas complets + sommeil, eau, stress.',
      quotePremium: '« Ce qui se mesure se transforme. »',
      macroSummaryTitle: '⚙️ Macros en attente',
      macroSummaryBody:
          'Dès qu’un repas est saisi, je peux vérifier énergie & protéines vs ton objectif.',
      activityCoachTitle: '🏃‍♂️ Coach activité & récupération',
      activityCoachBody: isSportif
          ? 'Note tes entraînements + repas pré/post pour affiner énergie & timing.'
          : '2–3 créneaux de 20–30 min/semaine (marche rapide, vélo doux, renfo).',
      mindsetTitle: mTitle,
      mindsetBody: mBody,
      hydrationRatio: null,
      sleepHours: hol.sleepHours,
      stressLevel: hol.stress,
      energyRatio: null,
      proteinRatio: null,
    );
  }

  final decision = _decideTheme(
    day: day,
    hyd: hyd,
    targets: targets,
  );

  // anti-répétition du thème primaire
  String topic = decision.primaryTopic;
  if (hist.isNotEmpty && hist.first == topic) {
    final entries = decision.microRatios.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final e in entries) {
      if (e.key != topic) {
        topic = e.key;
        break;
      }
    }
  }
  await _pushHistory(sp, _adviceHistoryKey, topic, keep: 6);

  // HERO via asset
  final hero = _pickHeroFromAsset(topic, now, hist);
  final cardTitle = hero['title']!;
  final focusTheme = hero['theme']!;
  final scienceInsight = hero['insight']!;

  // LABO: textes principaux selon microTopic (esprit inchangé)
  String deficitCritique, beneficeAssocie, sourcePremium, astuceAbsorption;
  switch (decision.microTopic) {
    case 'omega9':
      deficitCritique =
          'Oméga-9 en dessous de la zone optimale.';
      beneficeAssocie =
          'Soutien cardio-métabolique & souplesse membranaire.';
      sourcePremium =
          'Huile d’olive, avocat, amandes/noisettes au quotidien.';
      astuceAbsorption =
          'Utilise l’huile d’olive à cru/fin de cuisson douce.';
      break;
    case 'omega6':
      deficitCritique = 'Oméga-6 (LA) un peu bas.';
      beneficeAssocie =
          'Structure membranaire, peau & voies hormonales.';
      sourcePremium =
          'Huiles vierges (tournesol bio), noix/graines variées.';
      astuceAbsorption =
          'Évite les huiles raffinées surchauffées.';
      break;
    case 'omega3_ALA':
      deficitCritique = 'Oméga-3 ALA insuffisants.';
      beneficeAssocie =
          'Précurseur végétal des oméga-3 marins EPA/DHA.';
      sourcePremium =
          '1 c.s lin/chia moulus/jour ou quelques noix.';
      astuceAbsorption =
          'Mouds le lin/chia juste avant de consommer.';
      break;
    case 'omega3':
      deficitCritique = 'Oméga-3 ALA (végétaux) sous la cible.';
      beneficeAssocie =
          'Précurseur végétal des oméga-3, anti-inflammatoire.';
      sourcePremium =
          'Graines de chanvre/lin moulues, noix, huile de colza.';
      astuceAbsorption = 'Mouds les graines juste avant de consommer.';
      break;
    case 'omega3_marins':
    case 'EPA':
    case 'DHA':
      deficitCritique = 'Oméga-3 marins sous la cible.';
      beneficeAssocie =
          'Clarté mentale, récupération, anti-inflammation.';
      sourcePremium =
          '2×/sem poisson gras (sardines/maquereau/hareng).';
      astuceAbsorption = 'Cuisson douce + bons lipides.';
      break;
    case 'vitA':
      deficitCritique =
          'Vitamine A en dessous de l’optimum.';
      beneficeAssocie =
          'Vision nocturne, peau/muqueuses, immunité.';
      sourcePremium =
          'Carotte/patate douce + abats/œufs (selon choix).';
      astuceAbsorption =
          'Associe à un peu de gras pour conversion.';
      break;
    case 'vitD':
      deficitCritique =
          'Vitamine D probablement insuffisante.';
      beneficeAssocie =
          'Immunité, force, humeur, santé osseuse.';
      sourcePremium =
          'Sardines/maquereau/œufs entiers, lumière matin.';
      astuceAbsorption =
          'Lipides de qualité au repas contenant vit D.';
      break;
    case 'vitE':
      deficitCritique = 'Vitamine E insuffisante.';
      beneficeAssocie =
          'Antioxydant des membranes cellulaires.';
      sourcePremium =
          'Huiles vierges, amandes, noisettes, graines.';
      astuceAbsorption =
          'Utilisation à froid/cuisson douce.';
      break;
    case 'vitK':
      deficitCritique = 'Vitamine K un peu juste.';
      beneficeAssocie =
          'Coagulation équilibrée & santé osseuse.';
      sourcePremium =
          'Légumes verts + un filet d’huile.';
      astuceAbsorption =
          'Associe verts feuillus à un peu de lipides.';
      break;
    case 'vitC':
      deficitCritique = 'Vitamine C sous optimal.';
      beneficeAssocie =
          'Antioxydant, immunité, absorption du fer.';
      sourcePremium =
          'Kiwi, agrumes, poivron cru, persil.';
      astuceAbsorption =
          'Consomme plutôt cru/peu cuit.';
      break;
    case 'B1':
    case 'B2':
    case 'B3':
      deficitCritique = 'B1/B2/B3 un peu en deçà.';
      beneficeAssocie =
          'Métabolisme énergétique & système nerveux.';
      sourcePremium =
          'Céréales complètes, légumineuses, poissons/œufs.';
      astuceAbsorption =
          'Réduis l’ultra-transformé pauvre en B.';
      break;
    case 'B5':
    case 'B6':
      deficitCritique = 'B5/B6 sous la cible.';
      beneficeAssocie = 'Stress, neurotransmetteurs, AA.';
      sourcePremium =
          'Volailles, banane, pois chiches, œufs, avocat.';
      astuceAbsorption = 'Répartis sur la journée.';
      break;
    case 'B9':
      deficitCritique =
          'Folates (B9) insuffisants.';
      beneficeAssocie =
          'Renouvellement cellulaire & qualité du sang.';
      sourcePremium =
          'Verts feuillus, légumineuses, herbes fraîches.';
      astuceAbsorption = 'Part crue ou vapeur douce.';
      break;
    case 'B12':
      deficitCritique = 'Vitamine B12 basse.';
      beneficeAssocie =
          'Système nerveux & globules rouges.';
      sourcePremium =
          'Produits animaux ou aliments enrichis.';
      astuceAbsorption =
          'Vegan strict : discuter supplémentation pro.';
      break;
    case 'calcium':
      deficitCritique = 'Calcium sous la cible.';
      beneficeAssocie =
          'Solidité osseuse & signalisation cellulaire.';
      sourcePremium =
          'Laitiers/alternatives, eaux calciques, tahini.';
      astuceAbsorption =
          'Répartis + statut vit D correct.';
      break;
    case 'copper':
      deficitCritique = 'Cuivre un peu faible.';
      beneficeAssocie =
          'Collagène, vaisseaux, métabolisme du fer.';
      sourcePremium =
          'Fruits de mer, cacao, noix/graines.';
      astuceAbsorption =
          'Associe à alimentation variée.';
      break;
    case 'iron':
      deficitCritique = 'Fer sous-optimal.';
      beneficeAssocie =
          'Oxygénation musculaire & énergie.';
      sourcePremium =
          'Légumineuses/abats/viandes + vit C.';
      astuceAbsorption =
          'Évite thé/café juste après repas riches en fer.';
      break;
    case 'iodine':
      deficitCritique = 'Iode plutôt bas.';
      beneficeAssocie =
          'Thyroïde → métabolisme & température.';
      sourcePremium =
          'Sel iodé, poissons, fruits de mer, algues raisonnées.';
      astuceAbsorption =
          'Évite excès d’algues si pathologie thyroïde.';
      break;
    case 'magnesium':
      deficitCritique = 'Magnésium insuffisant.';
      beneficeAssocie =
          'Relaxation nerveuse/musculaire, sommeil.';
      sourcePremium =
          'Amandes, chocolat noir, verts feuillus, eaux magnésiennes.';
      astuceAbsorption =
          'Limite café tardif ; associe B6.';
      break;
    case 'manganese':
      deficitCritique = 'Manganèse bas.';
      beneficeAssocie = 'Cofacteur antioxydant.';
      sourcePremium =
          'Céréales complètes, noix, thé vert (modéré).';
      astuceAbsorption =
          'Limite raffinés pauvres en oligo-éléments.';
      break;
    case 'phosphorus':
      deficitCritique = 'Phosphore légèrement bas.';
      beneficeAssocie =
          'Structure os/dents & énergie.';
      sourcePremium =
          'Poisson, œufs, oléagineux.';
      astuceAbsorption =
          'Évite sodas aux phosphates ajoutés.';
      break;
    case 'potassium':
      deficitCritique = 'Potassium insuffisant.';
      beneficeAssocie =
          'Équilibre tensionnel, contraction musculaire.';
      sourcePremium =
          'Banane, avocat, verts, patate douce, légumineuses.';
      astuceAbsorption =
          'Une part crue/vapeur pour préserver minéraux.';
      break;
    case 'selenium':
      deficitCritique = 'Sélénium un peu juste.';
      beneficeAssocie = 'Antioxydant clé + thyroïde.';
      sourcePremium =
          'Poisson, fruits de mer, œufs (mieux absorbés).';
      astuceAbsorption =
          'Évite les excès prolongés.';
      break;
    case 'sodium':
      deficitCritique =
          'Sodium un peu bas vs besoins.';
      beneficeAssocie =
          'Hydrique, conduction nerveuse.';
      sourcePremium =
          'Sel de qualité sur aliments bruts si transpiration.';
      astuceAbsorption =
          'Évite ultra-salés transformés.';
      break;
    case 'zinc':
      deficitCritique =
          'Zinc possiblement insuffisant.';
      beneficeAssocie =
          'Immunité, peau, hormones.';
      sourcePremium =
          'Fruits de mer, bœuf, graines de courge.';
      astuceAbsorption = 'Limite excès de sucre.';
      break;
    case 'fibers':
      deficitCritique = 'Fibres sous 30 g/j.';
      beneficeAssocie =
          'Microbiote, satiété, glycémie.';
      sourcePremium =
          '+Légumineuses, légumes à chaque repas, fruits entiers.';
      astuceAbsorption =
          'Monte progressivement + eau suffisante.';
      break;
    default:
      deficitCritique =
          'Un ou plusieurs micronutriments sous la cible.';
      beneficeAssocie =
          'Plus de densité micro = énergie & sommeil meilleurs.';
      sourcePremium =
          'Aliments bruts variés, poissons & œufs.';
      astuceAbsorption =
          'Assiette colorée = spectre micro plus large.';
      break;
  }

  // Hints + recettes via asset
  final hints = <String>[];
  final sorted = decision.microRatios.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (final e in sorted) {
    if (e.key == decision.microTopic) continue;
    if (!e.value.isFinite || e.value >= 0.95) continue;
    hints.add(_shortMicroHint(e.key, e.value));
    if (hints.length >= 12) break;
  }
  final recipes =
      _buildRecipesFromAsset(decision.microRatios, now, hist);

    // Alignement holistique
  final sleep = hol.sleepHours;
  final stress = hol.stress;
  final hydR = decision.hydrationRatio;
  final slot = _hourSlot6(now);

  String chronoAnalyse, actionLifestyle;
  List<String> pickCoach(List<String> list) =>
      list.isEmpty ? ['Bouge un peu aujourd’hui 😉'] : list;

  // On définit quelques “packs” d’actions possibles
  final lowSleepHighStressPacks = [
    '1️⃣ 20–30 min dehors (lumière naturelle) + 5 min de respiration nasale lente en fin de journée.',
    '2️⃣ Couvre-feu digital 45–60 min avant le coucher + lecture légère ou journal de gratitude (3 points).',
    '3️⃣ Dîner plus tôt, léger et peu sucré, puis douche tiède et respiration 4–6 pendant 3–5 min.',
    '4️⃣ Si ruminations : noter tout ce qui tourne en boucle sur papier avant d’aller au lit.',
  ];

  final lowSleepPacks = [
    '1️⃣ Fixer une heure de coucher cible réaliste (même le week-end) et s’y tenir 3 soirs de suite.',
    '2️⃣ Avancer le dernier café/thé noir au plus tard 14–15 h.',
    '3️⃣ Créer un petit rituel de “décompression” de 10–15 min (étirements doux + lumière tamisée).',
    '4️⃣ Chambre : fraîche, très sombre, silencieuse ou bruit blanc léger.',
  ];

  final highStressPacks = [
    '1️⃣ Micro-pauses : 2–3 min toutes les 60–90 min (respiration calme + quelques pas).',
    '2️⃣ 5 respirations lentes avant chaque repas pour faire redescendre le système nerveux.',
    '3️⃣ Marche de 10–15 min en extérieur sans téléphone, en portant l’attention sur la respiration.',
    '4️⃣ Le soir : écrire 3 choses qui se sont bien passées dans la journée, même si elles sont petites.',
  ];

  final stableTerrainPacks = [
    '1️⃣ Maintiens ton rythme de coucher et de lever, même le week-end (±1 h max).',
    '2️⃣ Ajoute 8–12 min de marche lente après un repas pour digestion + glycémie.',
    '3️⃣ Prévois 1 moment “off écran” de 15–20 min dans la journée (lecture, musique, nature).',
    '4️⃣ Introduis 1 portion de légumes verts en plus pour soutenir micronutrition & récupération.',
  ];

  if (sleep != null && stress != null) {
    // Cas le plus “chargé” : peu de sommeil + beaucoup de stress
    if (sleep < 7 && stress >= 7) {
      chronoAnalyse =
          'Sommeil court (~${sleep.toStringAsFixed(1)} h) + stress élevé ($stress/10). Le système nerveux tire fort sur les réserves.';
      final pool = [...lowSleepHighStressPacks];
      actionLifestyle = _pickRotating<String>(
        pool,
        slot: slot,
        avoid: packHist,
      );
    }
    // Sommeil court mais stress modéré
    else if (sleep < 7) {
      chronoAnalyse =
          'Temps de sommeil un peu court (~${sleep.toStringAsFixed(1)} h). L’empilement de nuits raccourcies finit par impacter énergie et humeur.';
      final pool = [...lowSleepPacks];
      actionLifestyle = _pickRotating<String>(
        pool,
        slot: slot,
        avoid: packHist,
      );
    }
    // Stress élevé mais sommeil correct
    else if (stress >= 7) {
      chronoAnalyse =
          'Sommeil convenable (~${sleep.toStringAsFixed(1)} h) mais stress élevé ($stress/10). Le mental tourne vite.';
      var pool = [...highStressPacks];
      if (hydR < 0.7) {
        pool.add('Hydratation un peu basse : répartir l’eau sur la journée aide aussi la clarté mentale.');
      }
      actionLifestyle = _pickRotating<String>(
        pool,
        slot: slot,
        avoid: packHist,
      );
    }
    // Sommeil OK + stress modéré
    else {
      chronoAnalyse =
          'Sommeil et niveau de stress plutôt stables (≈${sleep.toStringAsFixed(1)} h, stress $stress/10). On peut jouer le “fine tuning” vitalité.';
      final pool = [...stableTerrainPacks];
      actionLifestyle = _pickRotating<String>(
        pool,
        slot: slot,
        avoid: packHist,
      );
    }
  } else {
    // Données partielles : on motive à compléter l’auto-suivi
    chronoAnalyse =
        'Renseigne ton sommeil et ton niveau de stress pour des conseils bien-être personnalisés, adaptés à ta forme du moment.';
    actionLifestyle =
        'Pendant 3 jours, note chaque matin tes heures de sommeil, ton niveau de stress (1–10) et ton énergie au réveil. TOTUM affinera progressivement les leviers proposés pour toi.';
  }

  await _pushHistory(sp, _packHistoryKey, actionLifestyle, keep: 6);

  // Macros
  String macroSummaryTitle, macroSummaryBody;
  String pct(double r) => '${(r * 100).round()} %';
  final eR = decision.energyRatio;
  final pR = decision.proteinRatio;

  if (goalIdx == 0) {
    macroSummaryTitle = '⚖️ Perte de poids intelligente';
    if (eR > 1.1) {
      macroSummaryBody =
          'Apport ~${pct(eR)} : vise un déficit léger (-10 à -20 %) durable.';
    } else if (eR < 0.8) {
      macroSummaryBody =
          'Apport ~${pct(eR)} : si fatigue/fringales, remonte avec aliments bruts.';
    } else {
      macroSummaryBody =
          'Énergie ~${pct(eR)} : trajectoire cohérente. Qualité & fibres = priorité.';
    }
    if (pR < 0.9) {
      macroSummaryBody +=
          ' • Protéines ~${pct(pR)} : une source à chaque repas.';
    } else if (pR > 1.2 && isSportif) {
      macroSummaryBody +=
          ' • Protéines généreuses ~${pct(pR)} : répartis sur 3–4 prises.';
    }
  } else if (goalIdx >= 2) {
    macroSummaryTitle = '🏗️ Construction musculaire';
    if (eR < 0.9) {
      macroSummaryBody =
          'Calories ~${pct(eR)} : surplus +10–15 % conseillé.';
    } else if (eR > 1.2) {
      macroSummaryBody =
          'Surplus ~${pct(eR)} : ramène vers +10–15 % pour limiter la prise de gras.';
    } else {
      macroSummaryBody =
          'Niveau ~${pct(eR)} : OK. Timing glucides autour séances = clé.';
    }
    if (pR < 1.0) {
      macroSummaryBody +=
          ' • Protéines ~${pct(pR)} : 1.6–2.2 g/kg/j sur 3–4 repas.';
    } else {
      macroSummaryBody +=
          ' • Couverture protéique ~${pct(pR)}.';
    }
  } else {
    macroSummaryTitle = '⚙️ Maintien du poids de forme';
    if (eR < 0.9) {
      macroSummaryBody =
          'Énergie ~${pct(eR)} : un peu basse. Remonte légèrement si fatigue.';
    } else if (eR > 1.1) {
      macroSummaryBody =
          'Énergie ~${pct(eR)} : un peu haute. Ajuste extras & boissons.';
    } else {
      macroSummaryBody =
          'Énergie ~${pct(eR)} : alignée. Joue la qualité pour digestion/sommeil.';
    }
    if (pR < 0.9) {
      macroSummaryBody +=
          ' • Protéines ~${pct(pR)} : garde un socle suffisant.';
    }
  }

  // Coach depuis asset
  final repo = AdviceContentRepo.instance;
  String activityCoachTitle = '🏃‍♂️ Coach activité & récupération';
  final slotIdx = _hourSlot6(now);
  List<String> coachList;
  if (!isSportif) {
    coachList = repo.coach['sedentaire'] ?? [];
  } else if (goalIdx == 0) {
    coachList = repo.coach['perte'] ?? [];
  } else if (goalIdx >= 2) {
    coachList = repo.coach['masse'] ?? [];
  } else {
    coachList = repo.coach['maintien'] ?? [];
  }
  final pickedCoach = pickCoach(coachList);
  final activityCoachBody =
      pickedCoach[slotIdx % pickedCoach.length];

  // Saisie active & Motivation
  const logTitle = '🧭 Ajuste ton tableau de bord holistique';
  const logFields = [
    'Durée de sommeil (heures)',
    'Litres d’eau (hors café/alcool)',
    'Stress ressenti (1–10)',
  ];

  String defi24h, quotePremium;
  if (topic == 'hydration') {
    defi24h =
        'Atteins ${(hyd.targetMl / 1000).toStringAsFixed(1)} L aujourd’hui, répartis sur la journée.';
    quotePremium =
        '« Une cellule bien hydratée travaille en silence pour ta longévité. »';
  } else if ([
    'omega3',
    'omega3_ALA',
    'omega6',
    'omega9',
    'EPA',
    'DHA',
  ].contains(topic)) {
    defi24h =
        'Ajoute une vraie source d’EFAs (poisson gras ou lin/chia moulus + huile colza/olive).';
    quotePremium =
        '« Les lipides de qualité sont la matière première de ton cerveau. »';
  } else if ([
    'vitA',
    'vitD',
    'vitE',
    'vitK',
  ].contains(topic)) {
    defi24h =
        '1 source liposoluble + lumière du matin 10–15 min.';
    quotePremium =
        '« Lumière + liposolubles = orchestration métabolique. »';
  } else if ([
    'vitC',
    'B1',
    'B2',
    'B3',
    'B5',
    'B6',
    'B9',
    'B12',
  ].contains(topic)) {
    defi24h =
        'Repas très coloré + une bonne source protéique.';
    quotePremium =
        '« Ton énergie, c’est du code info + du carburant. »';
  } else if (topic == 'fibers') {
    defi24h =
        '1 portion de légumes en plus + 1 portion de légumineuses.';
    quotePremium =
        '« Ton microbiote se nourrit de tes habitudes. »';
  } else {
    defi24h =
        'Choisis une action du Labo et applique-la aujourd’hui.';
    quotePremium =
        '« Les micronutriments, code source de ta vitalité. »';
  }

  // Mindset (depuis asset)
  final ms = repo.mindsetPacks;
  final mIdx = ms.isNotEmpty
      ? (_dayOfYearIndex(now, ms.length) + slotIdx) % ms.length
      : 0;
  final mindsetTitle = (ms.isNotEmpty
          ? ms[mIdx]['title']
          : '🧠 Progression > perfection') ??
      '🧠 Progression > perfection';
  final mindsetBody = (ms.isNotEmpty
          ? ms[mIdx]['body']
          : 'Chaque repas aligné est un vote pour ton identité.') ??
      'Chaque repas aligné est un vote pour ton identité.';

  final totumScore = await computeTodayTotumScore(l10n);
  await _updateCoachScoreHistory(totumScore);

  // Contexte coach + sélection des conseils de la banque
  final daySeed = now.day + now.month * 31;
  final int dietMode =
      (await SharedPreferences.getInstance()).getInt('profile_diet') ?? 0;
  final coachCtx = CoachContext(
    ratios: decision.microRatios,
    goalIndex: goals.goalIndex,
    activityIdx: goals.activityIdx,
    sleepHours: hol.sleepHours,
    stress: hol.stress,
    diet: dietMode,
  );
  final advNutrition = _pickAdvice('nutrition', coachCtx, daySeed,
      excludeMicro: decision.microTopic);
  final advMouvement = _pickAdvice('mouvement', coachCtx, daySeed);
  final advSommeil = _pickAdvice('sommeil', coachCtx, daySeed);
  final advStress = _pickAdvice('stress', coachCtx, daySeed);
  final advMindset = _pickAdvice('mindset', coachCtx, daySeed);

  // Déficits calculés AVANT le message, pour que le coach nomme le principal.
  final deficits = topDeficits(decision.microRatios, max: 5, diet: dietMode);
  final suggestedRecipes = suggestRecipes(decision.microRatios, count: 3);
  // Message coach dynamique, direct et actionnable.
  final coachMessage = _coachDailyMessage(
      coachCtx, totumScore, deficits.isNotEmpty ? deficits.first : null);

  return AdviceScript(
    score: totumScore,
    coachMessage: coachMessage,
    deficitKey: decision.microTopic,
    advNutrition: advNutrition,
    advMouvement: advMouvement,
    advSommeil: advSommeil,
    advStress: advStress,
    advMindset: advMindset,
    suggestedRecipes: suggestedRecipes,
    deficits: deficits,
    cardTitle: cardTitle,
    focusTheme: focusTheme,
    scienceInsight: scienceInsight,
    deficitCritique: deficitCritique,
    beneficeAssocie: beneficeAssocie,
    sourcePremium: sourcePremium,
    astuceAbsorption: astuceAbsorption,
    extraMicronutrientHints: hints,
    recipeIdeas: recipes,
    chronoAnalyse: chronoAnalyse,
    actionLifestyle: actionLifestyle,
    logTitle: logTitle,
    logFields: logFields,
    defi24h: defi24h,
    quotePremium: quotePremium,
    macroSummaryTitle: macroSummaryTitle,
    macroSummaryBody: macroSummaryBody,
    activityCoachTitle: activityCoachTitle,
    activityCoachBody: activityCoachBody,
    mindsetTitle: mindsetTitle,
    mindsetBody: mindsetBody,
    hydrationRatio: decision.hydrationRatio,
    sleepHours: hol.sleepHours,
    stressLevel: hol.stress,
    energyRatio: decision.energyRatio,
    proteinRatio: decision.proteinRatio,
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  BANQUE DE CONSEILS COACH — chargement + sélection contextuelle
// ═══════════════════════════════════════════════════════════════════════

class CoachAdvice {
  final String id;
  final String titre;
  final String body;
  final String tag;
  final Map<String, dynamic> trigger;
  const CoachAdvice(this.id, this.titre, this.body, this.tag, this.trigger);
}

class CoachAdvicesRepo {
  CoachAdvicesRepo._();
  static final CoachAdvicesRepo instance = CoachAdvicesRepo._();

  final Map<String, List<CoachAdvice>> _byPillar = {};
  bool get isLoaded => _byPillar.isNotEmpty;

  Future<void> load() async {
    if (_byPillar.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString('assets/coach_advices.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        if (entry.key.startsWith('_')) continue;
        final list = (entry.value as List)
            .map((e) => CoachAdvice(
                  e['id']?.toString() ?? '',
                  e['titre']?.toString() ?? '',
                  e['body']?.toString() ?? '',
                  e['tag']?.toString() ?? '',
                  (e['trigger'] as Map?)?.cast<String, dynamic>() ?? {},
                ))
            .toList();
        _byPillar[entry.key] = list;
      }
    } catch (e) {
      debugPrint('Erreur chargement coach_advices: $e');
    }
  }

  List<CoachAdvice> pillar(String name) => _byPillar[name] ?? const [];
}

/// Contexte de sélection des conseils, dérivé de la situation de l'utilisateur.
class CoachContext {
  final Map<String, double> ratios; // microRatios
  final int goalIndex;
  final int activityIdx;
  final double? sleepHours;
  final int? stress;
  final int diet; // 0 omnivore, 1 végétarien, 2 végétalien
  const CoachContext({
    required this.ratios,
    required this.goalIndex,
    required this.activityIdx,
    this.sleepHours,
    this.stress,
    this.diet = 0,
  });

  String get goalKey {
    if (goalIndex <= 0) return 'loss';
    if (goalIndex >= 3) return 'gain';
    return 'maintain';
  }

  String get activityKey => activityIdx <= 0 ? 'low' : 'normal';
}

/// Un conseil correspond-il au contexte ? Score de pertinence (plus haut = mieux).
/// -1 = ne s'applique pas.
int _adviceScore(CoachAdvice a, CoachContext ctx) {
  final t = a.trigger;
  if (t.isEmpty) return 1; // générique : toujours applicable, priorité faible

  // Carence micro
  if (t.containsKey('micro')) {
    final micro = t['micro'].toString();
    final below = (t['below'] as num?)?.toDouble() ?? 0.7;
    final r = ctx.ratios[micro];
    if (r == null || r >= below) return -1;
    // plus la carence est marquée, plus le score est haut
    return 10 + ((below - r) * 20).round();
  }
  // Objectif
  if (t.containsKey('goal')) {
    if (t['goal'].toString() != ctx.goalKey) return -1;
    return 6;
  }
  // Activité
  if (t.containsKey('activity')) {
    if (t['activity'].toString() != ctx.activityKey) return -1;
    return 5;
  }
  // Sommeil
  if (t.containsKey('sleep_below')) {
    final thr = (t['sleep_below'] as num).toDouble();
    if (ctx.sleepHours == null || ctx.sleepHours! >= thr) return -1;
    return 8;
  }
  if (t.containsKey('sleep_above')) {
    final thr = (t['sleep_above'] as num).toDouble();
    if (ctx.sleepHours == null || ctx.sleepHours! < thr) return -1;
    return 4;
  }
  // Stress
  if (t.containsKey('stress_above')) {
    final thr = (t['stress_above'] as num).toInt();
    if (ctx.stress == null || ctx.stress! <= thr) return -1;
    return 8;
  }
  if (t.containsKey('stress_below')) {
    final thr = (t['stress_below'] as num).toInt();
    if (ctx.stress == null || ctx.stress! >= thr) return -1;
    return 4;
  }
  return 1;
}

/// Sélectionne un conseil du pilier selon le contexte, avec rotation
/// quotidienne et anti-répétition.
CoachAdvice? _pickAdvice(String pillar, CoachContext ctx, int daySeed,
    {String? excludeMicro}) {
  final all = CoachAdvicesRepo.instance.pillar(pillar);
  if (all.isEmpty) return null;

  // Décorrélation : chaque pilier tourne sur sa propre séquence.
  final seed = daySeed + pillar.codeUnits.fold<int>(0, (a, b) => a + b);

  final targeted = <MapEntry<CoachAdvice, int>>[];
  final generic = <CoachAdvice>[];

  for (final a in all) {
    // On n'évoque pas ici le nutriment déjà traité par la vignette Priorité.
    if (excludeMicro != null &&
        a.trigger['micro']?.toString() == excludeMicro) {
      continue;
    }
    final s = _adviceScore(a, ctx);
    if (s < 0) continue;
    if (s >= 5) {
      targeted.add(MapEntry(a, s));
    } else {
      generic.add(a);
    }
  }

  if (targeted.isEmpty) {
    if (generic.isEmpty) return all[seed % all.length];
    return generic[seed % generic.length];
  }

  targeted.sort((a, b) => b.value.compareTo(a.value));

  // Un seul conseil ciblé disponible : on glisse un générique un jour sur
  // trois, pour éviter de servir exactement la même chose indéfiniment.
  if (targeted.length == 1 && generic.isNotEmpty && seed % 3 == 2) {
    return generic[seed % generic.length];
  }

  // Plusieurs conseils ciblés : rotation quotidienne dans une bande large.
  final maxScore = targeted.first.value;
  final top = targeted.where((e) => e.value >= maxScore - 3).toList();
  return top[seed % top.length].key;
}

/// Message du Coach du jour : lecture personnalisée de la situation,
/// SANS répéter la priorité (qui a sa propre vignette juste en dessous).
/// Aliment brut concret qui corrige le mieux chaque carence — l'action « à faire
/// maintenant » que le coach recommande. Choisis pour rester simples et courants.
const Map<String, String> _kQuickFix = {
  'iron': 'des lentilles ou un peu de boudin, avec un filet de citron pour l\'absorption',
  'magnesium': 'une poignée d\'amandes ou un carré de chocolat noir',
  'calcium': 'des sardines, un yaourt ou une poignée d\'amandes',
  'zinc': 'des graines de courge, du bœuf ou des huîtres',
  'iodine': 'du poisson, des fruits de mer ou un œuf',
  'selenium': 'une sardine, un œuf ou des fruits de mer',
  'potassium': 'un avocat, une patate douce ou des légumineuses',
  'vitC': 'un kiwi, un poivron rouge ou quelques fraises',
  'vitD': 'un poisson gras (sardine, maquereau) et un peu de soleil',
  'vitE': 'des amandes, des noisettes ou un filet d\'huile vierge',
  'vitA': 'une carotte, de la patate douce ou du jaune d\'œuf',
  'vitK': 'des légumes verts (épinard, chou) ou un peu de fromage affiné',
  'B9': 'des légumes verts à feuilles ou des légumineuses',
  'B12': 'des œufs, du poisson ou de la viande',
  'B6': 'de la volaille, une banane ou des pois chiches',
  'omega3': 'des graines de chanvre ou de lin moulues, ou des noix',
  'omega3_marins': 'des sardines, du maquereau ou du hareng',
  'copper': 'des oléagineux, du chocolat noir ou des fruits de mer',
  'manganese': 'des céréales complètes, des oléagineux ou du thé',
  'phosphorus': 'des œufs, du poisson ou des légumineuses',
  'fibers': 'des légumineuses, un fruit entier ou des légumes',
};

String _coachDailyMessage(
    CoachContext ctx, TotumScore? score, DeficitInfo? mainDeficit) {
  final now = DateTime.now();
  final hour = now.hour;

  if (score == null) {
    return 'Renseigne tes repas et je te dis en un coup d\'œil où tu en es et quoi ajuster.';
  }

  final s = score.global.round();

  // 1) État chiffré, court et clair.
  String etat;
  if (score.isProvisional && score.dayPercent < 45) {
    etat = s >= 70
        ? 'Bon début : $s/100 sur ce que tu as déjà mangé.'
        : 'Journée qui démarre : $s/100 pour l\'instant, tout reste à construire.';
  } else if (s >= 85) {
    etat = 'Excellente journée : $s/100. C\'est ce niveau-là qui construit ta santé sur le long terme.';
  } else if (s >= 70) {
    etat = 'Bonne journée : $s/100, avec encore un peu de marge.';
  } else if (s >= 55) {
    etat = 'Journée correcte : $s/100. Un geste ciblé et tu passes un cap.';
  } else {
    etat = 'Journée à rééquilibrer : $s/100. Rien de grave, un bon repas inverse la tendance.';
  }

  // 2) Progression vs la dernière journée complète.
  String progression = '';
  if (_coachYesterdayScore != null && !score.isProvisional) {
    final diff = (score.global - _coachYesterdayScore!).round();
    if (diff >= 5) {
      progression = ' En hausse de $diff points vs ta dernière journée 📈.';
    } else if (diff <= -5) {
      progression = ' En baisse de ${-diff} points vs ta dernière journée.';
    }
  }

  // 3) LE FOCUS DU JOUR : on alterne nutrition / bien-être selon ce qui est
  //    VRAIMENT prioritaire aujourd'hui, pour incarner l'approche holistique
  //    sans diluer le message. Le bien-être peut passer DEVANT la nutrition
  //    quand le sommeil ou le stress l'exigent.
  final sleep = ctx.sleepHours;
  final stress = ctx.stress;
  final defPct = mainDeficit?.percent ?? 100;
  final defLabel = mainDeficit?.label.toLowerCase() ?? '';
  final defFix = mainDeficit != null
      ? (_dietAwareFix(mainDeficit.ratioKey, ctx.diet) ??
          _kQuickFix[mainDeficit.ratioKey])
      : null;

  String action;
  if (sleep != null && sleep < 6.0) {
    // A — sommeil vraiment court : LA priorité, avant l'assiette
    action =
        ' Ta priorité aujourd\'hui n\'est pas dans l\'assiette : tu n\'as dormi que ${sleep.toStringAsFixed(1)} h. Tes fringales seront plus fortes — mise sur du brut et du rassasiant, et vise une nuit plus longue ce soir.';
  } else if (stress != null && stress >= 8) {
    // B — stress fort : priorité bien-être
    action =
        ' Ton stress est à $stress/10 : c\'est le point à travailler en priorité. Prends 5 respirations lentes avant chaque repas — ça apaise le mental et améliore ta digestion.';
  } else if (mainDeficit != null && defPct < 65) {
    // C — carence marquée : priorité nutrition
    action = defFix != null
        ? ' Le point à corriger en priorité : $defLabel ($defPct% de ta cible). Le réflexe : $defFix.'
        : ' Le point à corriger en priorité : $defLabel ($defPct% de ta cible).';
  } else if (sleep != null && sleep < 6.5) {
    // D — sommeil moyen
    action =
        ' Ta nuit a été un peu courte (${sleep.toStringAsFixed(1)} h) : privilégie du rassasiant aujourd\'hui et lève le pied sur les excitants.';
  } else if (stress != null && stress >= 7) {
    // D bis — stress notable
    action =
        ' Ton stress ($stress/10) mérite un peu d\'attention : quelques respirations lentes dans la journée te feront du bien.';
  } else if (mainDeficit != null && defPct < 80) {
    // E — carence légère
    action = defFix != null
        ? ' Petit point d\'amélioration : $defLabel ($defPct% de ta cible). Pense à $defFix.'
        : ' Petit point d\'amélioration : $defLabel ($defPct% de ta cible).';
  } else {
    // F — rien de marquant : on célèbre et on oriente selon l'objectif
    if (hour >= 18) {
      action =
          ' Rien à corriger d\'urgence : laisse la nuit faire son travail de récupération.';
    } else {
      switch (ctx.goalKey) {
        case 'loss':
          action =
              ' Rien à corriger : garde le cap avec le duo protéines + légumes à chaque repas, c\'est lui qui tient la satiété.';
          break;
        case 'gain':
          action =
              ' Rien à corriger : pense à répartir tes protéines sur la journée pour bien nourrir ton muscle.';
          break;
        default:
          action =
              ' Rien à corriger : garde le cap avec du brut et de la variété, c\'est la régularité qui paie.';
      }
    }
  }

  return '$etat$progression$action';
}

/// Mémorise le dernier score d'une journée complète, pour permettre au coach
/// d'afficher une progression. Stocke score + date ; ne compare qu'à un
/// AUTRE jour (pas la même journée qui se met à jour en continu).
double? _coachYesterdayScore;
Future<void> _updateCoachScoreHistory(TotumScore? score) async {
  if (score == null) return;
  final sp = await SharedPreferences.getInstance();
  final today = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
  final lastDate = sp.getString('coach_last_score_date');
  final lastScore = sp.getDouble('coach_last_score_value');

  // On expose comme "hier" le dernier score enregistré un autre jour.
  if (lastDate != null && lastDate != today && lastScore != null) {
    _coachYesterdayScore = lastScore;
  } else {
    _coachYesterdayScore = null;
  }

  // On enregistre le score du jour (journée complète only, pour un repère stable).
  if (!score.isProvisional) {
    await sp.setString('coach_last_score_date', today);
    await sp.setDouble('coach_last_score_value', score.global);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  RECETTES TOTUM — chargement + suggestion selon carences
// ═══════════════════════════════════════════════════════════════════════

class TotumRecipeIngredient {
  final String foodId;
  final String foodName;
  final double grams;
  const TotumRecipeIngredient(this.foodId, this.foodName, this.grams);
}

class TotumRecipe {
  final String id;
  final String category;
  final String name;
  final String description;
  final List<TotumRecipeIngredient> ingredients;
  final double totalWeightG;
  final double? kcal100, prot100, carb100, fat100, fiber100;
  final Map<String, double> micros100;
  final List<String> tags;
  /// Étapes de préparation numérotées ("clé en main") — vide sur d'éventuelles
  /// anciennes entrées sans ce champ, jamais requis pour ne pas casser un
  /// cache/import antérieur.
  final List<String> steps;
  const TotumRecipe({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.totalWeightG,
    this.kcal100,
    this.prot100,
    this.carb100,
    this.fat100,
    this.fiber100,
    required this.micros100,
    this.tags = const [],
    this.steps = const [],
  });

  bool get _isCollation => category == 'Collation';

  /// Objectif dominant de la recette, calculé automatiquement depuis ses
  /// macros RÉELLES SUR LA PORTION (pas /100g) — seuils stricts validés :
  /// perte de poids ≤500kcal (repas) / <100kcal (collation) ; hyperprotéiné
  /// ≥30g de protéines (repas) / ≥15g (collation). Jamais posé à la main.
  List<String> get goalTags {
    final kcalTotal = (kcal100 ?? 0) * totalWeightG / 100;
    final protTotal = (prot100 ?? 0) * totalWeightG / 100;
    final out = <String>[];
    final kcalLimit = _isCollation ? 100.0 : 500.0;
    final protFloor = _isCollation ? 15.0 : 30.0;
    if (kcalTotal < kcalLimit) out.add('perte_poids');
    if (protTotal >= protFloor) out.add('hyperproteine');
    if (out.isEmpty) out.add('equilibre');
    return out;
  }

  /// Healthy Score /100 — calculé depuis les données réellement disponibles
  /// (macros + micronutriments CIQUAL déjà présents sur chaque recette).
  /// Inspiré du principe protéines/fibres/densité nutritionnelle/qualité
  /// des lipides/densité énergétique/sucre-sodium, adapté à ce que TOTUM
  /// peut réellement mesurer plutôt qu'une formule abstraite.
  int get healthyScore {
    final kcal = kcal100 ?? 0;
    final prot = prot100 ?? 0;
    final fiber = fiber100 ?? 0;
    final fat = fat100 ?? 0;
    double m(String k) => micros100[k] ?? 0.0;

    final protPer100kcal = kcal > 0 ? (prot * 100 / kcal) : 0;
    final sProt = (protPer100kcal / 8.0 * 20).clamp(0, 20);

    final sFiber = (fiber / 5.0 * 15).clamp(0, 15);

    // Score à crédit partiel (pas tout-ou-rien) : un plat proche du seuil
    // sur un micronutriment garde une part de ses points au lieu de perdre
    // le crédit entier — évite qu'un plat globalement riche mais juste
    // sous un seuil soit noté comme s'il ne contenait rien.
    const microChecks = [
      ('Vitamine_C_mg_100g', 15.0), ('Fer_mg_100g', 1.5),
      ('Magnésium_mg_100g', 40.0), ('Potassium_mg_100g', 300.0),
      ('Calcium_mg_100g', 80.0), ('Zinc_mg_100g', 1.0),
      ('Vitamine_B9_µg_100g', 40.0), ('Beta-Carotène_µg_100g', 300.0),
    ];
    final ratios =
        microChecks.map((e) => (m(e.$1) / e.$2).clamp(0, 1)).toList();
    final sMicro =
        (ratios.reduce((a, b) => a + b) / ratios.length * 20).clamp(0, 20);

    final unsat = m('Acide_oléique_W9_g_100g') +
        m('Acide_linoléique_W6_LA_g_100g') +
        m("Acide_alpha-linolénique_W3_ALA_g_100g");
    final sLipid = fat > 0 ? ((unsat / fat) * 15).clamp(0, 15) : 7.5;

    // Densité calorique : plein score jusqu'à 150 kcal/100g (légumes, plats
    // légers), puis décroissance progressive jusqu'à 0 à 550 kcal/100g —
    // un plat calorique mais par ailleurs sain (poisson gras, avocat, noix)
    // n'est plus sanctionné aussi durement qu'un plat calorique mais vide.
    final sDensity = kcal <= 150
        ? 15.0
        : (15 * (1 - (kcal - 150) / (550 - 150))).clamp(0, 15);

    final sugar = m('Sucres_g_100g');
    final sodium = m('Sodium_mg_100g');
    final sSugar = (7.5 - (sugar / 20 * 7.5)).clamp(0, 7.5);
    final sSodium = (7.5 - (sodium / 600 * 7.5)).clamp(0, 7.5);

    final total = sProt + sFiber + sMicro + sLipid + sDensity + sSugar + sSodium;
    return total.round().clamp(0, 100);
  }
}

class TotumRecipesRepo {
  TotumRecipesRepo._();
  static final TotumRecipesRepo instance = TotumRecipesRepo._();

  final List<TotumRecipe> _all = [];
  bool get isLoaded => _all.isNotEmpty;
  List<TotumRecipe> get all => List.unmodifiable(_all);

  Future<void> load() async {
    if (_all.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString('assets/totum_recipes.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = (map['recipes'] as List?) ?? [];
      for (final e in list) {
        final r = e as Map<String, dynamic>;
        final ings = ((r['ingredients'] as List?) ?? []).map((x) {
          final m = x as Map<String, dynamic>;
          return TotumRecipeIngredient(
            (m['foodId'] ?? '').toString(),
            (m['foodName'] ?? '').toString(),
            (m['grams'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        _all.add(TotumRecipe(
          id: (r['id'] ?? '').toString(),
          category: (r['category'] ?? '').toString(),
          name: (r['name'] ?? '').toString(),
          description: (r['description'] ?? '').toString(),
          ingredients: ings,
          totalWeightG: (r['total_weight_g'] as num?)?.toDouble() ?? 100,
          kcal100: (r['kcal100'] as num?)?.toDouble(),
          prot100: (r['prot100'] as num?)?.toDouble(),
          carb100: (r['carb100'] as num?)?.toDouble(),
          fat100: (r['fat100'] as num?)?.toDouble(),
          fiber100: (r['fiber100'] as num?)?.toDouble(),
          micros100: Map<String, double>.from(
            ((r['micros100'] as Map?) ?? {}).map((k, v) =>
                MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0)),
          ),
          tags: ((r['tags'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
          steps: ((r['steps'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        ));
      }
    } catch (e) {
      debugPrint('Erreur chargement totum_recipes: $e');
    }
  }
}

// Mapping clé de ratio (conseils) → clé micro CSV (recette)
const Map<String, String> _kRatioToMicroCol = {
  'calcium': 'Calcium_mg_100g',
  'iron': 'Fer_mg_100g',
  'magnesium': 'Magnésium_mg_100g',
  'zinc': 'Zinc_mg_100g',
  'iodine': 'Iode_µg_100g',
  'selenium': 'Sélénium_µg_100g',
  'potassium': 'Potassium_mg_100g',
  'vitC': 'Vitamine_C_mg_100g',
  'vitD': 'Vitamine_D_µg_100g',
  'vitE': 'Vitamine_E_mg_100g',
  'B9': 'Vitamine_B9_µg_100g',
  'B12': 'Vitamine_B12_µg_100g',
  'omega3': 'Acide_alpha-linolénique_W3_ALA_g_100g',
  'omega3_marins': 'DHA_g_100g',
  'copper': 'Cuivre_mg_100g',
  'manganese': 'Manganèse_mg_100g',
  'phosphorus': 'Phosphore_mg_100g',
  'B1': 'Vitamine_B1_mg_100g',
  'B2': 'Vitamine_B2_mg_100g',
  'B3': 'Vitamine_B3_mg_100g',
  'B5': 'Vitamine_B5_mg_100g',
  'B6': 'Vitamine_B6_mg_100g',
  'vitA': 'Rétinol_µg_100g',
  'vitK': 'Vitamine_K1_µg_100g',
  'fibers': 'Fibres_g_100g',
};

/// Poids d'importance physiologique par nutriment (1 = standard).
/// Sert à classer les carences : un déficit sur un nutriment clé
/// prime sur un déficit équivalent d'un nutriment secondaire.
const Set<String> _kMarineKeys = {'omega3_marins', 'EPA', 'DHA'};

/// Les 10 micronutriments jugés prioritaires pour la plupart des gens
/// (liste validée avec Alex) : ils dominent le calcul de "Priorité du jour",
/// tout en conservant le même mécanisme de calcul pour tous les nutriments.
const Set<String> _kPriorityRatioKeys = {
  'vitD', 'magnesium', 'iron', 'B12', 'zinc',
  'omega3_marins', 'vitC', 'vitK', 'iodine', 'B9',
};

String? _dietAwareFix(String ratioKey, int diet) {
  if (diet >= 1 && _kMarineKeys.contains(ratioKey)) {
    return 'un complément d\'oméga 3 issu de micro-algues (source végétale d\'EPA/DHA)';
  }
  if (diet == 2 && ratioKey == 'B12') {
    return 'un complément de vitamine B12 (indispensable en régime végétalien)';
  }
  return null;
}

const Map<String, double> _kNutrientWeight = {
  'vitD': 1.6, 'vitC': 1.5, 'iron': 1.5, 'magnesium': 1.4, 'omega3': 1.4,
  'omega3_marins': 1.4,
  'calcium': 1.3, 'B12': 1.3, 'zinc': 1.3, 'iodine': 1.2, 'B9': 1.2,
  'potassium': 1.1, 'vitA': 1.1, 'selenium': 1.1, 'fibers': 1.2,
  'vitE': 1.0, 'vitK': 1.3, 'B6': 1.0, 'B1': 0.9, 'B2': 0.9, 'B3': 0.9,
  'B5': 0.8, 'copper': 0.8, 'phosphorus': 0.7, 'manganese': 0.6,
};

/// Libellé lisible d'un nutriment à partir de sa clé de ratio.
const Map<String, String> _kRatioLabel = {
  'calcium': 'Calcium', 'iron': 'Fer', 'magnesium': 'Magnésium',
  'zinc': 'Zinc', 'iodine': 'Iode', 'selenium': 'Sélénium',
  'potassium': 'Potassium', 'vitC': 'Vitamine C', 'vitD': 'Vitamine D',
  'vitE': 'Vitamine E', 'B9': 'Vitamine B9', 'B12': 'Vitamine B12',
  'omega3': 'Oméga 3 (ALA)', 'omega3_marins': 'Oméga 3 marins (EPA/DHA)',
  'copper': 'Cuivre', 'manganese': 'Manganèse',
  'phosphorus': 'Phosphore', 'B1': 'Vitamine B1', 'B2': 'Vitamine B2',
  'B3': 'Vitamine B3', 'B5': 'Vitamine B5', 'B6': 'Vitamine B6',
  'vitA': 'Vitamine A', 'vitK': 'Vitamine K', 'fibers': 'Fibres',
};

/// Une carence détectée, avec ce qu'il faut pour l'afficher et l'expliquer.
class DeficitInfo {
  final String ratioKey;   // ex: 'iron'
  final String label;      // ex: 'Fer'
  final double ratio;      // 0..1 (part de la cible couverte)
  final String? ficheKey;  // clé de fiche nutriment
  const DeficitInfo({
    required this.ratioKey,
    required this.label,
    required this.ratio,
    this.ficheKey,
  });

  int get percent => (ratio * 100).round();
}

/// Classe les carences par priorité = déficit × importance physiologique.
/// Ne retient que les nutriments réellement sous la cible.
List<DeficitInfo> topDeficits(Map<String, double> ratios, {int max = 5, int diet = 0}) {
  final scored = <MapEntry<DeficitInfo, double>>[];
  ratios.forEach((key, r) {
    if (!r.isFinite || r >= 0.85) return;               // pas un vrai déficit
    if (!_kRatioLabel.containsKey(key)) return;
    // Les 10 micronutriments prioritaires (liste Alex) dominent le classement,
    // sans exclure les autres nutriments suivis (mécanisme conservé pour tous).
    final priorityBoost = _kPriorityRatioKeys.contains(key) ? 1.8 : 1.0;
    final weight = (_kNutrientWeight[key] ?? 1.0) * priorityBoost;
    final severity = (1.0 - r.clamp(0.0, 1.0)) * weight; // + haut = + prioritaire
    scored.add(MapEntry(
      DeficitInfo(
        ratioKey: key,
        label: _kRatioLabel[key] ?? key,
        ratio: r.clamp(0.0, 1.0),
        ficheKey: _kRatioToFicheKey[key],
      ),
      severity,
    ));
  });
  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.take(max).map((e) => e.key).toList();
}

/// Unité d'affichage par nutriment (pour la teneur pour 100 g).
const Map<String, String> _kRatioUnit = {
  'calcium': 'mg', 'iron': 'mg', 'magnesium': 'mg', 'zinc': 'mg',
  'iodine': 'µg', 'selenium': 'µg', 'potassium': 'mg', 'vitC': 'mg',
  'vitD': 'µg', 'vitE': 'mg', 'B9': 'µg', 'B12': 'µg', 'omega3': 'g',
  'omega3_marins': 'g',
  'copper': 'mg', 'manganese': 'mg', 'phosphorus': 'mg', 'B1': 'mg',
  'B2': 'mg', 'B3': 'mg', 'B5': 'mg', 'B6': 'mg', 'vitA': 'µg',
  'vitK': 'µg', 'fibers': 'g',
};

/// Un aliment consommé et la quantité de nutriment qu'il a apportée.
class ConsumedFood {
  final String name;
  final double amount; // quantité du nutriment réellement apportée
  const ConsumedFood(this.name, this.amount);
}

/// Liste les aliments CONSOMMÉS aujourd'hui qui contiennent le nutriment donné,
/// classés par quantité apportée (décroissant). C'est le miroir du réel.
Future<List<ConsumedFood>> consumedFoodsForRatio(String ratioKey) async {
  final col = _kRatioToMicroCol[ratioKey];
  if (col == null) return const [];
  // Vitamine K : K1 et K2 sont deux colonnes CIQUAL distinctes mais une
  // seule "vitamine K" côté utilisateur (comme dans _decideTheme) — on
  // additionne la contribution K2 quand on nous demande K1.
  final extraCol = col == 'Vitamine_K1_µg_100g' ? 'Vitamine_K2_µg_100g' : null;

  final repo = foods_loader.FoodsRepository.instance;
  final all = <foods_loader.FoodItem>[
    ...(repo.items as List).cast<foods_loader.FoodItem>(),
    ...repo.customs,
  ];
  foods_loader.FoodItem? findFood(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }

  final agg = <String, double>{};
  void add(String name, double amt) {
    if (amt <= 0) return;
    agg[name] = (agg[name] ?? 0) + amt;
  }

  // Colonnes macro stockées à part dans food_entries (grammes consommés).
  const macroCols = {
    'Protéines_g_100g': 'protein_g',
    'Glucides_g_100g': 'carbs_g',
    'Lipides_g_100g': 'fat_g',
    'Fibres_g_100g': 'fiber_g',
  };
  const macroLocal = {
    'Protéines_g_100g': 'prot',
    'Glucides_g_100g': 'carb',
    'Lipides_g_100g': 'fat',
    'Fibres_g_100g': 'fiber',
  };

  bool fromSupabase = false;
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      final today = _dateKey(DateTime.now());
      final List<Map<String, dynamic>> rows = await client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .eq('entry_date', today);
      for (final r in rows) {
        final id = (r['food_id'] ?? '').toString();
        final name = (r['food_name'] ?? 'Aliment').toString();
        final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0.0;
        double amountForKey(String key) {
          if (macroCols.containsKey(key)) {
            final v = r[macroCols[key]];
            return (v is num) ? v.toDouble() : 0.0;
          }
          final snap = r['micros'];
          if (snap is Map && snap[key] != null) {
            return (snap[key] is num) ? (snap[key] as num).toDouble() : 0.0;
          } else if (id.isNotEmpty) {
            final food = findFood(id);
            if (food != null) return food.microsFor(grams)[key] ?? 0.0;
          }
          return 0.0;
        }
        var amount = amountForKey(col);
        if (extraCol != null) amount += amountForKey(extraCol);
        add(name, amount);
      }
      if (rows.isNotEmpty) fromSupabase = true;
    }
  } catch (_) {}

  if (!fromSupabase) {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_journalKeyForDate(DateTime.now()));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final meal in decoded.keys) {
          final list = (decoded[meal] as List?) ?? [];
          for (final e in list) {
            final entry = Map<String, dynamic>.from(e as Map);
            final id = (entry['id'] ?? '').toString();
            final name = (entry['name'] ?? 'Aliment').toString();
            final grams = (entry['grams'] as num?)?.toDouble() ?? 0.0;
            double amountForKey(String key) {
              if (macroLocal.containsKey(key)) {
                final v = entry[macroLocal[key]];
                return (v is num) ? v.toDouble() : 0.0;
              }
              final food = findFood(id);
              if (food != null) return food.microsFor(grams)[key] ?? 0.0;
              return 0.0;
            }
            var amount = amountForKey(col);
            if (extraCol != null) amount += amountForKey(extraCol);
            add(name, amount);
          }
        }
      }
    } catch (_) {}
  }

  final out = agg.entries.map((e) => ConsumedFood(e.key, e.value)).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return out;
}

/// Suggère les recettes qui couvrent le mieux les carences de l'utilisateur.
List<TotumRecipe> suggestRecipes(Map<String, double> ratios, {int count = 3}) {
  final all = TotumRecipesRepo.instance.all;
  if (all.isEmpty) return [];

  // Identifier les 3 carences principales (ratio le plus bas sous 1.0)
  // Les 10 nutriments prioritaires sont artificiellement "creusés" pour le tri
  // uniquement, afin qu'ils remontent en tête sans fausser leur ratio réel.
  double sortKey(double v, String key) =>
      _kPriorityRatioKeys.contains(key) ? v - 0.15 : v;
  final deficits = ratios.entries
      .where((e) => _kRatioToMicroCol.containsKey(e.key) && e.value < 0.9)
      .toList()
    ..sort((a, b) =>
        sortKey(a.value, a.key).compareTo(sortKey(b.value, b.key)));

  if (deficits.isEmpty) {
    // Pas de carence marquée → recettes variées (rotation par jour)
    final seed = DateTime.now().day;
    final shuffled = [...all]..sort((a, b) =>
        ((a.id.hashCode + seed) % 100).compareTo((b.id.hashCode + seed) % 100));
    return shuffled.take(count).toList();
  }

  // Pour chaque recette, score = somme de sa richesse dans les micros déficitaires
  final topDeficits = deficits.take(3).map((e) => e.key).toList();
  final scored = <MapEntry<TotumRecipe, double>>[];
  for (final r in all) {
    double score = 0;
    for (final ratioKey in topDeficits) {
      final col = _kRatioToMicroCol[ratioKey]!;
      var val = r.micros100[col] ?? 0;
      // Vitamine K : additionner K2 (même logique que consumedFoodsForRatio).
      if (col == 'Vitamine_K1_µg_100g') {
        val += r.micros100['Vitamine_K2_µg_100g'] ?? 0;
      }
      // normaliser grossièrement par des ordres de grandeur typiques
      score += val;
    }
    scored.add(MapEntry(r, score));
  }
  scored.sort((a, b) => b.value.compareTo(a.value));

  // On garde les 10 recettes les plus pertinentes, puis on en fait tourner
  // `count` chaque jour : la pertinence est conservée, la lassitude évitée.
  final pool = scored.take(10).map((e) => e.key).toList();
  if (pool.length <= count) return pool;
  final seed = DateTime.now().day;
  return List<TotumRecipe>.generate(
    count,
    (i) => pool[(seed + i * 3) % pool.length],
  );
}

Color _deficitColor(int pct) {
  return TotumProgress.forFraction(pct / 100.0);
}

/// Jugement de qualité (pas une progression) — delta directionnel, règle 5.
Color _healthyScoreColor(int score) {
  if (score >= 70) return TotumColors.positive;
  if (score >= 45) return TotumColors.accent;
  return TotumColors.negative;
}

/// Page dédiée : toutes les carences classées + aliments riches (teneur/100 g) + fiche.
class PrioritesNutritionnellesScreen extends StatelessWidget {
  final List<DeficitInfo> deficits;
  const PrioritesNutritionnellesScreen({super.key, required this.deficits});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(title: Text(l10n.consPriorityNutritionalTitle)),
      body: deficits.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.consNoDeficitToday,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: TotumColors.textSecondary),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              children: [
                Text(
                  l10n.consPriorityIntro,
                  style: TextStyle(
                      fontSize: 13, color: TotumColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),
                for (final d in deficits) ...[
                  _DeficitDetailCard(deficit: d),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

/// Carte détaillée d'une carence dans la page dédiée.
class _DeficitDetailCard extends StatefulWidget {
  final DeficitInfo deficit;
  const _DeficitDetailCard({required this.deficit});

  @override
  State<_DeficitDetailCard> createState() => _DeficitDetailCardState();
}

class _DeficitDetailCardState extends State<_DeficitDetailCard> {
  Future<List<ConsumedFood>>? _future;

  @override
  void initState() {
    super.initState();
    _future = consumedFoodsForRatio(widget.deficit.ratioKey);
  }

  String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = widget.deficit;
    final displayLabel = nutrientDisplayLabel(d.label, l10n);
    final c = _deficitColor(d.percent);
    final unit = _kRatioUnit[d.ratioKey] ?? '';

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : nom + couverture
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text('${d.percent}%',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: c)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayLabel,
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: d.ratio.clamp(0.03, 1.0),
                        minHeight: 6,
                        backgroundColor: c.withValues(alpha: 0.15),
                        color: c,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(l10n.consCoveredToday(d.percent),
                        style: TextStyle(
                            fontSize: 11.5, color: TotumColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.restaurant_menu, size: 16, color: c),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    l10n.consWhatYouAteToday,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: c)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<ConsumedFood>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final foods = snap.data ?? const <ConsumedFood>[];
              if (foods.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.consNoFoodContainedTodayAction,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: TotumColors.textPrimary),
                  ),
                );
              }
              final top = foods.take(8).toList();
              final maxVal = top.first.amount;
              return Column(
                children: [
                  for (final f in top)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            flex: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (f.amount / maxVal).clamp(0.02, 1.0),
                                minHeight: 6,
                                backgroundColor: c.withValues(alpha: 0.10),
                                color: c.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 62,
                            child: Text('${_fmt(f.amount)} $unit',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: TotumColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          if (d.ficheKey != null) ...[
            const SizedBox(height: 6),
            Divider(height: 1, color: TotumColors.outline),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => showNutrientFiche(context, d.ficheKey!),
              child: Row(
                children: [
                  Icon(Icons.menu_book, size: 17, color: c),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l10n.consWhereToFindReadFiche(displayLabel.toLowerCase()),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c)),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: c),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bannière horizontale de recettes suggérées.
class _RecipesBanner extends StatelessWidget {
  final List<TotumRecipe> recipes;
  const _RecipesBanner({required this.recipes});

  IconData _iconFor(String cat) {
    switch (cat) {
      case 'Petit-déjeuner':
        return Icons.free_breakfast;
      case 'Déjeuner':
        return Icons.lunch_dining;
      case 'Dîner':
        return Icons.dinner_dining;
      case 'Collation':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  // Un seul accent de marque (règle 1 de la charte) — les catégories se
  // différencient par l'icône (_iconFor) et le libellé, pas par la couleur.
  Color _colorFor(String cat) => TotumColors.accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final r = recipes[i];
          final color = _colorFor(r.category);
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: r),
                ),
              );
            },
            child: Container(
              width: 220,
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 74,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.05)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Icon(_iconFor(r.category), size: 34, color: color),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(_recipeCategoryLabel(r.category, context.l10n),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${r.kcal100?.round() ?? 0} kcal/100g',
                          style: TextStyle(
                              fontSize: 11, color: TotumColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreCriteriaRow extends StatelessWidget {
  final String label;
  final String detail;
  const _ScoreCriteriaRow(this.label, this.detail);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: '$label  ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            TextSpan(
                text: detail,
                style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// === UI (forme/ordre + icône compte) ==============================
class RecipeDetailScreen extends StatefulWidget {
  final TotumRecipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _saving = false;
  bool _added = false;
  RemainingToday? _remaining;

  @override
  void initState() {
    super.initState();
    computeRemainingToday().then((r) {
      if (mounted) setState(() => _remaining = r);
    });
  }

  Future<void> _addToMyRecipes() async {
    setState(() => _saving = true);
    final r = widget.recipe;
    try {
      final sp = await SharedPreferences.getInstance();
      const key = 'recipes_v1';
      final raw = sp.getString(key);
      final List<dynamic> current =
          (raw != null && raw.isNotEmpty) ? jsonDecode(raw) as List : [];

      // Éviter les doublons (même id)
      current.removeWhere((e) =>
          (e is Map && (e['id']?.toString() == r.id)));

      final recipeJson = {
        'id': r.id,
        'name': r.name,
        'description': r.description,
        'ingredients': r.ingredients
            .map((i) => {
                  'foodId': i.foodId,
                  'foodName': i.foodName,
                  'grams': i.grams,
                })
            .toList(),
        'total_weight_g': r.totalWeightG,
        'kcal100': r.kcal100,
        'prot100': r.prot100,
        'carb100': r.carb100,
        'fat100': r.fat100,
        'fiber100': r.fiber100,
        'micros100': r.micros100,
        'steps': r.steps,
        // Traçabilité : cette recette perso vient de la bibliothèque TOTUM
        // (pas envoyé à Supabase, colonne inexistante — voir note ci-dessous ;
        // de toute façon ré-déductible depuis le préfixe "recipe:totum_" de l'id).
        'from_library': true,
      };
      current.add(recipeJson);
      await sp.setString(key, jsonEncode(current));

      // Supabase (best-effort) — schéma de la table `recipes` : mêmes
      // colonnes que celles utilisées par _RecipesStore.save() côté Journal
      // (PAS de colonne `steps`, propre à TotumRecipe) : l'envoyer ferait
      // échouer l'upsert entier et empêcherait la recette d'apparaître
      // dans "Mes recettes" au rechargement suivant.
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client.from('recipes').upsert({
            'user_id': user.id,
            'id': r.id,
            'name': r.name,
            'description': r.description,
            'ingredients': recipeJson['ingredients'],
            'total_weight_g': r.totalWeightG,
            'kcal100': r.kcal100,
            'prot100': r.prot100,
            'carb100': r.carb100,
            'fat100': r.fat100,
            'fiber100': r.fiber100,
            'micros100': r.micros100,
          });
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _saving = false;
          _added = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.consRecipeAddedSnackbar),
            backgroundColor: TotumColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.consAddRecipeError)),
        );
      }
    }
  }

  void _showHealthyScoreInfo(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: TotumColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TotumColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.favorite, size: 20, color: TotumColors.accent),
                const SizedBox(width: 8),
                Text(l10n.consHealthyScoreTitle,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.consHealthyScoreIntro,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            _ScoreCriteriaRow(l10n.nutrientProtein, l10n.consCriteriaProteinDetail),
            _ScoreCriteriaRow(l10n.nutrientFiber, l10n.consCriteriaFiberDetail),
            _ScoreCriteriaRow(l10n.consCriteriaMicronutrients, l10n.consCriteriaMicronutrientsDetail),
            _ScoreCriteriaRow(l10n.consCriteriaFatQuality, l10n.consCriteriaFatQualityDetail),
            _ScoreCriteriaRow(l10n.consCriteriaCalorieDensity, l10n.consCriteriaCalorieDensityDetail),
            _ScoreCriteriaRow(l10n.nutrientSugars, l10n.consCriteriaSugarsDetail),
            _ScoreCriteriaRow('Sodium', l10n.consCriteriaSodiumDetail),
            const SizedBox(height: 12),
            Text(
              l10n.consHealthyScoreLegend,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: TotumColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.consHealthyScorePreworkoutNote,
              style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showFitScoreInfo(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: TotumColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TotumColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.track_changes, size: 20, color: TotumColors.accent),
                const SizedBox(width: 8),
                Text(l10n.consFitScoreTitle,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.consFitScoreIntro,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            _ScoreCriteriaRow(l10n.consCriteriaCalories, l10n.consFitCriteriaCaloriesDetail),
            _ScoreCriteriaRow(l10n.nutrientProtein, l10n.consFitCriteriaProteinDetail),
            _ScoreCriteriaRow(l10n.nutrientCarbs, l10n.consFitCriteriaCarbsDetail),
            _ScoreCriteriaRow(l10n.nutrientFat, l10n.consFitCriteriaFatDetail),
            const SizedBox(height: 12),
            Text(
              l10n.consFitScoreLegend,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: TotumColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.consFitScoreDetail,
              style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final portion = r.totalWeightG;
    // Valeurs pour une portion complète
    double perPortion(double? per100) => (per100 ?? 0) * portion / 100;

    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(title: Text(l10n.consRecipeScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(r.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: TotumColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(_recipeCategoryLabel(r.category, l10n),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TotumColors.accent)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              GestureDetector(
                onTap: () => _showHealthyScoreInfo(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _healthyScoreColor(r.healthyScore).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 12, color: _healthyScoreColor(r.healthyScore)),
                      const SizedBox(width: 3),
                      Text(l10n.consHealthyScoreBadge(r.healthyScore),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _healthyScoreColor(r.healthyScore))),
                      const SizedBox(width: 3),
                      Icon(Icons.info_outline,
                          size: 12,
                          color: _healthyScoreColor(r.healthyScore)),
                    ],
                  ),
                ),
              ),
              if (_remaining != null && _remaining!.hasTargets)
                GestureDetector(
                  onTap: () => _showFitScoreInfo(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TotumColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.track_changes, size: 12, color: TotumColors.accent),
                        const SizedBox(width: 3),
                        Text(
                            l10n.consFitBadge(smartMatchScore(r, _remaining!)),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: TotumColors.accent)),
                        const SizedBox(width: 3),
                        const Icon(Icons.info_outline,
                            size: 12, color: TotumColors.accent),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(r.description,
              style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 20),

          // Préparation — étapes numérotées "clé en main"
          if (r.steps.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.soup_kitchen_outlined, size: 17, color: TotumColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(l10n.consPreparationTitle,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < r.steps.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i == r.steps.length - 1 ? 0 : 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: TotumColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(r.steps[i],
                                style: const TextStyle(
                                    fontSize: 13.5, height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Bilan nutritionnel (portion complète)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.consRecipeValuesFor(portion.round().toString()),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 12),
                _macroRow(l10n.nutrientEnergy, '${perPortion(r.kcal100).round()} kcal',
                    TotumColors.accent),
                _macroRow(l10n.nutrientProtein,
                    '${perPortion(r.prot100).toStringAsFixed(1)} g',
                    TotumColors.accent),
                _macroRow(l10n.nutrientCarbs,
                    '${perPortion(r.carb100).toStringAsFixed(1)} g',
                    TotumColors.accent),
                _macroRow(l10n.nutrientFat,
                    '${perPortion(r.fat100).toStringAsFixed(1)} g',
                    TotumColors.accent),
                _macroRow(l10n.nutrientFiber,
                    '${perPortion(r.fiber100).toStringAsFixed(1)} g',
                    TotumColors.accent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Barre de projection post-consommation
          if (_remaining != null && _remaining!.hasTargets)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TotumColors.accent.withValues(alpha: 0.10),
                    TotumColors.accent.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TotumColors.accentBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.consAfterThisMeal,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: TotumColors.accent)),
                  const SizedBox(height: 10),
                  Builder(builder: (context) {
                    final rem = _remaining!;
                    double left(double have, double? per100) {
                      final used = (per100 ?? 0) * portion / 100;
                      return (have - used).clamp(0, double.infinity);
                    }
                    Widget stat(String label, double v, String unit) => Expanded(
                          child: Column(
                            children: [
                              Text(v.toStringAsFixed(v >= 100 ? 0 : 1),
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w900)),
                              Text('$unit $label',
                                  style: TextStyle(
                                      fontSize: 10.5, color: TotumColors.textSecondary)),
                            ],
                          ),
                        );
                    return Row(
                      children: [
                        stat('kcal', left(rem.kcal, r.kcal100), ''),
                        stat(l10n.consStatProt, left(rem.prot, r.prot100), 'g'),
                        stat(l10n.consStatCarb, left(rem.carb, r.carb100), 'g'),
                        stat(l10n.consStatFat, left(rem.fat, r.fat100), 'g'),
                      ],
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Ingrédients
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.consIngredientsTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 12),
                ...r.ingredients.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: TotumColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_cleanName(i.foodName),
                                style: const TextStyle(fontSize: 13.5)),
                          ),
                          Text('${i.grams.round()} g',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: TotumColors.textSecondary)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bouton ajouter
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor:
                    _added ? TotumColors.positive : TotumColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_saving || _added) ? null : _addToMyRecipes,
              icon: Icon(_added ? Icons.check : Icons.add, size: 20),
              label: Text(_added
                  ? l10n.consAddedToRecipes
                  : l10n.consAddToMyRecipes),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.consFindInJournalNote,
            style: TextStyle(fontSize: 12, color: TotumColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _cleanName(String n) {
    // Raccourcit les noms CIQUAL trop longs (garde avant la 1ère virgule)
    final idx = n.indexOf(',');
    return idx > 0 ? n.substring(0, idx) : n;
  }

  Widget _macroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

/// Catalogue de recettes — recherche, catégories, filtres objectif et
/// "Pour toi" — affiché directement dans l'onglet Recettes (plus de vignette
/// de redirection : on tombe immédiatement sur la bibliothèque complète).
class _RecipesCatalogView extends StatefulWidget {
  final List<TotumRecipe> todayRecipes;
  const _RecipesCatalogView({required this.todayRecipes});

  @override
  State<_RecipesCatalogView> createState() => _RecipesCatalogViewState();
}

class _RecipesCatalogViewState extends State<_RecipesCatalogView> {
  String _filter = 'Toutes';
  // Filtre objectif EXCLUSIF (comme les catégories) : un seul actif à la fois.
  String? _activeTag;
  bool _smartFitOn = false;
  bool _gridView = true;
  RemainingToday? _remaining;
  final _ingredientSearchCtrl = TextEditingController();
  String _ingredientQuery = '';

  // Mémorisation des filtres (Priorité 23) : Alex veut retrouver ses
  // sélections (catégorie, puce objectif, "Pour toi", mode d'affichage) en
  // revenant sur l'onglet — avant, tout retombait à "Toutes" à chaque fois.
  static const _kPrefFilter = 'conseils_recipes_filter_v1';
  static const _kPrefTag = 'conseils_recipes_activetag_v1';
  static const _kPrefSmartFit = 'conseils_recipes_smartfit_v1';
  static const _kPrefGridView = 'conseils_recipes_gridview_v1';

  Future<void> _restoreFilters() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _filter = sp.getString(_kPrefFilter) ?? 'Toutes';
      _activeTag = sp.getString(_kPrefTag);
      _smartFitOn = sp.getBool(_kPrefSmartFit) ?? false;
      _gridView = sp.getBool(_kPrefGridView) ?? true;
    });
  }

  Future<void> _persistFilters() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPrefFilter, _filter);
    if (_activeTag != null) {
      await sp.setString(_kPrefTag, _activeTag!);
    } else {
      await sp.remove(_kPrefTag);
    }
    await sp.setBool(_kPrefSmartFit, _smartFitOn);
    await sp.setBool(_kPrefGridView, _gridView);
  }

  /// Remet tous les filtres à zéro (demandé par Alex, en plus de la
  /// mémorisation) — la recherche par ingrédient n'est pas persistée
  /// (comportement standard d'un champ de recherche), mais reste réinitialisée
  /// ici aussi pour un vrai "retour à zéro" complet.
  Future<void> _resetFilters() async {
    setState(() {
      _filter = 'Toutes';
      _activeTag = null;
      _smartFitOn = false;
      _ingredientSearchCtrl.clear();
      _ingredientQuery = '';
    });
    await _persistFilters();
  }

  bool get _hasActiveFilters =>
      _filter != 'Toutes' || _activeTag != null || _smartFitOn || _ingredientQuery.isNotEmpty;

  static const _cats = [
    'Toutes',
    'Petit-déjeuner',
    'Déjeuner',
    'Dîner',
    'Collation',
    'Pré-workout',
  ];

  // Puces de filtre, exclusives entre elles.
  static const _quickFilters = [
    ('perte_poids', 'Léger', Icons.air),
    ('hyperproteine', 'Hyperprotéiné', Icons.egg_alt),
    ('rapide', 'Rapide', Icons.timer_outlined),
    ('sans_gluten', 'Sans gluten', Icons.grain),
    ('sans_lactose', 'Sans lactose', Icons.no_food),
    ('vegetarien', 'Végétarien', Icons.eco),
    ('vegetalien', 'Végétalien', Icons.spa),
    ('post_workout', 'Post-training', Icons.bolt),
  ];

  @override
  void initState() {
    super.initState();
    _restoreFilters();
    computeRemainingToday().then((r) {
      if (mounted) setState(() => _remaining = r);
    });
  }

  IconData _iconFor(String cat) {
    switch (cat) {
      case 'Petit-déjeuner':
        return Icons.free_breakfast;
      case 'Déjeuner':
        return Icons.lunch_dining;
      case 'Dîner':
        return Icons.dinner_dining;
      case 'Collation':
        return Icons.cookie;
      case 'Pré-workout':
        return Icons.bolt;
      default:
        return Icons.restaurant;
    }
  }

  // Un seul accent de marque (règle 1 de la charte) — les catégories se
  // différencient par l'icône (_iconFor) et le libellé, pas par la couleur.
  Color _colorFor(String cat) => TotumColors.accent;

  bool _matchesActiveFilters(TotumRecipe r) {
    if (_activeTag == null) return true;
    final allTags = {...r.tags, ...r.goalTags};
    return allTags.contains(_activeTag);
  }

  bool _matchesIngredientQuery(TotumRecipe r) {
    final q = _normalizeSearch(_ingredientQuery.trim());
    if (q.isEmpty) return true;
    return r.ingredients.any((i) => _normalizeSearch(i.foodName).contains(q));
  }

  @override
  void dispose() {
    _ingredientSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = TotumRecipesRepo.instance.all;
    final byCategory =
        _filter == 'Toutes' ? all : all.where((r) => r.category == _filter).toList();
    var filtered = byCategory
        .where(_matchesActiveFilters)
        .where(_matchesIngredientQuery)
        .toList();
    final remaining = _remaining;
    final smartFitActive = _smartFitOn && remaining != null && remaining.hasTargets;
    if (smartFitActive) {
      filtered.sort((a, b) =>
          smartMatchScore(b, remaining).compareTo(smartMatchScore(a, remaining)));
      // "Pour toi" doit réellement resserrer la sélection, pas juste trier
      // silencieusement la même liste (sinon rien ne semble changer à l'écran) :
      // on ne garde que les recettes bien adaptées, avec un filet de sécurité
      // si trop peu de recettes de cette sélection atteignent le seuil.
      final wellFitted =
          filtered.where((r) => smartMatchScore(r, remaining) >= 55).toList();
      filtered = wellFitted.length >= 6 ? wellFitted : filtered.take(10).toList();
    }
    final showToday = widget.todayRecipes.isNotEmpty &&
        _filter == 'Toutes' &&
        _activeTag == null &&
        _ingredientQuery.isEmpty;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.consRecipesTotumTitle,
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(l10n.consRecipesCountSorted(all.length),
                              style: TextStyle(
                                  fontSize: 12.5, color: TotumColors.textSecondary)),
                        ],
                      ),
                    ),
                    FilterChip(
                      avatar: Icon(Icons.auto_awesome,
                          size: 16,
                          color: _smartFitOn ? Colors.white : kTotumOrange),
                      label: Text(l10n.consForYouChip),
                      selected: _smartFitOn,
                      onSelected: (v) {
                        setState(() => _smartFitOn = v);
                        _persistFilters();
                      },
                      selectedColor: kTotumOrange,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _smartFitOn ? Colors.white : TotumColors.textPrimary,
                      ),
                      backgroundColor: TotumColors.surface,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TotumColors.outline),
                      ),
                      child: IconButton(
                        tooltip: _gridView ? l10n.consListView : l10n.consGridView,
                        icon: Icon(
                          _gridView ? Icons.view_list : Icons.grid_view_rounded,
                          size: 20,
                          color: TotumColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _gridView = !_gridView);
                          _persistFilters();
                        },
                      ),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: TotumColors.outline),
                        ),
                        child: IconButton(
                          tooltip: l10n.consResetFilters,
                          icon: Icon(Icons.filter_alt_off_outlined,
                              size: 20, color: TotumColors.textSecondary),
                          onPressed: _resetFilters,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Recherche par ingrédient clé ("j'ai du poulet, du riz...") —
                // combinable avec la catégorie et les puces de filtre ci-dessous.
                TextField(
                  controller: _ingredientSearchCtrl,
                  onChanged: (v) => setState(() => _ingredientQuery = v),
                  decoration: InputDecoration(
                    hintText: l10n.consSearchByIngredient,
                    hintStyle: const TextStyle(fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _ingredientQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _ingredientSearchCtrl.clear();
                              _ingredientQuery = '';
                            }),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Filtres de catégorie
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _cats[i];
                      final selected = cat == _filter;
                      return ChoiceChip(
                        avatar: cat == 'Toutes'
                            ? null
                            : Icon(_iconFor(cat),
                                size: 16,
                                color: selected ? Colors.white : _colorFor(cat)),
                        label: Text(_recipeCategoryLabel(cat, l10n)),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _filter = cat);
                          _persistFilters();
                        },
                        selectedColor: _colorFor(cat),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : TotumColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        backgroundColor: TotumColors.surface,
                      );
                    },
                  ),
                ),
                // Filtres objectif, en grandes tuiles visuelles — pour trouver
                // son bonheur d'un coup d'œil, cumulables avec la catégorie.
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _quickFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final (tagKey, label, icon) = _quickFilters[i];
                      final selected = _activeTag == tagKey;
                      const tileColor = TotumColors.accent;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTag = selected ? null : tagKey;
                          });
                          _persistFilters();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 84,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(
                                    colors: [tileColor, TotumProgress.stop75],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: selected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? Colors.transparent : TotumColors.outline,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: tileColor.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon,
                                  size: 24,
                                  color: selected ? Colors.white : tileColor),
                              const SizedBox(height: 6),
                              Text(
                                _quickFilterLabel(tagKey, l10n),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  color: selected ? Colors.white : TotumColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (showToday) ...[
                  const SizedBox(height: 8),
                  Text(l10n.consForYouToday,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _RecipesBanner(recipes: widget.todayRecipes),
                  const SizedBox(height: 18),
                ],
                Text(
                  filtered.isEmpty
                      ? l10n.consNoRecipe
                      : smartFitActive
                          ? l10n.consRecipesSelectedForYou(filtered.length)
                          : l10n.consRecipesCountPlural(filtered.length),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucune recette ne correspond à ces filtres pour le moment.',
                style: TextStyle(fontSize: 13, color: TotumColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (_gridView)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildRecipeCard(filtered[i]),
                childCount: filtered.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRecipeListRow(filtered[i]),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Ligne recette pour l'affichage liste — plus compact que la grille,
  /// pour qui préfère parcourir vite plutôt que visuellement.
  Widget _buildRecipeListRow(TotumRecipe r) {
    final color = _colorFor(r.category);
    final hs = r.healthyScore;
    final remaining = _remaining;
    final smartPct = (remaining != null && remaining.hasTargets)
        ? smartMatchScore(r, remaining)
        : null;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDeco(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(r.category), color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${r.category} · ${r.kcal100?.round() ?? 0} kcal/100g',
                        style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary),
                      ),
                      _miniBadge('$hs', _healthyScoreColor(hs), icon: Icons.favorite),
                      if (smartPct != null && smartPct >= 60)
                        _miniBadge('Fit $smartPct%', kTotumOrange, icon: Icons.track_changes),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: TotumColors.textMuted),
          ],
        ),
      ),
    );
  }

  /// Vignette recette pour la grille — image/icône thématique, nom, badges.
  Widget _buildRecipeCard(TotumRecipe r) {
    final color = _colorFor(r.category);
    final hs = r.healthyScore;
    final remaining = _remaining;
    final smartPct = (remaining != null && remaining.hasTargets)
        ? smartMatchScore(r, remaining)
        : null;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 76,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(_iconFor(r.category), size: 32, color: color),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                height: 1.2)),
                        const SizedBox(height: 3),
                        Text('${r.kcal100?.round() ?? 0} kcal/100g',
                            style: TextStyle(
                                fontSize: 10.5, color: TotumColors.textSecondary)),
                      ],
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _miniBadge('$hs', _healthyScoreColor(hs), icon: Icons.favorite),
                        if (smartPct != null && smartPct >= 60)
                          _miniBadge('$smartPct%', kTotumOrange, icon: Icons.track_changes),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.5, color: color),
            const SizedBox(width: 3),
          ],
          Text(text,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Clé de ratio (moteur de conseils) → clé de fiche nutriment (assets JSON).
const Map<String, String> _kRatioToFicheKey = {
  'omega9': 'omega9',
  'omega6': 'omega6',
  'omega3_ALA': 'omega3',
  'omega3': 'omega3',
  'omega3_marins': 'epa',
  'EPA': 'epa',
  'DHA': 'dha',
  'vitA': 'retinol',
  'vitD': 'vitd',
  'vitE': 'vite',
  'vitK': 'vitk',
  'vitC': 'vitc',
  'B1': 'b1',
  'B2': 'b2',
  'B3': 'b3',
  'B5': 'b5',
  'B6': 'b6',
  'B9': 'b9',
  'B12': 'b12',
  'calcium': 'calcium',
  'copper': 'cuivre',
  'iron': 'fer',
  'iodine': 'iode',
  'magnesium': 'magnesium',
  'manganese': 'manganese',
  'phosphorus': 'phosphore',
  'potassium': 'potassium',
  'selenium': 'selenium',
  'sodium': 'sodium',
  'zinc': 'zinc',
  'fibers': 'fibres',
};

class ConseilsScreen extends StatefulWidget {
  const ConseilsScreen({super.key});

  @override
  State<ConseilsScreen> createState() => ConseilsScreenState();
}

class ConseilsScreenState extends State<ConseilsScreen>
    with SingleTickerProviderStateMixin {
  late Future<AdviceScript> _future;
  // Dernier contenu affiché avec succès — permet de continuer à le montrer
  // pendant qu'un rafraîchissement est en cours, au lieu de faire disparaître
  // toute la page (curseurs compris) le temps du chargement.
  AdviceScript? _lastData;
  bool _refreshing = false;
  final TextEditingController _sleepCtrl = TextEditingController();
  final TextEditingController _waterCtrl = TextEditingController();
  final TextEditingController _stressCtrl = TextEditingController();
  // 3 sections scrollables indépendamment (Coaching / Vitalité / Recettes),
  // même pattern que l'onglet "Ajouter un aliment" du Journal.
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    _future = _initAndLoad(context.l10n);
  }

  Future<AdviceScript> _initAndLoad(AppLocalizations l10n) async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hol = await _readHolisticLog(sp, now);
    if (hol.sleepHours != null) {
      _sleepCtrl.text = hol.sleepHours!.toStringAsFixed(1);
    }
    if (hol.stress != null) {
      _stressCtrl.text = hol.stress!.toString();
    }
    return _buildAdviceScript(l10n);
  }

  /// Recharge le contenu — appelé par main.dart à chaque retour sur cet
  /// onglet (les 4 onglets restent montés en permanence via IndexedStack
  /// pour éviter le flash au changement d'onglet, donc plus rien ne
  /// recharge automatiquement au retour comme avant). Garde l'ancien
  /// contenu affiché pendant le recalcul, même pattern que
  /// [_saveHolisticAndRefresh].
  Future<void> refresh() async {
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _refreshing = true;
      _future = _initAndLoad(l10n);
    });
    final result = await _future;
    if (mounted) {
      setState(() {
        _lastData = result;
        _refreshing = false;
      });
    }
  }

  Future<void> _saveHolisticAndRefresh() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();

    double? d(String s) {
      if (s.trim().isEmpty) return null;
      return double.tryParse(s.replaceAll(',', '.'));
    }

    int? i(String s) {
      if (s.trim().isEmpty) return null;
      return int.tryParse(s);
    }

    await _saveHolisticLog(
      sp,
      now,
      sleepHours: d(_sleepCtrl.text),
      waterLiters: null,
      stress: i(_stressCtrl.text),
    );

    // On garde le contenu actuel affiché (curseurs, score, cartes) et on ne
    // montre qu'un indicateur discret le temps du recalcul — plus de page
    // blanche pendant le rafraîchissement.
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _refreshing = true;
      _future = _initAndLoad(l10n);
    });
    final result = await _future;
    if (mounted) {
      setState(() {
        _lastData = result;
        _refreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _sleepCtrl.dispose();
    _waterCtrl.dispose();
    _stressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TotumColors.textPrimary,
        title: Text(l10n.navConseils,
            style: TextStyle(fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: l10n.accountScreenTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: kTotumOrange,
          unselectedLabelColor: TotumColors.textMuted,
          indicatorColor: kTotumOrange,
          tabs: [
            Tab(icon: const Icon(Icons.auto_awesome), text: l10n.consTabCoaching),
            Tab(icon: const Icon(Icons.spa), text: l10n.consTabVitality),
            Tab(icon: const Icon(Icons.restaurant_menu), text: l10n.consTabRecipes),
          ],
        ),
      ),
      body: FutureBuilder<AdviceScript>(
        future: _future,
        builder: (context, snap) {
          // Premier chargement (rien à montrer encore) : plein écran, normal.
          if (snap.connectionState != ConnectionState.done && _lastData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? _lastData;
          if (data == null) {
            return Center(child: Text(l10n.consNoAdviceAvailable));
          }
          if (snap.connectionState == ConnectionState.done) {
            // Mémorise ce contenu comme "dernier connu" pour les prochains
            // rafraîchissements silencieux.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _lastData != data) {
                setState(() => _lastData = data);
              }
            });
          }
          final isRefreshing =
              _refreshing || snap.connectionState != ConnectionState.done;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _refreshing = true);
              final l10n = context.l10n;
              final result = await (() {
                _future = _initAndLoad(l10n);
                return _future;
              })();
              if (mounted) setState(() { _lastData = result; _refreshing = false; });
            },
            child: Stack(
              children: [
                TabBarView(
                  controller: _tab,
                  children: [
                    // ── Onglet 1 : Coaching (score du jour, priorités, conseils) ──
                    ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                      children: [
                        _AnimatedAppear(index: 0, child: _CoachHeroCard(data: data)),
                        const SizedBox(height: 14),
                        _AnimatedAppear(index: 1, child: _ScorePriorityRow(data: data)),
                        const SizedBox(height: 14),
                        _AnimatedAppear(index: 2, child: _DailyAdviceEntryCard(data: data)),
                        const SizedBox(height: 16),
                        Text(
                          l10n.consMedicalDisclaimer,
                          style: TextStyle(fontSize: 11, color: TotumColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    // ── Onglet 2 : Vitalité (sommeil, stress, soleil) ──────────
                    ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                      children: [
                        _AnimatedAppear(
                          index: 0,
                          child: _WellbeingCard(
                            data: data,
                            sleepCtrl: _sleepCtrl,
                            stressCtrl: _stressCtrl,
                            onSave: _saveHolisticAndRefresh,
                          ),
                        ),
                      ],
                    ),
                    // ── Onglet 3 : Recettes — catalogue complet, immédiat ──────
                    _RecipesCatalogView(todayRecipes: data.suggestedRecipes),
                  ],
                ),
                // Barre de rafraîchissement discrète — remplace l'ancien
                // écran de chargement plein écran qui faisait tout disparaître.
                if (isRefreshing)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: kTotumOrange,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CARTES UI — Conseils 2.0
// ═══════════════════════════════════════════════════════════════════════

/// Bandeau "Coach du jour" — accueil + message coach personnalisé.
class _CoachHeroCard extends StatelessWidget {
  final AdviceScript data;
  const _CoachHeroCard({required this.data});

  ({String salut, IconData icon}) _timeContext(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 6) return (salut: l10n.consGreetingNight, icon: Icons.bedtime);
    if (h < 12) return (salut: l10n.consGreetingMorning, icon: Icons.wb_sunny);
    if (h < 18) return (salut: l10n.consGreetingAfternoon, icon: Icons.wb_sunny_outlined);
    if (h < 22) return (salut: l10n.consGreetingEvening, icon: Icons.nights_stay);
    return (salut: l10n.consGreetingLateNight, icon: Icons.bedtime);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctx = _timeContext(l10n);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TotumColors.accent, TotumProgress.stop75],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TotumColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Élément décoratif : cercle lumineux en fond
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(ctx.icon,
                        color: TotumColors.accent, size: 25),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ctx.salut,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        Text(l10n.consCoachTodayLabel,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  data.coachMessage != null && data.coachMessage!.isNotEmpty
                      ? data.coachMessage!
                      : (data.quotePremium.isNotEmpty
                          ? data.quotePremium
                          : l10n.consDefaultCoachQuote),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rangée "Score du jour + Priorité".
class _ScorePriorityRow extends StatelessWidget {
  final AdviceScript data;
  const _ScorePriorityRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = data.score;
    const accent = TotumColors.accent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Score TOTUM → ouvre le Bilan ──────────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BilanScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDeco(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s != null) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.color.withValues(alpha: 0.12),
                          border: Border.all(color: s.color, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(s.global.round().toString(),
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: s.color)),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.bilanScoreTitle,
                          style:
                              TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(s.moodFor(l10n),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: s.color)),
                      if (s.isProvisional) ...[
                        const SizedBox(height: 4),
                        Text(l10n.consScoreProvisional(s.dayPercent),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10.5, color: TotumColors.textMuted)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.consSeeDetail,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent)),
                          const Icon(Icons.chevron_right, size: 15, color: accent),
                        ],
                      ),
                    ] else
                      const Text('—'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Priorité du jour → ouvre la fiche nutriment ───────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PrioritesNutritionnellesScreen(deficits: data.deficits),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDeco(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.flag_rounded,
                              size: 18, color: accent),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(l10n.consPriorityOfTheDay,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (data.deficits.isEmpty)
                      Flexible(
                        child: Text(
                          l10n.consNoDeficitTodayShort,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: TotumColors.textPrimary,
                              height: 1.4),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final d in data.deficits)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nutrientDisplayLabel(d.label, l10n),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${d.percent}%',
                                    style: TextStyle(
                                        fontSize: 10.5, color: TotumColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu,
                            size: 15, color: accent),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            data.deficits.isEmpty
                                ? l10n.consSeeDetail
                                : l10n.consTapToSeeWhereToFind,
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  }

/// Bannière d'accès aux conseils du jour (nutrition, mouvement, sommeil,
/// stress, mindset) — remontée au même niveau que les autres bannières de
/// l'onglet Coaching, plus une porte d'entrée cachée dans un coin.
class _DailyAdviceEntryCard extends StatelessWidget {
  final AdviceScript data;
  const _DailyAdviceEntryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = [
      data.advNutrition, data.advMouvement, data.advSommeil,
      data.advStress, data.advMindset,
    ].whereType<CoachAdvice>().length;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConseilsDuJourScreen(data: data)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TotumColors.accent, TotumProgress.stop75],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: TotumColors.accent.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories,
                  color: TotumColors.accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.consDailyAdviceTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    count > 0
                        ? l10n.consPersonalizedAdviceCount(count)
                        : l10n.consAdviceCategories,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}

/// Carte "Bien-être holistique" — sommeil + stress, saisie + conseil.
class _WellbeingCard extends StatefulWidget {
  final AdviceScript data;
  final TextEditingController sleepCtrl;
  final TextEditingController stressCtrl;
  final Future<void> Function() onSave;
  const _WellbeingCard({
    required this.data,
    required this.sleepCtrl,
    required this.stressCtrl,
    required this.onSave,
  });

  @override
  State<_WellbeingCard> createState() => _WellbeingCardState();
}

class _WellbeingCardState extends State<_WellbeingCard> {
  late double _sleep;
  late double _stress;

  // Un seul accent de marque (règle 1) — Sommeil/Stress se différencient par
  // l'icône et le titre, cohérent avec ConseilsDuJourScreen (même 2 piliers).
  static const _sleepColor = TotumColors.accent;
  static const _stressColor = TotumColors.accent;

  @override
  void initState() {
    super.initState();
    _sleep = double.tryParse(widget.sleepCtrl.text.replaceAll(',', '.')) ?? 7.5;
    _stress = double.tryParse(widget.stressCtrl.text.replaceAll(',', '.')) ?? 4;
  }

  void _syncControllers() {
    widget.sleepCtrl.text = _sleep.toStringAsFixed(1);
    widget.stressCtrl.text = _stress.round().toString();
  }

  String _sleepWord() {
    if (_sleep < 5) return 'Très court';
    if (_sleep < 6.5) return 'Insuffisant';
    if (_sleep < 8) return 'Correct';
    if (_sleep <= 9.5) return 'Idéal';
    return 'Long';
  }

  String _stressWord() {
    if (_stress <= 2) return 'Serein';
    if (_stress <= 4) return 'Calme';
    if (_stress <= 6) return 'Modéré';
    if (_stress <= 8) return 'Élevé';
    return 'Très élevé';
  }

  // Indication courte, ludique et actionnable sous chaque palier — pour que
  // le mot affiché (« Correct », « Idéal »…) ne reste jamais sans contexte.
  String _sleepTip() {
    if (_sleep < 5) return 'Une nuit aussi courte pèse sur ta récupération et tes fringales dès demain — priorise le coucher ce soir.';
    if (_sleep < 6) return 'Sous 6h de façon répétée, le risque de fatigue et de fringales augmente nettement — regagne du terrain progressivement.';
    if (_sleep < 7) return 'Zone "limite acceptable" pour les experts du sommeil : quelques minutes de plus suffiraient à basculer dans la zone recommandée.';
    if (_sleep <= 9) return 'Tu es dans la fourchette recommandée pour un adulte — la zone la plus favorable à ta récupération.';
    if (_sleep <= 10) return 'Toujours une zone jugée acceptable — un besoin naturel de dormir un peu plus n\'est pas un problème en soi.';
    return 'Au-delà de 10h de façon récurrente, ça vaut la peine de vérifier la qualité de ton sommeil si la fatigue persiste.';
  }

  String _stressTip() {
    if (_stress <= 2) return 'Un très bon terrain pour ta récupération globale — profites-en pour ancrer ce qui fonctionne bien pour toi.';
    if (_stress <= 4) return 'Un niveau sain. Garde les leviers qui t\'aident à rester dans cette zone.';
    if (_stress <= 6) return 'Rien d\'alarmant, mais quelques minutes de respiration lente peuvent t\'aider à redescendre encore.';
    if (_stress <= 8) return 'À ce niveau, le corps carbure aux hormones du stress — une pause respiration ou une marche peuvent vraiment faire la différence aujourd\'hui.';
    return 'Un niveau qui mérite ton attention en priorité aujourd\'hui — commence par une pause calme avant toute autre chose.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bien-être holistique',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          'Les trois piliers de ta vitalité au quotidien : sommeil, stress '
          'et exposition au soleil.',
          style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),

        // ── CARTE SOMMEIL (↔ Rituel du soir) ──────────────────────────
        _pillarCard(
          color: _sleepColor,
          icon: Icons.nightlight_round,
          title: 'Sommeil',
          valueLabel: '${_sleep.toStringAsFixed(1)} h · ${_sleepWord()}',
          tip: _sleepTip(),
          slider: Slider(
            value: _sleep.clamp(0, 12),
            min: 0,
            max: 12,
            divisions: 24,
            activeColor: _sleepColor,
            label: '${_sleep.toStringAsFixed(1)} h',
            onChanged: (v) {
              setState(() => _sleep = v);
              _syncControllers();
            },
          ),
          toolIcon: Icons.nightlight_round,
          toolTitle: 'Rituel du soir',
          toolSubtitle: 'Mieux dormir',
          onTool: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RituelSoirScreen()),
          ),
        ),
        const SizedBox(height: 14),

        // ── CARTE STRESS (↔ Respiration) ──────────────────────────────
        _pillarCard(
          color: _stressColor,
          icon: Icons.spa,
          title: 'Stress',
          valueLabel: '${_stress.round()}/10 · ${_stressWord()}',
          tip: _stressTip(),
          slider: Slider(
            value: _stress.clamp(0, 10),
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: _stressColor,
            label: '${_stress.round()}/10',
            onChanged: (v) {
              setState(() => _stress = v);
              _syncControllers();
            },
          ),
          toolIcon: Icons.air,
          toolTitle: 'Respiration',
          toolSubtitle: 'Anti-stress',
          onTool: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BreathGoalPickerScreen()),
          ),
        ),
        const SizedBox(height: 14),

        // Conseil personnalisé (si présent) — reflète directement sommeil/stress
        if (widget.data.chronoAnalyse.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: TotumColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology_alt,
                          size: 17, color: TotumColors.accent),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Ton analyse du jour',
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.data.chronoAnalyse,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
                if (widget.data.actionLifestyle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(widget.data.actionLifestyle,
                      style: TextStyle(
                          fontSize: 13, color: TotumColors.textPrimary, height: 1.45)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Bouton mettre à jour — juste après sommeil/stress, qu'il recalcule
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: TotumColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              _syncControllers();
              widget.onSave();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Mettre à jour mes conseils'),
          ),
        ),
        const SizedBox(height: 20),

        // ── CARTE SOLEIL & VITAMINE D — pilier séparé, page dédiée ─────
        _sunCard(context),
      ],
    );
  }

  /// Une carte-pilier autonome (sommeil / stress) : header, slider, conseil,
  /// accès à l'outil associé — chacune visuellement indépendante et scrollable.
  Widget _pillarCard({
    required Color color,
    required IconData icon,
    required String title,
    required String valueLabel,
    required String tip,
    required Widget slider,
    required IconData toolIcon,
    required String toolTitle,
    required String toolSubtitle,
    required VoidCallback onTool,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              Text(valueLabel,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: TotumColors.textPrimary)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: slider,
          ),
          Text(
            tip,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: color.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onTool,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(toolIcon, size: 17, color: color),
                  const SizedBox(width: 8),
                  Text(toolTitle,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(width: 6),
                  Text('· $toolSubtitle',
                      style: TextStyle(
                          fontSize: 11.5, color: TotumColors.textMuted)),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 17, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte Soleil & vitamine D — même gabarit visuel que les cartes-piliers.
  Widget _sunCard(BuildContext context) {
    const color = TotumColors.accent;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SunVitaminDScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.wb_sunny, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Soleil & vitamine D',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Une bonne partie de ta vitamine D vient de l\'exposition au '
              'soleil, pas seulement de l\'alimentation. Estime ta synthèse '
              'du jour pour savoir où tu en es.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: TotumColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny, size: 17, color: color),
                  SizedBox(width: 8),
                  Text('Estimer ma synthèse',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                  Spacer(),
                  Icon(Icons.chevron_right, size: 17, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile de conseil thématique homogène.
/// Carte STRESS interactive : exercice de respiration guidé par un cercle animé.
/// Trois techniques au choix, chacune scientifiquement validée.
/// Vignette compacte d'accès à la page respiration (gestion du stress).
/// Une technique de respiration entièrement paramétrable.
/// Objectif de séance (Priorité 43, retour d'Alex, capture d'écran/audit
/// Breathwrk à l'appui — Breathwrk structure toute sa bibliothèque en
/// catégories objectif du même esprit : Relax/Balance/Restore/Focus/
/// Energize/Unwind). Une technique peut servir plusieurs objectifs.
enum BreathGoal { apaiser, renforcer, equilibrer, debuter }

extension BreathGoalLabel on BreathGoal {
  String get label => switch (this) {
        BreathGoal.apaiser => 'Apaiser',
        BreathGoal.renforcer => 'Renforcer',
        BreathGoal.equilibrer => 'Équilibrer',
        BreathGoal.debuter => 'Débuter',
      };
  String get subtitle => switch (this) {
        BreathGoal.apaiser => 'Calmer le mental, faire retomber le stress',
        BreathGoal.renforcer => 'Booster l\'énergie, muscler le contrôle du souffle',
        BreathGoal.equilibrer => 'Rythme régulier, équilibre du système nerveux',
        BreathGoal.debuter => 'La base, en douceur, pour prendre ses marques',
      };
  IconData get icon => switch (this) {
        BreathGoal.apaiser => Icons.spa_outlined,
        BreathGoal.renforcer => Icons.bolt_outlined,
        BreathGoal.equilibrer => Icons.balance_outlined,
        BreathGoal.debuter => Icons.school_outlined,
      };
}

class BreathTech {
  final String key;
  final String name;
  final String desc;
  final String benefit;
  final List<String> phaseLabels; // ordre des phases
  final List<int> defaultSeconds; // durée par défaut de chaque phase
  final List<double> scales;      // échelle du cercle par phase (1.0..2.0)
  // Type de son procédural par phase (Priorité 41) — remplace l'ancienne
  // liste de clés MP3 'inhale'/'hold'/'exhale' : distingue explicitement
  // rétention poumons pleins (330 Hz) et poumons vides (220 Hz), que
  // l'ancien système ne pouvait pas différencier (même clé 'hold' pour les
  // deux, la fréquence cible restait implicite dans le fichier audio lui-même).
  final List<BreathPhaseType> soundKinds;
  final int minSec;
  final int maxSec;
  // Priorité 43 : objectifs de séance couverts par cette technique (une
  // technique peut en couvrir plusieurs) + objectif "principal" pour la
  // mettre en avant en tête de liste quand on filtre par cet objectif.
  final List<BreathGoal> goals;
  final BreathGoal? primaryGoal;
  final String source; // courte citation scientifique, ton déjà utilisé pour les bandeaux Marques/Restaurant
  const BreathTech({
    required this.key,
    required this.name,
    required this.desc,
    required this.benefit,
    required this.phaseLabels,
    required this.defaultSeconds,
    required this.scales,
    required this.soundKinds,
    required this.goals,
    this.primaryGoal,
    this.source = '',
    this.minSec = 2,
    this.maxSec = 10,
  });
}

const List<BreathTech> kBreathTechs = [
  BreathTech(
    key: 'coherence',
    name: 'Cohérence cardiaque',
    desc:
        'Un rythme régulier où l\'inspiration et l\'expiration durent le même temps. Le classique « 365 » : 3 fois par jour, 6 respirations par minute, pendant 5 minutes.',
    benefit:
        'La technique anti-stress la plus étudiée. Elle synchronise le cœur et la respiration, équilibre le système nerveux autonome, fait baisser le cortisol et améliore la variabilité cardiaque — un marqueur clé de santé et de longévité.',
    phaseLabels: ['Inspire', 'Expire'],
    defaultSeconds: [5, 5],
    scales: [2.0, 1.0],
    soundKinds: [BreathPhaseType.inhale, BreathPhaseType.exhale],
    goals: [BreathGoal.equilibrer, BreathGoal.apaiser, BreathGoal.debuter],
    primaryGoal: BreathGoal.equilibrer,
    source: 'Base de preuve la plus solide sur la variabilité cardiaque de fond (résonance cardio-respiratoire à 5-6 resp/min).',
    minSec: 3,
    maxSec: 8,
  ),
  BreathTech(
    key: 'square',
    name: 'Respiration carrée',
    desc:
        'Quatre temps égaux : inspire, retiens poumons pleins, expire, retiens poumons vides. On dessine mentalement un carré. Utilisée par les forces spéciales pour rester calme sous pression.',
    benefit:
        'Les deux rétentions renforcent le contrôle du souffle et la concentration. Idéale pour retrouver son sang-froid avant un événement stressant, calmer le mental et ancrer l\'attention dans l\'instant.',
    phaseLabels: ['Inspire', 'Retiens', 'Expire', 'Retiens'],
    defaultSeconds: [4, 4, 4, 4],
    scales: [2.0, 2.0, 1.0, 1.0],
    soundKinds: [
      BreathPhaseType.inhale,
      BreathPhaseType.holdFull,
      BreathPhaseType.exhale,
      BreathPhaseType.holdEmpty,
    ],
    goals: [BreathGoal.renforcer, BreathGoal.equilibrer],
    primaryGoal: BreathGoal.renforcer,
    source: 'Un des 3 bras de l\'essai randomisé de Stanford (Balban, Huberman, Spiegel — Cell Reports Medicine, 2023) sur la respiration et l\'humeur.',
    minSec: 2,
    maxSec: 8,
  ),
  BreathTech(
    key: 'weil478',
    name: '4-7-8',
    desc:
        'Inspire 4 secondes, retiens 7 secondes, expire lentement sur 8 secondes. Popularisée par le Dr Andrew Weil, parfois surnommée "calmant naturel".',
    benefit:
        'L\'expiration longue associée à la rétention active fortement le système nerveux parasympathique — celui du repos et de la récupération. Particulièrement efficace pour redescendre avant le sommeil ou calmer une montée d\'anxiété.',
    phaseLabels: ['Inspire', 'Retiens', 'Expire'],
    defaultSeconds: [4, 7, 8],
    scales: [1.6, 1.6, 1.0],
    soundKinds: [BreathPhaseType.inhale, BreathPhaseType.holdFull, BreathPhaseType.exhale],
    goals: [BreathGoal.apaiser],
    primaryGoal: BreathGoal.apaiser,
    source: 'Étude 2022 (Physiological Reports) : amélioration de la variabilité cardiaque et baisse de la tension artérielle systolique après une séance.',
    minSec: 2,
    maxSec: 12,
  ),
  BreathTech(
    key: 'diaphragmatic',
    name: 'Respiration ventrale',
    desc:
        'La base de toute pratique respiratoire : on gonfle le ventre à l\'inspire (pas la poitrine), on le relâche à l\'expire. Aucune rétention, aucun rythme complexe à retenir.',
    benefit:
        'Réapprend à utiliser pleinement le diaphragme plutôt qu\'une respiration thoracique courte et superficielle — la base sur laquelle s\'appuient toutes les autres techniques. Le point de départ le plus accessible pour découvrir la respiration guidée.',
    phaseLabels: ['Inspire (ventre)', 'Expire'],
    defaultSeconds: [4, 6],
    scales: [1.5, 1.0],
    soundKinds: [BreathPhaseType.inhale, BreathPhaseType.exhale],
    goals: [BreathGoal.debuter],
    primaryGoal: BreathGoal.debuter,
    source: 'Technique fondation enseignée en kinésithérapie respiratoire et en gestion du stress, préalable classique aux techniques plus structurées.',
    minSec: 3,
    maxSec: 9,
  ),
  BreathTech(
    key: 'physiologicalSigh',
    name: 'Soupir physiologique',
    desc:
        'Deux inspirations courtes par le nez, l\'une après l\'autre sans expirer entre les deux, puis une longue expiration par la bouche. Le geste que le corps fait déjà naturellement pour "souffler".',
    benefit:
        'La double inspiration rouvre les petits sacs pulmonaires (alvéoles) affaissés, l\'expiration longue qui suit déclenche un apaisement quasi immédiat. Dans une étude comparative, cette technique a fait mieux que la respiration carrée, l\'hyperventilation cyclique ET la méditation de pleine conscience pour améliorer l\'humeur.',
    phaseLabels: ['Inspire', 'Inspire (complément)', 'Expire'],
    defaultSeconds: [2, 1, 5],
    scales: [2.0, 2.15, 1.0],
    soundKinds: [BreathPhaseType.inhale, BreathPhaseType.inhaleTopUp, BreathPhaseType.exhale],
    goals: [BreathGoal.apaiser],
    primaryGoal: BreathGoal.apaiser,
    source: 'Balban, Huberman, Spiegel — Cell Reports Medicine, 2023 (Stanford) : technique la mieux notée des 3 comparées sur l\'humeur et la fréquence respiratoire.',
    minSec: 1,
    maxSec: 8,
  ),
];

/// Hyperventilation cyclique façon Wim Hof (Priorité 43) : structure
/// fondamentalement différente des `BreathTech` ci-dessus — des "rounds"
/// hétérogènes (respirations rapides, puis rétention à durée LIBRE choisie
/// par l'utilisateur, puis récupération à durée fixe), pas une séquence de
/// phases identiques répétée N fois. Plutôt que de forcer ce cas unique
/// dans le modèle `BreathTech`/`_runPhase()` (qui fonctionne bien pour les
/// 5 autres techniques), c'est un type de données et un écran dédiés — voir
/// `_CyclicHyperventilationScreen`. Réutilise `BreathAudioEngine.startPhase`
/// comme seule brique bas niveau, comme les autres techniques.
class BreathRoundsTech {
  final String key;
  final String name;
  final String desc;
  final String benefit;
  final int rapidBreathsPerRound;
  final int rapidBreathSeconds;
  final int recoveryHoldSeconds;
  final int minRounds;
  final int maxRounds;
  final int defaultRounds;
  // Priorité 44 (retour d'Alex) : la méthode originelle prévoit une
  // rétention "aussi longtemps que confortable" — mais un compte à rebours
  // préréglé (réglable, comme les rounds) plutôt qu'un bouton à taper est
  // ce que font réellement les apps WHM de référence, y compris
  // l'application officielle Wim Hof Method (minuteur de rétention réglable,
  // pas d'interaction requise pendant la séance) — voir "Breathe Like Wim"/
  // Vayu, qui exposent exactement ce réglage. Permet de garder les yeux
  // fermés du début à la fin, comme demandé.
  final int minHoldSeconds;
  final int maxHoldSeconds;
  final int defaultHoldSeconds;
  final List<BreathGoal> goals;
  final String source;
  final String safetyWarning;
  const BreathRoundsTech({
    required this.key,
    required this.name,
    required this.desc,
    required this.benefit,
    required this.rapidBreathsPerRound,
    required this.rapidBreathSeconds,
    required this.recoveryHoldSeconds,
    required this.minRounds,
    required this.maxRounds,
    required this.defaultRounds,
    required this.minHoldSeconds,
    required this.maxHoldSeconds,
    required this.defaultHoldSeconds,
    required this.goals,
    required this.source,
    required this.safetyWarning,
  });
}

const List<BreathRoundsTech> kBreathRoundsTechs = [
  BreathRoundsTech(
    key: 'cyclicHyperventilation',
    name: 'Hyperventilation cyclique',
    desc:
        'Une série de 30 respirations amples et rapides, suivie d\'une rétention poumons vides, puis d\'une courte récupération. On répète l\'ensemble sur plusieurs "rounds", les yeux fermés du début à la fin — aucune action requise pendant la séance.',
    benefit:
        'Un vrai coup de fouet : la phase rapide augmente temporairement l\'alcalinité du sang, la rétention qui suit entraîne la tolérance au CO2 et le contrôle du souffle. Une pratique intense, à réserver aux moments où vous cherchez de l\'énergie ou à repousser vos limites de contrôle respiratoire — pas une technique de détente.',
    rapidBreathsPerRound: 30,
    rapidBreathSeconds: 1,
    recoveryHoldSeconds: 15,
    minRounds: 1,
    maxRounds: 5,
    defaultRounds: 3,
    minHoldSeconds: 30,
    maxHoldSeconds: 180,
    defaultHoldSeconds: 60,
    goals: [BreathGoal.renforcer],
    source: 'Un des 3 bras de l\'essai de Stanford (Balban, Huberman, Spiegel — Cell Reports Medicine, 2023), sous le nom "cyclic hyperventilation with retention".',
    safetyWarning:
        'Cette technique fait momentanément baisser le taux de CO2 dans le sang et peut provoquer des étourdissements, des picotements ou, rarement, un évanouissement.\n\n'
        'À ne jamais pratiquer :\n'
        '• en étant debout, en conduisant, en nageant ou dans/près de l\'eau (risque de noyade documenté en cas de perte de connaissance)\n'
        '• en cas de grossesse\n'
        '• en cas d\'épilepsie ou d\'antécédents de convulsions\n'
        '• en cas de troubles cardiovasculaires\n'
        '• en cas de malaises ou évanouissements déjà connus\n\n'
        'Pratiquez toujours assis ou allongé, dans un endroit sûr. En cas de doute médical, demandez l\'avis d\'un professionnel de santé avant de commencer.',
  ),
];

/// Écran d'entrée du module Respiration (Priorité 43, retour d'Alex) :
/// parcours par objectif avant le choix technique — pattern validé par
/// l'audit d'apps concurrentes (Breathwrk structure toute sa bibliothèque en
/// catégories objectif du même esprit : Relax/Balance/Restore/Focus/
/// Energize/Unwind). Style visuel dérivé de `_cardDeco()`/`_accent` déjà
/// utilisés dans ce fichier plutôt qu'un nouveau langage visuel.
class BreathGoalPickerScreen extends StatefulWidget {
  const BreathGoalPickerScreen({super.key});

  @override
  State<BreathGoalPickerScreen> createState() => _BreathGoalPickerScreenState();
}

class _BreathGoalPickerScreenState extends State<BreathGoalPickerScreen> {
  int? _weekCount;

  @override
  void initState() {
    super.initState();
    loadBreathSessionsThisWeek().then((c) {
      if (mounted) setState(() => _weekCount = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        title: const Text('Respiration'),
        backgroundColor: TotumColors.surface,
        foregroundColor: TotumColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text('Qu\'est-ce que tu cherches aujourd\'hui ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (_weekCount != null && _weekCount! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                '${_weekCount!} séance${_weekCount! > 1 ? 's' : ''} cette semaine',
                style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary),
              ),
            ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              for (final goal in BreathGoal.values)
                _GoalCard(
                  goal: goal,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RespirationScreen(initialGoal: goal)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RespirationScreen()),
              ),
              child: const Text('Voir toutes les techniques'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final BreathGoal goal;
  final VoidCallback onTap;
  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Charte graphique (retour d'Alex, 13/08/2026) : une seule couleur
    // d'accent dans toute l'app (voir TotumColors, en-tête du fichier
    // totum_style.dart) — jamais une 2e couleur "de marque" par catégorie.
    // Les 4 cartes se distinguent par l'icône et le texte, pas la teinte
    // (même logique que `_pillarCard` : `_stressColor`/`_sleepColor` sont
    // tous deux littéralement `TotumColors.accent`, jamais des couleurs
    // distinctes).
    return InkWell(
      borderRadius: BorderRadius.circular(TotumRadius.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TotumColors.surface,
          borderRadius: BorderRadius.circular(TotumRadius.card),
          border: Border.all(color: TotumColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TotumColors.accentSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(goal.icon, color: TotumColors.accent, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.label,
                    style: TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
                const SizedBox(height: 3),
                Text(goal.subtitle,
                    style: TextStyle(fontSize: 11, height: 1.3, color: TotumColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Page dédiée : respiration guidée, entièrement paramétrable.
class RespirationScreen extends StatefulWidget {
  final BreathGoal? initialGoal;
  const RespirationScreen({super.key, this.initialGoal});

  @override
  State<RespirationScreen> createState() => _RespirationScreenState();
}

class _RespirationScreenState extends State<RespirationScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = TotumColors.accent;

  // Bug corrigé (retour d'Alex, 13/08/2026) : ces deux champs étaient
  // initialisés indépendamment — `_techIndex` pouvait être réassigné dans
  // `initState()` selon `widget.initialGoal`, mais `_seconds` restait figé
  // sur `kBreathTechs[0]` (Cohérence, 2 phases). Tant qu'on démarrait
  // toujours sur l'index 0, ça ne se voyait pas — dès qu'un objectif
  // amenait sur une technique à 3 phases (4-7-8, Soupir physiologique) sans
  // préférences déjà sauvegardées, `_seconds` gardait sa longueur 2 et
  // `_seconds[2]` plantait (RangeError). `late` + dépendance explicite à
  // `_techIndex` : les deux se calculent maintenant pour la même technique,
  // quel que soit l'ordre d'évaluation.
  late int _techIndex = widget.initialGoal != null ? _visibleTechIndices.first : 0;
  late List<int> _seconds = List<int>.from(kBreathTechs[_techIndex].defaultSeconds);
  int _cycles = 30;
  bool _soundOn = true;

  /// Priorité 43 : indices (dans `kBreathTechs`, la liste maîtresse — pour
  /// que `_techIndex`/`_selectTech`/`_seconds` continuent de fonctionner
  /// sans changement) des techniques à afficher pour l'objectif choisi sur
  /// l'écran parcours, triées technique "primaire" de l'objectif en tête.
  /// Sans objectif (accès direct à `RespirationScreen`), toutes les
  /// techniques, dans l'ordre existant.
  List<int> get _visibleTechIndices {
    final goal = widget.initialGoal;
    if (goal == null) return List.generate(kBreathTechs.length, (i) => i);
    final matches = [
      for (int i = 0; i < kBreathTechs.length; i++)
        if (kBreathTechs[i].goals.contains(goal)) i,
    ];
    if (matches.isEmpty) return List.generate(kBreathTechs.length, (i) => i);
    matches.sort((a, b) {
      // Priorité 53 (14/08/2026, retour d'Alex) : "Cohérence cardiaque"
      // doit toujours être la 1re technique proposée, quel que soit
      // l'objectif filtré — déjà vrai pour "Équilibrer" (sa primaryGoal),
      // pas pour "Apaiser"/"Débuter" où une autre technique gagnait le tri
      // par primaryGoal. Technique la plus universelle et la mieux établie
      // scientifiquement (base de preuve la plus solide, voir sa fiche) —
      // priorité explicite demandée sur les 3 objectifs où elle apparaît.
      final aCoherence = kBreathTechs[a].key == 'coherence' ? 0 : 1;
      final bCoherence = kBreathTechs[b].key == 'coherence' ? 0 : 1;
      if (aCoherence != bCoherence) return aCoherence.compareTo(bCoherence);
      final ap = kBreathTechs[a].primaryGoal == goal ? 0 : 1;
      final bp = kBreathTechs[b].primaryGoal == goal ? 0 : 1;
      return ap.compareTo(bp);
    });
    return matches;
  }

  List<BreathRoundsTech> get _visibleRoundsTechs {
    final goal = widget.initialGoal;
    if (goal == null) return kBreathRoundsTechs;
    return kBreathRoundsTechs.where((rt) => rt.goals.contains(goal)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _audio.init();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _cycles = sp.getInt('breath_cycles') ?? 30;
      _soundOn = sp.getBool('breath_sound') ?? true;
      for (int t = 0; t < kBreathTechs.length; t++) {
        final saved = sp.getStringList('breath_sec_${kBreathTechs[t].key}');
        if (saved != null && t == _techIndex) {
          _seconds = saved.map((e) => int.tryParse(e) ?? 4).toList();
        }
      }
    });
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('breath_cycles', _cycles);
    await sp.setBool('breath_sound', _soundOn);
    await sp.setStringList('breath_sec_${_tech.key}',
        _seconds.map((e) => e.toString()).toList());
  }

  bool _running = false;
  int _phaseIndex = 0;
  int _cycle = 0;
  int _remaining = 0;
  Timer? _timer;
  // Moteur audio procédural (Priorité 41) — remplace les 3 MP3 statiques
  // assets/sounds/{inhale,hold,exhale}.mp3 : synthèse en temps réel,
  // continue sur toute la session (voir breath_audio_engine.dart pour le
  // détail — accumulateur de phase jamais réinitialisé entre phases, d'où
  // l'absence de clic aux transitions, contrairement à l'ancien "stop +
  // replay un MP3" par phase).
  final BreathAudioEngine _audio = BreathAudioEngine();
  late final BreathBackgroundSession _background = BreathBackgroundSession(_audio);

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
    lowerBound: 1.0,
    upperBound: 2.0,
  )..value = 1.0;

  BreathTech get _tech => kBreathTechs[_techIndex];

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    _audio.dispose();
    // Bug corrigé (14/08/2026) : manquait ici (déjà présent côté
    // CyclicHyperventilationScreen) — sans ça, le service au premier plan
    // Android / la session audio iOS restaient actifs après une sortie de
    // page, même une fois le son SoLoud lui-même arrêté.
    _background.stop();
    super.dispose();
  }

  Future<void> _selectTech(int i) async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getStringList('breath_sec_${kBreathTechs[i].key}');
    setState(() {
      _techIndex = i;
      _seconds = saved != null
          ? saved.map((e) => int.tryParse(e) ?? 4).toList()
          : List<int>.from(kBreathTechs[i].defaultSeconds);
    });
  }

  Future<void> _playPhaseAudio(BreathPhaseType type, int durationSeconds) async {
    if (!_soundOn) return;
    await _audio.startPhase(type: type, durationSeconds: durationSeconds);
  }

  Future<void> _start() async {
    _savePrefs();
    setState(() {
      _running = true;
      _cycle = 0;
      _phaseIndex = 0;
    });
    // Bug corrigé (14/08/2026, retour d'Alex : "la première inspire n'a
    // jamais de son") : `startSession()` n'était pas attendu — `_runPhase()`
    // (donc le tout premier `startPhase()`) s'exécutait quasi aussitôt,
    // souvent AVANT que `_sessionActive` ne passe à `true` dans
    // `startSession()` (lui-même `await _soloud.play(...)` en interne).
    // `startPhase()` voyait donc `_sessionActive == false` et abandonnait
    // silencieusement — seul le premier carillon était perdu, la nappe de
    // fond démarrant juste après restait, elle, audible (d'où le symptôme :
    // "j'entends l'ambiance mais jamais le premier gong").
    await _audio.startSession(enabled: _soundOn);
    _background.start();
    _runPhase();
  }

  void _stop() {
    _timer?.cancel();
    _anim.stop();
    _anim.value = 1.0;
    _audio.stopSession();
    _background.stop();
    setState(() => _running = false);
  }

  void _runPhase() {
    final dur = _seconds[_phaseIndex];
    final scale = _tech.scales[_phaseIndex];
    final type = _tech.soundKinds[_phaseIndex];
    // Priorité 53 (14/08/2026, retour d'Alex) : métronome doux pendant les
    // rétentions, en plus de la nappe de fond qui continue — un tic à
    // chaque seconde entière (au démarrage de la rétention, puis à chaque
    // frappe du minuteur), jamais sur les autres phases.
    final isHold = type == BreathPhaseType.holdFull || type == BreathPhaseType.holdEmpty;
    setState(() => _remaining = dur);
    _playPhaseAudio(type, dur);
    if (isHold && _soundOn) _audio.playTick();

    _anim.duration = Duration(seconds: dur);
    if (scale > _anim.value) {
      _anim.animateTo(scale,
          duration: Duration(seconds: dur), curve: Curves.easeInOut);
    } else if (scale < _anim.value) {
      _anim.animateBack(scale,
          duration: Duration(seconds: dur), curve: Curves.easeInOut);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (isHold && _soundOn && _remaining > 0) _audio.playTick();
      if (_remaining <= 0) {
        t.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    if (!_running) return;
    int next = _phaseIndex + 1;
    if (next >= _tech.phaseLabels.length) {
      next = 0;
      final c = _cycle + 1;
      if (c >= _cycles) {
        _finish();
        return;
      }
      setState(() => _cycle = c);
    }
    setState(() => _phaseIndex = next);
    _runPhase();
  }

  void _finish() {
    _timer?.cancel();
    _anim.animateBack(1.0, duration: const Duration(seconds: 2));
    _audio.stopSession();
    _background.stop();
    recordBreathSessionCompleted();
    setState(() => _running = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Séance terminée. Prends un instant pour ressentir.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  int get _totalMinutes {
    final perCycle = _seconds.fold<int>(0, (a, b) => a + b);
    return (perCycle * _cycles / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        title: const Text('Respiration'),
        backgroundColor: TotumColors.surface,
        foregroundColor: TotumColors.textPrimary,
        elevation: 0,
      ),
      body: _running ? _buildRunning() : _buildSetup(),
    );
  }

  Widget _buildRunning() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 220,
            width: 220,
            child: Center(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  return Container(
                    width: 90 * _anim.value,
                    height: 90 * _anim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _accent.withValues(alpha: 0.4),
                          _accent.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                          color: _accent.withValues(alpha: 0.55), width: 3),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(_tech.phaseLabels[_phaseIndex],
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: _accent)),
          const SizedBox(height: 4),
          Text('$_remaining',
              style: TextStyle(fontSize: 18, color: TotumColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Cycle ${_cycle + 1} / $_cycles',
              style: TextStyle(fontSize: 13, color: TotumColors.textMuted)),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: _stop,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('Arrêter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: const BorderSide(color: _accent),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetup() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Choix de la technique — liste scrollable (Priorité 43, retour
        // d'Alex) : une Row d'Expanded à largeur égale fonctionnait pour 2
        // techniques mais devient illisible dès 5, chaque chip s'écrasant.
        Builder(builder: (_) {
          final indices = _visibleTechIndices;
          final roundsTechs = _visibleRoundsTechs;
          return SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // + roundsTechs.length : tuile(s) "protocole avancé"
              // (hyperventilation cyclique) en fin de liste — rendu distinct,
              // ne passe jamais par _selectTech (flux durée/slider normal),
              // gate de sécurité + écran dédié via _openRoundsTech. Les deux
              // listes sont déjà filtrées/triées par objectif (voir
              // _visibleTechIndices/_visibleRoundsTechs) quand on arrive
              // depuis le parcours objectif.
              itemCount: indices.length + roundsTechs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, pos) {
                if (pos >= indices.length) {
                  final rt = roundsTechs[pos - indices.length];
                  return GestureDetector(
                    onTap: () => _openRoundsTech(context, rt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TotumColors.accentBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rt.name,
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                          const Text('Protocole avancé',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: TotumColors.accent)),
                        ],
                      ),
                    ),
                  );
                }
                final i = indices[pos];
                return GestureDetector(
                  onTap: () => _selectTech(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: i == _techIndex ? _accent : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: i == _techIndex ? _accent : TotumColors.outline),
                    ),
                    child: Text(
                      kBreathTechs[i].name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: i == _techIndex ? Colors.white : TotumColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 16),
        // Description + bénéfice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TotumColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tech.desc,
                  style: TextStyle(
                      fontSize: 13, height: 1.5, color: TotumColors.textPrimary)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite_outline,
                        size: 16, color: _accent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(_tech.benefit,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: TotumColors.textPrimary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Réglages des durées de phase
        const Text('Durée de chaque phase',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (int i = 0; i < _tech.phaseLabels.length; i++)
          _buildPhaseSlider(i),
        const SizedBox(height: 16),
        // Réglage du nombre de cycles
        Row(
          children: [
            Icon(Icons.repeat, size: 18, color: TotumColors.textSecondary),
            const SizedBox(width: 8),
            const Text('Nombre de cycles',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$_cycles',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: _accent)),
          ],
        ),
        Slider(
          value: _cycles.toDouble(),
          min: 3,
          max: 30,
          divisions: 27,
          activeColor: _accent,
          label: '$_cycles',
          onChanged: (v) => setState(() => _cycles = v.round()),
        ),
        // Durée totale estimée
        Center(
          child: Text('≈ $_totalMinutes min de séance',
              style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary)),
        ),
        const SizedBox(height: 12),
        // Son on/off
        SwitchListTile(
          value: _soundOn,
          onChanged: (v) => setState(() => _soundOn = v),
          activeThumbColor: _accent,
          contentPadding: EdgeInsets.zero,
          title: const Text('Sons de guidage',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          secondary: Icon(_soundOn ? Icons.volume_up : Icons.volume_off,
              color: _accent),
        ),
        const SizedBox(height: 16),
        // Bouton démarrer
        ElevatedButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow, size: 24),
          label: const Text('Commencer la séance'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseSlider(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(_tech.phaseLabels[i],
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Slider(
              value: _seconds[i].toDouble(),
              min: _tech.minSec.toDouble(),
              max: _tech.maxSec.toDouble(),
              divisions: _tech.maxSec - _tech.minSec,
              activeColor: _accent,
              label: '${_seconds[i]} s',
              onChanged: (v) => setState(() => _seconds[i] = v.round()),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text('${_seconds[i]}s',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

enum _RoundPhase { intro, rapidBreathing, holdRelease, recoveryHold, done }

/// Écran dédié à l'hyperventilation cyclique (Priorité 43) — voir le
/// commentaire sur [BreathRoundsTech] pour pourquoi ce n'est pas un
/// `BreathTech` de plus. Même cycle de vie moteur audio/arrière-plan que
/// `_RespirationScreenState` (son propre `BreathAudioEngine`+
/// `BreathBackgroundSession`), mais machine à états dédiée pour les rounds
/// hétérogènes.
class CyclicHyperventilationScreen extends StatefulWidget {
  final BreathRoundsTech tech;
  const CyclicHyperventilationScreen({super.key, required this.tech});

  @override
  State<CyclicHyperventilationScreen> createState() => _CyclicHyperventilationScreenState();
}

class _CyclicHyperventilationScreenState extends State<CyclicHyperventilationScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = TotumColors.accent;

  final BreathAudioEngine _audio = BreathAudioEngine();
  late final BreathBackgroundSession _background = BreathBackgroundSession(_audio);
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.tech.rapidBreathSeconds),
    lowerBound: 1.0,
    upperBound: 1.6,
  )..value = 1.0;

  _RoundPhase _phase = _RoundPhase.intro;
  int _totalRounds = 3;
  // Priorité 45 (retour d'Alex) : rétention réglable ROUND PAR ROUND, pas
  // une seule durée partagée — en pratique la tolérance au CO2 augmente
  // round après round, donc les gens veulent souvent une rétention plus
  // longue sur les derniers rounds. Liste indexée par round (0 = round 1),
  // toujours de taille >= _totalRounds (voir _ensureHoldSecondsSize).
  final List<int> _holdSecondsPerRound = [];
  int _round = 1;
  int _breathIndex = 0; // 0..rapidBreathsPerRound*2 (demi-cycles inspire/expire)
  int _holdRemainingSec = 0; // rétention : compte à rebours, aucune action requise
  int _recoveryRemainingSec = 0; // récupération : compte à rebours classique
  Timer? _timer;
  bool _soundOn = true;

  /// Étend/tronque `_holdSecondsPerRound` pour qu'il ait toujours au moins
  /// `_totalRounds` entrées — les nouvelles entrées reprennent la durée par
  /// défaut de la technique, les entrées déjà réglées par l'utilisateur ne
  /// sont jamais perdues si on redescend puis remonte le nombre de rounds.
  void _ensureHoldSecondsSize() {
    while (_holdSecondsPerRound.length < _totalRounds) {
      _holdSecondsPerRound.add(widget.tech.defaultHoldSeconds);
    }
  }

  /// Durée totale estimée — même principe que `_RespirationScreenState
  /// ._totalMinutes`, adapté au Wim Hof : respiration rapide (comptée en
  /// demi-cycles inspire/expire) + rétention RÉGLÉE PAR ROUND (pas une
  /// durée unique) + récupération fixe, sommées sur tous les rounds.
  int get _totalMinutes {
    final rapidSecondsPerRound = widget.tech.rapidBreathsPerRound * widget.tech.rapidBreathSeconds * 2;
    var totalSeconds = 0;
    for (int r = 0; r < _totalRounds; r++) {
      totalSeconds += rapidSecondsPerRound + _holdSecondsPerRound[r] + widget.tech.recoveryHoldSeconds;
    }
    return (totalSeconds / 60).round();
  }

  @override
  void initState() {
    super.initState();
    _totalRounds = widget.tech.defaultRounds;
    _ensureHoldSecondsSize();
    _audio.init();
    SharedPreferences.getInstance().then((sp) {
      if (!mounted) return;
      setState(() => _soundOn = sp.getBool('breath_sound') ?? true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    _audio.dispose();
    _background.stop();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _RoundPhase.rapidBreathing;
      _round = 1;
      _breathIndex = 0;
    });
    // Priorité 55 (retour d'Alex) : pas de nappe de fond pendant les
    // respirations rapides, seulement les carillons inspire/expire —
    // `startAmbient: false` garde la session active (carillons OK) sans
    // démarrer la nappe ; elle ne démarre qu'à l'entrée en rétention (voir
    // `_startHoldRelease()`), et s'arrête au retour en respiration rapide
    // (voir `_endRound()`).
    await _audio.startSession(enabled: _soundOn, startAmbient: false);
    await _background.start();
    _runRapidBreathing();
  }

  void _runRapidBreathing() {
    final tech = widget.tech;
    final totalHalfCycles = tech.rapidBreathsPerRound * 2;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: tech.rapidBreathSeconds), (t) {
      if (!mounted) return;
      final isInhale = _breathIndex.isEven;
      _audio.startPhase(
        type: isInhale ? BreathPhaseType.inhale : BreathPhaseType.exhale,
        durationSeconds: tech.rapidBreathSeconds,
        fast: true,
      );
      // Priorité 57 (14/08/2026, 3e retour d'Alex — retrait total de la
      // voix sur ce module) : le tic de métronome (déjà utilisé pour les
      // rétentions) sert désormais aussi de repère de rythme sur CHAQUE
      // inspire/expire de la respiration rapide, en plus du carillon.
      _audio.playTick();
      if (isInhale) {
        _anim.animateTo(1.6, duration: Duration(seconds: tech.rapidBreathSeconds));
      } else {
        _anim.animateBack(1.0, duration: Duration(seconds: tech.rapidBreathSeconds));
      }
      setState(() => _breathIndex++);
      if (_breathIndex >= totalHalfCycles) {
        t.cancel();
        _startHoldRelease();
      }
    });
    // Démarre tout de suite le tout premier demi-cycle (inspire) au lieu
    // d'attendre 1s avant le premier son/mouvement.
    _audio.startPhase(type: BreathPhaseType.inhale, durationSeconds: tech.rapidBreathSeconds, fast: true);
    _audio.playTick();
    _anim.animateTo(1.6, duration: Duration(seconds: tech.rapidBreathSeconds));
    setState(() => _breathIndex = 1);
  }

  /// Rétention poumons vides — retour d'Alex (13/08/2026) : la méthode
  /// originelle prévoit une tenue "aussi longtemps que confortable", mais un
  /// bouton à taper en pleine rétention est exactement le geste à éviter
  /// (utilisateur les yeux fermés, écran potentiellement verrouillé). Les
  /// vraies apps WHM de référence (dont l'appli officielle Wim Hof Method,
  /// et "Breathe Like Wim") résolvent ça avec un minuteur de rétention
  /// RÉGLABLE round par round (voir `_holdSecondsPerRound`, une ligne de
  /// stepper par round sur l'écran d'intro) plutôt qu'une tenue littéralement
  /// infinie — aucune interaction requise pendant la séance. Toujours pas de
  /// `startPhase` unique sur toute la durée : on relance un chunk
  /// `holdEmpty` de 5s en boucle (l'accumulateur de phase jamais réinitialisé
  /// garantit la continuité d'un chunk au suivant), simplement piloté par un
  /// compte à rebours au lieu d'un tap.
  void _startHoldRelease() {
    final totalHold = _holdSecondsPerRound[_round - 1];
    setState(() {
      _phase = _RoundPhase.holdRelease;
      _holdRemainingSec = totalHold;
    });
    _anim.animateBack(1.0, duration: const Duration(milliseconds: 400));
    // Priorité 55 (retour d'Alex) : la nappe de fond ne joue QUE pendant
    // les rétentions (celle-ci + la récupération qui suit) — coupée durant
    // les respirations rapides (voir `_start()`/`_endRound()`).
    _audio.startAmbient();
    // Priorité 57 (14/08/2026, 3e retour d'Alex — retrait total de la voix
    // sur ce module) : plus aucune parole nulle part, juste le tic de
    // métronome — une fois au tout début de la rétention...
    _audio.playTick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _phase != _RoundPhase.holdRelease) { t.cancel(); return; }
      setState(() => _holdRemainingSec--);
      // ...puis rejoué toutes les 30 secondes écoulées jusqu'à la fin de
      // la rétention (repère de temps purement sonore, plus de phrase
      // "Reste 30 secondes") — inconditionnel, quelle que soit la durée.
      final elapsed = totalHold - _holdRemainingSec;
      if (elapsed > 0 && elapsed % 30 == 0) {
        _audio.playTick();
      }
      if (_holdRemainingSec <= 0) {
        t.cancel();
        _startRecoveryHold();
      }
    });
  }

  void _startRecoveryHold() {
    final dur = widget.tech.recoveryHoldSeconds;
    setState(() {
      _phase = _RoundPhase.recoveryHold;
      _recoveryRemainingSec = dur;
    });
    _audio.startPhase(type: BreathPhaseType.holdFull, durationSeconds: dur);
    _anim.animateTo(1.4, duration: Duration(seconds: dur));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recoveryRemainingSec--);
      if (_recoveryRemainingSec <= 0) {
        t.cancel();
        _endRound();
      }
    });
  }

  void _endRound() {
    if (_round >= _totalRounds) {
      _finish();
      return;
    }
    // Retour en respiration rapide pour le round suivant : coupe la nappe
    // de fond (Priorité 55 — réservée aux rétentions).
    _audio.stopAmbient();
    setState(() {
      _round++;
      _breathIndex = 0;
      _phase = _RoundPhase.rapidBreathing;
    });
    _anim.value = 1.0;
    _runRapidBreathing();
  }

  Future<void> _finish() async {
    _timer?.cancel();
    await _audio.stopSession();
    await _background.stop();
    await recordBreathSessionCompleted();
    if (!mounted) return;
    setState(() => _phase = _RoundPhase.done);
  }

  Future<void> _exitEarly() async {
    _timer?.cancel();
    await _audio.stopSession();
    await _background.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        title: Text(widget.tech.name),
        backgroundColor: TotumColors.surface,
        foregroundColor: TotumColors.textPrimary,
        elevation: 0,
        leading: _phase == _RoundPhase.intro || _phase == _RoundPhase.done
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: _exitEarly),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _RoundPhase.intro:
        return _buildIntro();
      case _RoundPhase.rapidBreathing:
        return _buildRapidBreathing();
      case _RoundPhase.holdRelease:
        return _buildHoldRelease();
      case _RoundPhase.recoveryHold:
        return _buildRecoveryHold();
      case _RoundPhase.done:
        return _buildDone();
    }
  }

  Widget _buildIntro() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(widget.tech.desc,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: TotumColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.favorite_outline, size: 16, color: _accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(widget.tech.benefit,
                    style: TextStyle(fontSize: 12, height: 1.45, color: TotumColors.textPrimary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Nombre de rounds', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _totalRounds > widget.tech.minRounds
                  ? () => setState(() => _totalRounds--) // les durées déjà réglées restent en mémoire
                  : null,
            ),
            SizedBox(
              width: 50,
              child: Text('$_totalRounds', textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _totalRounds < widget.tech.maxRounds
                  ? () => setState(() {
                        _totalRounds++;
                        _ensureHoldSecondsSize();
                      })
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Durée de rétention par round', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Aucune action à faire pendant la séance — réglez chaque round à l\'avance selon votre expérience.',
            style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
        const SizedBox(height: 10),
        // Priorité 45 (retour d'Alex) : une durée de rétention réglable PAR
        // ROUND (pas une seule durée partagée) — en pratique la tolérance au
        // CO2 augmente round après round, donc la rétention visée aussi.
        for (int r = 0; r < _totalRounds; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text('Round ${r + 1}',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  onPressed: _holdSecondsPerRound[r] > widget.tech.minHoldSeconds
                      ? () => setState(() => _holdSecondsPerRound[r] -= 15)
                      : null,
                ),
                SizedBox(
                  width: 46,
                  child: Text('${_holdSecondsPerRound[r]}s', textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  onPressed: _holdSecondsPerRound[r] < widget.tech.maxHoldSeconds
                      ? () => setState(() => _holdSecondsPerRound[r] += 15)
                      : null,
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Durée totale estimée — même repère que les techniques classiques
        // (Priorité 58, retour d'Alex : "précise le temps que cela prendra,
        // comme pour les autres respirations").
        Center(
          child: Text('≈ $_totalMinutes min de séance',
              style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _start,
            child: const Text('Commencer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _roundLabel() => Text('Round $_round / $_totalRounds',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textSecondary));

  Widget _buildRapidBreathing() {
    final total = widget.tech.rapidBreathsPerRound;
    final current = (_breathIndex / 2).ceil().clamp(0, total);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roundLabel(),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 160 * _anim.value / 1.6,
              height: 160 * _anim.value / 1.6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withValues(alpha: 0.18)),
              alignment: Alignment.center,
              child: Container(
                width: 90, height: 90,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('$current / $total', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Respirations amples et rapides', style: TextStyle(color: TotumColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildHoldRelease() {
    // Pas de bouton ici (retour d'Alex) : compte à rebours automatique,
    // aucune action requise — voir le commentaire sur _startHoldRelease.
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roundLabel(),
          const SizedBox(height: 20),
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withValues(alpha: 0.12),
                border: Border.all(color: _accent, width: 2)),
            alignment: Alignment.center,
            child: Text('$_holdRemainingSec',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 14),
          Text('Retenez, poumons vides',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Fermez les yeux, laissez-vous guider par le son',
              textAlign: TextAlign.center,
              style: TextStyle(color: TotumColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRecoveryHold() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roundLabel(),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 160 * _anim.value / 1.6,
              height: 160 * _anim.value / 1.6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withValues(alpha: 0.18)),
              alignment: Alignment.center,
              child: Text('$_recoveryRemainingSec',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 10),
          Text('Inspirez et retenez — récupération',
              style: TextStyle(color: TotumColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 56, color: _accent),
            const SizedBox(height: 14),
            const Text('Séance terminée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('$_totalRounds round${_totalRounds > 1 ? 's' : ''} complété${_totalRounds > 1 ? 's' : ''}. Prends un instant pour ressentir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TotumColors.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Porte de sécurité obligatoire avant la 1re utilisation d'une technique à
/// rounds (hyperventilation cyclique) — pas une simple ligne de texte
/// discrète : case à cocher qui débloque le bouton, dialog non-dismissable
/// en tapant à côté. Persisté une seule fois (SharedPreferences), même
/// idiome que `_loadPrefs()`/`_savePrefs()` ailleurs dans ce fichier.
Future<void> _openRoundsTech(BuildContext context, BreathRoundsTech tech) async {
  final sp = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  final acknowledged = sp.getBool('breath_hyperv_ack_v1') ?? false;
  if (!acknowledged) {
    bool checked = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Avant de commencer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tech.safetyWarning, style: const TextStyle(fontSize: 13, height: 1.5)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (v) => setDlg(() => checked = v ?? false),
                    ),
                    const Expanded(
                      child: Text('J\'ai lu et je comprends ces précautions',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: checked ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await sp.setBool('breath_hyperv_ack_v1', true);
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CyclicHyperventilationScreen(tech: tech)),
  );
}

/// Page dédiée : le rituel du soir, organisé en piliers du sommeil.
/// Chaque action est cochable et accompagnée de son "pourquoi" physiologique.
class RituelSoirScreen extends StatefulWidget {
  const RituelSoirScreen({super.key});

  @override
  State<RituelSoirScreen> createState() => _RituelSoirScreenState();
}

class _SleepAction {
  final String action;
  final String why;
  const _SleepAction(this.action, this.why);
}

class _SleepPillar {
  final String title;
  final IconData icon;
  final String intro;
  final List<_SleepAction> actions;
  const _SleepPillar(this.title, this.icon, this.intro, this.actions);
}

class _RituelSoirScreenState extends State<RituelSoirScreen> {
  static const _accent = TotumColors.accent;

  static const _pillars = <_SleepPillar>[
    _SleepPillar(
      'La lumière',
      Icons.wb_sunny_outlined,
      'La lumière est le principal régulateur de ton horloge biologique. Bien gérée, elle cale ton sommeil naturellement.',
      [
        _SleepAction(
          'Vois la lumière du jour dès le réveil',
          '10 à 30 minutes de lumière naturelle le matin calent ton horloge interne et déclenchent, 14 à 16 h plus tard, la sécrétion de mélatonine du soir. C\'est le geste le plus puissant pour bien dormir — et il se fait le matin.',
        ),
        _SleepAction(
          'Baisse les lumières 1 à 2 h avant le coucher',
          'Une lumière vive le soir fait croire à ton cerveau qu\'il fait encore jour et bloque la mélatonine. Passe en éclairage tamisé, chaud, indirect.',
        ),
        _SleepAction(
          'Coupe les écrans ou filtre la lumière bleue',
          'La lumière bleue des écrans est celle qui supprime le plus la mélatonine. Mode nuit, lunettes anti-lumière bleue, ou mieux : pose l\'écran.',
        ),
        _SleepAction(
          'Dors dans l\'obscurité totale',
          'La moindre source lumineuse, même une veilleuse ou une LED de chargeur, perçue à travers les paupières, réduit la qualité du sommeil profond. Rideaux occultants ou masque.',
        ),
      ],
    ),
    _SleepPillar(
      'La température',
      Icons.thermostat,
      'S\'endormir exige que la température de ton corps baisse d\'environ 1 °C. Tout ce qui favorise ce refroidissement aide à dormir.',
      [
        _SleepAction(
          'Garde ta chambre autour de 18 °C',
          'Une chambre fraîche facilite la baisse de température corporelle nécessaire à l\'endormissement. Trop chaude, elle est l\'une des causes les plus fréquentes de réveils nocturnes.',
        ),
        _SleepAction(
          'Prends une douche tiède 1 à 2 h avant',
          'Paradoxalement, une douche tiède dilate les vaisseaux et aide le corps à évacuer sa chaleur ensuite : la température chute plus vite, et l\'endormissement suit.',
        ),
        _SleepAction(
          'Garde les extrémités au chaud',
          'Des pieds froids resserrent les vaisseaux et empêchent le corps d\'évacuer sa chaleur centrale. Des chaussettes peuvent, contre l\'intuition, aider à s\'endormir plus vite.',
        ),
      ],
    ),
    _SleepPillar(
      'Stimulants & alimentation',
      Icons.no_food,
      'Ce que tu consommes dans la seconde partie de journée pèse lourd sur ta nuit.',
      [
        _SleepAction(
          'Dernière caféine 6 à 8 h avant le coucher',
          'La caféine bloque l\'adénosine, la molécule qui te rend somnolent, pendant 6 h et plus. Un café de milieu d\'après-midi ampute le sommeil profond sans même t\'empêcher de t\'endormir. Pense aussi au thé, au maté, au chocolat noir.',
        ),
        _SleepAction(
          'Dîne léger et tôt, 3 h avant',
          'Une digestion en cours élève la température du corps et mobilise l\'organisme, à l\'opposé de ce que demande le sommeil. Un dîner léger et précoce améliore nettement la profondeur de la nuit.',
        ),
        _SleepAction(
          'Modère les liquides en soirée',
          'Trop boire juste avant de dormir multiplie les réveils nocturnes pour aller aux toilettes, qui fragmentent les cycles. Hydrate-toi surtout en journée.',
        ),
        _SleepAction(
          'Mise sur les aliments favorables au sommeil',
          'Certains aliments bruts apportent du tryptophane, du magnésium et de la glycine, précurseurs de la mélatonine et de la sérotonine : amandes, noix, banane, flocons d\'avoine, kiwi, poisson gras.',
        ),
      ],
    ),
    _SleepPillar(
      'Mental & stress',
      Icons.self_improvement,
      'Un mental agité est la cause n°1 des difficultés d\'endormissement. L\'apaiser est un entraînement.',
      [
        _SleepAction(
          'Fais une décharge mentale',
          'Note sur papier ce qui t\'préoccupe et tes tâches du lendemain. Sortir les pensées de ta tête pour les poser ailleurs réduit la rumination qui tourne en boucle au coucher.',
        ),
        _SleepAction(
          'Pratique quelques minutes de cohérence cardiaque',
          'Ralentir le souffle active le système parasympathique, celui du repos. Quelques cycles de respiration lente préparent physiologiquement le corps au sommeil.',
        ),
        _SleepAction(
          'Termine sur trois gratitudes',
          'Repenser à trois moments positifs de la journée oriente le mental vers le calme plutôt que vers l\'anxiété, et facilite un endormissement serein.',
        ),
        _SleepAction(
          'Évite les contenus anxiogènes le soir',
          'Actualités, mails de travail, débats en ligne activent le système de vigilance juste avant de dormir. Réserve la soirée à ce qui apaise.',
        ),
      ],
    ),
    _SleepPillar(
      'Rythme & régularité',
      Icons.schedule,
      'Le sommeil aime la régularité plus que tout. Un rythme stable vaut mieux qu\'une longue grasse matinée de rattrapage.',
      [
        _SleepAction(
          'Couche-toi et lève-toi à heures régulières',
          'Des horaires constants, même le week-end, renforcent ton horloge biologique. C\'est la régularité, plus que la durée seule, qui détermine la qualité du sommeil.',
        ),
        _SleepAction(
          'Respecte tes cycles de 90 minutes',
          'Le sommeil se déroule par cycles d\'environ 90 min. Se réveiller en fin de cycle, plutôt qu\'en plein sommeil profond, rend le réveil bien plus facile.',
        ),
        _SleepAction(
          'Couche-toi dès les premiers signes',
          'Bâillements, paupières lourdes, yeux qui piquent : c\'est ton train du sommeil qui passe. Le rater, c\'est attendre le prochain cycle 90 min plus tard.',
        ),
        _SleepAction(
          'Gère tes siestes',
          'Une sieste de 10 à 20 min en début d\'après-midi récupère sans empiéter sur la nuit. Trop longue ou trop tardive, elle sabote l\'endormissement du soir.',
        ),
      ],
    ),
    _SleepPillar(
      'L\'environnement',
      Icons.bedroom_parent_outlined,
      'Ta chambre doit devenir un sanctuaire que ton cerveau associe uniquement au repos.',
      [
        _SleepAction(
          'Réserve le lit au sommeil',
          'Travailler, manger ou scroller au lit brouille l\'association mentale lit = sommeil. Ton cerveau doit apprendre qu\'entrer dans le lit signifie dormir.',
        ),
        _SleepAction(
          'Chasse le bruit',
          'Même sans te réveiller, un bruit perturbe la profondeur du sommeil. Bouchons d\'oreilles ou bruit blanc régulier peuvent masquer les nuisances imprévisibles.',
        ),
        _SleepAction(
          'Soigne ta literie',
          'Un matelas et un oreiller adaptés évitent les micro-réveils liés à l\'inconfort. On y passe un tiers de sa vie : c\'est un investissement santé.',
        ),
      ],
    ),
  ];

  final Set<String> _done = {};

  int get _totalActions =>
      _pillars.fold(0, (a, p) => a + p.actions.length);

  @override
  Widget build(BuildContext context) {
    final progress = _totalActions > 0 ? _done.length / _totalActions : 0.0;
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        title: const Text('Rituel du soir'),
        backgroundColor: TotumColors.surface,
        foregroundColor: TotumColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Intro + progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  _accent.withValues(alpha: 0.10),
                  _accent.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un sommeil de qualité n\'est pas une chance, c\'est le résultat de bonnes habitudes. Voici les leviers qui comptent vraiment — coche ceux que tu mets en place.',
                  style: TextStyle(
                      fontSize: 13, height: 1.5, color: TotumColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: _accent.withValues(alpha: 0.12),
                          color: _accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${_done.length}/$_totalActions',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _accent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Les 6 leviers de ton sommeil',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Appuie sur un levier pour voir les gestes et cocher ceux que tu mets en place.',
              style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary, height: 1.4)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: _pillars.length,
            itemBuilder: (context, p) => _buildPillarCard(_pillars[p]),
          ),
        ],
      ),
    );
  }

  /// Compte les actions cochées pour un pilier donné.
  int _doneCountFor(_SleepPillar pillar) {
    int n = 0;
    for (int i = 0; i < pillar.actions.length; i++) {
      if (_done.contains('${pillar.title}#$i')) n++;
    }
    return n;
  }

  /// Vignette-tip d'un levier dans la cartographie.
  Widget _buildPillarCard(_SleepPillar pillar) {
    final done = _doneCountFor(pillar);
    final total = pillar.actions.length;
    final complete = done == total && total > 0;
    return GestureDetector(
      onTap: () => _openPillarSheet(pillar),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: complete ? _accent.withValues(alpha: 0.5) : TotumColors.outline,
            width: complete ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(pillar.icon, size: 22, color: _accent),
                ),
                const Spacer(),
                if (complete)
                  const Icon(Icons.check_circle, size: 20, color: _accent)
                else
                  Text('$done/$total',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: TotumColors.textMuted)),
              ],
            ),
            const Spacer(),
            Text(pillar.title,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w900, height: 1.2)),
            const SizedBox(height: 4),
            Text(
              pillar.intro,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11, height: 1.35, color: TotumColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre le détail d'un levier (ses gestes) dans une feuille modale.
  void _openPillarSheet(_SleepPillar pillar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TotumColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TotumColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(pillar.icon, size: 24, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(pillar.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(pillar.intro,
                  style: TextStyle(
                      fontSize: 13, height: 1.5, color: TotumColors.textSecondary)),
              const SizedBox(height: 16),
              for (int i = 0; i < pillar.actions.length; i++) ...[
                _buildActionSheet(pillar.title, i, pillar.actions[i],
                    setSheetState),
                if (i < pillar.actions.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Une action cochable, version feuille (met à jour la feuille ET l'écran).
  Widget _buildActionSheet(
      String pillarKey, int i, _SleepAction action, StateSetter setSheetState) {
    final id = '$pillarKey#$i';
    final done = _done.contains(id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (done) {
            _done.remove(id);
          } else {
            _done.add(id);
          }
        });
        setSheetState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: done ? _accent.withValues(alpha: 0.05) : TotumColors.page,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done ? _accent.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: done ? _accent : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: done ? _accent : TotumColors.outlineStrong, width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.action,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          color: done ? TotumColors.textMuted : TotumColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(action.why,
                      style: TextStyle(
                          fontSize: 12.5, height: 1.45, color: TotumColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Page dédiée « Tes conseils du jour » — ouverte depuis la vignette coach.
/// Regroupe tous les conseils enrichis + le défi du jour.
class ConseilsDuJourScreen extends StatelessWidget {
  final AdviceScript data;
  const ConseilsDuJourScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        title: const Text('Tes conseils du jour'),
        backgroundColor: TotumColors.surface,
        foregroundColor: TotumColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [TotumColors.accent, TotumProgress.stop75],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_stories, color: Colors.white, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tes conseils personnalisés, choisis selon ta journée et tes objectifs.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (data.advNutrition != null) ...[
            _AdviceTile(
              icon: Icons.restaurant_menu,
              color: TotumColors.accent,
              title: data.advNutrition!.titre,
              body: data.advNutrition!.body,
              accentLabel: data.advNutrition!.tag,
            ),
            const SizedBox(height: 12),
          ],
          if (data.advMouvement != null) ...[
            _AdviceTile(
              icon: Icons.directions_run,
              color: TotumColors.accent,
              title: data.advMouvement!.titre,
              body: data.advMouvement!.body,
              accentLabel: data.advMouvement!.tag,
            ),
            const SizedBox(height: 12),
          ],
          if (data.advSommeil != null) ...[
            _AdviceTile(
              icon: Icons.nightlight_round,
              color: TotumColors.accent,
              title: data.advSommeil!.titre,
              body: data.advSommeil!.body,
              accentLabel: data.advSommeil!.tag,
            ),
            const SizedBox(height: 12),
          ],
          if (data.advStress != null) ...[
            _AdviceTile(
              icon: Icons.air,
              color: TotumColors.accent,
              title: data.advStress!.titre,
              body: data.advStress!.body,
              accentLabel: data.advStress!.tag,
            ),
            const SizedBox(height: 12),
          ],
          if (data.advMindset != null) ...[
            _AdviceTile(
              icon: Icons.self_improvement,
              color: TotumColors.accent,
              title: data.advMindset!.titre,
              body: data.advMindset!.body,
              accentLabel: data.advMindset!.tag,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          _ChallengeCard(data: data),
          const SizedBox(height: 18),
          Text(
            'Ces conseils ne remplacent pas un avis médical. En cas de pathologie ou de doute, rapprochez-vous de votre professionnel de santé.',
            style: TextStyle(fontSize: 11, color: TotumColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AdviceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String accentLabel;
  const _AdviceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.accentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(accentLabel,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body,
                    style: TextStyle(
                        fontSize: 13, color: TotumColors.textPrimary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte "Défi du jour".
class _ChallengeCard extends StatelessWidget {
  final AdviceScript data;
  const _ChallengeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.defi24h.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TotumColors.accent.withValues(alpha: 0.10),
            TotumColors.accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TotumColors.accentBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TotumColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events,
                color: TotumColors.accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ton défi du jour',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TotumColors.accent)),
                const SizedBox(height: 4),
                Text(data.defi24h,
                    style: TextStyle(
                        fontSize: 13, color: TotumColors.textPrimary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: TotumColors.surface,
      borderRadius: BorderRadius.circular(TotumRadius.card),
      border: Border.all(color: TotumColors.outline),
    );

class _AnimatedAppear extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedAppear({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}