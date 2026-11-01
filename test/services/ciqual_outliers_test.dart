// Valeurs CIQUAL aberrantes corrigées le 01/11/2026
// (scripts/fix_ciqual_outliers.py, ancienne valeur tracée dans
// Corrections_Proposees.csv). Depuis le partage 3.0, chaque aliment affiche
// SES apports sur un visuel public : une seule valeur fausse devient une
// affirmation fausse (« Café : vitamine B6 107 % », « Pomme de terre :
// sélénium 50 % »). Ce test empêche leur retour (réimport de la table…).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<String> _split(String line) {
  final res = <String>[];
  final buf = StringBuffer();
  var inQ = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQ = !inQ;
    } else if (ch == ',' && !inQ) {
      res.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  res.add(buf.toString());
  return res;
}

void main() {
  final lines = File('assets/foods.csv').readAsLinesSync();
  final h = _split(lines.first);
  final rows = <int, List<String>>{};
  for (final l in lines.skip(1)) {
    final c = _split(l);
    final code = int.tryParse(c.first);
    if (code != null && c.length == h.length) rows[code] = c;
  }
  String name(int code) => rows[code]![h.indexOf('nom')];
  double v(int code, String col) => double.tryParse(rows[code]![h.indexOf(col)].replaceAll(',', '.')) ?? 0;

  test('les valeurs aberrantes corrigées le restent', () {
    const expected = <(int, String, double)>[
      (18004, 'Vitamine_B6_mg_100g', 0.01), // café : 0,73 -> 0,001
      (18071, 'Vitamine_B6_mg_100g', 0.01), // expresso : 0,74 -> 0,002
      (18162, 'Vitamine_B6_mg_100g', 0.05), // chicorée et café : 0,86 -> 0,025
      (4008, 'Sélénium_µg_100g', 2), // pomme de terre crue : 22,9 -> 0,4
      (4048, 'Sélénium_µg_100g', 2), // pomme de terre cuite (moyenne) : 8 -> 0,6
      (26043, 'Sélénium_µg_100g', 50), // cabillaud cru : 136 -> 33,1
      (26134, 'Sélénium_µg_100g', 50), // lieu noir cru : 120 -> 19,8
      (28902, 'Zinc_mg_100g', 3), // jambon cuit supérieur découenné : 6,5 -> 2,1
      (27006, 'Fer_mg_100g', 1), // truite rôtie : 1,92 -> 0,35
      (20116, 'Sélénium_µg_100g', 5), // chou blanc cru : 20 -> 1,86
      (36016, 'Fer_mg_100g', 1.5), // poulet viande et peau crues : 3,41 -> 0,9
      (36016, 'Vitamine_B2_mg_100g', 0.3), // 0,82 -> 0,12
      (36016, 'Vitamine_B12_µg_100g', 1), // 2,21 -> 0,31
      (20137, 'Vitamine_B1_mg_100g', 0.15), // tomates pelées en conserve : 0,58 -> 0,046
      (20048, 'Vitamine_B1_mg_100g', 0.15),
      (20255, 'Vitamine_B1_mg_100g', 0.15), // échalote cuite : 0,53 -> 0,032
      (6591, 'Vitamine_B1_mg_100g', 0.3), // veau, collier braisé : 0,7 -> 0,06
      (19037, 'Vitamine_B2_mg_100g', 0.4), // lait demi-écrémé enrichi en D : 1,16 -> 0,16
      (26080, 'Fer_mg_100g', 1), // dorade royale sauvage : 1,6 -> 0,39
      (26109, 'Fer_mg_100g', 1), // dorade rose : 4,3 -> 0,39
      (10037, 'Fer_mg_100g', 2), // calmar bouilli : 5,77 -> 0,68
      (10037, 'Rétinol_µg_100g', 50), // 203 -> 10
      (4004, 'Vitamine_B3_mg_100g', 8), // chips : 19,4 -> 4,76
      (4038, 'Vitamine_B9_µg_100g', 80), // chips allégées : 254 -> 29
    ];
    for (final (code, col, max) in expected) {
      expect(v(code, col), lessThan(max), reason: '$code ${name(code)} — $col');
      expect(v(code, col), greaterThan(0), reason: '$code ${name(code)} — $col : la valeur doit rester renseignée');
    }
  });

  test('règles physiques sur toute la base', () {
    for (final code in rows.keys) {
      final n = name(code).toLowerCase();
      // Un café ou un thé prêt à boire n'apporte pas de vitamine B6.
      if ((n.startsWith('café') || n.startsWith('thé')) && n.contains('prêt')) {
        expect(v(code, 'Vitamine_B6_mg_100g'), lessThan(0.05), reason: name(code));
      }
      // La pomme de terre et les choux n'accumulent pas le sélénium.
      if (n.startsWith('pomme de terre') || n.startsWith('chou blanc') || n.startsWith('chou vert') ||
          n.startsWith('chou rouge') || n.startsWith('chou-fleur')) {
        expect(v(code, 'Sélénium_µg_100g'), lessThan(5), reason: name(code));
      }
    }
  });
}
