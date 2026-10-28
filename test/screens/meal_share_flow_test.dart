// test/screens/meal_share_flow_test.dart
//
// Parcours de partage complet (27/10/2026, retour d'Alex : "le partage ne
// fonctionne pas") : écran réel -> "Créer 8 visuels" -> fiche "Tes visuels
// sont prêts" -> "Partager…". Le canal natif de partage (share_plus) et le
// dossier temporaire (path_provider) sont simulés : on vérifie que le menu
// de partage reçoit bien les 8 PNG, et que la légende est copiée.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:share_plus_platform_interface/method_channel/method_channel_share.dart';
import 'package:totum_app/l10n/app_localizations.dart';
import 'package:totum_app/screens/meal_share_screen.dart';
import 'package:totum_app/services/meal_share.dart';

void main() {
  testWidgets('créer puis partager : le menu de partage reçoit les 8 visuels', (tester) async {
    // Police embarquée des visuels (pubspec : TotumShare), chargée comme dans l'app.
    await tester.runAsync(() async {
      final loader = FontLoader('TotumShare');
      for (final f in ['Regular', 'Bold', 'Black']) {
        final bytes = File('assets/fonts/Roboto-$f.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    });
    // Le test tourne sur Windows : on force l'implémentation MOBILE de
    // share_plus (canal natif), celle qui s'exécute sur Android/iOS.
    SharePlatform.instance = MethodChannelShare();
    SharedPreferences.setMockInitialValues({});
    final tmp = Directory.systemTemp.createTempSync('totum_share_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tmp.path);
    List<Object?>? sharedPaths;
    messenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), (call) async {
      if (call.method == 'shareFiles') sharedPaths = (call.arguments as Map)['paths'] as List<Object?>;
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    String? clipboard;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });

    final data = MealShareData(
      title: 'Bowl saumon quinoa', date: DateTime(2026, 10, 27),
      items: const [
        MealShareItem(name: 'Saumon', emoji: '🐟', grams: 150, kcal: 300,
            micros: {'EPA_g_100g': 1.2, 'DHA_g_100g': 1.8, 'Vitamine_D_µg_100g': 11, 'Sélénium_µg_100g': 40}),
        MealShareItem(name: 'Quinoa', emoji: '🌾', grams: 120, kcal: 144, micros: {'Magnésium_mg_100g': 75}),
      ],
      kcal: 444, protein: 35, carbs: 25, fat: 20, fiber: 4,
      micros: const {'EPA_g_100g': 1.2, 'DHA_g_100g': 1.8, 'Vitamine_D_µg_100g': 11, 'Sélénium_µg_100g': 40, 'Magnésium_mg_100g': 75},
    );
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final shotKey = GlobalKey();
    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final ro = shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await ro.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/screens').createSync(recursive: true);
        File('build/screens/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
    await tester.runAsync(() async {
      // FLUTTER_ROOT d'abord (posé par l'outil flutter partout, CI Linux
      // comprise) ; police absente = ignorée, jamais un plantage.
      final root = Platform.environment['FLUTTER_ROOT'] ??
          '${Platform.environment['USERPROFILE']}/flutter';
      final sdk = '$root/bin/cache/artifacts/material_fonts';
      Future<void> load(String family, String path) async {
        final f = File(path);
        if (!f.existsSync()) return;
        final b = f.readAsBytesSync();
        await (FontLoader(family)..addFont(Future.value(ByteData.view(b.buffer)))).load();
      }
      // Roboto embarquée dans le dépôt (assets/fonts) : présente partout.
      for (final f in ['Regular', 'Bold', 'Black']) {
        await load('Roboto', 'assets/fonts/Roboto-$f.ttf');
      }
      await load('MaterialIcons', '$sdk/materialicons-regular.otf');
      final em = File(r'C:\Windows\Fonts\seguiemj.ttf');
      if (em.existsSync()) {
        final b = em.readAsBytesSync();
        await (FontLoader('Emoji')..addFont(Future.value(ByteData.view(b.buffer)))).load();
      }
    });
    await tester.pumpWidget(RepaintBoundary(key: shotKey, child: MaterialApp(
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji'], colorSchemeSeed: const Color(0xFFFF7A00)),
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MealShareScreen(data: data),
    )));
    await tester.pumpAndSettle();

    await shot('share_1_ecran');
    await tester.tap(find.text('Créer 8 visuel(s)'));
    for (var i = 0; i < 40 && find.text('Tes visuels sont prêts').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Tes visuels sont prêts'), findsOneWidget);
    expect(clipboard, contains('Bowl saumon quinoa'));

    // Fin de l'animation d'entrée de la fiche de résultat.
    await tester.pump(const Duration(seconds: 1));
    await shot('share_2_pret');
    await tester.ensureVisible(find.text('Partager…'));
    await tester.pump();
    await tester.tap(find.text('Partager…'));
    for (var i = 0; i < 150 && sharedPaths == null; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final snacks = tester
        .widgetList<Text>(find.descendant(of: find.byType(SnackBar), matching: find.byType(Text)))
        .map((t) => t.data)
        .toList();
    expect(sharedPaths, isNotNull, reason: 'messages : $snacks');
    expect(sharedPaths!.length, 8);
    for (final p in sharedPaths!) {
      final f = File(p as String);
      expect(f.existsSync(), isTrue);
      expect(f.path, endsWith('.png'));
      expect(f.lengthSync(), greaterThan(10000));
    }
  });
}
