import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/foods_loader.dart' as foods_loader;
import 'account_screen.dart'; // ✅

// Supabase client global (comme dans les autres écrans)
SupabaseClient get _client => Supabase.instance.client;


/// ───────────────────────────── Couleurs / helpers ─────────────────────────────

const Color _kPctBrique = Color(0xFFD32F2F); // 0–50 %
const Color _kPctOrange = Color(0xFFFF7A00); // 50–80 %
const Color _kPctMiel   = Color(0xFFFFD54F); // 80–110 %
const Color _kPctMenthe = Color(0xFF00C853); // >110 %

const Color kTotumOrange = Color(0xFFFF7A00);

Color _barColor(double pct) {
  if (!pct.isFinite) return _kPctBrique;
  if (pct < 0.5) return _kPctBrique;
  if (pct < 0.8) return _kPctOrange;
  if (pct <= 1.1) return _kPctMiel;
  return _kPctMenthe;
}

/// Couleur inversée pour la section "🛑 À surveiller"
Color _watchColor(double pct) {
  if (!pct.isFinite) return _kPctBrique;
  if (pct <= 1.0) return _kPctMenthe; // ≤100 % = vert
  if (pct <= 1.2) return _kPctOrange; // 100–120 % = orange
  return _kPctBrique;                 // >120 % = rouge
}

Color _accent(BuildContext _) => kTotumOrange;

/// ───────────────────────────── Périodes ─────────────────────────────

enum ReportSpan { day, d7, d30, d90 }

class _SpanInfo {
  final DateTime from;
  final DateTime to;
  final bool isAverage;
  const _SpanInfo(this.from, this.to, this.isAverage);
}

_SpanInfo _spanInfo(ReportSpan span) {
  final now = DateTime.now();
  switch (span) {
    case ReportSpan.day:
      final d = DateTime(now.year, now.month, now.day);
      return _SpanInfo(d, d, false);
    case ReportSpan.d7:
      return _SpanInfo(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
        DateTime(now.year, now.month, now.day),
        true,
      );
    case ReportSpan.d30:
      return _SpanInfo(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)),
        DateTime(now.year, now.month, now.day),
        true,
      );
    case ReportSpan.d90:
      return _SpanInfo(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 89)),
        DateTime(now.year, now.month, now.day),
        true,
      );
  }
}

/// ───────────────────────────── Modèles internes ─────────────────────────────

class _GoalsRaw {
  final double kcal;
  final double prot;
  final String sex; // 'male' | 'female'
  final double weightKg;
  final int activityIdx; // 0..4
  const _GoalsRaw({
    required this.kcal,
    required this.prot,
    required this.sex,
    required this.weightKg,
    required this.activityIdx,
  });
}

class _DayTotals {
  final double kcal;
  final double prot;
  final double carb;
  final double fat;
  final double fiber;
  final Map<String, double> micros;
  final double waterMlFromJournal;
  final List<String> waterSources;
  final bool hasData;
  _DayTotals({
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

  factory _DayTotals.empty() => _DayTotals(
        kcal: 0,
        prot: 0,
        carb: 0,
        fat: 0,
        fiber: 0,
        micros: <String, double>{},
        waterMlFromJournal: 0,
        waterSources: const [],
        hasData: false,
      );
}

class Metric {
  final String label;
  final double value;
  final double? target;
  final String unit;
  final int decimals;
  const Metric(this.label, this.value, this.target, this.unit, this.decimals);
}

class MetricGroup {
  final String title;
  final List<Metric> metrics;
  final bool isWatch;
  const MetricGroup({
    required this.title,
    required this.metrics,
    this.isWatch = false,
  });
}

class HydrationData {
  final double journalMl;
  final double manualMl;
  final double targetMl;
  final List<String> sources;
  const HydrationData({
    required this.journalMl,
    required this.manualMl,
    required this.targetMl,
    required this.sources,
  });

  double get totalMl => journalMl + manualMl;
  double get ratio => targetMl > 0 ? (totalMl / targetMl) : 0.0;
}

class DailyEnergyPoint {
  final DateTime date;
  final double kcal;

  const DailyEnergyPoint({
    required this.date,
    required this.kcal,
  });
}

class BilanData {
  final DateTime from;
  final DateTime to;
  final bool isAverage;

  // Totaux / moyennes
  final double kcal;
  final double prot;
  final double carb;
  final double fat;
  final double fiber;

  // Micros
  final Map<String, double> micros;

  // Nouveau : points journaliers d’énergie (pour le graphique)
  final List<DailyEnergyPoint> dailyEnergy;

  // Groupes pour l’affichage
  final MetricGroup macrosGroup;
  final MetricGroup efasGroup;
  final MetricGroup watchGroup;
  final MetricGroup vitaminsGroup;
  final MetricGroup mineralsGroup;
  final MetricGroup indicGroup;

  // Hydratation
  final HydrationData hydration;

  const BilanData({
    required this.from,
    required this.to,
    required this.isAverage,
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.micros,
    required this.dailyEnergy,
    required this.macrosGroup,
    required this.efasGroup,
    required this.watchGroup,
    required this.vitaminsGroup,
    required this.mineralsGroup,
    required this.indicGroup,
    required this.hydration,
  });
}


/// ───────────────────────────── Helpers profil / objectifs ─────────────────────────────

Future<_GoalsRaw> _readGoalsRaw() async {
  final sp = await SharedPreferences.getInstance();
  final kcal = sp.getDouble('goals_kcal') ?? 2000.0;
  final prot = sp.getDouble('goals_prot') ?? 120.0;
  final sexStr = sp.getString('profile_sex') ?? 'male';
  final sex = (sexStr == 'female') ? 'female' : 'male';
  final weight = sp.getDouble('profile_weight') ?? 70.0;
  final act = sp.getInt('profile_activity') ?? 0;
  return _GoalsRaw(
    kcal: kcal,
    prot: prot,
    sex: sex,
    weightKg: weight,
    activityIdx: act,
  );
}

/// Objectif hydratation basé sur poids & activité
double _hydrationTarget(double weightKg, int activityIdx) {
  int bonus = switch (activityIdx.clamp(0, 4)) {
    1 => 300,
    2 => 600,
    3 || 4 => 900,
    _ => 0,
  };
  return (weightKg * 30.0 + bonus).clamp(1000, 6000).toDouble();
}

/// ───────────────────────────── Helpers FoodsRepository / Journal ─────────────────────────────

Future<void> _ensureFoodsLoaded() async {
  final repo = foods_loader.FoodsRepository.instance;
  try {
    final items = (repo.items as List);
    if (items.isNotEmpty) return;
  } catch (_) {
    // on tente quand même de charger
  }
  try {
    await repo.loadFromAsset('assets/foods.csv');
  } catch (_) {}
  try {
    await repo.loadCustomFoods();
  } catch (_) {}
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _hydrationManualKeyForDate(DateTime d) =>
    'hydration_manual_ml_${_dateKey(d)}';

String _journalKeyForDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return 'journal_${y}-${m}-${dd}';
}

/// Détecte si le nom d'aliment correspond à de l'eau en bouteille / eau du robinet
bool _looksLikeWater(String name) {
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
  for (final b in brands) {
    if (lower.contains(b)) return true;
  }
  return false;
}

/// Totaux (macros + micros + eau) pour une journée donnée
Future<_DayTotals> _computeDayTotalsForDate(
  DateTime day,
  foods_loader.FoodsRepository repo,
  SharedPreferences sp,
) async {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final dd = day.day.toString().padLeft(2, '0');
  final ymd = '$y-$m-$dd';

  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
  final microTotals = <String, double>{};
  double waterMl = 0;
  final waterNames = <String>{};

  // Repo aliments (base CSV + customs)
  final List<foods_loader.FoodItem> allFoods = [
    ...(repo.items as List),
    ...repo.customs,
  ];

  foods_loader.FoodItem? _findFood(String id) {
    for (final f in allFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

  // 1) 🔹 Tentative via Supabase (multi-appareils)
  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> rows = await _client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .eq('entry_date', ymd);

      if (rows.isNotEmpty) {
        for (final r in rows) {
          final id = (r['food_id'] ?? '').toString();
          final name = (r['food_name'] ?? '').toString();
          final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0.0;

          // Macros depuis Supabase
          kcal += (r['energy_kcal'] as num?)?.toDouble() ?? 0.0;
          prot += (r['protein_g'] as num?)?.toDouble() ?? 0.0;
          carb += (r['carbs_g'] as num?)?.toDouble() ?? 0.0;
          fat  += (r['fat_g'] as num?)?.toDouble() ?? 0.0;
          fiber += (r['fiber_g'] as num?)?.toDouble() ?? 0.0;

          // Micros depuis la base CSV / customs
          if (id.isNotEmpty) {
            final food = _findFood(id);
            if (food != null) {
              final mic = food.microsFor(grams);
              mic.forEach((k, v) {
                microTotals[k] = (microTotals[k] ?? 0.0) + v;
              });
            }
          }

          // Eau (on suppose 1 g ≈ 1 ml)
          if (_looksLikeWater(name)) {
            waterMl += grams;
            waterNames.add(name);
          }
        }

        if ((kcal + prot + carb + fat + fiber) > 0 ||
            microTotals.isNotEmpty ||
            waterMl > 0) {
          return _DayTotals(
            kcal: kcal,
            prot: prot,
            carb: carb,
            fat: fat,
            fiber: fiber,
            micros: microTotals,
            waterMlFromJournal: waterMl,
            waterSources: waterNames.toList(),
            hasData: true,
          );
        }
      }
    }
  } catch (_) {
    // En cas de souci réseau / Supabase → on tombera sur le fallback local
  }

  // 2) 🔹 Fallback : lecture locale du journal_YYYY-MM-DD (comportement historique)
  final key = _journalKeyForDate(day);
  final raw = sp.getString(key);
  if (raw == null || raw.isEmpty) {
    return _DayTotals.empty();
  }

  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return _DayTotals.empty();
  }

  // Réinitialise les compteurs pour la partie locale
  kcal = 0;
  prot = 0;
  carb = 0;
  fat = 0;
  fiber = 0;
  microTotals.clear();
  waterMl = 0;
  waterNames.clear();

  for (final mealList in decoded.values) {
    if (mealList is! List) continue;
    for (final entry in mealList) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final id = (m['id'] ?? '').toString();
      final name = (m['name'] ?? '').toString();
      final grams = (m['grams'] as num?)?.toDouble() ?? 0.0;

      // Macros depuis le journal (pour coller au journal)
      kcal += (m['kcal'] as num?)?.toDouble() ?? 0.0;
      prot += (m['prot'] as num?)?.toDouble() ?? 0.0;
      carb += (m['carb'] as num?)?.toDouble() ?? 0.0;
      fat  += (m['fat'] as num?)?.toDouble() ?? 0.0;
      fiber += (m['fiber'] as num?)?.toDouble() ?? 0.0;

      // Micros depuis la base CSV
      final food = _findFood(id);
      if (food != null) {
        final mic = food.microsFor(grams);
        mic.forEach((k, v) {
          microTotals[k] = (microTotals[k] ?? 0.0) + v;
        });
      }

      // Eau (on suppose 1 g ≈ 1 ml)
      if (_looksLikeWater(name)) {
        waterMl += grams;
        waterNames.add(name);
      }
    }
  }

  return _DayTotals(
    kcal: kcal,
    prot: prot,
    carb: carb,
    fat: fat,
    fiber: fiber,
    micros: microTotals,
    waterMlFromJournal: waterMl,
    waterSources: waterNames.toList(),
    hasData: (kcal + prot + carb + fat + fiber) > 0 ||
        microTotals.isNotEmpty ||
        waterMl > 0,
  );
}


/// ───────────────────────────── Hydratation ─────────────────────────────

Future<HydrationData> _computeHydrationForToday(_GoalsRaw goals) async {
  final sp = await SharedPreferences.getInstance();
  final repo = foods_loader.FoodsRepository.instance;
  await _ensureFoodsLoaded();

  final now = DateTime.now();
  final dayTotals = await _computeDayTotalsForDate(now, repo, sp);

  final manualKey =
      'hydration_manual_ml_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final manual = sp.getDouble(manualKey) ?? 0.0;

  final target = sp.getDouble('goals_water_ml') ??
      _hydrationTarget(goals.weightKg, goals.activityIdx);

  return HydrationData(
    journalMl: dayTotals.waterMlFromJournal,
    manualMl: manual,
    targetMl: target,
    sources: dayTotals.waterSources,
  );
}

Future<void> _bumpManualWater(int deltaMl) async {
  final sp = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final key =
      'hydration_manual_ml_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final cur = sp.getDouble(key) ?? 0.0;
  await sp.setDouble(
    key,
    (cur + deltaMl).clamp(0, 20000).toDouble(),
  );
}

/// ───────────────────────────── Calcul Bilan pour une période ─────────────────────────────

Future<BilanData> _computeBilanForSpan(ReportSpan span) async {
  final goals = await _readGoalsRaw();
  final sp = await SharedPreferences.getInstance();
  final repo = foods_loader.FoodsRepository.instance;
  await _ensureFoodsLoaded();

  final info = _spanInfo(span);
  final from = info.from;
  final to = info.to;
  final isAvg = info.isAverage;

  double sumKcal = 0, sumProt = 0, sumCarb = 0, sumFat = 0, sumFib = 0;
  final microTotals = <String, double>{};
  int daysWithData = 0;

  // Nouveau : on garde aussi la courbe d’énergie jour par jour
  final List<DailyEnergyPoint> energyPoints = [];

  for (DateTime d = from;
      !d.isAfter(to);
      d = d.add(const Duration(days: 1))) {
    final dt = await _computeDayTotalsForDate(d, repo, sp);
    if (!dt.hasData) continue;
    daysWithData++;

    sumKcal += dt.kcal;
    sumProt += dt.prot;
    sumCarb += dt.carb;
    sumFat += dt.fat;
    sumFib += dt.fiber;

    // On ajoute le point pour le graphique
    energyPoints.add(DailyEnergyPoint(date: d, kcal: dt.kcal));

    dt.micros.forEach((k, v) {
      microTotals[k] = (microTotals[k] ?? 0.0) + v;
    });
  }

    if (isAvg && daysWithData > 0) {
    final div = daysWithData.toDouble();
    sumKcal /= div;
    sumProt /= div;
    sumCarb /= div;
    sumFat  /= div;
    sumFib  /= div;
    microTotals.updateAll((key, value) => value / div);
  }

  // ───────── Hydratation : jour vs moyennes 7/30/90 ─────────
  HydrationData hydration;

  if (!isAvg) {
    // Mode "Jour" : on garde exactement le comportement actuel
    hydration = await _computeHydrationForToday(goals);
  } else {
    // Mode moyenne 7 / 30 / 90 jours :
    // on calcule la moyenne journalière (journal + manuel) sur la période.
    double sumJournalWater = 0;
    double sumManualWater  = 0;
    int daysCount = 0;

    final repo = foods_loader.FoodsRepository.instance;
    await _ensureFoodsLoaded();
    final sp = await SharedPreferences.getInstance();

    for (DateTime d = from;
        !d.isAfter(to);
        d = d.add(const Duration(days: 1))) {

      final dt = await _computeDayTotalsForDate(d, repo, sp);
      if (!dt.hasData) continue;
      daysCount++;

      sumJournalWater += dt.waterMlFromJournal;
      final manualKey = _hydrationManualKeyForDate(d);
      sumManualWater  += sp.getDouble(manualKey) ?? 0.0;
    }

    double avgJournal = 0;
    double avgManual  = 0;
    if (daysCount > 0) {
      final div = daysCount.toDouble();
      avgJournal = sumJournalWater / div;
      avgManual  = sumManualWater  / div;
    }

    // Objectif hydrique : basé sur le profil (comme avant)
    final target = (await SharedPreferences.getInstance())
            .getDouble('goals_water_ml') ??
        _hydrationTarget(goals.weightKg, goals.activityIdx);

    hydration = HydrationData(
      journalMl: avgJournal,
      manualMl: avgManual,
      targetMl: target,
      sources: const [], // on n'affiche pas les sources pour une moyenne
    );
  }

  // Construction des groupes de métriques à partir des totaux
  final data = _buildMetricGroups(
    from: from,
    to: to,
    isAverage: isAvg,
    kcal: sumKcal,
    prot: sumProt,
    carb: sumCarb,
    fat: sumFat,
    fiber: sumFib,
    micros: microTotals,
    goals: goals,
    hydration: hydration,
    dailyEnergy: energyPoints,
  );

  return data;
}


/// Création des groupes de métriques en respectant ton cahier des charges
BilanData _buildMetricGroups({
  required DateTime from,
  required DateTime to,
  required bool isAverage,
  required double kcal,
  required double prot,
  required double carb,
  required double fat,
  required double fiber,
  required Map<String, double> micros,
  required _GoalsRaw goals,
  required HydrationData hydration,
  required List<DailyEnergyPoint> dailyEnergy,
}) {
  double m(String key) => micros[key] ?? 0.0;

  // Objectifs macros
  final goalKcal = goals.kcal <= 0 ? 2000.0 : goals.kcal;
  final goalProt = goals.prot <= 0 ? 120.0 : goals.prot;
  final goalCarb = (goalKcal * 0.55) / 4.0;
  final goalFat  = (goalKcal * 0.35) / 9.0;
  const goalFiber = 30.0;

  // EFA à partir de %E
  final goalO9  = (goalKcal * 0.20) / 9.0;
  final goalLA  = (goalKcal * 0.04) / 9.0;
  final goalALA = (goalKcal * 0.01) / 9.0;
  const goalEPA = 0.25;
  const goalDHA = 0.25;

  // À surveiller
  final goalSat    = (goalKcal * 0.12) / 9.0;
  final goalSugars = (goalKcal * 0.10) / 4.0;
  const goalSalt   = 5.0;

  final isF = goals.sex == 'female';

  // Objectifs vitamines
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

  // Objectifs minéraux
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

  // Groupes

  final macrosGroup = MetricGroup(
    title: '⚡ Macro-cibles',
    metrics: [
      Metric('Énergie',   kcal,      goalKcal, 'kcal', 0),
      Metric('Protéines', prot,      goalProt, 'g',    1),
      Metric('Glucides',  carb,      goalCarb, 'g',    1),
      Metric('Lipides',   fat,       goalFat,  'g',    1),
      Metric('Fibres',    fiber,     goalFiber,'g',    1),
    ],
  );

  final efasGroup = MetricGroup(
    title: '🧠 Acides gras essentiels',
    metrics: [
      Metric('Oméga 9 (Oléique)', m('Acide_oléique_W9_g_100g'),           goalO9,  'g', 2),
      Metric('Oméga 6 (LA)',      m('Acide_linoléique_W6_LA_g_100g'),     goalLA,  'g', 2),
      Metric('Oméga 3 (ALA)',     m('Acide_alpha-linolénique_W3_ALA_g_100g'), goalALA, 'g', 2),
      Metric('EPA',               m('EPA_g_100g'),                         goalEPA,'g', 2),
      Metric('DHA',               m('DHA_g_100g'),                         goalDHA,'g', 2),
    ],
  );

  final watchGroup = MetricGroup(
    title: '🛑 À surveiller',
    isWatch: true,
    metrics: [
      Metric('AG saturés', m('AG_saturés_g_100g'), goalSat,    'g', 2),
      Metric('Sucres',     m('Sucres_g_100g'),     goalSugars, 'g', 1),
      Metric('Sel',        m('Sel_g_100g'),        goalSalt,   'g', 1),
    ],
  );

  final vitaminsGroup = MetricGroup(
    title: '🍋 Vitamines',
    metrics: [
      Metric('Vit A', m('Rétinol_µg_100g'),           vitTargets['Vit A'], 'µg', 0),
      Metric('Vit D', m('Vitamine_D_µg_100g'),        vitTargets['Vit D'], 'µg', 0),
      Metric('Vit E', m('Vitamine_E_mg_100g'),        vitTargets['Vit E'], 'mg', 1),
      Metric('Vit K', m('Vitamine_K1_µg_100g'),       vitTargets['Vit K'], 'µg', 0),
      Metric('Vit C', m('Vitamine_C_mg_100g'),        vitTargets['Vit C'], 'mg', 0),
      Metric('B1',    m('Vitamine_B1_mg_100g'),       vitTargets['B1'],    'mg', 1),
      Metric('B2',    m('Vitamine_B2_mg_100g'),       vitTargets['B2'],    'mg', 1),
      Metric('B3',    m('Vitamine_B3_mg_100g'),       vitTargets['B3'],    'mg', 1),
      Metric('B5',    m('Vitamine_B5_mg_100g'),       vitTargets['B5'],    'mg', 1),
      Metric('B6',    m('Vitamine_B6_mg_100g'),       vitTargets['B6'],    'mg', 1),
      Metric('B9',    m('Vitamine_B9_µg_100g'),       vitTargets['B9'],    'µg', 0),
      Metric('B12',   m('Vitamine_B12_µg_100g'),      vitTargets['B12'],   'µg', 0),
    ],
  );

  final mineralsGroup = MetricGroup(
    title: '🧱 Minéraux',
    metrics: [
      Metric('Calcium',   m('Calcium_mg_100g'),   minTargets['Calcium'],   'mg', 0),
      Metric('Cuivre',    m('Cuivre_mg_100g'),    minTargets['Cuivre'],    'mg', 1),
      Metric('Fer',       m('Fer_mg_100g'),       minTargets['Fer'],       'mg', 1),
      Metric('Iode',      m('Iode_µg_100g'),      minTargets['Iode'],      'µg', 0),
      Metric('Magnésium', m('Magnésium_mg_100g'), minTargets['Magnésium'],'mg', 0),
      Metric('Manganèse', m('Manganèse_mg_100g'), minTargets['Manganèse'],'mg', 1),
      Metric('Phosphore', m('Phosphore_mg_100g'), minTargets['Phosphore'],'mg', 0),
      Metric('Potassium', m('Potassium_mg_100g'), minTargets['Potassium'],'mg', 0),
      Metric('Sélénium',  m('Sélénium_µg_100g'),  minTargets['Sélénium'], 'µg', 0),
      Metric('Sodium',    m('Sodium_mg_100g'),    minTargets['Sodium'],   'mg', 0),
      Metric('Zinc',      m('Zinc_mg_100g'),      minTargets['Zinc'],     'mg', 1),
    ],
  );

  final indicGroup = MetricGroup(
    title: 'ℹ️ Apports indicatifs',
    metrics: [
      Metric('Cholestérol', m('Cholestérol_mg_100g'), 1000.0, 'mg', 0),
    ],
  );

    return BilanData(
    from: from,
    to: to,
    isAverage: isAverage,
    kcal: kcal,
    prot: prot,
    carb: carb,
    fat: fat,
    fiber: fiber,
    micros: micros,
    dailyEnergy: dailyEnergy,
    macrosGroup: macrosGroup,
    efasGroup: efasGroup,
    watchGroup: watchGroup,
    vitaminsGroup: vitaminsGroup,
    mineralsGroup: mineralsGroup,
    indicGroup: indicGroup,
    hydration: hydration,
  );
}

/// ───────────────────────────── UI : Écran principal ─────────────────────────────

class BilanScreen extends StatefulWidget {
  const BilanScreen({super.key});

  @override
  State<BilanScreen> createState() => _BilanScreenState();
}

class _BilanScreenState extends State<BilanScreen> {
  ReportSpan _span = ReportSpan.day;
  late Future<BilanData> _future;
  int _glassSize = 125; // 125 ml par défaut

  bool _showEnergyChart = true; // 👈 nouveau

  @override
  void initState() {
    super.initState();
    _future = _computeBilanForSpan(_span);
  }

  void _onSpanChanged(ReportSpan span) {
    setState(() {
      _span = span;
      _future = _computeBilanForSpan(span);
    });
  }

  @override
  Widget build(BuildContext context) {
    final segmented = <ReportSpan, Widget>{
      ReportSpan.day:
          const Padding(padding: EdgeInsets.all(8), child: Text('Jour')),
      ReportSpan.d7:
          const Padding(padding: EdgeInsets.all(8), child: Text('7 j')),
      ReportSpan.d30:
          const Padding(padding: EdgeInsets.all(8), child: Text('30 j')),
      ReportSpan.d90:
          const Padding(padding: EdgeInsets.all(8), child: Text('90 j')),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilan'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CupertinoSegmentedControl<ReportSpan>(
              groupValue: _span,
              onValueChanged: _onSpanChanged,
              children: segmented,
            ),
          ),
        ],
      ),
      body: FutureBuilder<BilanData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('Aucune donnée à afficher.'));
          }

          final data = snap.data!;
          final fmt = MaterialLocalizations.of(context);
          final range =
              '${fmt.formatShortDate(data.from)} → ${fmt.formatShortDate(data.to)}${data.isAverage ? " (moyenne)" : ""}';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _computeBilanForSpan(_span);
              });
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(range,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                // 👇 Nouveau : carte "Résumé graphique (kcal)" pour 7/30/90 jours
                if (_span != ReportSpan.day && data.dailyEnergy.isNotEmpty) ...[
                  _EnergyChartCard(
                    span: _span,
                    points: data.dailyEnergy,
                    goalKcal: data.macrosGroup.metrics.first.target ?? 0.0,
                    show: _showEnergyChart,
                    onToggleShow: (v) {
                      setState(() {
                        _showEnergyChart = v;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Bloc macro premium : donut + 4 curseurs
                _MacroOverview(group: data.macrosGroup),
                const SizedBox(height: 8),

                _Section(
                  title: data.efasGroup.title,
                  metrics: data.efasGroup.metrics,
                  isWatch: false,
                ),
                _Section(
                  title: data.watchGroup.title,
                  metrics: data.watchGroup.metrics,
                  isWatch: true,
                ),
                _Section(
                  title: data.vitaminsGroup.title,
                  metrics: data.vitaminsGroup.metrics,
                  isWatch: false,
                ),
                _Section(
                  title: data.mineralsGroup.title,
                  metrics: data.mineralsGroup.metrics,
                  isWatch: false,
                ),
                _Section(
                  title: data.indicGroup.title,
                  metrics: data.indicGroup.metrics,
                  isWatch: false,
                ),

                const SizedBox(height: 12),
                _HydrationSection(
                  data: data.hydration,
                  glassSize: _glassSize,
                  onGlassSizeChanged: (v) {
                    if (v != null) {
                      setState(() => _glassSize = v);
                    }
                  },
                  onAddGlass: () async {
                    await _bumpManualWater(_glassSize);
                    setState(() {
                      _future = _computeBilanForSpan(_span);
                    });
                  },
                  onUndoGlass: () async {
                    await _bumpManualWater(-_glassSize);
                    setState(() {
                      _future = _computeBilanForSpan(_span);
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EnergyChartCard extends StatelessWidget {
  final ReportSpan span;
  final List<DailyEnergyPoint> points;
  final double goalKcal;
  final bool show;
  final ValueChanged<bool> onToggleShow;

  const _EnergyChartCard({
    required this.span,
    required this.points,
    required this.goalKcal,
    required this.show,
    required this.onToggleShow,
  });

  String _titleForSpan() {
    switch (span) {
      case ReportSpan.d7:
        return 'Votre équilibre énergétique (7 jours)';
      case ReportSpan.d30:
        return 'Votre équilibre énergétique (30 jours)';
      case ReportSpan.d90:
        return 'Votre équilibre énergétique (90 jours)';
      case ReportSpan.day:
        return 'Votre équilibre énergétique (1 jour)';
    }
  }

  // Format simple type "Nov 4"
  String _formatShortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[d.month - 1];
    return '$month ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    // Si l’utilisateur a masqué le graphique : on affiche juste l’en-tête + switch
    if (!show) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _titleForSpan(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Switch(
                value: show,
                onChanged: onToggleShow,
              ),
            ],
          ),
        ),
      );
    }

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    // Valeurs d’énergie par jour
    final kcalValues = points.map((e) => e.kcal).toList();

    // On utilise le max entre objectif et max réel pour échelle
    final maxVal = [
      if (goalKcal > 0) goalKcal,
      ...kcalValues,
    ].fold<double>(0.0, (p, e) => e > p ? e : p);
    final maxY = (maxVal <= 0) ? 200.0 : maxVal * 1.15;

    // Moyenne sur la période
    final avgKcal =
        kcalValues.fold(0.0, (a, b) => a + b) / kcalValues.length;

    // 🎨 Code couleur des barres selon l’objectif, avec la PALETTE TOTUM
    Color _barColorFor(double value) {
      if (goalKcal <= 0) {
        // Pas d’objectif défini → orange Totum neutre
        return kTotumOrange;
      }
      final ratio = value / goalKcal;
      if (!ratio.isFinite) return _kPctBrique;

      if (ratio < 0.9) {
        // En dessous de l’objectif → miel (tu peux manger un peu plus)
        return _kPctMiel;
      } else if (ratio <= 1.1) {
        // Dans les clous → vert menthe
        return _kPctMenthe;
      } else {
        // Au-dessus → brique (alerte)
        return _kPctBrique;
      }
    }

    // Groupes de barres
    final barGroups = List.generate(points.length, (index) {
      final p = points[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: p.kcal,
            width: 6,
            borderRadius: BorderRadius.circular(4),
            color: _barColorFor(p.kcal),
          ),
        ],
      );
    });

    final lastIndex = points.length - 1;
    final desiredLabels = () {
      switch (span) {
        case ReportSpan.d7:
          return 3; // début, milieu, fin
        case ReportSpan.d30:
          return 3; // environ tous les 10 jours
        case ReportSpan.d90:
          return 9; // environ tous les 10 jours
        case ReportSpan.day:
          return 1;
      }
    }();

    final step =
        points.length <= 1 ? 1 : (points.length / desiredLabels).ceil();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête + switch
            Row(
              children: [
                Expanded(
                  child: Text(
                    _titleForSpan(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Switch(
                  value: show,
                  onChanged: onToggleShow,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 📊 Graphique énergie
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                  ),
                  // Axes visibles (baseline gauche + bas)
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black26, width: 1),
                      bottom: BorderSide(color: Colors.black26, width: 1),
                      right: BorderSide(color: Colors.transparent),
                      top: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    // Axe Y : repères en kcal (y compris 0)
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value < 0) {
                            return const SizedBox.shrink();
                          }
                          final text = value.round().toString();
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    // Axe X : dates échantillonnées (début / milieu / fin, etc.)
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }

                          // On affiche environ "desiredLabels" dates réparties
                          if (index % step != 0 && index != lastIndex) {
                            return const SizedBox.shrink();
                          }

                          final date = points[index].date;
                          final label = _formatShortDate(date);

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  // Ligne horizontale = objectif kcal
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (goalKcal > 0)
                        HorizontalLine(
                          y: goalKcal,
                          color: kTotumOrange.withOpacity(0.7),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                        ),
                    ],
                  ),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Infos texte en dessous
            Text(
              'Objectif journalier : ${goalKcal.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Moyenne sur la période : ${avgKcal.toStringAsFixed(0)} kcal/jour',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}


/// ───────────────────────────── UI : Macro overview (donut + 4 curseurs) ─────────────────────────────

class _MacroOverview extends StatelessWidget {
  final MetricGroup group;
  const _MacroOverview({required this.group});

  @override
  Widget build(BuildContext context) {
    if (group.metrics.isEmpty) {
      return const SizedBox.shrink();
    }
    // On suppose : [Énergie, Protéines, Glucides, Lipides, Fibres]
    final energy = group.metrics[0];
    final others = group.metrics.skip(1).toList();

    final target = energy.target ?? 0.0;
    final pct = (target == 0)
        ? 0.0
        : (energy.value / target).clamp(0.0, 2.0);
    final color = _barColor(pct);

    final remaining =
        target > 0 ? (target - energy.value).clamp(0.0, double.infinity) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Énergie',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 94,
                  height: 94,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pct.clamp(0.02, 1.0),
                        strokeWidth: 9,
                        color: color,
                        backgroundColor: color.withOpacity(0.18),
                      ),
                      Text(
                        '${(pct * 100).clamp(0, 200).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black, // ← pourcentage en noir
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Objectif = ${target.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Consommé = ${energy.value.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Restant = ${remaining.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: others.map((m) {
                final t = m.target ?? 0.0;
                final pct = (t == 0)
                    ? 0.0
                    : (m.value / t).clamp(0.0, 2.0);
                final c = _barColor(pct);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            m.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: c.withOpacity(0.35)),
                          ),
                          child: Text(
                            '${(pct * 100).clamp(0, 200).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: c,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.02, 1.0),
                          minHeight: 9,
                          backgroundColor: c.withOpacity(0.18),
                          color: c,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${m.value.toStringAsFixed(m.decimals)} ${m.unit} '
                        '/ ${m.target?.toStringAsFixed(m.decimals)} ${m.unit}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────────────── UI : Section générique de curseurs ─────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Metric> metrics;
  final bool isWatch;
  const _Section({
    required this.title,
    required this.metrics,
    required this.isWatch,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final colorOf = isWatch ? _watchColor : _barColor;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          initiallyExpanded: false,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: metrics.map((m) {
            final pct = (m.target == null || m.target == 0)
                ? null
                : (m.value / m.target!).clamp(0.0, 2.0).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        m.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (pct != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorOf(pct).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colorOf(pct).withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          '${(pct * 100).clamp(0, 200).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorOf(pct),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  if (pct != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.02, 1.0).toDouble(),
                        minHeight: 12,
                        backgroundColor: colorOf(pct).withOpacity(0.18),
                        color: colorOf(pct),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.value.toStringAsFixed(m.decimals)} ${m.unit} / '
                      '${m.target!.toStringAsFixed(m.decimals)} ${m.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ] else
                    Text(
                      '${m.value.toStringAsFixed(m.decimals)} ${m.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// ───────────────────────────── UI : Hydratation ─────────────────────────────

class _HydrationSection extends StatelessWidget {
  final HydrationData data;
  final int glassSize;
  final ValueChanged<int?> onGlassSizeChanged;
  final VoidCallback onAddGlass;
  final VoidCallback onUndoGlass;

  const _HydrationSection({
    required this.data,
    required this.glassSize,
    required this.onGlassSizeChanged,
    required this.onAddGlass,
    required this.onUndoGlass,
  });

  @override
  Widget build(BuildContext context) {
    final pct = data.ratio.clamp(0.0, 2.0);
    final color = _barColor(pct);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text(
                '💧 Hydratation',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: glassSize,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 125, child: Text('Verre 125 ml')),
                  DropdownMenuItem(value: 250, child: Text('Verre 250 ml')),
                ],
                onChanged: onGlassSizeChanged,
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_drink, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.02, 1.0),
                      minHeight: 10,
                      backgroundColor: color.withOpacity(0.18),
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).clamp(0, 200).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${data.totalMl.toStringAsFixed(0)} ml / ${data.targetMl.toStringAsFixed(0)} ml',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.start,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent(context),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: onAddGlass,
                  label: const Text('Ajouter un verre'),
                ),
                OutlinedButton.icon(
                  onPressed: onUndoGlass,
                  icon: const Icon(Icons.undo),
                  label: const Text('Annuler dernier'),
                ),
              ],
            ),
            if (data.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Depuis le journal :',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Wrap(
                spacing: 6,
                runSpacing: -6,
                children: data.sources
                    .take(8)
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
