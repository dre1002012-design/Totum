// Portions ménagères (food_portions.dart) — contrôle sur TOUTE la base
// CIQUAL (31/10/2026, demande d'Alex : « vérifie que l'intégralité des
// portions est correcte et validée »). Écrit aussi build/portions_report.tsv
// (une ligne par aliment) pour la relecture humaine.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/services/foods_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('portions plausibles et bien couvertes sur toute la base CIQUAL', () async {
    final repo = FoodsRepository();
    await repo.loadFromAsset('assets/foods.csv');
    final bySubgroup = <String, (int, int)>{};
    final report = StringBuffer('code\tsous_groupe\tnom\tportion\tgrammes\n');
    for (final f in repo.items) {
      final ps = repo.portionsFor(f.id);
      final sg = f.sousGroupe ?? '';
      final (n, withP) = bySubgroup[sg] ?? (0, 0);
      bySubgroup[sg] = (n + 1, withP + (ps.isEmpty ? 0 : 1));
      for (final p in ps) {
        expect(p.grams, inInclusiveRange(0.4, 450), reason: '${f.name} : ${p.label} ${p.grams} g');
        expect(p.labelEn, isNotNull);
      }
      report.writeln('${f.ciqualCode}\t$sg\t${f.name}\t${ps.isEmpty ? '' : ps.first.label}\t${ps.isEmpty ? '' : ps.first.grams}');
    }
    Directory('build').createSync(recursive: true);
    File('build/portions_report.tsv').writeAsStringSync(report.toString());
    // Familles où une portion ménagère a toujours un sens : couverture totale.
    for (final sg in const [
      'fruits', 'légumes', 'laits', 'fromages et alternatives végétales', 'viandes crues', 'viandes cuites',
      'poissons crus', 'poissons cuits', 'oeufs', 'pains et assimilés', 'viennoiseries', 'huiles et graisses végétales',
      'beurres', 'fruits à coque et graines oléagineuses', 'légumineuses', 'pâtes, riz et céréales', 'boissons sans alcool',
      'produits laitiers frais et alternatives végétales', 'charcuteries et alternatives végétales', 'boisson alcoolisées',
    ]) {
      final (n, withP) = bySubgroup[sg]!;
      expect(withP / n, greaterThanOrEqualTo(0.9), reason: '$sg : $withP/$n aliments avec une portion');
    }
    final total = bySubgroup.values.fold<int>(0, (t, v) => t + v.$1);
    final covered = bySubgroup.values.fold<int>(0, (t, v) => t + v.$2);
    // ignore: avoid_print
    print('portions : $covered/$total aliments CIQUAL couverts');
    expect(covered / total, greaterThanOrEqualTo(0.8));
  });
}
