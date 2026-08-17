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

/// Totaux réellement logués un jour donné.
Future<DayTotals> computeDayTotals(DateTime day) async {
  await _ensureFoodsLoaded();
  final repo = FoodsRepository.instance;
  final ymd = _dateKey(day);

  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
  final micros = <String, double>{};
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

          kcal += (r['energy_kcal'] as num?)?.toDouble() ?? 0.0;
          prot += (r['protein_g'] as num?)?.toDouble() ?? 0.0;
          carb += (r['carbs_g'] as num?)?.toDouble() ?? 0.0;
          fat  += (r['fat_g'] as num?)?.toDouble() ?? 0.0;
          fiber += (r['fiber_g'] as num?)?.toDouble() ?? 0.0;

          final snap = r['micros'];
          if (snap is Map && snap.isNotEmpty) {
            snap.forEach((k, v) {
              final d = (v is num) ? v.toDouble() : 0.0;
              micros[k.toString()] = (micros[k.toString()] ?? 0.0) + d;
            });
          } else if (id.isNotEmpty) {
            final food = repo.findById(id);
            if (food != null) {
              food.microsFor(grams).forEach((k, v) => micros[k] = (micros[k] ?? 0) + v);
            }
          }
        }
        gotSupabaseData = (kcal + prot + carb + fat + fiber) > 0 || micros.isNotEmpty;
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
        kcal = 0; prot = 0; carb = 0; fat = 0; fiber = 0;
        micros.clear();
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
      } catch (_) {
        kcal = 0; prot = 0; carb = 0; fat = 0; fiber = 0;
        micros.clear();
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
