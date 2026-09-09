// test/screens/expenditure_info_sheet_screenshot_test.dart
//
// Outil de démonstration (pas un test de régression classique), même esprit
// que expenditure_chart_screenshot_test.dart — demandé implicitement par
// Alex (20/08/2026 : "essaye toi-même de faire les tests... rendu visuel")
// après la refonte de la fiche d'information "D'où vient ce chiffre ?"
// (ExpenditureInfoSheet, lib/screens/expenditure_screen.dart). Rend le VRAI
// composant, pas une reconstruction approximative. Deux scénarios rendus
// côte à côte dans le même PNG : (1) le profil réel d'Alex (41 ans, 181cm,
// 72,3kg, Actif) avec la dépense estimée réellement observée le 20/08/2026
// (1273 kcal/j) — sous son BMR théorique, pour vérifier que l'avertissement
// de plausibilité se déclenche bien et reste lisible ; (2) un cas où
// l'estimation dépasse le BMR, pour vérifier l'état "normal" (coche verte).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/l10n/app_localizations.dart';
import 'package:totum_app/screens/expenditure_screen.dart';
import 'package:totum_app/services/calibration_service.dart';
import 'package:totum_app/services/profile.dart';
import 'package:totum_app/theme/totum_style.dart';

/// Charge Roboto + les icônes Material directement depuis le SDK Flutter
/// local — sans ça, tout texte s'affiche en blocs gris et les Icon() en
/// carrés vides dans l'environnement de test headless. Best-effort.
Future<void> _tryLoadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      (Platform.environment['USERPROFILE'] != null
          ? '${Platform.environment['USERPROFILE']}\\flutter'
          : null);
  if (root == null) return;
  final fonts = <String, String>{
    'Roboto': '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    'MaterialIcons': '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final file = File(entry.value);
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    final loader = FontLoader(entry.key)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

const _alexProfile = UserProfile(
  sex: Sex.male,
  age: 41,
  heightCm: 181,
  weightKg: 72.3,
  activity: ActivityLevel.active,
  goal: GoalType.maintain,
);

Future<Widget> _sheet(List<ExpenditurePoint> data) async {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(
      backgroundColor: TotumColors.page,
      body: ExpenditureInfoSheet(
        data: data,
        profileFuture: Future.value(_alexProfile),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'capture la fiche "D\'où vient ce chiffre ?" refondue — cas sous le BMR (1273 kcal/j réel) et cas normal',
      (tester) async {
    await tester.runAsync(_tryLoadRealFonts);

    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    // Assez haut pour ne rien couper — le contenu réel dépasse largement un
    // écran de téléphone, mais SingleChildScrollView le rend consultable ;
    // ici on veut TOUT voir dans le PNG sans avoir à scroller.
    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });

    // Cas 1 — celui réellement observé sur le compte d'Alex le 20/08/2026 :
    // dépense estimée sous le BMR théorique (~1900 kcal), coverage faible.
    final belowBmrPoint = ExpenditurePoint(
      date: DateTime(2026, 8, 20),
      estimateKcal: 1273,
      lowKcal: 1139,
      highKcal: 1407,
      avgKcalLogged: 1234,
      weightChangeKg: -0.05,
      daysWithFoodLogged: 9,
      windowDays: 20,
    );
    final key1 = GlobalKey();
    await tester.pumpWidget(Center(
      child: RepaintBoundary(
        key: key1,
        child: SizedBox(
          width: 430,
          child: await _sheet([belowBmrPoint]),
        ),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Le FutureBuilder(profileFuture) a besoin d'un tour d'event loop réel
    // pour se résoudre (Future.value se résout en microtask, pas
    // immédiatement synchrone dans le pump fictif).
    await tester.runAsync(() async => Future.delayed(Duration.zero));
    await tester.pump();

    await tester.runAsync(() async {
      final boundary = key1.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final outFile = File('build/expenditure_info_sheet_below_bmr.png');
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(byteData!.buffer.asUint8List());
    });

    // Cas 2 — dépense estimée cohérente, au-dessus du BMR : vérifie l'état
    // "normal" (coche verte, pas d'avertissement rouge).
    final normalPoint = ExpenditurePoint(
      date: DateTime(2026, 8, 20),
      estimateKcal: 2610,
      lowKcal: 2440,
      highKcal: 2780,
      avgKcalLogged: 2580,
      weightChangeKg: -0.15,
      daysWithFoodLogged: 17,
      windowDays: 20,
    );
    final key2 = GlobalKey();
    await tester.pumpWidget(Center(
      child: RepaintBoundary(
        key: key2,
        child: SizedBox(
          width: 430,
          child: await _sheet([normalPoint]),
        ),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.runAsync(() async => Future.delayed(Duration.zero));
    await tester.pump();

    await tester.runAsync(() async {
      final boundary = key2.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final outFile = File('build/expenditure_info_sheet_normal.png');
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });
}
