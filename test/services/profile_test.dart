// test/services/profile_test.dart
//
// Priorité 66 (audit global, "je veux que l'application soit totalement
// fiable") : premier socle de tests, volontairement centré sur
// services/profile.dart — le moteur de calcul nutritionnel (BMR/TDEE,
// objectifs caloriques, macros, micronutriments). C'est la surface la plus
// critique de l'app (une app de santé/nutrition qui affiche un mauvais
// chiffre perd la confiance de l'utilisateur immédiatement) et la plus
// isolée/testable (fonctions pures, aucune dépendance réseau/stockage pour
// le calcul lui-même). Teste uniquement l'API PUBLIQUE du fichier — les
// fonctions privées (_bmrMifflin, _goalEnergyAdjustmentKcal...) sont
// exercées indirectement, exactement comme l'app les utilise réellement.
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/profile.dart';

UserProfile _profile({
  Sex sex = Sex.male,
  int age = 30,
  double heightCm = 178,
  double weightKg = 75,
  ActivityLevel activity = ActivityLevel.moderate,
  GoalType goal = GoalType.maintain,
  double? bodyFatPercent,
  double? targetWeightKg,
  DietStyle dietStyle = DietStyle.balanced,
  double? activityPalOverride,
}) =>
    UserProfile(
      sex: sex,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      activity: activity,
      goal: goal,
      bodyFatPercent: bodyFatPercent,
      targetWeightKg: targetWeightKg,
      dietStyle: dietStyle,
      activityPalOverride: activityPalOverride,
    );

void main() {
  group('computeBmr', () {
    test('sans % masse grasse, suit exactement Mifflin-St Jeor (homme)', () {
      final p = _profile(sex: Sex.male, age: 30, heightCm: 178, weightKg: 75);
      // Mifflin-St Jeor homme : 10*poids + 6.25*taille - 5*âge + 5
      const expected = 10 * 75 + 6.25 * 178 - 5 * 30 + 5;
      expect(computeBmr(p), closeTo(expected, 0.01));
    });

    test('sans % masse grasse, suit exactement Mifflin-St Jeor (femme)', () {
      final p =
          _profile(sex: Sex.female, age: 28, heightCm: 165, weightKg: 60);
      const expected = 10 * 60 + 6.25 * 165 - 5 * 28 - 161;
      expect(computeBmr(p), closeTo(expected, 0.01));
    });

    test('avec % masse grasse valide, bascule sur Cunningham (500 + 22*LBM)',
        () {
      final p = _profile(weightKg: 80, bodyFatPercent: 15);
      const lbm = 80 * (1 - 15 / 100.0);
      const expected = 500 + 22 * lbm;
      expect(computeBmr(p), closeTo(expected, 0.01));
    });

    test(
        'bf=2 (plancher physiologique) utilise déjà Cunningham, pas Mifflin '
        '— régression du bug de seuil ">4" vs ">=2" documenté dans le code',
        () {
      final withBf = computeBmr(_profile(weightKg: 80, bodyFatPercent: 2));
      const lbm = 80 * (1 - 2 / 100.0);
      const expectedCunningham = 500 + 22 * lbm;
      expect(withBf, closeTo(expectedCunningham, 0.01));
    });

    test('bf=60 (hors plage physiologique) retombe sur Mifflin, pas Cunningham',
        () {
      final p = _profile(
          sex: Sex.male, age: 30, heightCm: 178, weightKg: 75, bodyFatPercent: 60);
      const expectedMifflin = 10 * 75 + 6.25 * 178 - 5 * 30 + 5;
      expect(computeBmr(p), closeTo(expectedMifflin, 0.01));
    });

    test('le BMR ne dépend jamais du niveau d\'activité', () {
      final sedentary = computeBmr(_profile(activity: ActivityLevel.sedentary));
      final extreme = computeBmr(_profile(activity: ActivityLevel.extreme));
      expect(sedentary, equals(extreme));
    });
  });

  group('computeGoals — cohérence des calories selon l\'objectif', () {
    test('maintain sans poids cible = TDEE exact (aucun ajustement)', () {
      final p = _profile(goal: GoalType.maintain);
      final bmr = computeBmr(p);
      // PAL modéré = 1.48 (voir _activityFactor)
      final expectedTdee = bmr * 1.48;
      final goals = computeGoals(p);
      expect(goals.kcal, closeTo(expectedTdee, 15)); // tolérance = arrondi à 10 kcal
    });

    test('lose < maintain < gain, à profil égal', () {
      final maintain = computeGoals(_profile(goal: GoalType.maintain)).kcal;
      final lose = computeGoals(_profile(goal: GoalType.lose)).kcal;
      final gain = computeGoals(_profile(goal: GoalType.gain)).kcal;
      expect(lose, lessThan(maintain));
      expect(gain, greaterThan(maintain));
    });

    test('loseMild est un déficit plus doux que lose', () {
      final lose = computeGoals(_profile(goal: GoalType.lose)).kcal;
      final loseMild = computeGoals(_profile(goal: GoalType.loseMild)).kcal;
      final maintain = computeGoals(_profile(goal: GoalType.maintain)).kcal;
      expect(loseMild, greaterThan(lose));
      expect(loseMild, lessThan(maintain));
    });

    test(
        'senior (60+) a un déficit plus conservateur qu\'un jeune adulte, '
        'pour le même objectif "lose"', () {
      final young =
          computeGoals(_profile(age: 30, goal: GoalType.lose)).kcal;
      final senior =
          computeGoals(_profile(age: 65, goal: GoalType.lose)).kcal;
      final maintainYoung =
          computeGoals(_profile(age: 30, goal: GoalType.maintain)).kcal;
      final maintainSenior =
          computeGoals(_profile(age: 65, goal: GoalType.maintain)).kcal;
      // Écart au maintien : doit être plus petit (en valeur absolue) chez le senior.
      final deficitYoung = maintainYoung - young;
      final deficitSenior = maintainSenior - senior;
      expect(deficitSenior, lessThan(deficitYoung));
    });
  });

  group('computeGoals — style alimentaire (régression Priorité 65)', () {
    // Le bug corrigé dans conseils_screen.dart (_buildAdviceTargets)
    // recalculait un split fixe 55%/35% glucides/lipides à partir des
    // calories, en ignorant complètement le style alimentaire — un profil
    // kéto y voyait une cible glucides ~9x trop élevée. Ce test verrouille
    // le comportement CORRECT de la source de vérité (computeGoals) pour
    // qu'une régression future soit détectée immédiatement, ici, avant même
    // d'atteindre l'écran.
    test('kéto : glucides toujours fixés à 30g, quel que soit le profil', () {
      for (final p in [
        _profile(dietStyle: DietStyle.keto, goal: GoalType.lose),
        _profile(dietStyle: DietStyle.keto, goal: GoalType.gain, weightKg: 95),
        _profile(dietStyle: DietStyle.keto, sex: Sex.female, weightKg: 55),
      ]) {
        expect(computeGoals(p).carb, equals(30.0));
      }
    });

    test('kéto donne des glucides très inférieurs à un profil équilibré équivalent',
        () {
      final keto = computeGoals(_profile(dietStyle: DietStyle.keto));
      final balanced = computeGoals(_profile(dietStyle: DietStyle.balanced));
      expect(keto.carb, lessThan(balanced.carb * 0.2));
    });

    test('riche en glucides > équilibré > riche en lipides, sur les glucides',
        () {
      final highCarb = computeGoals(_profile(dietStyle: DietStyle.highCarb)).carb;
      final balanced = computeGoals(_profile(dietStyle: DietStyle.balanced)).carb;
      final highFat = computeGoals(_profile(dietStyle: DietStyle.highFat)).carb;
      expect(highCarb, greaterThan(balanced));
      expect(balanced, greaterThan(highFat));
    });

    test('les lipides ne dépassent jamais le plafond AMDR de 35% des kcal '
        '(sauf kéto, qui vise par construction des lipides élevés)', () {
      for (final style in [
        DietStyle.balanced,
        DietStyle.highCarb,
        DietStyle.highFat,
      ]) {
        final g = computeGoals(_profile(dietStyle: style));
        final fatPct = (g.fat * 9.0) / g.kcal * 100;
        expect(fatPct, lessThanOrEqualTo(35.5), reason: 'style=$style');
      }
    });
  });

  group('computeGoals — bornes de sécurité', () {
    test('les protéines restent dans la fourchette 1.0-2.5 g/kg de poids', () {
      for (final activity in ActivityLevel.values) {
        for (final goal in GoalType.values) {
          final p = _profile(activity: activity, goal: goal, weightKg: 70);
          final prot = computeGoals(p).prot;
          expect(prot, greaterThanOrEqualTo(70 * 1.0 - 0.5));
          expect(prot, lessThanOrEqualTo(70 * 2.5 + 0.5));
        }
      }
    });

    test('les fibres restent bornées entre 25g et 45g même à calories extrêmes',
        () {
      final veryLow = computeGoals(
          _profile(weightKg: 40, activity: ActivityLevel.sedentary, goal: GoalType.lose));
      final veryHigh = computeGoals(
          _profile(weightKg: 130, activity: ActivityLevel.extreme, goal: GoalType.gain));
      expect(veryLow.fiber, greaterThanOrEqualTo(25.0));
      expect(veryHigh.fiber, lessThanOrEqualTo(45.0));
    });

    test('prot + carb + fat en kcal ne dépasse jamais sensiblement les calories cibles',
        () {
      // Garde-fou contre le cas théorique #7 relevé par l'audit (protéines
      // maximales + kcal très basses pourrait, en théorie, faire déborder
      // la somme des macros au-delà de la cible calorique).
      for (final goal in GoalType.values) {
        for (final style in DietStyle.values) {
          final p = _profile(
            weightKg: 45,
            activity: ActivityLevel.extreme,
            goal: goal,
            dietStyle: style,
            age: 55,
          );
          final g = computeGoals(p);
          final macroKcal = g.prot * 4 + g.carb * 4 + g.fat * 9;
          // Tolérance généreuse (10%) : ces bornes existent pour des cas
          // extrêmes très improbables, pas pour un profil-type.
          expect(macroKcal, lessThanOrEqualTo(g.kcal * 1.10),
              reason: 'goal=$goal style=$style');
        }
      }
    });

    test(
        'kcal ne descend jamais sous le plancher de sécurité (RED-S/dérèglement hormonal — Priorité 71)',
        () {
      // Petit gabarit + déficit "lose" : sans garde-fou, atterrit sous les
      // 1000 kcal/jour (cas réel repéré par l\'audit du 17/08/2026).
      final p = _profile(
        sex: Sex.female,
        age: 25,
        heightCm: 155,
        weightKg: 48,
        activity: ActivityLevel.sedentary,
        goal: GoalType.lose,
      );
      final g = computeGoals(p);
      final bmr = computeBmr(p);
      expect(g.kcal, greaterThanOrEqualTo(minSafeKcalFor(Sex.female, bmr)));
      expect(g.kcal, greaterThanOrEqualTo(1200.0));
    });

    test(
        'minSafeKcalFor retient le plus élevé entre le plancher absolu par sexe et 90% du BMR',
        () {
      expect(minSafeKcalFor(Sex.female, 1000), 1200.0); // plancher absolu domine
      expect(minSafeKcalFor(Sex.male, 2000), 1800.0); // 90% du BMR domine
    });
  });

  group('nearestActivityLevel', () {
    test('couvre les 6 paliers dans l\'ordre croissant du PAL', () {
      expect(nearestActivityLevel(1.20), ActivityLevel.sedentary);
      expect(nearestActivityLevel(1.35), ActivityLevel.light);
      expect(nearestActivityLevel(1.48), ActivityLevel.moderate);
      expect(nearestActivityLevel(1.62), ActivityLevel.active);
      expect(nearestActivityLevel(1.78), ActivityLevel.veryActive);
      expect(nearestActivityLevel(1.95), ActivityLevel.extreme);
    });
  });

  group('goalRateBwPerWeekFor', () {
    test('lose est toujours négatif, gain toujours positif, maintain nul', () {
      expect(goalRateBwPerWeekFor(GoalType.lose, 30), lessThan(0));
      expect(goalRateBwPerWeekFor(GoalType.loseMild, 30), lessThan(0));
      expect(goalRateBwPerWeekFor(GoalType.gain, 30), greaterThan(0));
      expect(goalRateBwPerWeekFor(GoalType.gainMild, 30), greaterThan(0));
      expect(goalRateBwPerWeekFor(GoalType.maintain, 30), equals(0.0));
    });

    test('un senior (60+) obtient un rythme "lose" plus conservateur qu\'un jeune',
        () {
      final young = goalRateBwPerWeekFor(GoalType.lose, 30).abs();
      final senior = goalRateBwPerWeekFor(GoalType.lose, 65).abs();
      expect(senior, lessThan(young));
    });

    test('un profil déjà sec (lean) obtient un rythme "lose" plus conservateur',
        () {
      final normal = goalRateBwPerWeekFor(GoalType.lose, 30,
              sex: Sex.male, bodyFatPercent: 20)
          .abs();
      final lean = goalRateBwPerWeekFor(GoalType.lose, 30,
              sex: Sex.male, bodyFatPercent: 10)
          .abs();
      expect(lean, lessThan(normal));
    });
  });

  group('computeEnergyBreakdown', () {
    test('kcal (cible finale) - bmr = mouvement + ajustement objectif, jamais négatif',
        () {
      final p = _profile(goal: GoalType.maintain);
      final b = computeEnergyBreakdown(p);
      expect(b.bmr, greaterThan(0));
      expect(b.tdee, greaterThan(b.bmr)); // le PAL est toujours > 1
      expect(b.movementKcal, greaterThanOrEqualTo(0));
    });
  });

  group('computeNutritionTargets — cohérence globale', () {
    test('les cibles nutritionnelles reprennent exactement les mêmes calories que computeGoals',
        () {
      final p = _profile();
      final targets = computeNutritionTargets(p);
      final goals = computeGoals(p);
      expect(targets.goals.kcal, equals(goals.kcal));
    });

    test('ALA et LA respectent toujours les planchers ANSES (1% / 4% des calories)',
        () {
      final p = _profile();
      final t = computeNutritionTargets(p);
      final alaFloorG = (t.goals.kcal * 0.01) / 9.0;
      final laFloorG = (t.goals.kcal * 0.04) / 9.0;
      expect(t.o3, closeTo(alaFloorG, 0.15));
      expect(t.o6, closeTo(laFloorG, 0.15));
    });

    test('B1/B3 augmentent avec les calories (expression ANSES en mg/MJ, pas fixe)',
        () {
      final low = computeNutritionTargets(
          _profile(weightKg: 45, activity: ActivityLevel.sedentary, goal: GoalType.lose));
      final high = computeNutritionTargets(
          _profile(weightKg: 100, activity: ActivityLevel.extreme, goal: GoalType.gain));
      expect(high.b1Mg, greaterThanOrEqualTo(low.b1Mg));
      expect(high.b3Mg, greaterThanOrEqualTo(low.b3Mg));
    });

    test('B2 augmente avec les calories, comme B1/B3 (régression Priorité 71 — restait figée à 1,6mg)',
        () {
      final low = computeNutritionTargets(
          _profile(weightKg: 45, activity: ActivityLevel.sedentary, goal: GoalType.lose));
      final high = computeNutritionTargets(
          _profile(weightKg: 100, activity: ActivityLevel.extreme, goal: GoalType.gain));
      expect(high.b2Mg, greaterThan(low.b2Mg));
      expect(low.b2Mg, greaterThanOrEqualTo(1.6)); // plancher toujours respecté
    });

    test('la vitamine K augmente avec le poids corporel (régression Priorité 71 — restait figée à 79µg)',
        () {
      final light = computeNutritionTargets(_profile(weightKg: 50));
      final heavy = computeNutritionTargets(_profile(weightKg: 110));
      expect(heavy.vitKUg, greaterThan(light.vitKUg));
      expect(light.vitKUg, closeTo(50.0, 0.5));
      expect(heavy.vitKUg, closeTo(110.0, 0.5));
    });

    test(
        'le calcium se relève aussi pour un homme senior (65+), pas seulement une femme 50+ (régression Priorité 71)',
        () {
      final youngMan = computeNutritionTargets(_profile(sex: Sex.male, age: 30));
      final seniorMan = computeNutritionTargets(_profile(sex: Sex.male, age: 70));
      final olderWoman = computeNutritionTargets(_profile(sex: Sex.female, age: 55));
      expect(youngMan.caMg, 950.0);
      expect(seniorMan.caMg, 1200.0);
      expect(olderWoman.caMg, 1200.0);
    });
  });
}
