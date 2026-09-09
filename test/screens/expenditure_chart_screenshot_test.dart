// test/screens/expenditure_chart_screenshot_test.dart
//
// Outil de démonstration (pas un test de régression classique), demandé
// explicitement par Alex le 19/08/2026 : "fais un test de ton côté et
// fais-moi un imprimé écran de la courbe". Rend le VRAI composant
// `ExpenditureChart` (lib/screens/expenditure_screen.dart), le même utilisé
// en production, avec des données synthétiques réalistes (convergence
// progressive 3090 -> ~2660 kcal, bande d'incertitude qui se resserre) pour
// produire un PNG consultable sans attendre des semaines de vraies données
// sur un compte réel. Volontairement laissé dans le dépôt (peut être
// relancé à tout moment pour revérifier visuellement un changement du
// graphique) plutôt que supprimé après usage.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/l10n/app_localizations.dart';
import 'package:totum_app/screens/expenditure_screen.dart';
import 'package:totum_app/services/calibration_service.dart';
import 'package:totum_app/theme/totum_style.dart';

/// Charge la police Roboto directement depuis le SDK Flutter local (pas une
/// dépendance projet) — sans ça, `flutter test` rend tout texte comme des
/// blocs gris (aucune police système disponible dans l'environnement de
/// test headless). Best-effort : si le SDK n'est pas trouvé à l'un des
/// emplacements usuels, échoue silencieusement (le PNG reste utilisable
/// pour juger la FORME du graphique, juste sans texte lisible).
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
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return;
    }
  }
}

void main() {
  testWidgets('capture un exemple du graphique Dépense énergétique fini',
      (tester) async {
    // Chargement de police = vraie I/O disque — comme `toImage()` plus bas,
    // ne se résout jamais si on l'attend depuis la zone de temps fictif du
    // test (voir le commentaire sur `tester.runAsync` plus bas).
    await tester.runAsync(_tryLoadRealFont);
    final now = DateTime(2026, 8, 19);
    final points = List<ExpenditurePoint>.generate(45, (i) {
      final date = now.subtract(Duration(days: 44 - i));
      final t = i / 44;
      // Convergence progressive formule (3090) -> calibré (~2660), même
      // histoire que le profil réel d'Alex (41 ans, 181cm, 72,7kg, Actif) —
      // pas des valeurs inventées au hasard, ancrées sur les chiffres déjà
      // vérifiés dans cette session.
      final estimate = 3090 - 430 * (1 - math.exp(-3 * t));
      final coverage = (0.3 + 0.7 * t).clamp(0.0, 1.0);
      final uncertainty =
          estimate.abs() * (0.15 - 0.10 * coverage).clamp(0.03, 0.15);
      return ExpenditurePoint(
        date: date,
        estimateKcal: estimate,
        lowKcal: estimate - uncertainty,
        highKcal: estimate + uncertainty,
        // Champs ajoutés le 19/08/2026 (fiche de détail au tap) — valeurs
        // synthétiques mais cohérentes entre elles pour l'exemple.
        avgKcalLogged: 2450 + 60 * math.sin(t * 6),
        weightChangeKg: -0.4 * (1 - t),
        daysWithFoodLogged: 14 + (coverage * 6).round(),
        windowDays: 20,
      );
    });

    // La fiche de détail (nouvelle le 19/08/2026) ajoute une hauteur
    // significative sous le graphique — le viewport par défaut du test
    // (~600px) déborde désormais. Agrandi explicitement plutôt que de
    // rendre le layout scrollable (plus simple pour une capture nette).
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(900, 1300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        // `_PointDetailCard` (nouveau le 19/08/2026) utilise `context.l10n`
        // — sans ces délégués, `AppLocalizations.of(context)` retourne null
        // et plante au build. Absent des versions précédentes de ce test
        // car rien n'utilisait encore le l10n dans le sous-arbre rendu.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Forcé en français — sans ça, la fiche de détail suit la locale du
        // système d'exploitation qui exécute le test (souvent l'anglais sur
        // cette machine), alors que le reste de la démo (légende) est
        // écrit en dur en français : incohérence purement liée à ce script
        // de démonstration, pas à l'app réelle (qui suit AppSettings.language).
        locale: const Locale('fr'),
        home: Scaffold(
          backgroundColor: TotumColors.page,
          // SingleChildScrollView plutôt qu'un Center + hauteur de viewport
          // devinée : la fiche de détail (ajoutée le 19/08/2026) rend le
          // contenu plus haut, et la hauteur exacte importe peu ici (seule
          // la capture du RepaintBoundary compte, pas ce qui est visible à
          // l'écran du test).
          body: SingleChildScrollView(
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  width: 430,
                  color: TotumColors.page,
                  padding: const EdgeInsets.all(16),
                  child: TotumCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(points.last.estimateKcal.round().toString(),
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: TotumColors.textPrimary)),
                            Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, bottom: 5),
                                child: Text('kcal/j',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: TotumColors.textSecondary))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ExpenditureChart(data: points, height: 220),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                      color: TotumColors.accent,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('Dépense estimée',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: TotumColors.textSecondary)),
                            ]),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                  width: 12,
                                  height: 9,
                                  color: TotumColors.accentSoft),
                              const SizedBox(width: 6),
                              Text('Marge d\'incertitude',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: TotumColors.textSecondary)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // `pumpAndSettle()` ne se termine jamais ici (fl_chart entretient une
    // animation interne qui ne converge jamais à l'équalité exacte dans le
    // test binding) — attente bornée à la place, largement suffisante pour
    // laisser l'animation d'entrée (courte, ~150-250ms par défaut) se jouer.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // `RenderRepaintBoundary.toImage()` est une opération RÉELLEMENT
    // asynchrone (rendu/rasterisation) — elle ne se résout jamais si on
    // l'attend depuis la zone de temps FICTIF du test (`tester.pump`
    // n'avance pas le vrai event loop). `tester.runAsync` fait tourner ce
    // bloc dans le vrai event loop, le pattern documenté pour capturer un
    // PNG depuis un widget test.
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final outFile = File('build/expenditure_chart_demo.png');
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });
}
