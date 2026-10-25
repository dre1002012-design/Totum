// Recherche d'aliments multi-mots (25/10/2026) — testée sur la VRAIE base
// CIQUAL/USDA embarquée (assets/*.csv), avec des requêtes telles qu'un
// utilisateur les tape réellement (phrases, ordre libre, sans virgule,
// fautes de frappe), pas sur des données synthétiques.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/food_search.dart';

List<String> _splitCsvLine(String line) {
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

class _Food {
  final String name;
  final String? alt;
  _Food(this.name, this.alt);
}

List<_Food> _load(String path, String nameCol, String? altCol) {
  final lines = File(path).readAsLinesSync();
  final headers = _splitCsvLine(lines.first);
  final ni = headers.indexOf(nameCol);
  final ai = altCol == null ? -1 : headers.indexOf(altCol);
  final out = <_Food>[];
  for (final l in lines.skip(1)) {
    final c = _splitCsvLine(l);
    if (c.length != headers.length) continue;
    final primary = ai >= 0 && c[ai].trim().isNotEmpty ? c[ai].trim() : c[ni].trim();
    out.add(_Food(primary, c[ni].trim()));
  }
  return out;
}

void main() {
  final ciqual = _load('assets/foods.csv', 'nom', 'nom_generique');
  final usda = _load('assets/usda_foods.csv', 'nom', 'nom_fr');
  final all = [...ciqual, ...usda];
  final index = FoodSearchIndex((o) {
    final f = o as _Food;
    return (f.name, [f.alt]);
  });

  List<String> top(String q, {int n = 5, List<_Food>? within}) => rankFoods<_Food>(
        within ?? ciqual, q,
        keyOf: index.keyOf, limit: n,
      ).map((f) => f.name).toList();

  String f(String s) => foldForSearch(s);

  test('normalisation : accents, casse, ponctuation', () {
    expect(foldForSearch("Huile d'olive, VIERGE-extra (aliment moyen)"),
        'huile d olive vierge extra aliment moyen');
    expect(searchTokens('Les pâtes de blé complètes'), ['pate', 'ble', 'complete']);
    expect(searchTokens('Œufs'), ['oeuf']);
  });

  test('une phrase sans virgule trouve un nom CIQUAL "Catégorie, précision"', () {
    final r = top('magret de canard');
    expect(r, isNotEmpty);
    expect(f(r.first), allOf(contains('canard'), contains('magret')));

    final p = top('pâtes cuites');
    expect(p, isNotEmpty);
    expect(f(p.first), allOf(contains('pate'), contains('cuite')));

    final pr = top('poulet rôti');
    expect(pr, isNotEmpty);
    expect(f(pr.first), allOf(contains('poulet'), contains('roti')));
  });

  test("l'ordre des mots est libre", () {
    expect(top('cru magret canard'), isNotEmpty);
    expect(f(top('cru magret canard').first), contains('magret'));
    expect(f(top('vierge extra huile olive').first), contains('huile d olive'));
  });

  test('une faute de frappe d\'une lettre est tolérée', () {
    expect(f(top('bananne').first), startsWith('banane'));
    expect(f(top('poullet').first), contains('poulet'));
  });

  test('un mot seul : les aliments qui COMMENCENT par ce mot passent devant', () {
    final r = top('banane', n: 3);
    expect(r.every((n) => f(n).startsWith('banane')), isTrue, reason: '$r');
    final o = top('oeuf', n: 3);
    expect(o.every((n) => f(n).startsWith('oeuf')), isTrue, reason: '$o');
  });

  test('phrase longue avec un mot absent : résultats quand même (mode phrase)', () {
    final r = top("pâtes complètes cuites à l'eau");
    expect(r, isNotEmpty);
    expect(f(r.first), allOf(contains('pate'), contains('complete')));
  });

  test('requêtes réelles du journal d\'Alex', () {
    expect(f(top('huile olive').first), contains('huile d olive'));
    expect(f(top('sardine huile tournesol').first), allOf(contains('sardine'), contains('tournesol')));
    // Pas de 75 % dans CIQUAL (c'est un aliment perso d'Alex) : le mode
    // phrase doit quand même proposer des chocolats noirs, jamais "rien".
    expect(f(top('chocolat noir 75').first), contains('chocolat noir'));
    expect(f(top('chocolat noir 70').first), allOf(contains('chocolat noir'), contains('70')));
    expect(f(top('fromage blanc 0%').first), contains('fromage blanc'));
    expect(f(top('lait demi ecreme').first), contains('demi ecreme'));
    expect(f(top('pomme de terre cuite').first), contains('pomme de terre'));
    expect(f(top('thon naturel').first), allOf(contains('thon'), contains('naturel')));
  });

  test('USDA : recherche sur le nom français traduit', () {
    final r = top('poulet', within: usda, n: 3);
    expect(r, isNotEmpty);
  });

  test('performance : recherche sur ~11 000 aliments, cache chaud', () {
    // 1er passage = construction des clés (une fois par session dans l'app).
    final sw0 = Stopwatch()..start();
    rankFoods<_Food>(all, 'a', keyOf: index.keyOf);
    sw0.stop();
    final sw = Stopwatch()..start();
    for (final q in ['p', 'po', 'pou', 'poul', 'poule', 'poulet', 'poulet r', 'poulet roti']) {
      rankFoods<_Food>(all, q, keyOf: index.keyOf);
    }
    sw.stop();
    // ignore: avoid_print
    print('index: ${sw0.elapsedMilliseconds} ms (${all.length} aliments) — '
        '8 frappes: ${sw.elapsedMilliseconds} ms '
        '(${(sw.elapsedMilliseconds / 8).toStringAsFixed(1)} ms/frappe)');
    expect(sw.elapsedMilliseconds / 8, lessThan(60));
  });
}
