// test/widgets/word_safe_text_test.dart
//
// Vérifie RÉELLEMENT (pas une supposition) que WordSafeText ne coupe jamais
// un mot en son milieu — demande explicite d'Alex le 19/08/2026 après
// qu'une 1re tentative par comptage de caractères s'est révélée encore
// fautive en usage réel. Rendu avec une vraie police (chargée depuis le SDK
// Flutter local, comme pour la capture de démonstration du graphique de
// dépense énergétique) pour que les mesures de largeur de texte soient
// représentatives d'un rendu réel, pas des blocs gris par défaut du
// binding de test.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/widgets/word_safe_text.dart';

Future<void> _tryLoadRealFont() async {
  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    if (Platform.environment['USERPROFILE'] != null)
      '${Platform.environment['USERPROFILE']}\\flutter\\bin\\cache\\artifacts\\material_fonts\\roboto-regular.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final loader = FontLoader('Roboto')..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return;
    }
  }
}

void main() {
  testWidgets('WordSafeText ne coupe jamais un mot en son milieu (noms réels, largeur contrainte)',
      (tester) async {
    await tester.runAsync(_tryLoadRealFont);

    // Noms réels tirés de la base custom_foods d'Alex (export Supabase du
    // 19/08/2026) — plusieurs dépassent largement 2 lignes à cette largeur,
    // exactement le cas signalé en usage réel.
    const names = <String>[
      'Filets de maquereaux aux vin blanc et aux aromates',
      'Tablette dégustation BIO - Chocolat noir pure origine Sao Tomé 76% - 100g',
      'Jambon Supérieur sans couenne Conservation Sans Nitrite - x4 tranches,140g',
      'Lustucru gnocchi a poêler format xxl 720g',
      'Yaourt au lait entier, nature',
      'Grimbergen 25 cl Grimbergen 0,0% 0.0 DEGRE ALCOOL',
      'A', // cas trivial : tient toujours, aucune troncature attendue.
    ];

    for (final name in names) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              // 220px : largeur représentative d'une colonne de texte dans
              // une ListTile réelle (icône + texte + tag en marge).
              child: SizedBox(
                width: 220,
                child: WordSafeText(name, maxLines: 2, style: const TextStyle(fontSize: 14, height: 1.25)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final rendered = tester.widget<Text>(find.byType(Text)).data!;

      if (rendered == name) continue; // tenait déjà entièrement, rien à vérifier.

      expect(rendered.endsWith('…'), isTrue,
          reason: 'Troncature de "$name" -> "$rendered" ne se termine pas par "…"');
      final withoutEllipsis = rendered.substring(0, rendered.length - 1);
      expect(name.startsWith(withoutEllipsis), isTrue,
          reason: '"$withoutEllipsis" n\'est pas un préfixe exact de "$name"');

      if (withoutEllipsis.isNotEmpty) {
        final nextCharIndex = withoutEllipsis.length;
        final atWordBoundary = nextCharIndex == name.length || name[nextCharIndex] == ' ';
        expect(atWordBoundary, isTrue,
            reason: 'Troncature EN PLEIN MILIEU D\'UN MOT pour "$name" -> "$rendered" '
                '(caractère suivant dans le nom original : '
                '"${nextCharIndex < name.length ? name[nextCharIndex] : "<fin>"}")');
      }
    }
  });
}
