// « Les essentiels du quotidien » (staple_foods.dart, 31/10/2026) : la liste
// par défaut du « + » doit montrer des aliments courants, complets et
// nommés clairement — jamais un code disparu, un aliment sans énergie ou
// deux libellés identiques.
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/foods_loader.dart';
import 'package:totum_app/services/food_portions.dart';
import 'package:totum_app/services/staple_foods.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chaque essentiel existe, a une énergie connue et un nom unique', () async {
    final repo = FoodsRepository();
    await repo.loadFromAsset('assets/foods.csv');
    expect(kStapleCiqualCodes.toSet().length, kStapleCiqualCodes.length,
        reason: 'code en double dans la liste');
    expect(kStapleCiqualCodes.length, greaterThanOrEqualTo(120));

    final shownNames = <String, int>{};
    for (final f in repo.items) {
      final n = displayNameOf(f, f.name).toLowerCase();
      shownNames[n] = (shownNames[n] ?? 0) + 1;
    }
    for (final code in kStapleCiqualCodes) {
      final f = repo.findById('ciqual:$code');
      expect(f, isNotNull, reason: 'ciqual:$code absent de foods.csv');
      expect(f!.kcal100, isNotNull, reason: '${f.name} : énergie inconnue');
      expect(f.pictogramme, isNotNull, reason: '${f.name} : pas de pictogramme');
      final shown = displayNameOf(f, f.name);
      expect(shownNames[shown.toLowerCase()], 1, reason: '« $shown » affiché pour 2 aliments');
      expect(shown.length, lessThanOrEqualTo(60), reason: '« $shown » trop long pour la liste');
    }
    expect(stapleRank('ciqual:${kStapleCiqualCodes.first}'), 0);
    expect(isStapleFood('ciqual:1'), isFalse);
  });

  test('portions ménagères : chaque essentiel en a une, plausible', () async {
    final repo = FoodsRepository.instance;
    await repo.loadFromAsset('assets/foods.csv');
    for (final code in kStapleCiqualCodes) {
      final ps = repo.portionsFor('ciqual:$code');
      expect(ps, isNotEmpty, reason: 'ciqual:$code sans portion');
      for (final p in ps) {
        expect(p.grams, inInclusiveRange(1, 400), reason: 'ciqual:$code ${p.label}');
        expect(p.labelEn, isNotNull);
      }
    }
    for (final code in householdPortionCodes) {
      expect(kStapleCiqualCodes, contains(code), reason: 'portion orpheline ciqual:$code');
    }
    // Les pièges du « 100 g par défaut » : huile, œuf, café.
    expect(repo.portionsFor('ciqual:17270').first.grams, 10);
    expect(repo.portionsFor('ciqual:22000').first.grams, 50);
    expect(repo.portionsFor('ciqual:18071').first.grams, 40);
    // Repère par famille pour un aliment hors essentiels (huile de noix).
    expect(repo.portionsFor('ciqual:17220').first.grams, 10);
    // Plats : repères usuels (part de pizza, assiette de plat composé).
    final pizza = repo.items.firstWhere((f) => f.name.startsWith('Pizza'));
    expect(repo.portionsFor(pizza.id).first.grams, 120);
    final plat = repo.items.firstWhere((f) => f.sousGroupe == 'plats composés');
    expect(repo.portionsFor(plat.id).first.grams, 300);
  });
}
