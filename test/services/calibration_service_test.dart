// test/services/calibration_service_test.dart
//
// Audit du 19/08/2026 (retour d'Alex — fiabilité du moteur de calibration
// adaptative) : verrouille le comportement de [emaTrend], la fonction de
// lissage dont dépend maintenant directement [CalibrationService
// .computeCalibration] et [CalibrationService.expenditureHistory] (avant
// cet audit, ces deux méthodes comparaient des poids BRUTS, jamais lissés —
// voir tasks/2026-08-19_Audit calculs Profil...md). Seule la fonction pure
// est testable sans dépendance réseau/SharedPreferences ; le reste du
// service est exercé indirectement via `profile_test.dart`
// (`blendCalibratedTargets`).
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/calibration_service.dart';
import 'package:totum_app/services/pause_service.dart';

void main() {
  group('pausedDaysInRangeSync', () {
    // BUG CORRIGÉ (30/08/2026, retour d'Alex — chute de -476 kcal en 2 jours
    // sur son graphique de dépense énergétique dès qu'il s'est mis en pause) :
    // [CalibrationService.expenditureHistory] ne compensait pas la perte de
    // sa pesée la plus ancienne quand la fenêtre glisse sans qu'aucune
    // nouvelle pesée n'arrive pour la remplacer (cas typique d'une pause en
    // cours) — contrairement à [CalibrationService.computeCalibration], qui
    // élargit déjà sa fenêtre en arrière du nombre de jours de pause pour
    // neutraliser exactement ce mécanisme. Ces tests verrouillent la
    // fonction qui porte maintenant ce même élargissement dans
    // [expenditureHistory].
    test('aucune pause -> 0, jamais d\'élargissement', () {
      expect(
        pausedDaysInRangeSync(const [], DateTime(2026, 8, 1), DateTime(2026, 8, 20)),
        0,
      );
    });

    test('pause en cours partiellement dans la plage -> compte seulement les jours qui se recoupent', () {
      final pauses = [PausePeriod(start: DateTime(2026, 8, 29))]; // en cours, end == null
      // Plage [8/9, 8/29] : seul le 29/8 tombe dans la pause -> 1 jour.
      expect(
        pausedDaysInRangeSync(pauses, DateTime(2026, 8, 9), DateTime(2026, 8, 29)),
        1,
      );
      // Plage [8/9, 8/30] : 29/8 ET 30/8 tombent dans la pause (en cours,
      // sans fin) -> 2 jours, exactement le cas d'Alex (pause déclarée le
      // 29/8, graphique consulté le 30/8).
      expect(
        pausedDaysInRangeSync(pauses, DateTime(2026, 8, 9), DateTime(2026, 8, 30)),
        2,
      );
    });

    test('pause déjà terminée -> compte [start, end] inclus, rien après', () {
      final pauses = [
        PausePeriod(start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 15)),
      ];
      expect(
        pausedDaysInRangeSync(pauses, DateTime(2026, 8, 1), DateTime(2026, 8, 20)),
        6, // 10, 11, 12, 13, 14, 15
      );
    });
  });


  group('emaTrend', () {
    test('liste vide -> liste vide', () {
      expect(emaTrend(const []), isEmpty);
    });

    test('1er point = poids brut (rien à lisser)', () {
      final data = [WeighIn(DateTime(2026, 8, 1), 80.0)];
      expect(emaTrend(data), [80.0]);
    });

    test(
        'un pic isolé d\'un jour (rétention d\'eau/cheat meal) n\'a qu\'un effet '
        'BORNÉ et DÉCROISSANT sur la tendance — jamais un saut permanent', () {
      // Poids stable à 80kg, pic à 83kg (+3kg, cas explicitement cité par
      // Alex : "un cheat meal, ça peut être deux ou trois kilos") un seul
      // jour, puis retour à la normale.
      final data = [
        WeighIn(DateTime(2026, 8, 1), 80.0),
        WeighIn(DateTime(2026, 8, 2), 80.0),
        WeighIn(DateTime(2026, 8, 3), 83.0), // pic isolé
        WeighIn(DateTime(2026, 8, 4), 80.0),
        WeighIn(DateTime(2026, 8, 5), 80.0),
      ];
      final trend = emaTrend(data, alpha: 0.1);

      // Le pic ne doit déplacer la tendance que de alpha*(delta) = 0.3kg le
      // jour même — jamais du delta complet (3kg), qui trahirait une
      // absence de lissage.
      expect(trend[2] - trend[1], closeTo(0.3, 0.01));
      // Et la tendance doit ensuite REDESCENDRE (converger de nouveau vers
      // 80) au lieu de rester bloquée sur le pic.
      expect(trend[3], lessThan(trend[2]));
      expect(trend[4], lessThan(trend[3]));
      // Aucun jour ne doit dépasser le pic brut lui-même (pas d'emballement).
      for (final t in trend) {
        expect(t, lessThanOrEqualTo(83.0001));
      }
    });

    test(
        'un écart de plusieurs jours entre 2 pesées composé l\'alpha (rattrape '
        'plus vite un long trou de suivi que si c\'était 1 jour)', () {
      final withGap = emaTrend([
        WeighIn(DateTime(2026, 8, 1), 80.0),
        WeighIn(DateTime(2026, 8, 10), 78.0), // 9 jours d'écart
      ]);
      final withoutGap = emaTrend([
        WeighIn(DateTime(2026, 8, 1), 80.0),
        WeighIn(DateTime(2026, 8, 2), 78.0), // 1 jour d'écart
      ]);
      // Sur un long trou, la tendance doit se rapprocher beaucoup plus du
      // poids réellement mesuré (moins "en retard") que sur un pas d'1 jour.
      expect((withGap[1] - 78.0).abs(), lessThan((withoutGap[1] - 78.0).abs()));
    });
  });
}
