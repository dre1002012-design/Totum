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
import 'package:totum_app/l10n/app_localizations_en.dart';
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

typedef _Food = ({Map<String, double> micros, String emoji, List<double> macros, bool plant, int? nova});

/// nom CIQUAL -> (micros pour 100 g, pictogramme, macros pour 100 g,
/// végétal ?, NOVA estimé)
Map<String, _Food> _loadCiqual() {
  final lines = File('assets/foods.csv').readAsLinesSync();
  final h = _split(lines.first);
  final out = <String, _Food>{};
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
      plant: isPlantFood(groupe: c[h.indexOf('groupe')], sousGroupe: c[h.indexOf('sous_groupe')]),
      nova: int.tryParse(c[h.indexOf('score_nova_estime')]),
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
    classify: (id) => (isPlant: db[id]?.plant ?? false, nova: db[id]?.nova),
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

  test('stars : classées par PERTINENCE santé, % exacts (apports ANSES), source n°1', () {
    final hs = data.highlights(max: 20);
    expect(hs, isNotEmpty);
    for (var i = 1; i < hs.length; i++) {
      expect(nutrientRelevance(hs[i - 1]), greaterThanOrEqualTo(nutrientRelevance(hs[i])));
    }
    expect(hs.every((h) => h.percent >= 15), isTrue);
    // Au plus 2 vitamines B parmi les stars (trio varié).
    expect(hs.where((h) => RegExp(r'^b\d+$').hasMatch(h.key)).length, lessThanOrEqualTo(2));
    // Jamais de nutriment déjà abondant (retour d'Alex du 26/10/2026).
    for (final banned in ['p', 'na', 'cu', 'mn']) {
      expect(hs.map((h) => h.key), isNot(contains(banned)));
    }
    final b12 = data.panel(NutrientKind.vitamin).firstWhere((h) => h.key == 'b12');
    expect(b12.percent, closeTo(b12.amount / 4 * 100, 1e-9)); // ANSES : 4 µg
    // 190 g de sardines : source n°1 des oméga-3 marins.
    expect(hs.firstWhere((h) => h.key == 'epaDha').topSourceName, startsWith('Sardine'));
    // D'où ça vient : parts décroissantes, somme = 100 %.
    final parts = data.contributions(hs.first.def);
    expect(parts.fold<double>(0, (t, c) => t + c.share), closeTo(1, 1e-9));
    for (var i = 1; i < parts.length; i++) {
      expect(parts[i - 1].share, greaterThanOrEqualTo(parts[i].share));
    }
  });

  test("petit-déjeuner réel d'Alex (œufs, lin, huile d'olive, banane) : stars pertinentes", () {
    final bf = _alexMeal(const {
      'Lin brun graine': 22.0,
      'Huile olive vierge extra': 15.0,
      'Oeuf cru': 160.0,
      'Banane chair sans peau crue': 99.0,
    }, 'Petit-déjeuner');
    final stars = bf.highlights(max: 3);
    // ignore: avoid_print
    print('stars: ${stars.map((h) => '${h.label} ${h.percent.round()} %').join(' | ')}');
    // ignore: avoid_print
    print('corps: ${bf.bodySystems().map((b) => '${bodySystemLabel(b.system, false)} ${b.coverage.round()} %').join(' | ')}');
    // Le lin (22 g) apporte plus de 2 fois l'apport conseillé en oméga-3
    // végétal : il doit être LA star, pas la B12 des œufs.
    expect(stars.first.key, 'ala');
    expect(stars.map((h) => h.key), isNot(contains('b12')));
  });

  test('pertinence : 686 % de B12 ne passe plus devant 45 % de magnésium', () {
    NutrientHighlight h(String key, double pct) {
      final d = essentialNutrients.firstWhere((e) => e.key == key);
      return NutrientHighlight(def: d, amount: d.reference * pct / 100);
    }
    expect(nutrientRelevance(h('mg', 45)), greaterThan(nutrientRelevance(h('b12', 686))));
    expect(nutrientRelevance(h('vitD', 60)), greaterThan(nutrientRelevance(h('b3', 300))));
    // Au-delà de 100 % plus rien ne compte vraiment (rendement décroissant).
    expect(nutrientRelevance(h('b12', 686)) - nutrientRelevance(h('b12', 150)), lessThan(10));
  });

  test('ton corps : 8 fonctions, couvertures entre 0 et 100, nutriments réels', () {
    final sys = data.bodySystems();
    expect(sys.length, BodySystem.values.length);
    for (final b in sys) {
      expect(b.coverage, inInclusiveRange(0, 100));
      for (final t in b.top) {
        expect(t.def.systems, contains(b.system));
      }
    }
    for (var i = 1; i < sys.length; i++) {
      expect(sys[i - 1].coverage, greaterThanOrEqualTo(sys[i].coverage));
    }
  });

  test('acides gras essentiels et nutriments à compléter', () {
    final fa = data.fattyAcids;
    expect(fa.epaDhaMg, greaterThan(500));
    expect(fa.laAlaRatio, isNotNull);
    final gaps = data.gaps();
    expect(gaps.every((g) => g.percent < data.gapThreshold), isTrue);
    expect(data.covered().every((c) => c.percent >= data.gapThreshold), isTrue);
  });

  test('légende : généraliste, 5 mots-dièse max, aucun emoji de nutriment, aucune allégation', () {
    final cap = captionFor(data, handle: '@moncompte');
    expect(RegExp(r'#\w+').allMatches(cap).length, lessThanOrEqualTo(5));
    expect(cap.toLowerCase(), isNot(contains('riche en')));
    expect(cap.toLowerCase(), isNot(contains('naturo')));
    expect(cap, contains('@moncompte'));
    expect(cap, contains('Ciqual'));
    // Seuls 💾 (enregistrer) et ✈️ (envoyer, icône d'Instagram) sont admis.
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    final found = emoji.allMatches(cap).map((m) => m.group(0)).toSet()..removeAll({'💾', '✈'});
    expect(found, isEmpty, reason: 'emojis inattendus : $found');
    expect(captionFor(data, mentionTotum: false), isNot(contains('Totum')));
  });

  test('nutriments : noms complets en clair, jamais de symbole chimique ni d\'emoji', () {
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    const symbols = {'Mg', 'Zn', 'Se', 'Fe', 'Ca', 'K', 'I', 'Na', 'P', 'Cu', 'Mn'};
    final labels = <String>{};
    for (final n in essentialNutrients) {
      for (final t in [n.labelFr, n.labelEn, n.titleFr, n.roleFr, n.foodsFr, n.foodsEn]) {
        expect(emoji.hasMatch(t), isFalse, reason: '${n.key} : "$t"');
      }
      expect(symbols.contains(n.labelFr), isFalse, reason: n.labelFr);
      expect(labels.add(n.labelFr), isTrue, reason: 'libellé en double : ${n.labelFr}');
      expect(n.systems, isNotEmpty, reason: n.key);
    }
    expect(kRefFiberG, 30); // repère ANSES, cité tel quel sur les visuels
  });

  test('angles du partage : accroches et constats propres à chaque public', () {
    // Sardines, pommes de terre, poivron, raisin, chocolat : 3 végétaux
    // (le chocolat est un produit sucré, pas un végétal identifiable).
    expect(data.plantCount, 3);
    expect(data.rawShare, isNotNull);
    expect(data.energyDensity, closeTo(data.kcal / data.totalGrams * 100, 1e-9));
    final sport = hookFor(data, focus: ShareFocus.sport);
    expect(sport.headline, contains('g de protéines et'));
    final sat = hookFor(data, focus: ShareFocus.satiety);
    expect(sat.headline, contains('kcal pour'));
    final lon = hookFor(data, focus: ShareFocus.longevity);
    expect(lon.headline, startsWith('3 végétaux différents'));
    expect(lon.subline, contains('American Gut Project'));
    // Sport : au moins un nutriment « sport » parmi les 3 stars (l'angle
    // favorise sans écraser un apport majeur, ici 374 % d'oméga-3 marins).
    final hs = data.highlights(focus: ShareFocus.sport, max: 3);
    expect(hs.any((h) => kFocusNutrients[ShareFocus.sport]!.contains(h.key)), isTrue);
    for (final f in ShareFocus.values) {
      final ins = insightsFor(data, focus: f);
      expect(ins.length, inInclusiveRange(1, 3));
      expect(hashtagsFor(data, focus: f).length, lessThanOrEqualTo(5));
      expect(captionFor(data, focus: f), isNot(contains('riche en')));
    }
  });

  test('aliments stars : sardines en tête, % propres à chaque aliment, apports phares pondérés', () {
    final spots = data.spotlights(max: 4);
    // ignore: avoid_print
    print('aliments stars : ${spots.map((s) => '${s.item.name} [${s.top.map((t) => '${t.$1.key} ${t.$2.round()} %').join(', ')}]').join(' | ')}');
    expect(spots, isNotEmpty);
    expect(spots.first.item.name, startsWith('Sardine'));
    // Même pertinence que les stars : 61 % de vitamine D (souvent
    // insuffisante) passe devant 425 % de B12 (abondante).
    expect(spots.first.top.map((t) => t.$1.key), containsAll(['epaDha', 'vitD']));
    expect(spots.first.top.map((t) => t.$1.key), isNot(contains('b12')));
    // Une vedette apporte au moins 20 % de quelque chose.
    for (final s in spots) {
      expect(s.top.any((t) => t.$2 >= 20) || s.proteinPct >= 20 || s.fiberPct >= 20, isTrue, reason: s.item.name);
    }
    for (var i = 1; i < spots.length; i++) {
      expect(spots[i - 1].score, greaterThanOrEqualTo(spots[i].score));
    }
    for (final s in spots) {
      expect(s.top.length, lessThanOrEqualTo(3));
      for (final (d, pct) in s.top) {
        // % de l'apport conseillé apporté par CET aliment seul.
        expect(pct, closeTo(d.amount(s.item.micros) / d.reference * 100, 1e-9));
        expect(pct, greaterThanOrEqualTo(10));
      }
      expect(s.proteinPct, closeTo(s.item.protein / kRefProteinG * 100, 1e-9));
      expect(s.systems.length, lessThanOrEqualTo(3));
    }
  });

  test('nom court : garde l\'état cru/cuit/sec, qui change le sens d\'un poids', () {
    expect(shortFoodName('Pâtes sèches, standard, cuites, sans sel ajouté'), 'Pâtes cuites');
    expect(shortFoodName('Pâtes, crues (sèches)'), 'Pâtes crues');
    expect(shortFoodName('Pâtes, cuites'), 'Pâtes cuites');
    expect(shortFoodName('Riz blanc, cru'), 'Riz blanc cru');
    expect(shortFoodName('Lentille, bouillie/cuite à l\'eau (aliment moyen)'), 'Lentille cuite');
    expect(shortFoodName('Pomme de terre, cuite (aliment moyen)'), 'Pomme de terre cuite');
    expect(shortFoodName('Abricot sec'), 'Abricot sec');
    expect(shortFoodName('Blanc de poulet, grillé'), 'Blanc de poulet');
    expect(shortFoodName("Sardine, à l'huile d'olive, appertisée, égouttée"), 'Sardine');
    expect(shortFoodName('White rice, cooked'), 'Cooked white rice');
    expect(shortFoodName('Pasta, dry (uncooked)'), 'Dry pasta');
    expect(shortFoodName('Dried apricot'), 'Dried apricot');
  });

  test('densité : même règle pour le compte et pour les barres, cohérente avec les calories', () {
    expect(data.energyShare, closeTo(data.kcal / kRefEnergyKcal, 1e-12));
    final all = data.all();
    expect(all.length, essentialNutrients.length);
    for (var i = 1; i < all.length; i++) {
      expect(all[i - 1].percent, greaterThanOrEqualTo(all[i].percent));
    }
    expect(data.denseCount, all.where(data.isDense).length);
    for (final h in all.where(data.isDense)) {
      expect(h.percent, greaterThanOrEqualTo(data.energyShare * 100));
      expect(h.percent, greaterThanOrEqualTo(15));
    }
    // ignore: avoid_print
    print('densité : ${(data.energyShare * 100).round()} % des calories, ${data.denseCount} essentiels au-delà');
  });

  test('stress-test : repas sans micronutriments (soda) — aucun faux « dense », aucun aliment star', () {
    final soda = MealShareData(
      title: 'Soda', date: DateTime(2026, 11, 1), kcal: 139, protein: 0, carbs: 35, fat: 0, fiber: 0,
      micros: const {'Sucres_g_100g': 35},
      items: const [MealShareItem(name: 'Boisson au cola', emoji: '🥤', grams: 330, kcal: 139, micros: {'Sucres_g_100g': 35})],
    );
    expect(soda.denseCount, 0);
    expect(soda.spotlights(), isEmpty);
    expect(soda.fullyCovered, 0);
    final hook = hookFor(soda);
    expect(hook.headline, isNot(contains('dense')));
    expect(hook.subline, isNot(contains('dense')));
    // Repas vide : aucune division par zéro, rien de « dense ».
    final empty = MealShareData(title: '', date: DateTime(2026, 11, 1), kcal: 0, protein: 0, carbs: 0, fat: 0,
        fiber: 0, micros: const {}, items: const []);
    expect(empty.denseCount, 0);
    expect(empty.spotlights(), isEmpty);
  });

  test('le saviez-vous : 21 fiches, sans allégation interdite ; badge « souvent insuffisant » ciblé', () {
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    // Règlement (UE) 1169/2011, art. 7.3 : jamais prévenir/traiter/guérir.
    final forbidden = RegExp(r'guéri|prévien|soign|trait|cure|prevent|treat|riche en|source de', caseSensitive: false);
    for (final n in essentialNutrients) {
      for (final t in [n.factFr, n.factEn]) {
        expect(t.trim(), isNotEmpty, reason: n.key);
        expect(t.length, lessThan(130), reason: '${n.key} : fiche trop longue pour 2 lignes');
        expect(emoji.hasMatch(t), isFalse, reason: '${n.key} : "$t"');
        expect(forbidden.hasMatch(t), isFalse, reason: '${n.key} : "$t"');
      }
    }
    expect({for (final n in essentialNutrients) if (n.oftenLow) n.key}, {'vitD', 'epaDha', 'mg', 'ala', 'i'});
  });

  test('journée : accroche « couverts à 100 % » fondée sur le vrai compte', () {
    final day = _alexDay();
    final hook = hookFor(day);
    // ignore: avoid_print
    print('journée : ${day.fullyCovered} essentiels à 100 %, ${day.essentialsAtLeast(50)} à 50 % — « ${hook.headline} »');
    if (day.fullyCovered >= 6) {
      expect(hook.headline, contains('${day.fullyCovered} nutriments essentiels sur ${essentialNutrients.length} couverts à 100 %'));
      expect(hook.subline, contains('${day.essentialsAtLeast(50) - day.fullyCovered} autres'));
    }
  });

  testWidgets('rendu PNG de tous les visuels (4 ambiances, 6 formats)', (tester) async {
    final fr = AppLocalizationsFr();
    await tester.runAsync(() async {
      // Police EMBARQUÉE des visuels (pubspec : TotumShare), comme en production.
      final loader = FontLoader('TotumShare');
      for (final f in ['Regular', 'Bold', 'Black']) {
        final bytes = File('assets/fonts/Roboto-$f.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
      await _loadFont('Emoji', [r'C:\Windows\Fonts\seguiemj.ttf']);
      final root = Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['USERPROFILE']}/flutter';
      await _loadFont('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
      final dir = Directory('build/share')..createSync(recursive: true);
      for (final f in dir.listSync()) {
        f.deleteSync();
      }
      Future<void> render(MealShareSlide slide, String name) async {
        final img = await renderWidgetToImage(slide,
            logicalSize: slide.logicalSize, pixelRatio: slide.exportScale, view: tester.view);
        File('${dir.path}/$name.png').writeAsBytesSync(await imageToPng(img));
      }
      MealShareSlide make(ShareSlideKind k, SharePalette p, {int? i, bool reel = false, String handle = ''}) =>
          MealShareSlide(kind: k, data: data, palette: p, l10n: fr, handle: handle,
              index: i, count: i == null ? null : carouselKinds.length, reelFrame: reel,
              fontFamilyFallback: const ['Emoji']);

      for (final pal in SharePalette.all) {
        for (var i = 0; i < carouselKinds.length; i++) {
          await render(make(carouselKinds[i], pal, i: i + 1, handle: pal.id == 'nature' ? '@moncompte' : ''),
              '${pal.id}_${i + 1}_${carouselKinds[i].name}');
        }
      }
      await render(make(ShareSlideKind.story, SharePalette.nature), 'format_story');
      await render(make(ShareSlideKind.post, SharePalette.linen), 'format_post');
      await render(make(ShareSlideKind.landscape, SharePalette.totumCream), 'format_paysage');
      await render(make(ShareSlideKind.banner, SharePalette.totumCream), 'format_banniere_playstore');
      await render(make(ShareSlideKind.stars, SharePalette.totumNight, reel: true), 'format_reel_4');
      for (final f in ShareFocus.values) {
        for (final k in [ShareSlideKind.cover, ShareSlideKind.cta]) {
          await render(
            MealShareSlide(kind: k, data: data, palette: SharePalette.totumCream, l10n: fr, focus: f,
                index: carouselKinds.indexOf(k) + 1, count: carouselKinds.length,
                fontFamilyFallback: const ['Emoji']),
            'angle_${f.name}_${k.name}');
        }
      }
      final day = _alexDay();
      final dayKinds = carouselKindsFor(day);
      expect(dayKinds, isNot(contains(ShareSlideKind.density)));
      expect(carouselKindsFor(data), carouselKinds);
      for (final k in dayKinds) {
        await render(
          MealShareSlide(kind: k, data: day, palette: SharePalette.nature, l10n: fr, 
              index: dayKinds.indexOf(k) + 1, count: dayKinds.length,
              fontFamilyFallback: const ['Emoji']),
          'journee_${k.name}');
      }
      expect(day.isFullDay, isTrue);
      expect(day.gaps().every((g) => g.percent < 75), isTrue);
      // Repas pauvre en nutriments : les visuels restent justes et lisibles.
      final soda = MealShareData(
        title: 'Soda', date: DateTime(2026, 11, 1), kcal: 139, protein: 0, carbs: 35, fat: 0, fiber: 0,
        micros: const {'Sucres_g_100g': 35},
        items: const [MealShareItem(name: 'Boisson au cola', emoji: '🥤', grams: 330, kcal: 139, micros: {'Sucres_g_100g': 35})],
      );
      for (final k in [ShareSlideKind.spotlight, ShareSlideKind.density, ShareSlideKind.stars, ShareSlideKind.panel]) {
        await render(
          MealShareSlide(kind: k, data: soda, palette: SharePalette.minimal, l10n: fr,
              fontFamilyFallback: const ['Emoji']),
          'soda_${k.name}');
      }
      // Petit-déjeuner réel (lin, œufs, huile d'olive, banane) en anglais.
      final bf = _alexMeal(const {
        'Lin brun graine': 22.0,
        'Huile olive vierge extra': 15.0,
        'Oeuf cru': 160.0,
        'Banane chair sans peau crue': 99.0,
      }, 'Breakfast');
      for (final k in carouselKinds) {
        await render(
          MealShareSlide(kind: k, data: bf, palette: SharePalette.linen, l10n: AppLocalizationsEn(), english: true,
              index: carouselKinds.indexOf(k) + 1, count: carouselKinds.length,
              fontFamilyFallback: const ['Emoji']),
          'breakfast_en_${carouselKinds.indexOf(k) + 1}_${k.name}');
      }
      final banner = make(ShareSlideKind.banner, SharePalette.totumCream);
      final img = await renderWidgetToImage(banner, logicalSize: banner.logicalSize, pixelRatio: banner.exportScale, view: tester.view);
      expect((img.width, img.height), (1024, 500));
      final land = make(ShareSlideKind.landscape, SharePalette.totumCream);
      final img2 = await renderWidgetToImage(land, logicalSize: land.logicalSize, pixelRatio: land.exportScale, view: tester.view);
      expect((img2.width, img2.height), (1200, 630));
    });
  });
}
