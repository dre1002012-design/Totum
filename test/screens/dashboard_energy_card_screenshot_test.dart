// test/screens/dashboard_energy_card_screenshot_test.dart
//
// Outil de démonstration (pas un test de régression classique), généré pour
// vérifier VISUELLEMENT la refonte "2 donuts" de la carte "Aujourd'hui" du
// tableau de bord (19/08/2026, 2e retour d'Alex) AVANT livraison — la
// structure exacte du widget (SizedBox > Stack > PieChart + Column
// centrale, Row de 2 Expanded) est reproduite ici à l'identique de
// `profile_screen.dart` (_energyDonut/_donutLegendRow/_kpiRemainingCard),
// avec des valeurs représentatives du profil réel d'Alex (41 ans, 181cm,
// 72,7kg, Actif — BMR ~1907, objectif calibré ~2660, donc mouvement ~753),
// pour confirmer que la mise en page tient sans débordement à une largeur
// d'écran réaliste.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/theme/totum_style.dart';

/// Charge une police depuis le SDK Flutter local sous le nom de famille
/// `family` — best-effort, échoue silencieusement si introuvable (le PNG
/// reste utilisable pour juger la mise en page, juste sans ce rendu précis).
/// Utilisé pour Roboto (texte) ET MaterialIcons (pictogrammes — sans elle,
/// chaque `Icon` se rend en petit carré vide "glyphe manquant", un artefact
/// de CET environnement de test headless, jamais présent sur un vrai
/// appareil où la police d'icônes est embarquée par défaut).
Future<void> _tryLoadRealFont(String family, String fileNameLower) async {
  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/$fileNameLower',
    if (Platform.environment['USERPROFILE'] != null)
      '${Platform.environment['USERPROFILE']}\\flutter\\bin\\cache\\artifacts\\material_fonts\\$fileNameLower',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final loader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return;
    }
  }
}

Widget _energyDonut({
  required double filledFraction,
  required Color filledColor,
  required String centerValue,
  required Color centerValueColor,
  required String centerLabel,
  required List<Widget> legendRows,
  Color? emptyColor,
}) {
  final f = filledFraction.clamp(0.0, 1.0);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 98,
        height: 98,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 32,
                sections: [
                  PieChartSectionData(value: f > 0 ? f : 0.0001, color: filledColor, title: '', radius: 13),
                  PieChartSectionData(
                      value: (1 - f) > 0 ? (1 - f) : 0.0001,
                      color: emptyColor ?? TotumColors.outline,
                      title: '',
                      radius: 13),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerValue,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: centerValueColor)),
                Text(centerLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: TotumColors.textSecondary, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      ...legendRows,
    ],
  );
}

Widget _donutLegendRow(IconData icon, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: TotumColors.textSecondary),
        const SizedBox(width: 5),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
      ],
    ),
  );
}

void main() {
  testWidgets('capture la carte Aujourd\'hui refondue (2 donuts)', (tester) async {
    await tester.runAsync(() async {
      await _tryLoadRealFont('Roboto', 'roboto-regular.ttf');
      await _tryLoadRealFont('MaterialIcons', 'materialicons-regular.otf');
    });

    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });

    // Valeurs représentatives : objectif calibré 2660, 1410 kcal déjà
    // loguées (donc 1250 kcal restant, pas dépassé) ; BMR 1907, mouvement
    // 753 (2660-1907) — cohérent avec le profil réel d'Alex vérifié cette
    // session.
    const kcalGoal = 2660;
    const kcalConsumed = 1410;
    const remaining = kcalGoal - kcalConsumed;
    const bmr = 1907;
    const movement = kcalGoal - bmr;

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: TotumColors.page,
          body: Center(
            child: RepaintBoundary(
              key: key,
              // 400dp : largeur d'écran téléphone usuelle moins les marges
              // de page (16+16) déjà appliquées par l'appelant réel.
              child: Container(
                width: 400,
                color: TotumColors.page,
                padding: const EdgeInsets.all(16),
                child: TotumCard(
                  accentBorder: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('AUJOURD\'HUI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: TotumColors.textMuted)),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _energyDonut(
                              filledFraction: kcalConsumed / kcalGoal,
                              filledColor: TotumColors.accent,
                              centerValue: remaining.toString(),
                              centerValueColor: TotumColors.textPrimary,
                              centerLabel: 'restant',
                              legendRows: [
                                _donutLegendRow(Icons.flag_rounded, '$kcalGoal'),
                                _donutLegendRow(Icons.restaurant_rounded, '$kcalConsumed'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _energyDonut(
                              filledFraction: movement / kcalGoal,
                              filledColor: TotumColors.accent,
                              emptyColor: TotumColors.outlineStrong,
                              centerValue: '+$movement',
                              centerValueColor: TotumColors.textPrimary,
                              centerLabel: 'Mouvement',
                              legendRows: [
                                _donutLegendRow(Icons.bedtime_outlined, '$bmr'),
                                _donutLegendRow(Icons.directions_run_rounded, '+$movement'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text('Affiné selon tes résultats réels',
                            style: TextStyle(
                                fontSize: 10, color: TotumColors.accent, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final outFile = File('build/dashboard_energy_card_demo.png');
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });
}
