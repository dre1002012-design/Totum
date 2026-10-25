// test/screens/add_food_page_screenshot_test.dart
//
// Banc de capture de la page "Ajouter un aliment" (refonte du 25/10/2026) :
// monte le VRAI JournalScreen, hors connexion (Supabase initialisé sur une
// URL factice, aucun utilisateur connecté -> données locales uniquement :
// vraie base CIQUAL/USDA embarquée), ouvre la page d'ajout comme le fait
// le « + » central, puis photographie les états clés (liste par défaut,
// recherche par phrase, Favoris, Perso, Marques & restaurants).
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
  testWidgets('captures de la page d\'ajout', (tester) async {
    final sdk = '${Platform.environment['USERPROFILE']}\\flutter\\bin\\cache\\artifacts\\material_fonts';
    await tester.runAsync(() async {
      await _font('Roboto', '$sdk\\roboto-regular.ttf');
      await _font('Roboto', '$sdk\\roboto-bold.ttf');
      await _font('Roboto', '$sdk\\roboto-black.ttf');
      await _font('MaterialIcons', '$sdk\\materialicons-regular.otf');
      await _font('Emoji', r'C:\Windows\Fonts\seguiemj.ttf');
    });
    SharedPreferences.setMockInitialValues({
      // Un peu d'historique réaliste : quelques aliments déjà utilisés,
      // avec leur dernière quantité (mémorisée depuis cette refonte).
      'food_stats': '{"ciqual:13005":{"count":12,"last":1,"g":120},'
          '"ciqual:22000":{"count":20,"last":2,"g":160},'
          '"ciqual:17270":{"count":25,"last":3,"g":5}}',
      'fav_food_ids_v2': '["ciqual:22000","ciqual:17270","ciqual:13005"]',
    });
    // Plugin natif de liens profonds utilisé par Supabase : absent en test,
    // simulé par un flux vide (aucun lien entrant).
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('com.llfbandit.app_links/events'),
      MockStreamHandler.inline(onListen: (_, __) {}),
    );
    await tester.runAsync(() => Supabase.initialize(
          url: 'http://localhost:1', publishableKey: 'test-anon-key',
        ));

    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
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
          fontFamilyFallback: const ['Emoji'],
          colorSchemeSeed: const Color(0xFFFF7A00),
        ),
        home: JournalScreen(key: key),
      ),
    ));

    Future<void> settle() async {
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    Future<void> shot(String name) async {
      await settle();
      await tester.runAsync(() async {
        final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await ro.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/screens').createSync(recursive: true);
        File('build/screens/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await settle();
    await shot('0_journal');

    // Comme le « + » central.
    key.currentState!.openAddPage(meal: 'Petit-déjeuner');
    await shot('1_ajout_defaut');

    await tester.enterText(find.byType(TextField).first, 'magret de canard');
    await shot('2_recherche_phrase');

    await tester.enterText(find.byType(TextField).first, 'big mac');
    await shot('3_recherche_marque');

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text('Favoris'));
    await shot('4_favoris');

    await tester.tap(find.text('Perso'));
    await shot('5_perso');

    await tester.tap(find.widgetWithText(Tab, 'Aliments'));
    await settle();
    await tester.tap(find.text('Marques & restaurants').first);
    await shot('6_marques_restaurants');
  });
}
