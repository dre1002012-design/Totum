// lib/services/day_totals.dart
//
// Lecteur public des totaux "du jour" (kcal, macros, micronutriments) à
// partir du journal local — même pattern que `_computeDayTotalsForAdviceDate`
// dans conseils_screen.dart (aliments + grammes stockés localement, micros
// dérivés à la volée via FoodsRepository), extrait ici en version publique et
// allégée (sans l'eau/l'hydratation) pour être réutilisable depuis le
// Tableau de bord sans dépendre d'un autre écran.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'foods_loader.dart';
import '../screens/sun_vitamin_d_screen.dart' show readSunVitD;

class DayTotals {
  final double kcal;
  final double prot;
  final double carb;
  final double fat;
  final double fiber;

  /// Clé = nom de colonne CSV (ex. 'Vitamine_D_µg_100g'), comme
  /// `FoodItem.micros100`.
  final Map<String, double> micros;

  const DayTotals({
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.micros,
  });

  static const empty = DayTotals(kcal: 0, prot: 0, carb: 0, fat: 0, fiber: 0, micros: {});

  bool get hasData => kcal > 0 || prot > 0 || carb > 0 || fat > 0;
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _ensureFoodsLoaded() async {
  final repo = FoodsRepository.instance;
  if (repo.items.isNotEmpty) return;
  try {
    await repo.loadFromAsset('assets/foods.csv');
  } catch (_) {}
  try {
    await repo.loadCustomFoods();
  } catch (_) {}
}

/// Totaux réellement logués un jour donné, depuis le journal local.
Future<DayTotals> computeDayTotals(DateTime day) async {
  final sp = await SharedPreferences.getInstance();
  final raw = sp.getString('journal_${_dateKey(day)}');
  if (raw == null || raw.isEmpty) return DayTotals.empty;

  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return DayTotals.empty;
  }

  await _ensureFoodsLoaded();
  final repo = FoodsRepository.instance;

  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
  final micros = <String, double>{};

  for (final mealList in decoded.values) {
    if (mealList is! List) continue;
    for (final entry in mealList) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final id = (m['id'] ?? '').toString();
      final grams = (m['grams'] as num?)?.toDouble() ?? 0.0;

      kcal += (m['kcal'] as num?)?.toDouble() ?? 0.0;
      prot += (m['prot'] as num?)?.toDouble() ?? 0.0;
      carb += (m['carb'] as num?)?.toDouble() ?? 0.0;
      fat += (m['fat'] as num?)?.toDouble() ?? 0.0;
      fiber += (m['fiber'] as num?)?.toDouble() ?? 0.0;

      final food = repo.findById(id);
      if (food != null) {
        food.microsFor(grams).forEach((k, v) => micros[k] = (micros[k] ?? 0) + v);
      }
    }
  }

  // Vitamine D solaire du jour courant (retour d'Alex, 11/08/2026 : "avec le
  // soleil, j'étais à 37%... le donut du tableau de bord était à 37%, donc
  // il ne comptabilise pas le soleil") — cette fonction ne l'ajoutait jamais,
  // contrairement à Conseils (`_computeDayTotalsForAdviceDate`) et Bilan (qui
  // l'ajoutent déjà chacun de leur côté). Uniquement pour aujourd'hui : le
  // soleil n'est pertinent que pour le jour où il a été renseigné/mesuré.
  final now = DateTime.now();
  if (day.year == now.year && day.month == now.month && day.day == now.day) {
    final sunD = await readSunVitD(now);
    if (sunD > 0) {
      micros['Vitamine_D_µg_100g'] = (micros['Vitamine_D_µg_100g'] ?? 0) + sunD;
    }
  }

  return DayTotals(kcal: kcal, prot: prot, carb: carb, fat: fat, fiber: fiber, micros: micros);
}

/// Totaux logués aujourd'hui.
Future<DayTotals> computeTodayTotals() => computeDayTotals(DateTime.now());
