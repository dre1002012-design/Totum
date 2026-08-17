// test/services/units_test.dart
//
// Priorité 66 (audit global) : conversions métrique <-> impérial. Ciblé
// notamment sur l'affichage pieds/pouces (formatHeight), où un arrondi
// composé (pieds puis pouces séparément) est un piège classique — voir le
// test de "débordement à 12 pouces" ci-dessous.
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/units.dart';

void main() {
  group('conversions round-trip', () {
    test('kg <-> lb aller-retour proche de la valeur d\'origine', () {
      for (final kg in [45.0, 60.5, 75.0, 90.3, 120.0]) {
        final roundTrip = Units.lbToKg(Units.kgToLb(kg));
        expect(roundTrip, closeTo(kg, 0.001));
      }
    });

    test('cm <-> in aller-retour proche de la valeur d\'origine', () {
      for (final cm in [150.0, 165.5, 178.0, 190.2]) {
        final roundTrip = Units.inToCm(Units.cmToIn(cm));
        expect(roundTrip, closeTo(cm, 0.001));
      }
    });

    test('valeurs de référence connues', () {
      // 1 kg ≈ 2.2046 lb ; 1 lb ≈ 0.4536 kg ; 1 in = 2.54 cm.
      expect(Units.kgToLb(1.0), closeTo(2.2046, 0.001));
      expect(Units.lbToKg(1.0), closeTo(0.4536, 0.001));
      expect(Units.cmToIn(2.54), closeTo(1.0, 0.0001));
      expect(Units.inToCm(1.0), equals(2.54));
    });
  });

  group('formatHeight (impérial, pieds/pouces)', () {
    test('ne doit jamais afficher 12 pouces — doit reporter sur le pied suivant',
        () {
      // 71.5 pouces = 5 pieds + 11.5 pouces, qui arrondit (arrondi simple)
      // à 12 pouces si les pieds et les pouces sont arrondis indépendamment
      // au lieu d'être arrondis ENSEMBLE avant de re-séparer pieds/pouces.
      final cm = Units.inToCm(71.5);
      final formatted = Units.formatHeight(cm, UnitSystem.imperial);
      expect(formatted, isNot(contains('12"')),
          reason:
              'formatHeight a produit "$formatted" — 12 pouces doit devenir 1 pied de plus, pas s\'afficher tel quel');
    });

    test('cas simple, sans arrondi ambigu', () {
      final cm = Units.inToCm(70.0); // 5'10"
      expect(Units.formatHeight(cm, UnitSystem.imperial), '5\'10"');
    });

    test('métrique : arrondi à l\'entier le plus proche', () {
      expect(Units.formatHeight(178.4, UnitSystem.metric), '178 cm');
      expect(Units.formatHeight(178.6, UnitSystem.metric), '179 cm');
    });
  });

  group('formatWeight', () {
    test('métrique : entier si rond, sinon 1 décimale', () {
      expect(Units.formatWeight(75.0, UnitSystem.metric), '75 kg');
      expect(Units.formatWeight(75.5, UnitSystem.metric), '75.5 kg');
    });

    test('impérial : toujours 1 décimale', () {
      expect(Units.formatWeight(Units.lbToKg(150.0), UnitSystem.imperial),
          '150.0 lb');
    });
  });

  group('weightToKg / heightToCm — cohérence avec displayWeight / displayHeight',
      () {
    test('un aller-retour affichage -> stockage -> affichage ne dérive pas',
        () {
      for (final system in UnitSystem.values) {
        const kg = 82.3;
        final displayed = Units.displayWeight(kg, system);
        final backToKg = Units.weightToKg(displayed, system);
        expect(backToKg, closeTo(kg, 0.01), reason: 'system=$system');
      }
    });
  });
}
