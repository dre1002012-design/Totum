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

MealShareData _alexLunch() => _alexMeal(const {
      "Sardine à l'huile de tournesol": 190.0,
      'Pomme de terre cuite aliment moyen': 438.0,
      'Poivron vert jaune ou rouge cuit': 100.0,
      'Raisin cru aliment moyen': 150.0,
      'Chocolat noir 70': 10.0,
    }, 'Sardines, pommes de terre & poivrons');

/// Journée réelle du 01/09/2026 (petit-déjeuner, déjeuner, dîner), hors
/// aliments perso absents de CIQUAL (whey, oeuf bleu-blanc-coeur -> oeuf).
MealShareData _alexDay() => _alexMeal(const {
      'Lin brun graine': 22.0,
      'Huile olive vierge extra': 15.0,
      'Oeuf cru': 160.0,
      'Banane chair sans peau crue': 99.0,
      "Sardine à l'huile de tournesol": 190.0,
      'Pomme de terre cuite aliment moyen': 438.0,
      'Poivron vert jaune ou rouge cuit': 100.0,
      'Raisin cru aliment moyen': 150.0,
      'Chocolat noir 70': 20.0,
      'Pates seches standard cuites': 600.0,
      'Camembert lait cru': 50.0,
      'Courgette chair et peau cuite': 300.0,
      'Miel': 15.0,
      'Fromage blanc nature 0%': 100.0,
    }, 'Ma journée', isFullDay: true);

MealShareData _alexMeal(Map<String, double> meal, String title, {bool isFullDay = false}) {
  final db = _loadCiqual();
  // Libellés tels qu'ils figurent dans l'export du journal d'Alex,
  // retrouvés dans la base par le moteur de recherche de l'app.
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
    title: title,
    date: DateTime(2026, 9, 1),
    entries: entries,
    isFullDay: isFullDay,
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

  test('micronutriments en vedette : essentiels santé uniquement, % exacts, triés, source n°1', () {
    final hs = data.highlights(max: 20);
    expect(hs, isNotEmpty);
    for (var i = 1; i < hs.length; i++) {
      expect(hs[i - 1].percent, greaterThanOrEqualTo(hs[i].percent));
    }
    expect(hs.every((h) => h.percent >= 15), isTrue);
    // Jamais de nutriment déjà abondant (retour d'Alex du 26/10/2026).
    for (final banned in ['p', 'na', 'cu', 'mn']) {
      expect(hs.map((h) => h.key), isNot(contains(banned)));
    }
    final b12 = hs.firstWhere((h) => h.key == 'b12');
    expect(b12.percent, closeTo(b12.amount / 2.5 * 100, 1e-9));
    // 190 g de sardines : source n°1 des oméga-3 et de la B12.
    expect(hs.firstWhere((h) => h.key == 'epaDha').topSourceName, startsWith('Sardine'));
    expect(b12.topSourceName, startsWith('Sardine'));
  });

  test('acides gras essentiels et nutriments à compléter', () {
    final fa = data.fattyAcids;
    expect(fa.epaDhaMg, greaterThan(500));
    expect(fa.laAlaRatio, isNotNull);
    final gaps = data.gaps();
    expect(gaps.every((g) => g.percent < data.gapThreshold), isTrue);
    expect(data.covered().every((c) => c.percent >= data.gapThreshold), isTrue);
  });

  test('légende : 5 mots-dièse maximum, aucune allégation "riche en", CTA selon la marque', () {
    final cap = captionFor(data, handle: '@agenaturo');
    expect(RegExp(r'#\w+').allMatches(cap).length, lessThanOrEqualTo(5));
    expect(cap.toLowerCase(), isNot(contains('riche en')));
    expect(cap, contains('@agenaturo'));
    final capTotum = captionFor(data, brand: ShareBrand.totum);
    expect(capTotum, contains('Google Play'));
    expect(RegExp(r'#\w+').allMatches(capTotum).length, lessThanOrEqualTo(5));
  });

  testWidgets('rendu PNG de tous les visuels (4 ambiances, 6 formats)', (tester) async {
    final fr = AppLocalizationsFr();
    await tester.runAsync(() async {
      final sdk = '${Platform.environment['USERPROFILE']}/flutter/bin/cache/artifacts/material_fonts';
      await _loadFont('Roboto', ['$sdk/roboto-regular.ttf']);
      await _loadFont('Roboto', ['$sdk/roboto-bold.ttf']);
      await _loadFont('Roboto', ['$sdk/roboto-black.ttf']);
      await _loadFont('Emoji', [r'C:\Windows\Fonts\seguiemj.ttf']);
      final dir = Directory('build/share')..createSync(recursive: true);
      for (final f in dir.listSync()) {
        f.deleteSync();
      }
      Future<void> render(MealShareSlide slide, String name) async {
        final img = await renderWidgetToImage(slide,
            logicalSize: slide.logicalSize, pixelRatio: slide.exportScale, view: tester.view);
        File('${dir.path}/$name.png').writeAsBytesSync(await imageToPng(img));
      }
      MealShareSlide make(ShareSlideKind k, SharePalette p, {ShareBrand brand = ShareBrand.coach, int? i, bool reel = false}) =>
          MealShareSlide(kind: k, data: data, palette: p, l10n: fr, handle: '@agenaturo', brand: brand,
              index: i, count: i == null ? null : carouselKinds.length, reelFrame: reel,
              fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji']);

      for (final pal in SharePalette.all) {
        final brand = pal.id.startsWith('totum') ? ShareBrand.totum : ShareBrand.coach;
        for (var i = 0; i < carouselKinds.length; i++) {
          await render(make(carouselKinds[i], pal, brand: brand, i: i + 1), '${pal.id}_${i + 1}_${carouselKinds[i].name}');
        }
      }
      await render(make(ShareSlideKind.story, SharePalette.naturoSage), 'format_story');
      await render(make(ShareSlideKind.post, SharePalette.naturoLinen), 'format_post');
      await render(make(ShareSlideKind.landscape, SharePalette.totumCream, brand: ShareBrand.totum), 'format_paysage');
      await render(make(ShareSlideKind.banner, SharePalette.totumCream, brand: ShareBrand.totum), 'format_banniere_playstore');
      await render(make(ShareSlideKind.micros, SharePalette.totumNight, reel: true), 'format_reel_3');
      final day = _alexDay();
      for (final k in [ShareSlideKind.cover, ShareSlideKind.micros, ShareSlideKind.gaps, ShareSlideKind.cta]) {
        await render(
          MealShareSlide(kind: k, data: day, palette: SharePalette.naturoSage, l10n: fr, handle: '@agenaturo',
              index: carouselKinds.indexOf(k) + 1, count: carouselKinds.length,
              fontFamily: 'Roboto', fontFamilyFallback: const ['Emoji']),
          'journee_${k.name}');
      }
      expect(day.isFullDay, isTrue);
      expect(day.gaps().every((g) => g.percent < 75), isTrue);
      final banner = make(ShareSlideKind.banner, SharePalette.totumCream);
      final img = await renderWidgetToImage(banner, logicalSize: banner.logicalSize, pixelRatio: banner.exportScale, view: tester.view);
      expect((img.width, img.height), (1024, 500));
      final land = make(ShareSlideKind.landscape, SharePalette.totumCream);
      final img2 = await renderWidgetToImage(land, logicalSize: land.logicalSize, pixelRatio: land.exportScale, view: tester.view);
      expect((img2.width, img2.height), (1200, 630));
    });
  });
}
