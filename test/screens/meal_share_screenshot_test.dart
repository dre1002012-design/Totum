// test/screens/meal_share_screenshot_test.dart
//
// Visuels Instagram d'un repas (25/10/2026) : calculs (% VNR, légende,
// mots-dièse) + rendu RÉEL des visuels en PNG 1080 px via le même moteur
// de rendu hors écran que l'app (services/widget_image_renderer.dart).
// Données : un vrai déjeuner du journal d'Alex (01/09/2026), micronutriments
// lus dans la vraie base CIQUAL embarquée (assets/foods.csv).
//
// Les PNG sont écrits dans build/share/ (ignoré par git) — relançable à
// tout moment pour revérifier visuellement une modification des visuels.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:totum_app/l10n/app_localizations_fr.dart';
import 'package:totum_app/services/food_search.dart';
import 'package:totum_app/services/meal_share.dart';
import 'package:totum_app/services/widget_image_renderer.dart';
import 'package:totum_app/widgets/meal_share_slides.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  for (final path in paths) {
    final f = File(path);
    if (await f.exists()) {
      final bytes = await f.readAsBytes();
      final loader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return;
    }
  }
}

List<String> _split(String line) {
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

/// nom CIQUAL -> (micros pour 100 g, pictogramme, macros pour 100 g)
Map<String, ({Map<String, double> micros, String emoji, List<double> macros})> _loadCiqual() {
  final lines = File('assets/foods.csv').readAsLinesSync();
  final h = _split(lines.first);
  final out = <String, ({Map<String, double> micros, String emoji, List<double> macros})>{};
  for (final l in lines.skip(1)) {
    final c = _split(l);
    if (c.length != h.length) continue;
    final micros = <String, double>{};
    for (var i = 0; i < h.length; i++) {
      final v = double.tryParse(c[i].replaceAll(',', '.'));
      if (v != null) micros[h[i]] = v;
    }
    double m(String k) => micros[k] ?? 0;
    out[c[h.indexOf('nom')]] = (
      micros: micros,
      emoji: c[h.indexOf('pictogramme')],
      macros: [m('Énergie_kcal_100g'), m('Protéines_g_100g'), m('Glucides_g_100g'), m('Lipides_g_100g'), m('Fibres_g_100g')],
    );
  }
  return out;
}

MealShareData _alexLunch() {
  final db = _loadCiqual();
  // Libellés tels qu'ils figurent dans l'export du journal d'Alex,
  // retrouvés dans la base par le moteur de recherche de l'app.
  const meal = {
    "Sardine à l'huile de tournesol": 190.0,
    'Pomme de terre cuite aliment moyen': 438.0,
    'Poivron vert jaune ou rouge cuit': 100.0,
    'Raisin cru aliment moyen': 150.0,
    'Chocolat noir 70': 10.0,
  };
  final index = FoodSearchIndex((o) => (o as String, const <String?>[]));
  final names = db.keys.toList();
  final entries = <Map<String, dynamic>>[];
  meal.forEach((query, g) {
    final key = rankFoods<String>(names, query, keyOf: index.keyOf, limit: 1).first;
    final f = db[key]!;
    entries.add({
      'id': key, 'name': key, 'grams': g,
      'kcal': f.macros[0] * g / 100, 'prot': f.macros[1] * g / 100, 'carb': f.macros[2] * g / 100,
      'fat': f.macros[3] * g / 100, 'fiber': f.macros[4] * g / 100,
    });
  });
  return buildMealShareData(
    title: 'Sardines, pommes de terre & poivrons',
    date: DateTime(2026, 9, 1),
    entries: entries,
    lookup: (id, name) {
      final f = db[id];
      return f == null ? null : (micros100: f.micros, emoji: f.emoji, displayName: id);
    },
  );
}

void main() {
  final data = _alexLunch();

  test('totaux et répartition énergétique cohérents', () {
    expect(data.items.length, 5);
    expect(data.kcal, greaterThan(800));
    final s = data.energySplit;
    expect(s.protein + s.carbs + s.fat, closeTo(1, 1e-9));
  });

  test('micronutriments : % VNR exacts, triés, seuil 15 %', () {
    final hs = data.highlights();
    expect(hs, isNotEmpty);
    for (var i = 1; i < hs.length; i++) {
      expect(hs[i - 1].percent, greaterThanOrEqualTo(hs[i].percent));
    }
    expect(hs.every((h) => h.percent >= 15), isTrue);
    // 190 g de sardines : B12 et vitamine D très au-dessus des VNR.
    expect(hs.map((h) => h.key), contains('b12'));
    final b12 = hs.firstWhere((h) => h.key == 'b12');
    expect(b12.percent, closeTo(b12.amount / 2.5 * 100, 1e-9));
  });

  test('légende : 5 mots-dièse maximum, aucune allégation "riche en"', () {
    final cap = captionFor(data, handle: '@naturo.alex');
    final tags = RegExp(r'#\w+').allMatches(cap).length;
    expect(tags, lessThanOrEqualTo(5));
    expect(cap.toLowerCase(), isNot(contains('riche en')));
    expect(cap, contains('@naturo.alex'));
    expect(cap, isNot(contains('de huile')));
    expect(cap, isNot(contains('de avocat')));
  });

  testWidgets('rendu PNG des visuels (carrousel, post, story, reel)', (tester) async {
    final fr = AppLocalizationsFr();
    await tester.runAsync(() async {
      await _loadFont('Roboto', [
        '${Platform.environment['USERPROFILE']}\\flutter\\bin\\cache\\artifacts\\material_fonts\\roboto-regular.ttf',
      ]);
      await _loadFont('Emoji', [r'C:\Windows\Fonts\seguiemj.ttf']);
      final dir = Directory('build/share')..createSync(recursive: true);
      Future<void> render(MealShareSlide slide, String name) async {
        final img = await renderWidgetToImage(slide,
            logicalSize: slide.logicalSize, pixelRatio: kShareExportScale, view: tester.view);
        expect(img.width, 1080);
        expect(img.height, slide.logicalSize.height * 3);
        File('${dir.path}/$name.png').writeAsBytesSync(await imageToPng(img));
      }

      for (final pal in SharePalette.all) {
        for (var i = 0; i < carouselKinds.length; i++) {
          await render(
            MealShareSlide(kind: carouselKinds[i], data: data, palette: pal, l10n: fr,
                handle: '@naturo.alex', index: i + 1, count: carouselKinds.length,
                fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji']),
            '${pal.id}_${i + 1}_${carouselKinds[i].name}',
          );
        }
      }
      await render(
        MealShareSlide(kind: ShareSlideKind.story, data: data, palette: SharePalette.cream, l10n: fr,
            handle: '@naturo.alex', fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji']),
        'cream_story');
      await render(
        MealShareSlide(kind: ShareSlideKind.post, data: data, palette: SharePalette.cream, l10n: fr,
            handle: '@naturo.alex', fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji']),
        'cream_post');
      await render(
        MealShareSlide(kind: ShareSlideKind.micros, data: data, palette: SharePalette.night, l10n: fr,
            handle: '@naturo.alex', index: 3, count: 5, reelFrame: true,
            fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji']),
        'night_reel_3');
    });
  });
}
