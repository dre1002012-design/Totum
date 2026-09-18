// lib/services/day_totals.dart
//
// Lecteur public des totaux "du jour" (kcal, macros, micronutriments).
// Priorité 65 (audit global, retour d'Alex) : lisait UNIQUEMENT le journal
// local (SharedPreferences), contrairement à journal_screen.dart et
// bilan_screen.dart qui traitent Supabase comme seule source de vérité pour
// un compte connecté (repli local uniquement en cas d'échec réseau/hors
// ligne). Un aliment logué depuis un autre appareil, ou juste avant que le
// cache local n'ait eu le temps de se réécrire, n'apparaissait donc jamais
// dans les anneaux du Tableau de bord alors qu'il apparaissait bien dans
// Journal/Bilan pour le même jour — même pattern Supabase-d'abord/repli-local
// que `_computeDayTotalsForDate` dans bilan_screen.dart, dupliqué ici en
// version publique et allégée (sans l'eau/l'hydratation) pour être
// réutilisable depuis le Tableau de bord sans dépendre d'un autre écran.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// Un aliment loggé, avec sa contribution individuelle (pas agrégée) —
/// ajouté le 19/09/2026 (demande d'Alex : rendre les donuts macros/micros du
/// Tableau de bord cliquables, pour voir QUELS aliments du jour contribuent
/// le plus/le moins à un nutriment donné, comme le font Cronometer/MyFitnessPal
/// sur leurs propres graphiques). `name` reprend le nom LOGUÉ à l'époque
/// (jamais recalculé depuis la base actuelle — un aliment peut avoir changé
/// de nom ou disparu depuis, la contribution réelle du jour ne doit jamais
/// devenir orpheline pour autant).
class FoodEntryContribution {
  final String name;
  final double grams;
  final double kcal, prot, carb, fat, fiber;
  final Map<String, double> micros;
  const FoodEntryContribution({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.micros,
  });
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

/// Aliments logués un jour donné, un par un (pas agrégés) — voir
/// [FoodEntryContribution]. Source de vérité partagée par [computeDayTotals]
/// (qui agrège ce résultat) et par tout écran voulant savoir QUELS aliments
/// composent un total (ex. détail d'un nutriment au tap sur un donut).
Future<List<FoodEntryContribution>> dayFoodEntries(DateTime day) async {
  await _ensureFoodsLoaded();
  final repo = FoodsRepository.instance;
  final ymd = _dateKey(day);
  final entries = <FoodEntryContribution>[];
  bool gotSupabaseData = false;

  // 1) 🔹 Tentative via Supabase (multi-appareils, seule source de vérité
  //    pour un compte connecté — même logique que _computeDayTotalsForDate
  //    dans bilan_screen.dart).
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> rows = await Supabase.instance.client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .eq('entry_date', ymd);

      if (rows.isNotEmpty) {
        for (final r in rows) {
          final id = (r['food_id'] ?? '').toString();
          final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0.0;
          final name = (r['food_name'] ?? '').toString();

          final entryKcal = (r['energy_kcal'] as num?)?.toDouble() ?? 0.0;
          final entryProt = (r['protein_g'] as num?)?.toDouble() ?? 0.0;
          final entryCarb = (r['carbs_g'] as num?)?.toDouble() ?? 0.0;
          final entryFat = (r['fat_g'] as num?)?.toDouble() ?? 0.0;
          final entryFiber = (r['fiber_g'] as num?)?.toDouble() ?? 0.0;

          final entryMicros = <String, double>{};
          final snap = r['micros'];
          if (snap is Map && snap.isNotEmpty) {
            snap.forEach((k, v) {
              entryMicros[k.toString()] = (v is num) ? v.toDouble() : 0.0;
            });
          } else if (id.isNotEmpty) {
            final food = repo.findById(id);
            if (food != null) entryMicros.addAll(food.microsFor(grams));
          }

          entries.add(FoodEntryContribution(
            name: name.isNotEmpty ? name : (repo.findById(id)?.name ?? id),
            grams: grams,
            kcal: entryKcal, prot: entryProt, carb: entryCarb, fat: entryFat, fiber: entryFiber,
            micros: entryMicros,
          ));
        }
        // Même condition que l'ancienne version agrégée-uniquement de cette
        // fonction (comportement préservé à l'identique par ce refactor) :
        // ne fait confiance à Supabase que si le total qui en résulte est
        // réellement non-vide, pas juste "des lignes existent".
        gotSupabaseData = entries.any((e) =>
            e.kcal + e.prot + e.carb + e.fat + e.fiber > 0 || e.micros.isNotEmpty);
      }
    }
  } catch (_) {
    // Souci réseau/Supabase → on tombera sur le repli local ci-dessous.
  }

  // 2) 🔹 Repli : lecture locale du journal_YYYY-MM-DD (hors ligne, ou compte
  //    non connecté).
  if (!gotSupabaseData) {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('journal_$ymd');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        entries.clear();
        for (final mealList in decoded.values) {
          if (mealList is! List) continue;
          for (final entry in mealList) {
            if (entry is! Map) continue;
            final m = Map<String, dynamic>.from(entry);
            final id = (m['id'] ?? '').toString();
            final grams = (m['grams'] as num?)?.toDouble() ?? 0.0;
            final food = repo.findById(id);

            entries.add(FoodEntryContribution(
              name: (m['name'] ?? food?.name ?? id).toString(),
              grams: grams,
              kcal: (m['kcal'] as num?)?.toDouble() ?? 0.0,
              prot: (m['prot'] as num?)?.toDouble() ?? 0.0,
              carb: (m['carb'] as num?)?.toDouble() ?? 0.0,
              fat: (m['fat'] as num?)?.toDouble() ?? 0.0,
              fiber: (m['fiber'] as num?)?.toDouble() ?? 0.0,
              micros: food != null ? food.microsFor(grams) : const {},
            ));
          }
        }
      } catch (_) {
        entries.clear();
      }
    }
  }

  return entries;
}

/// Totaux réellement logués un jour donné.
Future<DayTotals> computeDayTotals(DateTime day) async {
  final entries = await dayFoodEntries(day);

  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
  final micros = <String, double>{};
  for (final e in entries) {
    kcal += e.kcal; prot += e.prot; carb += e.carb; fat += e.fat; fiber += e.fiber;
    e.micros.forEach((k, v) => micros[k] = (micros[k] ?? 0.0) + v);
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
