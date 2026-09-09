// test/services/pause_service_test.dart
//
// Verrouille le comportement de [PausePeriod.contains] — en particulier la
// sentinelle "pause annulée le jour même" (19/08/2026, retour d'Alex :
// "il me remet tout le temps en pause après avoir mis je suis de retour").
// Seule la classe pure [PausePeriod] est testable sans dépendance réseau/
// stockage ; [PauseService] lui-même (Supabase + SharedPreferences) est
// exercé manuellement par Alex sur son compte réel.
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/pause_service.dart';

void main() {
  group('PausePeriod.contains', () {
    test('pause en cours (end null) contient toutes les dates depuis start', () {
      final p = PausePeriod(start: DateTime(2026, 8, 10));
      expect(p.contains(DateTime(2026, 8, 10)), isTrue);
      expect(p.contains(DateTime(2026, 8, 15)), isTrue);
      expect(p.contains(DateTime(2026, 8, 9)), isFalse);
    });

    test('pause terminée contient [start, end] inclus, rien après', () {
      final p = PausePeriod(start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12));
      expect(p.contains(DateTime(2026, 8, 10)), isTrue);
      expect(p.contains(DateTime(2026, 8, 11)), isTrue);
      expect(p.contains(DateTime(2026, 8, 12)), isTrue);
      expect(p.contains(DateTime(2026, 8, 13)), isFalse);
      expect(p.contains(DateTime(2026, 8, 9)), isFalse);
    });

    test(
        'BUG CORRIGÉ (19/08/2026) — sentinelle "pause annulée le jour même" '
        '(end = start - 1 jour) ne contient AUCUNE date, y compris start '
        'lui-même : c\'est exactement ce qui doit faire disparaître la '
        'bannière "en pause" après avoir tapé "je suis de retour"', () {
      final start = DateTime(2026, 8, 19);
      final cancelled = PausePeriod(start: start, end: start.subtract(const Duration(days: 1)));
      expect(cancelled.isActive, isFalse, reason: 'end non-null : la bannière ne doit plus afficher "en pause"');
      expect(cancelled.contains(DateTime(2026, 8, 19)), isFalse,
          reason: 'le jour de la pause annulée elle-même ne doit plus être exclu de la calibration');
      expect(cancelled.contains(DateTime(2026, 8, 18)), isFalse);
      expect(cancelled.contains(DateTime(2026, 8, 20)), isFalse);
    });

    test('copyWith ne change que end, jamais start', () {
      final p = PausePeriod(start: DateTime(2026, 8, 10));
      final ended = p.copyWith(end: DateTime(2026, 8, 14));
      expect(ended.start, DateTime(2026, 8, 10));
      expect(ended.end, DateTime(2026, 8, 14));
    });

    test(
        'BUG CORRIGÉ (31/08/2026, retour d\'Alex — pause du 29 au 30/8, '
        '"je suis de retour" le 31/8, journal du 31/8 attendu comptabilisé '
        'le soir même) — le jour où l\'utilisateur appuie sur "Je suis de '
        'retour" ne doit JAMAIS être exclu de la calibration : seuls les '
        'jours réellement absents (start à la veille du retour) doivent '
        'l\'être. [PauseService.endActivePause] doit produire exactement '
        'cet intervalle, jamais end = jour du retour.', () {
      final resumedCorrectly = PausePeriod(
        start: DateTime(2026, 8, 29),
        end: DateTime(2026, 8, 30), // veille du retour, PAS le 31
      );
      expect(resumedCorrectly.contains(DateTime(2026, 8, 29)), isTrue);
      expect(resumedCorrectly.contains(DateTime(2026, 8, 30)), isTrue);
      expect(resumedCorrectly.contains(DateTime(2026, 8, 31)), isFalse,
          reason: 'le jour du retour doit compter normalement dans la calibration dès qu\'il est loggé');
    });
  });
}
