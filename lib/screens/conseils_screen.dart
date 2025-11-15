// lib/screens/conseils_screen.dart
// TOTUM – Onglet CONSEILS (chargement contenu depuis assets/advices.json)
// - Garde la forme/ordre/visuel existants
// - Ajoute grosse rotation (HÉRO, mindset, coach, recettes) via JSON externe
// - Anti-répétition + rotation 6x/jour
// - Fallback interne si l’asset est absent/corrompu
//
// Dépendances: flutter (SDK), shared_preferences (déjà), services (rootBundle)
// Aucune autre dépendance.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/foods_loader.dart' as foods_loader;
import 'account_screen.dart';

// === THEME =========================================================
const Color kTotumOrange = Color(0xFFFF7A00);
Color _accent(BuildContext _) => kTotumOrange; // unique, pas de doublon

// === MODELES =======================================================
class AdviceScript {
  final String cardTitle;
  final String focusTheme;
  final String scienceInsight;

  final String deficitCritique;
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

  final List<foods_loader.FoodItem> allFoods = [
    ...(repo.items as List),
    ...repo.customs,
  ];
  foods_loader.FoodItem? findFood(String id) {
    for (final f in allFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

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
  SharedPreferences sp,
) async {
  await _ensureFoodsLoadedForAdvice();
  final now = DateTime.now();
  final dayTotals = await _computeDayTotalsForAdviceDate(now, sp);
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

_AdviceTargets _buildAdviceTargets(_AdviceGoalsRaw goals) {
  final goalKcal = goals.kcal <= 0 ? 2000.0 : goals.kcal;
  final goalProt = goals.prot <= 0 ? 120.0 : goals.prot;
  final goalCarb = (goalKcal * 0.55) / 4.0;
  final goalFat = (goalKcal * 0.35) / 9.0;
  const goalFiber = 30.0;

  const goalO9 = 15.0,
      goalLA = 10.0,
      goalALA = 2.0,
      goalEPA = 0.25,
      goalDHA = 0.25;
  final isF = goals.sex == 'female';

  final vitTargets = <String, double>{
    'Vit A': isF ? 650 : 750,
    'Vit D': 15,
    'Vit E': isF ? 9 : 10,
    'Vit K': 79,
    'Vit C': 110,
    'B1': 1.6,
    'B2': 1.6,
    'B3': 10,
    'B5': isF ? 5 : 6,
    'B6': isF ? 1.6 : 1.7,
    'B9': 330,
    'B12': 2.5,
  };
  final minTargets = <String, double>{
    'Calcium': 950,
    'Cuivre': isF ? 1.5 : 1.9,
    'Fer': 11,
    'Iode': 150,
    'Magnésium': isF ? 300 : 380,
    'Manganèse': 8,
    'Phosphore': 550,
    'Potassium': 3500,
    'Sélénium': 70,
    'Sodium': 1500,
    'Zinc': isF ? 11 : 14,
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
  final double vitK = m('Vitamine_K1_µg_100g');
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

  final ratios = <String, double>{
    'omega9': o9 / 15.0,
    'omega6': la / 10.0,
    'omega3_ALA': ala / 2.0,
    'omega3': (epa + dha) / (0.25 + 0.25),
    'EPA': epa / 0.25,
    'DHA': dha / 0.25,
    'vitA': vitA / 700.0,
    'vitD': vitD / 15.0,
    'vitE': vitE / 10.0,
    'vitK': vitK / 79.0,
    'vitC': vitC / 110.0,
    'B1': b1 / 1.6,
    'B2': b2 / 1.6,
    'B3': b3 / 10.0,
    'B5': b5 / 6.0,
    'B6': b6 / 1.7,
    'B9': b9 / 330.0,
    'B12': b12 / 2.5,
    'calcium': calcium / 950.0,
    'copper': copper / 1.8,
    'iron': iron / 11.0,
    'iodine': iodine / 150.0,
    'magnesium': magnesium / 360.0,
    'manganese': manganese / 8.0,
    'phosphorus': phosphorus / 550.0,
    'potassium': potassium / 3500.0,
    'selenium': selenium / 70.0,
    'sodium': sodium / 1500.0,
    'zinc': zinc / 12.5,
    'fibers': fibers / 30.0,
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
      return 'Sélénium : $ptxt → 1–2 noix du Brésil, poisson.';
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
  ].contains(topic)) topicKey = 'Bgroup';

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
Future<AdviceScript> _buildAdviceScript() async {
  final now = DateTime.now();
  final sp = await SharedPreferences.getInstance();

  // charge l’asset au premier appel (idempotent)
  if (!AdviceContentRepo.instance.isLoaded) {
    await AdviceContentRepo.instance
        .loadFromAsset('assets/advices.json');
  }

  final goals = await _readGoalsForAdvice();
  final targets = _buildAdviceTargets(goals);
  final day = await _computeDayTotalsForAdviceDate(now, sp);
  final hyd = await _computeHydrationForAdviceToday(goals, sp);
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
          '1–2 noix du Brésil/j + poisson/œufs.';
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

  final hydrationPacks = [
    '1️⃣ Objectif simple : 1 verre au lever, 1 verre à chaque repas, 1 verre milieu d’après-midi.',
    '2️⃣ Utiliser une gourde visible, remplie en début de matinée et début d’après-midi.',
    '3️⃣ Ajouter tisane (verveine, tilleul, mélisse…) le soir pour cumuler hydratation + détente.',
    '4️⃣ Aromatiser l’eau avec citron, rondelles de fruits ou feuilles de menthe pour donner envie de boire.',
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
          'Sommeil court (~${sleep.toStringAsFixed(1)} h) + stress élevé (${stress}/10). Le système nerveux tire fort sur les réserves.';
      var pool = [...lowSleepHighStressPacks];
      // si hydratation basse on injecte aussi un rappel eau
      if (hydR < 0.7) pool.addAll(hydrationPacks);
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
      var pool = [...lowSleepPacks];
      if (hydR < 0.7) {
        pool.add('Bonus hydratation : vise ${(hyd.targetMl / 1000).toStringAsFixed(1)} L répartis sur la journée, pas en “one shot” le soir.');
      }
      actionLifestyle = _pickRotating<String>(
        pool,
        slot: slot,
        avoid: packHist,
      );
    }
    // Stress élevé mais sommeil correct
    else if (stress >= 7) {
      chronoAnalyse =
          'Sommeil convenable (~${sleep.toStringAsFixed(1)} h) mais stress élevé (${stress}/10). Le mental tourne vite.';
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
          'Sommeil et niveau de stress plutôt stables (≈${sleep.toStringAsFixed(1)} h, stress ${stress}/10). On peut jouer le “fine tuning” vitalité.';
      var pool = [...stableTerrainPacks];
      if (hydR < 0.7) pool.addAll(hydrationPacks);
      actionLifestyle = _pickRotating<String>(
        pool,
        slot: slot,
        avoid: packHist,
      );
    }
  } else if (hydR < 0.7) {
    // Pas (encore) de données sommeil/stress mais hydratation clairement basse
    chronoAnalyse =
        'Hydratation sous la cible : glycémie, maux de tête ou fatigue peuvent être amplifiés.';
    actionLifestyle = _pickRotating<String>(
      hydrationPacks,
      slot: slot,
      avoid: packHist,
    );
  } else {
    // Données partielles : on motive à compléter l’auto-suivi
    chronoAnalyse =
        'Données holistiques partielles : plus tu renseignes sommeil, eau et stress, plus les conseils deviennent chirurgicaux.';
    actionLifestyle =
        'Pendant 3 jours, note chaque matin : heures de sommeil, litres d’eau de la veille, stress moyen (1–10) et énergie au réveil. TOTUM ajustera progressivement les leviers proposés.';
  }

  await _pushHistory(sp, _packHistoryKey, actionLifestyle, keep: 6);

  // Macros
  String macroSummaryTitle, macroSummaryBody;
  String _pct(double r) => '${(r * 100).round()} %';
  final eR = decision.energyRatio;
  final pR = decision.proteinRatio;

  if (goalIdx == 0) {
    macroSummaryTitle = '⚖️ Perte de poids intelligente';
    if (eR > 1.1) {
      macroSummaryBody =
          'Apport ~${_pct(eR)} : vise un déficit léger (-10 à -20 %) durable.';
    } else if (eR < 0.8) {
      macroSummaryBody =
          'Apport ~${_pct(eR)} : si fatigue/fringales, remonte avec aliments bruts.';
    } else {
      macroSummaryBody =
          'Énergie ~${_pct(eR)} : trajectoire cohérente. Qualité & fibres = priorité.';
    }
    if (pR < 0.9) {
      macroSummaryBody +=
          ' • Protéines ~${_pct(pR)} : une source à chaque repas.';
    } else if (pR > 1.2 && isSportif) {
      macroSummaryBody +=
          ' • Protéines généreuses ~${_pct(pR)} : répartis sur 3–4 prises.';
    }
  } else if (goalIdx >= 2) {
    macroSummaryTitle = '🏗️ Construction musculaire';
    if (eR < 0.9) {
      macroSummaryBody =
          'Calories ~${_pct(eR)} : surplus +10–15 % conseillé.';
    } else if (eR > 1.2) {
      macroSummaryBody =
          'Surplus ~${_pct(eR)} : ramène vers +10–15 % pour limiter la prise de gras.';
    } else {
      macroSummaryBody =
          'Niveau ~${_pct(eR)} : OK. Timing glucides autour séances = clé.';
    }
    if (pR < 1.0) {
      macroSummaryBody +=
          ' • Protéines ~${_pct(pR)} : 1.6–2.2 g/kg/j sur 3–4 repas.';
    } else {
      macroSummaryBody +=
          ' • Couverture protéique ~${_pct(pR)}.';
    }
  } else {
    macroSummaryTitle = '⚙️ Maintien du poids de forme';
    if (eR < 0.9) {
      macroSummaryBody =
          'Énergie ~${_pct(eR)} : un peu basse. Remonte légèrement si fatigue.';
    } else if (eR > 1.1) {
      macroSummaryBody =
          'Énergie ~${_pct(eR)} : un peu haute. Ajuste extras & boissons.';
    } else {
      macroSummaryBody =
          'Énergie ~${_pct(eR)} : alignée. Joue la qualité pour digestion/sommeil.';
    }
    if (pR < 0.9) {
      macroSummaryBody +=
          ' • Protéines ~${_pct(pR)} : garde un socle suffisant.';
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

  return AdviceScript(
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

// === UI (forme/ordre + icône compte) ==============================
class ConseilsScreen extends StatefulWidget {
  const ConseilsScreen({super.key});

  @override
  State<ConseilsScreen> createState() => _ConseilsScreenState();
}

class _ConseilsScreenState extends State<ConseilsScreen> {
  late Future<AdviceScript> _future;
  final TextEditingController _sleepCtrl = TextEditingController();
  final TextEditingController _waterCtrl = TextEditingController();
  final TextEditingController _stressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _initAndLoad();
  }

  Future<AdviceScript> _initAndLoad() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hol = await _readHolisticLog(sp, now);
    if (hol.sleepHours != null) {
      _sleepCtrl.text = hol.sleepHours!.toStringAsFixed(1);
    }
    if (hol.waterLiters != null) {
      _waterCtrl.text = hol.waterLiters!.toStringAsFixed(1);
    }
    if (hol.stress != null) {
      _stressCtrl.text = hol.stress!.toString();
    }
    return _buildAdviceScript();
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
    waterLiters: d(_waterCtrl.text),
    stress: i(_stressCtrl.text),
  );

  // ✅ Important : on utilise EXACTEMENT le même pipeline
  // que lors de l'ouverture de l'écran → _initAndLoad(),
  // pas seulement _buildAdviceScript().
  setState(() {
    _future = _initAndLoad();
  });
}

  @override
  void dispose() {
    _sleepCtrl.dispose();
    _waterCtrl.dispose();
    _stressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conseils'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon compte',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<AdviceScript>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: Text('Aucun conseil disponible.'),
            );
          }
          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = _buildAdviceScript()),
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _AnimatedAppear(
                  index: 0,
                  child: _HeroCard(data: data),
                ),
                const SizedBox(height: 14),
                _AnimatedAppear(
                  index: 1,
                  child: _LaboCard(data: data),
                ),
                const SizedBox(height: 14),
                _AnimatedAppear(
                  index: 2,
                  child: _HolisticCard(data: data),
                ),
                const SizedBox(height: 14),
                _AnimatedAppear(
                  index: 3,
                  child: _SaisieActiveCard(
                    data: data,
                    sleepCtrl: _sleepCtrl,
                    waterCtrl: _waterCtrl,
                    stressCtrl: _stressCtrl,
                    onSave: _saveHolisticAndRefresh,
                  ),
                ),
                const SizedBox(height: 14),
                _AnimatedAppear(
                  index: 4,
                  child: _MindsetCard(data: data),
                ),
                const SizedBox(height: 14),
                _AnimatedAppear(
                  index: 5,
                  child: _ActivityCoachCard(data: data),
                ),
                const SizedBox(height: 14),
                _AnimatedAppear(
                  index: 6,
                  child: _MacroCard(data: data),
                ),
                const SizedBox(height: 14),
                _AnimatedAppear(
                  index: 7,
                  child:
                      _MotivationCard(data: data, accent: accent),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ces conseils ne remplacent pas un avis médical. En cas de pathologie ou de doute, rapprochez-vous de votre professionnel de santé.',
                  style:
                      TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// === Cartes UI =====================================================
class _HeroCard extends StatelessWidget {
  final AdviceScript data;
  const _HeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.95),
            accent.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.cardTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.focusTheme,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.scienceInsight,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LaboCard extends StatelessWidget {
  final AdviceScript data;
  const _LaboCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.biotech_rounded, color: accent),
                const SizedBox(width: 8),
                const Text(
                  'Labo micro-nutriments',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _BulletLine(
              label: 'Déficit critique',
              value: data.deficitCritique,
            ),
            const SizedBox(height: 6),
            _BulletLine(
              label: 'Pourquoi c’est clé',
              value: data.beneficeAssocie,
            ),
            const SizedBox(height: 6),
            _BulletLine(
              label: 'Source premium',
              value: data.sourcePremium,
            ),
            const SizedBox(height: 6),
            _BulletLine(
              label: 'Astuce absorption',
              value: data.astuceAbsorption,
            ),
            if (data.extraMicronutrientHints.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'À surveiller aussi :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              for (final h in data.extraMicronutrientHints)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          h,
                          style:
                              const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (data.recipeIdeas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded,
                      color: accent),
                  const SizedBox(width: 8),
                  const Text(
                    'Idées recettes ciblées',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final r in data.recipeIdeas)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r,
                          style:
                              const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HolisticCard extends StatelessWidget {
  final AdviceScript data;
  const _HolisticCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight_round, color: accent),
                const SizedBox(width: 8),
                const Text(
                  'Alignement holistique',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.sleepHours != null ||
                data.stressLevel != null)
              Row(
                children: [
                  if (data.sleepHours != null) ...[
                    const Icon(Icons.hotel,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      '${data.sleepHours!.toStringAsFixed(1)} h',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (data.stressLevel != null) ...[
                    const Icon(Icons.graphic_eq,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'Stress ${data.stressLevel}/10',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            if (data.sleepHours != null ||
                data.stressLevel != null)
              const SizedBox(height: 6),
            Text(
              data.chronoAnalyse,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.actionLifestyle,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaisieActiveCard extends StatelessWidget {
  final AdviceScript data;
  final TextEditingController sleepCtrl;
  final TextEditingController waterCtrl;
  final TextEditingController stressCtrl;
  final Future<void> Function() onSave;

  const _SaisieActiveCard({
    required this.data,
    required this.sleepCtrl,
    required this.waterCtrl,
    required this.stressCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.logTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ces 3 infos relient sensations ↔ journal pour des conseils plus fins.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            _LabeledTextField(
              label: data.logFields[0],
              controller: sleepCtrl,
              suffixText: 'h',
            ),
            const SizedBox(height: 8),
            _LabeledTextField(
              label: data.logFields[1],
              controller: waterCtrl,
              suffixText: 'L',
            ),
            const SizedBox(height: 8),
            _LabeledTextField(
              label: data.logFields[2],
              controller: stressCtrl,
              suffixText: '/10',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => onSave(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text('Mettre à jour les conseils'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MindsetCard extends StatelessWidget {
  final AdviceScript data;
  const _MindsetCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_rounded, color: accent),
                const SizedBox(width: 8),
                const Text(
                  'Esprit & motivation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.mindsetTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.mindsetBody,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCoachCard extends StatelessWidget {
  final AdviceScript data;
  const _ActivityCoachCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center_rounded, color: accent),
                const SizedBox(width: 8),
                const Text(
                  'Coach activité & récupération',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.activityCoachTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.activityCoachBody,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final AdviceScript data;
  const _MacroCard({required this.data});

  String _percent(double? ratio) {
    if (ratio == null || !ratio.isFinite) return '--';
    return '${(ratio * 100).round()} %';
  }

  double _val(double? r) {
    if (r == null || !r.isFinite) return 0.0;
    final v = r;
    if (v < 0) return 0.0;
    if (v > 1.5) return 1.5;
    return v / 1.5;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded, color: accent),
                const SizedBox(width: 8),
                const Text(
                  'Énergie & protéines',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.macroSummaryTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.macroSummaryBody,
              style: const TextStyle(fontSize: 13),
            ),
            if (data.energyRatio != null ||
                data.proteinRatio != null) ...[
              const SizedBox(height: 10),
              if (data.energyRatio != null) ...[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Énergie',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      _percent(data.energyRatio),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _val(data.energyRatio),
                ),
              ],
              if (data.proteinRatio != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Protéines',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      _percent(data.proteinRatio),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _val(data.proteinRatio),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final AdviceScript data;
  final Color accent;
  const _MotivationCard({
    required this.data,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: accent.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 Défi 24h',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.defi24h,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              data.quotePremium,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === Widgets utilitaires ==========================================
class _BulletLine extends StatelessWidget {
  final String label, value;
  const _BulletLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 13)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? suffixText;
  const _LabeledTextField({
    required this.label,
    required this.controller,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

class _AnimatedAppear extends StatelessWidget {
  final Widget child;
  final int index;
  const _AnimatedAppear({
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 12),
        child: Opacity(
          opacity: v,
          child: child,
        ),
      ),
      child: child,
    );
  }
}
