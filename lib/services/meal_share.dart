// lib/services/meal_share.dart
//
// Données d'un repas (ou d'une journée) à partager sur les réseaux —
// carrousel, post, story, images de Reel, visuels paysage (site/Facebook)
// et bannière Play Store. Demande d'Alex (25-26/10/2026) : un contenu clé
// en main, à forte valeur ajoutée, "comme les meilleurs comptes de
// naturopathes", qui prouve qu'une alimentation bien choisie couvre
// quasiment tous les besoins — pour son compte perso (naturopathe, coach)
// et pour le compte de l'app Totum.
//
// Choix scientifiques et réglementaires (contenu PUBLIC, plus exigeant
// qu'un écran perso) :
// - % calculés sur les VALEURS NUTRITIONNELLES DE RÉFÉRENCE (VNR) de
//   l'étiquetage européen — règlement (UE) n° 1169/2011, annexe XIII — et
//   non sur les cibles personnelles de l'utilisateur.
// - MICRONUTRIMENTS "EN VEDETTE" = seulement ceux qui comptent pour la
//   santé et la longévité, et dont les apports sont souvent insuffisants
//   (études INCA3/Esteban en France) : oméga-3, magnésium, vitamines D, K,
//   C, B9, B12, potassium, zinc, sélénium, iode, calcium... JAMAIS le
//   phosphore, le sodium, le cuivre ou le manganèse — déjà abondants dans
//   l'alimentation moderne (retour d'Alex du 26/10/2026 : mettre en avant le
//   phosphore n'a aucun sens, au contraire).
// - Rôle de chaque nutriment = formulation des ALLÉGATIONS DE SANTÉ
//   AUTORISÉES par l'UE (règlement (UE) n° 432/2012) — rien d'inventé, rien
//   d'interdit.
// - Aucune allégation nutritionnelle ("riche en", "source de" — règlement
//   (CE) n° 1924/2006) : quantités et pourcentages factuels uniquement.
// - Acides gras essentiels : références ANSES 2011 (adulte, 2 000 kcal) —
//   ALA 1 % de l'énergie (2,2 g), LA 4 % (8,9 g), EPA+DHA 500 mg, rapport
//   LA/ALA < 5.

/// Une ligne d'ingrédient du repas partagé.
class MealShareItem {
  final String name;
  final String emoji;
  final double grams;
  final double kcal;
  /// Micronutriments de CET ingrédient (quantités réelles, pas /100 g) —
  /// sert à désigner la "source n°1" de chaque nutriment dans l'assiette.
  final Map<String, double> micros;
  const MealShareItem({
    required this.name,
    required this.emoji,
    required this.grams,
    required this.kcal,
    this.micros = const {},
  });
}

/// Marque du contenu : compte de l'app, ou compte perso du professionnel.
enum ShareBrand { totum, coach }

double _g(Map<String, double> m, String k) => m[k] ?? 0;

/// Un micronutriment "essentiel santé/longévité", avec sa référence, son
/// rôle (allégation UE autorisée) et des aliments qui en apportent.
class EssentialNutrient {
  final String key, labelFr, labelEn, unit, emoji;
  final double reference;
  /// Référence officielle utilisée (affichée en note de bas de visuel).
  final bool isVnr;
  /// Accroche courte (titre) et rôle (formulation d'allégation UE autorisée).
  final String titleFr, titleEn, roleFr, roleEn;
  /// Bons apports courants, pour compléter (pédagogie "l'alimentation suffit").
  final String foodsFr, foodsEn;
  final double Function(Map<String, double> m) amount;
  const EssentialNutrient(this.key, this.labelFr, this.labelEn, this.unit, this.reference, this.emoji,
      {this.isVnr = true,
      required this.titleFr, required this.titleEn,
      required this.roleFr, required this.roleEn,
      required this.foodsFr, required this.foodsEn,
      required this.amount});
  String label(bool en) => en ? labelEn : labelFr;
  String title(bool en) => en ? titleEn : titleFr;
  String role(bool en) => en ? roleEn : roleFr;
  String foods(bool en) => en ? foodsEn : foodsFr;
}

/// Ordre = priorité santé/longévité (départage à pourcentage égal, et ordre
/// des nutriments "à compléter").
final List<EssentialNutrient> essentialNutrients = [
  EssentialNutrient('epaDha', 'Oméga-3 EPA+DHA', 'Omega-3 EPA+DHA', 'mg', 500, '🐟', isVnr: false,
      titleFr: 'Cœur & cerveau', titleEn: 'Heart & brain',
      roleFr: "Contribuent à une fonction cardiaque normale (dès 250 mg par jour).",
      roleEn: 'Contribute to the normal function of the heart (from 250 mg a day).',
      foodsFr: '🐟 sardine · maquereau · saumon · hareng', foodsEn: '🐟 sardine · mackerel · salmon · herring',
      amount: (m) => (_g(m, 'EPA_g_100g') + _g(m, 'DHA_g_100g')) * 1000),
  EssentialNutrient('mg', 'Magnésium', 'Magnesium', 'mg', 375, '🌰',
      titleFr: 'Énergie & nerfs', titleEn: 'Energy & nerves',
      roleFr: 'Contribue à réduire la fatigue et au fonctionnement normal du système nerveux.',
      roleEn: 'Contributes to the reduction of tiredness and to normal functioning of the nervous system.',
      foodsFr: '🌰 graines de courge · amandes · 🍫 chocolat noir · 🫘 légumineuses',
      foodsEn: '🌰 pumpkin seeds · almonds · 🍫 dark chocolate · 🫘 legumes',
      amount: (m) => _g(m, 'Magnésium_mg_100g')),
  EssentialNutrient('vitD', 'Vitamine D', 'Vitamin D', 'µg', 5, '☀️',
      titleFr: 'Immunité & os', titleEn: 'Immunity & bones',
      roleFr: "Contribue au fonctionnement normal du système immunitaire et au maintien d'une ossature normale.",
      roleEn: 'Contributes to the normal function of the immune system and the maintenance of normal bones.',
      foodsFr: '🐟 poissons gras · 🥚 jaune d\'œuf · ☀️ soleil', foodsEn: '🐟 oily fish · 🥚 egg yolk · ☀️ sunlight',
      amount: (m) => _g(m, 'Vitamine_D_µg_100g')),
  EssentialNutrient('vitK', 'Vitamine K', 'Vitamin K', 'µg', 75, '🥬',
      titleFr: 'Os solides', titleEn: 'Strong bones',
      roleFr: "Contribue au maintien d'une ossature normale et à une coagulation sanguine normale.",
      roleEn: 'Contributes to the maintenance of normal bone and to normal blood clotting.',
      foodsFr: '🥬 légumes verts à feuilles · 🥦 brocoli · 🧀 fromages affinés', foodsEn: '🥬 leafy greens · 🥦 broccoli · 🧀 aged cheeses',
      amount: (m) => _g(m, 'Vitamine_K1_µg_100g') + _g(m, 'Vitamine_K2_µg_100g')),
  EssentialNutrient('b9', 'Vitamine B9', 'Folate', 'µg', 200, '🥦',
      titleFr: 'Renouvellement cellulaire', titleEn: 'Cell renewal',
      roleFr: 'Contribue à réduire la fatigue et à la formation normale du sang.',
      roleEn: 'Contributes to the reduction of tiredness and to normal blood formation.',
      foodsFr: '🥬 épinards · 🫘 lentilles · 🥑 avocat · 🥦 brocoli', foodsEn: '🥬 spinach · 🫘 lentils · 🥑 avocado · 🥦 broccoli',
      amount: (m) => _g(m, 'Vitamine_B9_µg_100g')),
  EssentialNutrient('b12', 'Vitamine B12', 'Vitamin B12', 'µg', 2.5, '🐟',
      titleFr: 'Système nerveux', titleEn: 'Nervous system',
      roleFr: 'Contribue au fonctionnement normal du système nerveux et à réduire la fatigue.',
      roleEn: 'Contributes to normal functioning of the nervous system and to the reduction of tiredness.',
      foodsFr: '🐟 poissons · 🦪 fruits de mer · 🥚 œufs · 🥩 viande', foodsEn: '🐟 fish · 🦪 seafood · 🥚 eggs · 🥩 meat',
      amount: (m) => _g(m, 'Vitamine_B12_µg_100g')),
  EssentialNutrient('k', 'Potassium', 'Potassium', 'mg', 2000, '🥑',
      titleFr: 'Tension & muscles', titleEn: 'Blood pressure & muscles',
      roleFr: "Contribue au maintien d'une pression sanguine normale et à une fonction musculaire normale.",
      roleEn: 'Contributes to the maintenance of normal blood pressure and to normal muscle function.',
      foodsFr: '🥔 pomme de terre · 🍌 banane · 🫘 légumineuses · 🥑 avocat', foodsEn: '🥔 potato · 🍌 banana · 🫘 legumes · 🥑 avocado',
      amount: (m) => _g(m, 'Potassium_mg_100g')),
  EssentialNutrient('vitC', 'Vitamine C', 'Vitamin C', 'mg', 80, '🍊',
      titleFr: 'Immunité & collagène', titleEn: 'Immunity & collagen',
      roleFr: 'Contribue au fonctionnement normal du système immunitaire et à la formation normale du collagène.',
      roleEn: 'Contributes to the normal function of the immune system and to normal collagen formation.',
      foodsFr: '🫑 poivron · 🥝 kiwi · 🍊 agrumes · 🥦 brocoli', foodsEn: '🫑 bell pepper · 🥝 kiwi · 🍊 citrus · 🥦 broccoli',
      amount: (m) => _g(m, 'Vitamine_C_mg_100g')),
  EssentialNutrient('zn', 'Zinc', 'Zinc', 'mg', 10, '🛡️',
      titleFr: 'Défenses & peau', titleEn: 'Defences & skin',
      roleFr: "Contribue au fonctionnement normal du système immunitaire et au maintien d'une peau normale.",
      roleEn: 'Contributes to the normal function of the immune system and to the maintenance of normal skin.',
      foodsFr: '🦪 huîtres · 🥩 bœuf · 🎃 graines de courge · 🫘 lentilles', foodsEn: '🦪 oysters · 🥩 beef · 🎃 pumpkin seeds · 🫘 lentils',
      amount: (m) => _g(m, 'Zinc_mg_100g')),
  EssentialNutrient('se', 'Sélénium', 'Selenium', 'µg', 55, '🌰',
      titleFr: 'Antioxydant', titleEn: 'Antioxidant',
      roleFr: 'Contribue à protéger les cellules contre le stress oxydatif et à une fonction thyroïdienne normale.',
      roleEn: 'Contributes to the protection of cells from oxidative stress and to normal thyroid function.',
      foodsFr: '🌰 noix du Brésil · 🐟 poissons · 🥚 œufs', foodsEn: '🌰 Brazil nuts · 🐟 fish · 🥚 eggs',
      amount: (m) => _g(m, 'Sélénium_µg_100g')),
  EssentialNutrient('i', 'Iode', 'Iodine', 'µg', 150, '🌊',
      titleFr: 'Thyroïde', titleEn: 'Thyroid',
      roleFr: 'Contribue à une fonction thyroïdienne normale et à des fonctions cognitives normales.',
      roleEn: 'Contributes to normal thyroid function and to normal cognitive function.',
      foodsFr: '🐟 poissons de mer · 🦐 crustacés · 🥛 laitages · 🧂 sel iodé', foodsEn: '🐟 sea fish · 🦐 shellfish · 🥛 dairy · 🧂 iodised salt',
      amount: (m) => _g(m, 'Iode_µg_100g')),
  EssentialNutrient('ca', 'Calcium', 'Calcium', 'mg', 800, '🦴',
      titleFr: 'Os & dents', titleEn: 'Bones & teeth',
      roleFr: "Nécessaire au maintien d'une ossature et d'une dentition normales.",
      roleEn: 'Needed for the maintenance of normal bones and teeth.',
      foodsFr: '🧀 fromages · 🥛 yaourt · 🐟 sardines avec arêtes · 🥬 chou', foodsEn: '🧀 cheese · 🥛 yoghurt · 🐟 sardines with bones · 🥬 kale',
      amount: (m) => _g(m, 'Calcium_mg_100g')),
  EssentialNutrient('fe', 'Fer', 'Iron', 'mg', 14, '🩸',
      titleFr: 'Oxygène & vitalité', titleEn: 'Oxygen & vitality',
      roleFr: "Contribue au transport normal de l'oxygène dans l'organisme et à réduire la fatigue.",
      roleEn: 'Contributes to normal oxygen transport in the body and to the reduction of tiredness.',
      foodsFr: '🫘 lentilles · 🥩 viande rouge · 🦪 moules · 🥬 épinards (+ vitamine C)', foodsEn: '🫘 lentils · 🥩 red meat · 🦪 mussels · 🥬 spinach (+ vitamin C)',
      amount: (m) => _g(m, 'Fer_mg_100g')),
  EssentialNutrient('vitE', 'Vitamine E', 'Vitamin E', 'mg', 12, '🌻',
      titleFr: 'Antioxydant', titleEn: 'Antioxidant',
      roleFr: 'Contribue à protéger les cellules contre le stress oxydatif.',
      roleEn: 'Contributes to the protection of cells from oxidative stress.',
      foodsFr: '🌻 graines de tournesol · 🌰 amandes · 🫒 huiles végétales', foodsEn: '🌻 sunflower seeds · 🌰 almonds · 🫒 vegetable oils',
      amount: (m) => _g(m, 'Vitamine_E_mg_100g')),
  EssentialNutrient('vitA', 'Vitamine A', 'Vitamin A', 'µg', 800, '🥕',
      titleFr: 'Vision & peau', titleEn: 'Vision & skin',
      roleFr: "Contribue au maintien d'une vision normale et d'une peau normale.",
      roleEn: 'Contributes to the maintenance of normal vision and normal skin.',
      foodsFr: '🥕 carotte · 🍠 patate douce · 🥬 épinards · 🥚 œufs', foodsEn: '🥕 carrot · 🍠 sweet potato · 🥬 spinach · 🥚 eggs',
      // Équivalents rétinol : rétinol + bêta-carotène / 6 (EFSA).
      amount: (m) => _g(m, 'Rétinol_µg_100g') + _g(m, 'Beta-Carotène_µg_100g') / 6),
  EssentialNutrient('b1', 'Vitamine B1', 'Vitamin B1', 'mg', 1.1, '🌾',
      titleFr: 'Métabolisme énergétique', titleEn: 'Energy metabolism',
      roleFr: 'Contribue à un métabolisme énergétique normal et à une fonction cardiaque normale.',
      roleEn: 'Contributes to normal energy-yielding metabolism and to the normal function of the heart.',
      foodsFr: '🌾 céréales complètes · 🫘 légumineuses · 🐖 porc', foodsEn: '🌾 whole grains · 🫘 legumes · 🐖 pork',
      amount: (m) => _g(m, 'Vitamine_B1_mg_100g')),
  EssentialNutrient('b6', 'Vitamine B6', 'Vitamin B6', 'mg', 1.4, '🍌',
      titleFr: 'Anti-fatigue', titleEn: 'Less tiredness',
      roleFr: 'Contribue à réduire la fatigue et au fonctionnement normal du système immunitaire.',
      roleEn: 'Contributes to the reduction of tiredness and to the normal function of the immune system.',
      foodsFr: '🍌 banane · 🐟 poissons · 🍗 volaille · 🥔 pomme de terre', foodsEn: '🍌 banana · 🐟 fish · 🍗 poultry · 🥔 potato',
      amount: (m) => _g(m, 'Vitamine_B6_mg_100g')),
];

/// Un micronutriment mis en avant, avec son % de la référence et sa source
/// principale dans l'assiette.
class NutrientHighlight {
  final EssentialNutrient def;
  final double amount;
  final String? topSourceName;
  final String? topSourceEmoji;
  /// Part (0-1) du total apportée par la source principale.
  final double topSourceShare;
  final bool english;
  const NutrientHighlight({
    required this.def,
    required this.amount,
    this.topSourceName,
    this.topSourceEmoji,
    this.topSourceShare = 0,
    this.english = false,
  });
  String get key => def.key;
  String get label => def.label(english);
  String get unit => def.unit;
  String get emoji => def.emoji;
  double get reference => def.reference;
  double get percent => def.reference > 0 ? amount / def.reference * 100 : 0;
}

/// Apports de référence énergie/macros (UE 1169/2011, annexe XIII, partie B).
const double kRefKcal = 2000;
/// Pas de VNR pour les fibres : apport adéquat EFSA.
const double kRefFiberG = 25;
/// Acides gras essentiels — ANSES 2011 (adulte, 2 000 kcal).
const double kRefAlaG = 2.22; // 1 % de l'énergie
const double kRefLaG = 8.9; // 4 % de l'énergie
const double kRefEpaDhaMg = 500;
const double kMaxLaAlaRatio = 5;

/// Profil des acides gras essentiels du repas.
class FattyAcidProfile {
  final double alaG, laG, epaDhaMg, oleicG, saturatedG;
  const FattyAcidProfile({required this.alaG, required this.laG, required this.epaDhaMg,
      required this.oleicG, required this.saturatedG});
  /// Rapport oméga-6 (LA) / oméga-3 (ALA) — ANSES : idéalement < 5.
  double? get laAlaRatio => alaG > 0.01 ? laG / alaG : null;
  bool get hasData => alaG + laG + epaDhaMg / 1000 + oleicG > 0.05;
}

/// Le repas (ou la journée) à partager, totaux déjà calculés.
class MealShareData {
  final String title;
  final DateTime date;
  final List<MealShareItem> items;
  final double kcal, protein, carbs, fat, fiber;
  /// Micronutriments TOTAUX (pas /100 g), clés CIQUAL.
  final Map<String, double> micros;
  /// Partage d'une journée entière (accroches/légende adaptées).
  final bool isFullDay;

  const MealShareData({
    required this.title,
    required this.date,
    required this.items,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.micros,
    this.isFullDay = false,
  });

  MealShareData copyWith({String? title}) => MealShareData(
        title: title ?? this.title, date: date, items: items, kcal: kcal,
        protein: protein, carbs: carbs, fat: fat, fiber: fiber, micros: micros,
        isFullDay: isFullDay,
      );

  /// Part de l'énergie de chaque macro (Atwater 4/4/9 ; fibres non comptées,
  /// comme sur l'étiquetage). Somme = 1 si énergie > 0.
  ({double protein, double carbs, double fat}) get energySplit {
    final p = protein * 4, c = carbs * 4, f = fat * 9;
    final total = p + c + f;
    if (total <= 0) return (protein: 0, carbs: 0, fat: 0);
    return (protein: p / total, carbs: c / total, fat: f / total);
  }

  double get epaDhaMg => ((micros['EPA_g_100g'] ?? 0) + (micros['DHA_g_100g'] ?? 0)) * 1000;

  FattyAcidProfile get fattyAcids => FattyAcidProfile(
        alaG: micros['Acide_alpha-linolénique_W3_ALA_g_100g'] ?? 0,
        laG: micros['Acide_linoléique_W6_LA_g_100g'] ?? 0,
        epaDhaMg: epaDhaMg,
        oleicG: micros['Acide_oléique_W9_g_100g'] ?? 0,
        saturatedG: micros['AG_saturés_g_100g'] ?? 0,
      );

  NutrientHighlight _highlight(EssentialNutrient d, bool english) {
    final total = d.amount(micros);
    MealShareItem? best;
    var bestAmount = 0.0;
    for (final it in items) {
      final a = d.amount(it.micros);
      if (a > bestAmount) {
        bestAmount = a;
        best = it;
      }
    }
    return NutrientHighlight(
      def: d,
      amount: total,
      topSourceName: best?.name,
      topSourceEmoji: best?.emoji,
      topSourceShare: total > 0 ? (bestAmount / total).clamp(0.0, 1.0) : 0,
      english: english,
    );
  }

  /// Micronutriments essentiels classés par % de la référence. [minPercent] :
  /// 15 % = seuil de "quantité significative" (directive 90/496/CEE, reprise
  /// par le règlement 1169/2011).
  List<NutrientHighlight> highlights({bool english = false, double minPercent = 15, int max = 6}) {
    final out = [for (final d in essentialNutrients) _highlight(d, english)]
      ..removeWhere((h) => h.percent < minPercent);
    // Tri stable : % décroissant, priorité santé à égalité.
    final order = {for (var i = 0; i < essentialNutrients.length; i++) essentialNutrients[i].key: i};
    out.sort((a, b) {
      final c = b.percent.compareTo(a.percent);
      return c != 0 ? c : order[a.key]!.compareTo(order[b.key]!);
    });
    return out.take(max).toList();
  }

  /// Seuil "peu couvert" : un repas représente environ un tiers de la
  /// journée — sous 25 % de la référence, il reste de la marge à combler
  /// ailleurs ; pour une journée entière, sous 75 %.
  double get gapThreshold => isFullDay ? 75 : 25;

  /// Essentiels encore peu couverts, dans l'ordre de priorité santé —
  /// "à compléter dans les autres repas".
  List<NutrientHighlight> gaps({bool english = false, int max = 4}) => [
        for (final d in essentialNutrients) _highlight(d, english),
      ].where((h) => h.percent < gapThreshold).take(max).toList();

  /// Essentiels déjà bien couverts (au-dessus du seuil "peu couvert").
  List<NutrientHighlight> covered({bool english = false}) {
    final out = [for (final d in essentialNutrients) _highlight(d, english)]
        .where((h) => h.percent >= gapThreshold)
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
    return out;
  }

  /// Nombre d'essentiels couverts à au moins [pct] %.
  int essentialsAtLeast(double pct) =>
      essentialNutrients.where((d) => d.amount(micros) / d.reference * 100 >= pct).length;
}

/// "vitamine B12", "oméga-3 EPA+DHA" : seule la 1re lettre passe en minuscule
/// (jamais "vitamine b12" au milieu d'une phrase).
String lowerFirst(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

/// Nombre au format de la langue : "1,4" / "1 870" en français, "1.4" /
/// "1,870" en anglais.
String fmtNum(double v, {int decimals = 0, bool english = false}) {
  var t = v.toStringAsFixed(decimals);
  final parts = t.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final fromEnd = intPart.length - i;
    buf.write(intPart[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1 && intPart[i] != '-') buf.write(english ? ',' : ' ');
  }
  t = buf.toString();
  if (parts.length > 1) t += (english ? '.' : ',') + parts[1];
  return t;
}

String formatAmount(double v, String unit) {
  if (unit == 'kcal' || v >= 100) return v.round().toString();
  if (v >= 10) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1).replaceAll('.0', '');
}

/// Accroche du 1er visuel : un titre court + une ligne de promesse, construits
/// UNIQUEMENT à partir des chiffres réels (jamais de promesse santé).
({String headline, String subline}) hookFor(MealShareData d, {bool english = false}) {
  final top = d.highlights(english: english, max: 1);
  final n30 = d.essentialsAtLeast(30);
  final scope = d.isFullDay
      ? (english ? 'in one day of eating' : 'en une journée')
      : (english ? 'in one plate' : 'dans une seule assiette');
  if (top.isNotEmpty && top.first.percent >= 100) {
    final h = top.first;
    return (
      headline: english
          ? '${h.percent.round()}% of the ${h.label} reference $scope'
          : '${h.percent.round()} % de la référence en ${lowerFirst(h.label)} $scope',
      subline: english
          ? '$n30 essential micronutrients above 30% — no supplements.'
          : '$n30 micronutriments essentiels au-dessus de 30 % — sans complément.',
    );
  }
  if (d.protein >= 30) {
    return (
      headline: english ? '${d.protein.round()} g of protein $scope' : '${d.protein.round()} g de protéines $scope',
      subline: english
          ? '${d.fiber.round()} g of fiber and $n30 essentials above 30%.'
          : '${d.fiber.round()} g de fibres et $n30 essentiels au-dessus de 30 %.',
    );
  }
  return (
    headline: english ? 'What this plate really contains' : 'Ce que contient vraiment mon assiette',
    subline: english
        ? 'Macros, micronutrients and essential fats, decoded.'
        : 'Macros, micronutriments et acides gras essentiels, décryptés.',
  );
}

/// "Ce que j'en retiens" : 2-3 constats factuels tirés des données.
List<String> insightsFor(MealShareData d, {bool english = false}) {
  final out = <String>[];
  final n30 = d.essentialsAtLeast(30);
  if (n30 >= 3) {
    out.add(english
        ? '$n30 of the ${essentialNutrients.length} essentials I track are above 30% of the reference — from real food only.'
        : '$n30 des ${essentialNutrients.length} micronutriments essentiels que je suis dépassent 30 % de la référence — uniquement avec de vrais aliments.');
  }
  if (d.protein >= 25) {
    out.add(english
        ? '${d.protein.round()} g of protein: a solid base for satiety and muscle maintenance.'
        : '${d.protein.round()} g de protéines : une base solide pour la satiété et le maintien musculaire.');
  }
  if (d.fiber >= 8) {
    out.add(english
        ? '${d.fiber.round()} g of fiber, i.e. ${(d.fiber / kRefFiberG * 100).round()}% of the EFSA 25 g/day.'
        : '${d.fiber.round()} g de fibres, soit ${(d.fiber / kRefFiberG * 100).round()} % des 25 g/j de l\'EFSA.');
  }
  final fa = d.fattyAcids;
  final ratio = fa.laAlaRatio;
  if (ratio != null && ratio <= kMaxLaAlaRatio && out.length < 3) {
    out.add(english
        ? 'Omega-6/omega-3 ratio of ${fmtNum(ratio, decimals: 1, english: true)}: within the ANSES target (< 5).'
        : 'Rapport oméga-6/oméga-3 de ${fmtNum(ratio, decimals: 1)} : dans la cible de l\'ANSES (< 5).');
  }
  return out.take(3).toList();
}

/// Mots-dièse : 5 maximum (limite Instagram depuis décembre 2025).
List<String> hashtagsFor(MealShareData d, {bool english = false, ShareBrand brand = ShareBrand.coach}) {
  final tags = <String>[];
  if (brand == ShareBrand.totum) {
    tags.add('#totum');
  } else {
    tags.add(english ? '#nutrition' : '#naturopathie');
  }
  tags.add(english ? '#micronutrients' : '#micronutrition');
  tags.add(english ? '#longevity' : '#longevite');
  if (d.epaDhaMg >= 500) {
    tags.add('#omega3');
  } else if (d.protein >= 30) {
    tags.add(english ? '#protein' : '#proteines');
  } else {
    tags.add(english ? '#healthyeating' : '#alimentationsaine');
  }
  tags.add(english ? '#wholefood' : '#mangersain');
  return tags.take(5).toList();
}

/// Appel à l'action final, selon la marque.
({String main, String sub}) ctaFor(ShareBrand brand, String handle, {bool english = false}) {
  final h = handle.trim();
  if (brand == ShareBrand.totum) {
    return (
      main: english ? 'Decode your own plates with Totum' : 'Décrypte tes propres assiettes avec Totum',
      sub: english
          ? 'Macros, micronutrients, essential fats — free on Google Play.'
          : 'Macros, micronutriments, acides gras essentiels — gratuit sur Google Play.',
    );
  }
  return (
    main: h.isEmpty
        ? (english ? 'Follow for one decoded plate every week' : 'Abonne-toi : une assiette décryptée chaque semaine')
        : (english ? 'Follow $h for more decoded plates' : 'Suis $h pour d\'autres assiettes décryptées'),
    sub: english
        ? 'Naturopathy, training and nutrition for health and longevity.'
        : 'Naturopathie, sport et nutrition au service de ta santé et ta longévité.',
  );
}

/// Légende complète prête à coller : accroche, macros, essentiels avec leur
/// rôle, acides gras, ingrédients, appels à l'enregistrement et au partage
/// (signaux qu'Instagram dit valoriser), puis 5 mots-dièse max.
String captionFor(MealShareData d, {bool english = false, String handle = '', ShareBrand brand = ShareBrand.coach}) {
  final b = StringBuffer();
  final hook = hookFor(d, english: english);
  b.writeln('${d.title} 🍽️');
  b.writeln(hook.headline);
  b.writeln();
  b.writeln('⚡ ${d.kcal.round()} kcal · 🥩 P ${d.protein.round()} g · '
      '🌾 ${english ? 'C' : 'G'} ${d.carbs.round()} g · 🫒 ${english ? 'F' : 'L'} ${d.fat.round()} g · '
      '🌿 ${english ? 'Fiber' : 'Fibres'} ${d.fiber.round()} g');
  final hs = d.highlights(english: english, max: 4);
  if (hs.isNotEmpty) {
    b.writeln();
    b.writeln(english ? '✨ Essential micronutrients (% of reference):' : '✨ Micronutriments essentiels (% de la référence) :');
    for (final h in hs) {
      b.writeln('${h.emoji} ${h.label} ${h.percent.round()} % — ${h.def.role(english)}');
    }
  }
  final fa = d.fattyAcids;
  if (fa.hasData) {
    b.writeln();
    b.writeln(english ? '🫒 Essential fats:' : '🫒 Acides gras essentiels :');
    b.writeln('Oméga-3 ALA ${fa.alaG.toStringAsFixed(1)} g · EPA+DHA ${fa.epaDhaMg.round()} mg · Oméga-6 ${fa.laG.toStringAsFixed(1)} g'
        '${fa.laAlaRatio != null ? ' · ratio ω6/ω3 ${fa.laAlaRatio!.toStringAsFixed(1)}' : ''}');
  }
  if (d.items.isNotEmpty && !d.isFullDay) {
    b.writeln();
    b.writeln(english ? '🥣 Ingredients:' : '🥣 Ingrédients :');
    for (final it in d.items) {
      b.writeln('• ${it.grams.round()} g ${english ? it.name : _withDe(it.name)}');
    }
  }
  b.writeln();
  b.writeln(english ? '💾 Save it for your next plate' : '💾 Enregistre-le pour ta prochaine assiette');
  b.writeln(english ? '✈️ Send it to someone who cares about their health' : '✈️ Envoie-le à quelqu\'un qui prend soin de sa santé');
  b.writeln(english ? '💬 Which nutrient surprised you most?' : '💬 Quel nutriment t\'a le plus surpris ?');
  b.writeln();
  final cta = ctaFor(brand, handle, english: english);
  b.writeln('👉 ${cta.main}');
  b.writeln(cta.sub);
  b.writeln(english
      ? 'Values per serving (ANSES-CIQUAL table, EU reference values).'
      : 'Valeurs pour la portion (table ANSES-CIQUAL, valeurs de référence UE).');
  b.writeln();
  b.write(hashtagsFor(d, english: english, brand: brand).join(' '));
  return b.toString();
}

/// "de pâtes" / "d'avocat" / "d'huile" — élision devant voyelle ou h muet.
String _withDe(String name) {
  if (name.isEmpty) return name;
  final first = name[0].toLowerCase();
  final lower = name[0].toLowerCase() + name.substring(1);
  return 'aàâeéèêiîoôuûyh'.contains(first) ? "d'$lower" : 'de $lower';
}

/// Nom court d'un ingrédient pour un visuel : partie avant la première
/// virgule ou parenthèse, capitalisée.
String shortFoodName(String name) {
  var n = name.split(RegExp(r'[,(]')).first.trim();
  if (n.isEmpty) n = name.trim();
  if (n.length > 34) n = '${n.substring(0, 33).trimRight()}…';
  return n.isEmpty ? n : n[0].toUpperCase() + n.substring(1);
}

/// Construit un [MealShareData] à partir des entrées du journal.
/// [lookup] retrouve l'aliment complet (micros /100 g, pictogramme, nom).
MealShareData buildMealShareData({
  required String title,
  required DateTime date,
  required List<Map<String, dynamic>> entries,
  required ({Map<String, double> micros100, String? emoji, String displayName})? Function(String id, String name) lookup,
  bool isFullDay = false,
}) {
  double kcal = 0, p = 0, c = 0, f = 0, fi = 0;
  final micros = <String, double>{};
  // Un même aliment présent plusieurs fois (journée entière, 2 repas) est
  // regroupé en une seule ligne d'ingrédient.
  final byName = <String, MealShareItem>{};
  for (final e in entries) {
    double num_(String k) => (e[k] as num?)?.toDouble() ?? 0.0;
    final grams = num_('grams');
    kcal += num_('kcal');
    p += num_('prot');
    c += num_('carb');
    f += num_('fat');
    fi += num_('fiber');
    final id = (e['id'] ?? '').toString();
    final rawName = (e['name'] ?? '').toString();
    final food = lookup(id, rawName);
    final itemMicros = <String, double>{};
    if (food != null) {
      food.micros100.forEach((k, v) {
        final a = v * grams / 100.0;
        itemMicros[k] = a;
        micros[k] = (micros[k] ?? 0) + a;
      });
    }
    final name = shortFoodName(food?.displayName ?? rawName);
    final prev = byName[name];
    if (prev == null) {
      byName[name] = MealShareItem(
        name: name, emoji: food?.emoji ?? '🍽️', grams: grams, kcal: num_('kcal'), micros: itemMicros,
      );
    } else {
      final merged = Map<String, double>.from(prev.micros);
      itemMicros.forEach((k, v) => merged[k] = (merged[k] ?? 0) + v);
      byName[name] = MealShareItem(
        name: name, emoji: prev.emoji, grams: prev.grams + grams, kcal: prev.kcal + num_('kcal'), micros: merged,
      );
    }
  }
  final items = byName.values.toList()..sort((a, b) => b.grams.compareTo(a.grams));
  return MealShareData(
    title: title, date: date, items: items,
    kcal: kcal, protein: p, carbs: c, fat: f, fiber: fi,
    micros: micros, isFullDay: isFullDay,
  );
}

/// Taille max d'une liste d'ingrédients lisible sur un visuel 1080 px.
int maxIngredientsOnSlide(int available) => available < 9 ? available : 9;
