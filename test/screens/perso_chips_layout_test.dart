// test/screens/perso_chips_layout_test.dart
//
// Vignettes Aliments / Recettes / Repas de l'onglet Perso (page d'ajout) :
// le mot de la vignette sélectionnée doit TOUJOURS être écrit en entier
// (3ᵉ signalement d'Alex, 31/10/2026), y compris sur un écran étroit, avec
// une police système agrandie et le compteur « 168 » de la bibliothèque de
// recettes. Monte le vrai JournalScreen hors connexion (même banc que
// add_food_page_screenshot_test.dart) dans plusieurs configurations et
// vérifie que le contenu de la vignette active n'est ni coupé ni réduit.
// PNG écrits dans build/screens/ (ignoré par git).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show EventChannel, FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:totum_app/l10n/app_localizations.dart';
import 'package:totum_app/screens/journal_screen.dart';

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  final bytes = await f.readAsBytes();
  await (FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

void main() {
  // (largeur logique en dp, zoom de police du téléphone)
  const configs = [
    (393.0, 1.0),
    (360.0, 1.3),
    (320.0, 1.0),
  ];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  for (final (width, scale) in configs) {
    testWidgets('vignettes Perso entières — ${width.toInt()} dp, police ×$scale', (tester) async {
      final root = Platform.environment['FLUTTER_ROOT'] ??
          '${Platform.environment['USERPROFILE']}/flutter';
      await tester.runAsync(() async {
        await _font('Roboto', 'assets/fonts/Roboto-Regular.ttf');
        await _font('Roboto', 'assets/fonts/Roboto-Bold.ttf');
        await _font('MaterialIcons', '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
      });
      SharedPreferences.setMockInitialValues({});
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/events'),
        MockStreamHandler.inline(onListen: (_, __) {}),
      );
      try {
        await tester.runAsync(() => Supabase.initialize(
              url: 'http://localhost:1', publishableKey: 'test-anon-key',
            ));
      } catch (_) {
        // Déjà initialisé par une configuration précédente.
      }

      tester.view.physicalSize = Size(width * 3, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final key = GlobalKey<JournalScreenState>();
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorSchemeSeed: const Color(0xFFFF7A00),
          ),
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: JournalScreen(key: key),
        ),
      ));

      Future<void> settle() async {
        for (var i = 0; i < 20; i++) {
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(milliseconds: 60));
        }
      }

      Future<void> shot(String name) async {
        await tester.runAsync(() async {
          final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await ro.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/screens').createSync(recursive: true);
          File('build/screens/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }

      await settle();
      key.currentState!.openAddPage(meal: 'Déjeuner');
      await settle();
      await tester.tap(find.text('Perso'));
      await settle();

      // Les 3 vignettes : chaque libellé est dans un FittedBox propre.
      Finder chipText(String label) => find.descendant(
            of: find.byType(FittedBox),
            matching: find.text(label),
          );
      // Rapport (largeur disponible / largeur naturelle) : 1 = rien réduit.
      double fitRatio(String label) {
        final fitted = find.ancestor(of: chipText(label), matching: find.byType(FittedBox)).first;
        final row = find.descendant(of: fitted, matching: find.byType(Row)).first;
        final avail = tester.getSize(fitted).width;
        final natural = tester.renderObject<RenderBox>(row).size.width;
        return avail / natural;
      }

      const labels = ['Aliments', 'Recettes', 'Repas'];
      for (final selected in labels) {
        await tester.tap(chipText(selected));
        await settle();
        expect(fitRatio(selected), greaterThanOrEqualTo(0.999),
            reason: '« $selected » sélectionnée doit être affichée en entier, sans réduction');
        for (final other in labels.where((l) => l != selected)) {
          // Jamais tronquées (FittedBox, pas d'ellipse) et restent lisibles.
          expect(fitRatio(other), greaterThan(0.75),
              reason: '« $other » non sélectionnée trop réduite');
        }
        await shot('perso_chips_${width.toInt()}dp_x${scale}_$selected');
      }
    });
  }
}
