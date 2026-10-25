// test/screens/onboarding_screenshot_test.dart
//
// Parcours d'inscription (audit du 25/10/2026) : champs vides au départ,
// bouton bloqué tant que les valeurs ne sont pas plausibles, message
// d'erreur sur une faute de frappe, récapitulatif avec l'origine du calcul.
// PNG dans build/screens/ (ignoré par git).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totum_app/l10n/app_localizations.dart';
import 'package:totum_app/screens/onboarding_screen.dart';

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  final bytes = await f.readAsBytes();
  await (FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

void main() {
  testWidgets('parcours d\'inscription : validation et récapitulatif', (tester) async {
    final sdk = '${Platform.environment['USERPROFILE']}\\flutter\\bin\\cache\\artifacts\\material_fonts';
    await tester.runAsync(() async {
      await _font('Roboto', '$sdk\\roboto-regular.ttf');
      await _font('Roboto', '$sdk\\roboto-bold.ttf');
      await _font('Roboto', '$sdk\\roboto-black.ttf');
      await _font('MaterialIcons', '$sdk\\materialicons-regular.otf');
    });
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto', colorSchemeSeed: const Color(0xFFFF7A00)),
        home: OnboardingScreen(onDone: () {}),
      ),
    ));
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await ro.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/screens').createSync(recursive: true);
        File('build/screens/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    FilledButton continueButton() => tester.widget<FilledButton>(find.byType(FilledButton));

    // Champs vides : impossible de continuer sans rien saisir.
    expect(continueButton().onPressed, isNull);
    await shot('onb_1_vide');

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '41');
    await tester.enterText(fields.at(1), '18'); // faute de frappe : 18 cm
    await tester.enterText(fields.at(2), '73.9');
    await tester.pump();
    expect(continueButton().onPressed, isNull);
    expect(find.text('Taille plausible : 120 à 230 cm'), findsOneWidget);
    await shot('onb_2_faute_de_frappe');

    await tester.enterText(fields.at(1), '181');
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Très actif').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maintien').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await shot('onb_3_recap');
    expect(find.textContaining('Mifflin'), findsOneWidget);
  });
}
