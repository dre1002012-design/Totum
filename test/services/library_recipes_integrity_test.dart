// Bibliothèque de recettes TOTUM (assets/totum_recipes*.json) — garde-fous
// ajoutés le 31/10/2026 après l'audit : les valeurs nutritionnelles des
// recettes avaient été calculées sur une ANCIENNE version de foods.csv
// (B9 moitié trop basse, sélénium ×2, vitamine E absente de 162 recettes…),
// et l'étiquette « hyperprotéiné » était posée à la main de façon
// incohérente. Ces tests recalculent chaque recette depuis la base réelle :
// toute dérive future (mise à jour CIQUAL, recette modifiée à la main) les
// fait échouer.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/foods_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FoodsRepository repo;
  late List<Map<String, dynamic>> fr;
  late List<Map<String, dynamic>> en;

  List<Map<String, dynamic>> load(String path) =>
      ((jsonDecode(File(path).readAsStringSync()) as Map)['recipes'] as List)
          .cast<Map<String, dynamic>>();

  setUpAll(() async {
    repo = FoodsRepository();
    await repo.loadFromAsset('assets/foods.csv');
    fr = load('assets/totum_recipes.json');
    en = load('assets/totum_recipes_en.json');
  });

  test('FR et EN : mêmes recettes, mêmes ingrédients, mêmes valeurs', () {
    expect(fr.length, en.length);
    expect(fr.length, greaterThanOrEqualTo(192));
    for (var i = 0; i < fr.length; i++) {
      final a = fr[i], b = en[i];
      expect(b['id'], a['id']);
      expect(b['category'], a['category']);
      expect(jsonEncode(b['ingredients']), jsonEncode(a['ingredients']), reason: '${a['id']}');
      for (final k in ['kcal100', 'prot100', 'carb100', 'fat100', 'fiber100', 'total_weight_g']) {
        expect(b[k], a[k], reason: '${a['id']} $k');
      }
      expect(jsonEncode(b['micros100']), jsonEncode(a['micros100']), reason: '${a['id']}');
    }
  });

  test('chaque recette est raccord avec la base d\'aliments actuelle', () {
    const cats = {'Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation', 'Pré-workout'};
    for (final r in fr) {
      final id = r['id'];
      expect(cats, contains(r['category']), reason: '$id');
      final ings = (r['ingredients'] as List).cast<Map<String, dynamic>>();
      final weight = ings.fold<double>(0, (s, i) => s + (i['grams'] as num).toDouble());
      expect((r['total_weight_g'] as num).toDouble(), closeTo(weight, 0.1), reason: '$id');
      double kcal = 0, prot = 0, carb = 0, fat = 0, fib = 0, b9 = 0, vitE = 0;
      for (final i in ings) {
        final f = repo.findById('ciqual:${i['foodId']}');
        expect(f, isNotNull, reason: '$id : ingrédient ${i['foodId']} absent de la base');
        expect(f!.kcal100, isNotNull, reason: '$id : ${f.name} sans énergie connue');
        final g = (i['grams'] as num).toDouble() / 100;
        kcal += f.kcal100! * g;
        prot += (f.prot100 ?? 0) * g;
        carb += (f.carb100 ?? 0) * g;
        fat += (f.fat100 ?? 0) * g;
        fib += (f.fiber100 ?? 0) * g;
        b9 += (f.micros100['Vitamine_B9_µg_100g'] ?? 0) * g;
        vitE += (f.micros100['Vitamine_E_mg_100g'] ?? 0) * g;
      }
      final k = 100 / weight;
      void near(String key, double calc) {
        final stored = (r[key] as num).toDouble();
        expect(stored, closeTo(calc * k, 0.02 + 0.01 * calc * k), reason: '$id $key');
      }
      near('kcal100', kcal);
      near('prot100', prot);
      near('carb100', carb);
      near('fat100', fat);
      near('fiber100', fib);
      final m = (r['micros100'] as Map).cast<String, num>();
      expect((m['Vitamine_B9_µg_100g'] ?? 0).toDouble(), closeTo(b9 * k, 0.01 + 0.01 * b9 * k),
          reason: '$id B9');
      expect((m['Vitamine_E_mg_100g'] ?? 0).toDouble(), closeTo(vitE * k, 0.01 + 0.01 * vitE * k),
          reason: '$id vitamine E');
    }
  });

  test('« hyperprotéiné » = règle de goalTags (≥ 30 g par repas, ≥ 15 g par collation)', () {
    for (final r in fr) {
      final portionProt = (r['prot100'] as num) * (r['total_weight_g'] as num) / 100;
      final floor = r['category'] == 'Collation' ? 15 : 30;
      expect((r['tags'] as List).contains('hyperproteine'), portionProt >= floor,
          reason: '${r['id']} ${r['name']} : ${portionProt.toStringAsFixed(1)} g');
    }
  });

  test('végétalien / végétarien : aucun ingrédient incompatible', () {
    const flesh = {
      'viandes crues', 'viandes cuites', 'poissons crus', 'poissons cuits',
      'mollusques et crustacés crus', 'mollusques et crustacés cuits',
      'charcuteries et alternatives végétales', 'produits à base de poissons et produits de la mer',
    };
    for (final r in fr) {
      final tags = (r['tags'] as List).cast<String>();
      final vegan = tags.contains('vegetalien');
      final veggie = vegan || tags.contains('vegetarien');
      for (final i in (r['ingredients'] as List).cast<Map<String, dynamic>>()) {
        final f = repo.findById('ciqual:${i['foodId']}')!;
        if (veggie) {
          expect(flesh.contains(f.sousGroupe), isFalse, reason: '${r['id']} : ${f.name}');
        }
        if (vegan) {
          final n = f.name.toLowerCase();
          expect(f.groupe == 'produits laitiers' || f.sousGroupe == 'oeufs' ||
                  n.startsWith('miel') || n.startsWith('oeuf') || n.startsWith('whey'),
              isFalse, reason: '${r['id']} (végétalien) : ${f.name}');
        }
      }
    }
  });
}
