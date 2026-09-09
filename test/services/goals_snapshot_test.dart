// test/services/goals_snapshot_test.dart
//
// Verrouille readGoalsSnapshotForDate() (profile.dart) — Priorité 71bis
// (20/08/2026, retour d'Alex : "tout est recalqué sur l'objectif
// d'aujourd'hui même en remontant dans le journal"). Supabase n'étant pas
// initialisé dans ce test, la fonction bascule automatiquement sur son
// repli local (SharedPreferences `goals_snapshots_v1`, le même cache que
// bilan_screen.dart) — c'est exactement ce chemin qu'on verrouille ici.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totum_app/services/profile.dart';

Map<String, dynamic> _snapshot(String date, double kcal) => {
      'date': date,
      'kcal': kcal, 'prot': 150.0, 'carb': 200.0, 'fat': 80.0, 'fiber': 30.0,
      'sat': 20.0, 'o9': 15.0, 'o6': 10.0, 'o3': 2.0, 'epa': 0.5, 'dha': 0.5,
      'sugars': 40.0, 'salt': 5.0,
      'caMg': 900.0, 'cuMg': 1.5, 'feMg': 10.0, 'iUg': 150.0,
      'mgMg': 350.0, 'mnMg': 2.0, 'pMg': 700.0, 'kMg': 3500.0,
      'seUg': 55.0, 'naMg': 2000.0, 'znMg': 10.0,
      'vitAUg': 800.0, 'vitBetacarUg': 1000.0, 'vitDUg': 15.0, 'vitEMg': 12.0,
      'vitKUg': 75.0, 'vitCMg': 90.0,
      'b1Mg': 1.2, 'b2Mg': 1.3, 'b3Mg': 16.0, 'b5Mg': 5.0, 'b6Mg': 1.5,
      'b9Ug': 300.0, 'b12Ug': 2.5,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'BUG CORRIGÉ (20/08/2026) — un jour passé retrouve son propre objectif '
      'historique (kcal notamment), pas celui d\'aujourd\'hui', () async {
    SharedPreferences.setMockInitialValues({
      'goals_snapshots_v1': jsonEncode([
        _snapshot('2026-08-19', 3090.0),
        _snapshot('2026-08-20', 2660.0),
      ]),
    });

    final aug19 = await readGoalsSnapshotForDate(DateTime(2026, 8, 19));
    final aug20 = await readGoalsSnapshotForDate(DateTime(2026, 8, 20));

    expect(aug19, isNotNull);
    expect(aug19!.goals.kcal, 3090.0);
    expect(aug20, isNotNull);
    expect(aug20!.goals.kcal, 2660.0);
    // Les deux jours doivent rester distincts — pas de "dernier snapshot
    // écrase tout", exactement le bug rapporté par Alex.
    expect(aug19.goals.kcal, isNot(aug20.goals.kcal));
  });

  test('retourne null pour une date sans instantané (jour antérieur au suivi)', () async {
    SharedPreferences.setMockInitialValues({
      'goals_snapshots_v1': jsonEncode([_snapshot('2026-08-20', 2660.0)]),
    });

    final noHistory = await readGoalsSnapshotForDate(DateTime(2026, 6, 1));
    expect(noHistory, isNull);
  });

  test('retourne null si aucun cache local n\'existe du tout', () async {
    SharedPreferences.setMockInitialValues({});
    final result = await readGoalsSnapshotForDate(DateTime(2026, 8, 20));
    expect(result, isNull);
  });
}
