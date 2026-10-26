// test/services/pause_energy_balance_test.dart
//
// Pauses et retour de pause dans le calcul de dépense empirique (26/10/2026,
// retour d'Alex : "je m'étais bien mis en pause ; si au retour j'ai pris
// 3 kg de rétention d'eau ou de repas plaisir, le bouton pause doit servir à
// ça"). Verrouille [estimateEnergyBalance] / [usableWeighIns], le cœur
// UNIQUE partagé par la cible calorique et le graphique.
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/calibration_service.dart';
import 'package:totum_app/services/pause_service.dart';

const _alexKcal = <String, double>{'2026-09-01': 2998.0, '2026-09-02': 2911.0, '2026-09-03': 3230.0, '2026-09-04': 3299.0, '2026-09-05': 3540.0, '2026-09-06': 3189.0, '2026-09-07': 3423.0, '2026-09-08': 3759.0, '2026-09-09': 3497.0, '2026-09-10': 3657.0, '2026-09-11': 3589.0, '2026-09-16': 3479.0, '2026-09-17': 3654.0, '2026-09-18': 3906.0, '2026-09-19': 4383.0, '2026-09-20': 2594.0, '2026-09-21': 3410.0, '2026-09-22': 3785.0, '2026-09-23': 3423.0, '2026-09-24': 3495.0, '2026-09-25': 3761.0, '2026-09-26': 3698.0, '2026-09-29': 3361.0, '2026-09-30': 3568.0, '2026-10-01': 3470.0, '2026-10-02': 3920.0, '2026-10-07': 3262.0, '2026-10-08': 3671.0, '2026-10-09': 3849.0, '2026-10-10': 3387.0, '2026-10-11': 3538.0, '2026-10-12': 3354.0, '2026-10-13': 3332.0, '2026-10-14': 3277.0, '2026-10-15': 3707.0};
const _alexWeights = <String, double>{'2026-08-20': 72.3, '2026-08-21': 72.8, '2026-08-22': 72.85, '2026-08-23': 72.75, '2026-08-24': 72.8, '2026-08-25': 72.25, '2026-08-26': 71.7, '2026-08-27': 72.2, '2026-08-28': 72.5, '2026-08-29': 73.15, '2026-08-31': 72.4, '2026-09-01': 72.35, '2026-09-02': 72.25, '2026-09-03': 71.75, '2026-09-04': 71.55, '2026-09-05': 72.1, '2026-09-06': 71.3, '2026-09-07': 71.65, '2026-09-08': 71.5, '2026-09-09': 72.1, '2026-09-10': 72.8, '2026-09-11': 72.65, '2026-09-15': 72.4, '2026-09-16': 72.1, '2026-09-17': 73.1, '2026-09-18': 72.6, '2026-09-19': 72.55, '2026-09-20': 73.05, '2026-09-21': 73.45, '2026-09-22': 73.0, '2026-09-23': 72.8, '2026-09-24': 72.75, '2026-09-25': 72.25, '2026-09-26': 72.7, '2026-09-28': 72.95, '2026-09-29': 72.85, '2026-09-30': 72.5, '2026-10-01': 72.35, '2026-10-02': 72.7, '2026-10-06': 74.1, '2026-10-07': 73.8, '2026-10-08': 73.15, '2026-10-09': 72.85, '2026-10-10': 73.25, '2026-10-11': 73.95, '2026-10-12': 74.5, '2026-10-13': 73.75, '2026-10-14': 73.4, '2026-10-15': 73.9, '2026-10-16': 73.9};

DateTime _d(String s) => DateTime.parse(s);
String _k(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  test('sans pause : poids stable -> dépense = apport moyen', () {
    final start = DateTime(2026, 9, 1);
    final w = [for (var i = 0; i < 20; i++) WeighIn(start.add(Duration(days: i)), 72.0)];
    final k = {for (var i = 0; i < 20; i++) _k(start.add(Duration(days: i))): 2500.0};
    final e = estimateEnergyBalance(weighIns: w, kcalByDay: k, pauses: const [], today: DateTime(2026, 10, 1))!;
    expect(e.tdee, closeTo(2500, 0.5));
    expect(e.segments, 1);
  });

  test('retour de pause avec +3 kg d\'eau : jamais attribués aux jours suivis', () {
    // 10 jours stables à 72 kg / 2500 kcal, pause de 5 jours (repas non
    // notés), retour à 75 kg qui redescend vers 72,3 kg (eau) puis stable.
    final pause = PausePeriod(start: DateTime(2026, 9, 11), end: DateTime(2026, 9, 15));
    final w = <WeighIn>[
      for (var i = 1; i <= 10; i++) WeighIn(DateTime(2026, 9, i), 72.0),
      WeighIn(DateTime(2026, 9, 16), 75.0),
      WeighIn(DateTime(2026, 9, 17), 74.2),
      WeighIn(DateTime(2026, 9, 18), 73.4),
      for (var i = 19; i <= 30; i++) WeighIn(DateTime(2026, 9, i), 72.3),
    ];
    final k = <String, double>{
      for (var i = 1; i <= 30; i++)
        if (i < 11 || i > 15) _k(DateTime(2026, 9, i)): 2500.0,
    };
    final usable = usableWeighIns(w, [pause]);
    // Les 3 jours de stabilisation (16, 17, 18) sont écartés.
    expect(usable.any((x) => x.date.day >= 16 && x.date.day <= 18), isFalse);
    final e = estimateEnergyBalance(weighIns: usable, kcalByDay: k, pauses: [pause], today: DateTime(2026, 10, 5))!;
    expect(e.segments, 2);
    expect(e.weightChangeKg.abs(), lessThan(0.05));
    expect(e.tdee, closeTo(2500, 30));

    // Contre-épreuve : l'ancien comportement (un seul lissage à travers la
    // pause, sans stabilisation) aurait lu une prise de poids et sous-estimé
    // la dépense de plusieurs centaines de kcal.
    final naive = estimateEnergyBalance(
        weighIns: w, kcalByDay: k, pauses: const [], today: DateTime(2026, 10, 5))!;
    expect(naive.tdee, lessThan(e.tdee - 150));
  });

  test('pause en cours : aucune stabilisation, pesées de pause exclues', () {
    final pause = PausePeriod(start: DateTime(2026, 10, 16));
    final w = [WeighIn(DateTime(2026, 10, 15), 72), WeighIn(DateTime(2026, 10, 18), 75)];
    expect(usableWeighIns(w, [pause]).map((x) => x.date.day), [15]);
  });

  test('données réelles d\'Alex (sept.-oct. 2026) : identique au rejeu indépendant', () {
    // Pauses supposées aux jours sans repas notés (export pause_periods non
    // fourni) — mêmes hypothèses que le rejeu Python du 26/10/2026.
    final pauses = [
      PausePeriod(start: _d('2026-09-12'), end: _d('2026-09-15')),
      PausePeriod(start: _d('2026-09-27'), end: _d('2026-09-28')),
      PausePeriod(start: _d('2026-10-03'), end: _d('2026-10-06')),
      PausePeriod(start: _d('2026-10-16')),
    ];
    final all = [for (final e in _alexWeights.entries) WeighIn(_d(e.key), e.value)]
      ..sort((a, b) => a.date.compareTo(b.date));
    EnergyBalanceEstimate at(DateTime today) {
      final base = today.subtract(const Duration(days: 20));
      final widened = base.subtract(Duration(days: pausedDaysInRangeSync(pauses, base, today)));
      final inWindow = usableWeighIns(all, pauses)
          .where((w) => !w.date.isBefore(widened) && !w.date.isAfter(today))
          .toList();
      return estimateEnergyBalance(weighIns: inWindow, kcalByDay: _alexKcal, pauses: pauses, today: today)!;
    }
    expect(at(DateTime(2026, 10, 15)).tdee, closeTo(3257, 2));
    expect(at(DateTime(2026, 10, 16)).tdee, closeTo(3272, 2));
    expect(at(DateTime(2026, 10, 2)).tdee, closeTo(3229, 2));
    // Le saut de +1,4 kg pendant la pause du 3-6/10 n'est plus imputé :
    expect(at(DateTime(2026, 10, 16)).weightChangeKg, lessThan(0.3));
  });
}
