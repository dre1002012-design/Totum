// Énergie manquante dans la table ANSES-CIQUAL (audit du 25/10/2026) :
// calculée selon le règlement (UE) 1169/2011 quand les 3 macros sont
// connues, jamais inventée sinon (voir energyFromMacros, foods_loader.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/foods_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coefficients du règlement UE 1169/2011 (annexe XIV)', () {
    // Canneberge crue (CIQUAL) : P 0,88 · G 7,6 · L 0,17 · fibres 5,65
    expect(energyFromMacros(prot: 0.88, carb: 7.6, fat: 0.17, fiber: 5.65, alcohol: 0),
        closeTo(4 * 0.88 + 4 * 7.6 + 9 * 0.17 + 2 * 5.65, 0.05));
    expect(energyFromMacros(prot: 10, carb: 0, fat: 0, alcohol: 10), 110);
  });

  test('une macro inconnue : aucune énergie inventée', () {
    expect(energyFromMacros(prot: 20, carb: 0, fat: null), isNull);
    expect(energyFromMacros(prot: null, carb: 5, fat: 1), isNull);
  });

  test('base réelle : plus aucun aliment à "0 kcal" avec des macros complètes', () async {
    final repo = FoodsRepository();
    await repo.loadFromAsset('assets/foods.csv');
    final items = repo.items;
    expect(items.length, greaterThan(3000));
    final canneberge = items.firstWhere((f) => f.name.startsWith('Canneberge'));
    expect(canneberge.kcal100, closeTo(46.8, 0.2));
    final brochette = items.firstWhere((f) => f.name == 'Brochette de boeuf, crue');
    expect(brochette.energyUnknown, isTrue, reason: 'lipides non mesurés par l\'ANSES');
    final complete = items.where((f) =>
        f.energyUnknown && f.prot100 != null && f.carb100 != null && f.fat100 != null);
    expect(complete, isEmpty);
    expect(items.where((f) => f.name.contains('  ')), isEmpty);
  });
}
