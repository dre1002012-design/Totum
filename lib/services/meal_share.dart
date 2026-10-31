// lib/services/meal_share.dart
//
// Données d'un repas (ou d'une journée) à partager — carrousel, post, story,
// images de Reel, visuel paysage (site, Facebook, LinkedIn) et bannière.
// Fonction GÉNÉRALISTE (27/10/2026, retour d'Alex) : l'app est en
// production, chaque utilisateur partage SES repas, sur le réseau ou le
// support de son choix — aucune notion de compte "pro" ou de marque imposée
// (un @compte optionnel et une mention Totum discrète, désactivable).
//
// Fiabilité des données affichées (contenu PUBLIC, donc plus exigeant
// qu'un écran perso) — 2 référentiels seulement, cités de façon homogène :
// - Vitamines et minéraux : % des VALEURS NUTRITIONNELLES DE RÉFÉRENCE (VNR)
//   de l'UE pour un adulte (règlement (UE) 1169/2011, annexe XIII) — les
//   mêmes que sur les emballages.
// - Fibres et acides gras essentiels : repères de l'ANSES pour un adulte
//   (fibres 30 g/j ; ALA 1 % de l'énergie, LA 4 %, EPA+DHA 500 mg/j, base
//   2 000 kcal ; rapport LA/ALA < 5).
// - Rôle de chaque nutriment : formulation des allégations de santé
//   AUTORISÉES dans l'UE (règlement (UE) 432/2012), au sujet du NUTRIMENT —
//   jamais une promesse sur le plat.
// - Aucune allégation "riche en"/"source de" (règlement (CE) 1924/2006).
// - Micronutriments EN VEDETTE = essentiels santé/longévité uniquement ;
//   jamais phosphore, sodium, cuivre, manganèse (déjà abondants).
// - Pas d'emoji pour représenter un nutriment (retour d'Alex : aucun ne
//   correspondait vraiment) : un symbole explicite (Mg, Zn, VIT D, ω3...) ;
//   les emojis restent réservés aux ALIMENTS, où ils ont un sens.

/// Une ligne d'ingrédient du repas partagé.
class MealShareItem {
  final String name;
  /// Pictogramme de l'aliment (base Ciqual), affiché seulement à côté de
  /// l'aliment lui-même.
  final String emoji;
  final double grams;
  final double kcal;
  /// Micronutriments de CET ingrédient (quantités réelles, pas /100 g) —
  /// sert à désigner la source n°1 de chaque nutriment dans l'assiette.
  final Map<String, double> micros;
  /// Faux si aucune donnée de micronutriments n'est connue pour cet
  /// ingrédient (aliment perso saisi sans micros, produit scanné incomplet).
  final bool hasMicroData;
  /// Aliment d'origine végétale (fruit, légume, légumineuse, céréale,
  /// oléagineux, herbe/épice, algue) — compte pour la diversité végétale.
  final bool isPlant;
  /// Degré de transformation NOVA (1 = brut ou peu transformé … 4 =
  /// ultra-transformé) ; estimé pour la base Ciqual, null si inconnu.
  final int? nova;
  const MealShareItem({
    required this.name,
    required this.emoji,
    required this.grams,
    required this.kcal,
    this.micros = const {},
    this.hasMicroData = true,
    this.isPlant = false,
    this.nova,
  });
}

/// Angle éditorial du partage (31/10/2026, demande d'Alex : le même repas
/// ne se raconte pas pareil pour un sportif, une personne qui surveille sa
/// ligne ou quelqu'un d'attentif à sa santé/longévité — coach,
/// nutritionniste, naturopathe). Change l'accroche, les chiffres de
/// couverture, l'ordre des micronutriments mis en avant, « À retenir » et
/// les mots-dièse — jamais les données elles-mêmes.
enum ShareFocus { balance, sport, satiety, longevity }

/// Micronutriments mis en avant en priorité selon l'angle (allégations UE
/// autorisées correspondantes : fonction musculaire, métabolisme
/// énergétique, fatigue pour le sport ; stress oxydatif, cœur, os pour la
/// longévité).
const Map<ShareFocus, List<String>> kFocusNutrients = {
  ShareFocus.sport: ['mg', 'k', 'fe', 'b1', 'b6', 'b12', 'zn'],
  ShareFocus.longevity: ['epaDha', 'vitC', 'vitE', 'se', 'b9', 'vitK', 'vitD', 'mg'],
};

/// Repère de diversité végétale : 30 végétaux différents par semaine
/// (McDonald et al., American Gut Project, mSystems 2018).
const int kPlantsPerWeekRef = 30;

enum NutrientKind { vitamin, mineral, fattyAcid }

double _g(Map<String, double> m, String k) => m[k] ?? 0;

/// Un micronutriment essentiel santé/longévité : symbole, référence, rôle
/// (allégation UE autorisée) et aliments qui en apportent.
class EssentialNutrient {
  final String key, labelFr, labelEn, unit;
  /// Symbole affiché dans le badge : "Mg", "D", "B12", "ω3"...
  final String symbol;
  final NutrientKind kind;
  final double reference;
  final String titleFr, titleEn, roleFr, roleEn, foodsFr, foodsEn;
  final double Function(Map<String, double> m) amount;
  const EssentialNutrient(this.key, this.labelFr, this.labelEn, this.unit, this.reference, this.symbol, this.kind,
      {required this.titleFr, required this.titleEn,
      required this.roleFr, required this.roleEn,
      required this.foodsFr, required this.foodsEn,
      required this.amount});
  String label(bool en) => en ? labelEn : labelFr;
  String title(bool en) => en ? titleEn : titleFr;
  String role(bool en) => en ? roleEn : roleFr;
  String foods(bool en) => en ? foodsEn : foodsFr;
}

/// Ordre = priorité santé/longévité (départage à pourcentage égal et ordre
/// des nutriments à compléter).
final List<EssentialNutrient> essentialNutrients = [
  EssentialNutrient('epaDha', 'Oméga-3 EPA+DHA', 'Omega-3 EPA+DHA', 'mg', 500, 'ω3', NutrientKind.fattyAcid,
      titleFr: 'Cœur & cerveau', titleEn: 'Heart & brain',
      roleFr: 'Contribuent à une fonction cardiaque normale (à partir de 250 mg par jour).',
      roleEn: 'Contribute to the normal function of the heart (from 250 mg a day).',
      foodsFr: 'sardine · maquereau · saumon · hareng', foodsEn: 'sardine · mackerel · salmon · herring',
      amount: (m) => (_g(m, 'EPA_g_100g') + _g(m, 'DHA_g_100g')) * 1000),
  EssentialNutrient('mg', 'Magnésium', 'Magnesium', 'mg', 375, 'Mg', NutrientKind.mineral,
      titleFr: 'Énergie & système nerveux', titleEn: 'Energy & nervous system',
      roleFr: 'Contribue à réduire la fatigue et au fonctionnement normal du système nerveux.',
      roleEn: 'Contributes to the reduction of tiredness and to normal functioning of the nervous system.',
      foodsFr: 'graines de courge · amandes · chocolat noir · légumineuses',
      foodsEn: 'pumpkin seeds · almonds · dark chocolate · legumes',
      amount: (m) => _g(m, 'Magnésium_mg_100g')),
  EssentialNutrient('vitD', 'Vitamine D', 'Vitamin D', 'µg', 5, 'D', NutrientKind.vitamin,
      titleFr: 'Immunité & os', titleEn: 'Immunity & bones',
      roleFr: "Contribue au fonctionnement normal du système immunitaire et au maintien d'une ossature normale.",
      roleEn: 'Contributes to the normal function of the immune system and the maintenance of normal bones.',
      foodsFr: 'poissons gras · jaune d\'œuf · exposition au soleil', foodsEn: 'oily fish · egg yolk · sunlight',
      amount: (m) => _g(m, 'Vitamine_D_µg_100g')),
  EssentialNutrient('vitK', 'Vitamine K', 'Vitamin K', 'µg', 75, 'K', NutrientKind.vitamin,
      titleFr: 'Os & coagulation', titleEn: 'Bones & clotting',
      roleFr: "Contribue au maintien d'une ossature normale et à une coagulation sanguine normale.",
      roleEn: 'Contributes to the maintenance of normal bone and to normal blood clotting.',
      foodsFr: 'légumes verts à feuilles · brocoli · fromages affinés', foodsEn: 'leafy greens · broccoli · aged cheeses',
      amount: (m) => _g(m, 'Vitamine_K1_µg_100g') + _g(m, 'Vitamine_K2_µg_100g')),
  EssentialNutrient('b9', 'Vitamine B9', 'Folate', 'µg', 200, 'B9', NutrientKind.vitamin,
      titleFr: 'Renouvellement cellulaire', titleEn: 'Cell renewal',
      roleFr: 'Contribue à réduire la fatigue et à la formation normale du sang.',
      roleEn: 'Contributes to the reduction of tiredness and to normal blood formation.',
      foodsFr: 'épinards · lentilles · avocat · brocoli', foodsEn: 'spinach · lentils · avocado · broccoli',
      amount: (m) => _g(m, 'Vitamine_B9_µg_100g')),
  EssentialNutrient('b12', 'Vitamine B12', 'Vitamin B12', 'µg', 2.5, 'B12', NutrientKind.vitamin,
      titleFr: 'Système nerveux', titleEn: 'Nervous system',
      roleFr: 'Contribue au fonctionnement normal du système nerveux et à réduire la fatigue.',
      roleEn: 'Contributes to normal functioning of the nervous system and to the reduction of tiredness.',
      foodsFr: 'poissons · fruits de mer · œufs · viande', foodsEn: 'fish · seafood · eggs · meat',
      amount: (m) => _g(m, 'Vitamine_B12_µg_100g')),
  EssentialNutrient('k', 'Potassium', 'Potassium', 'mg', 2000, 'K', NutrientKind.mineral,
      titleFr: 'Tension & muscles', titleEn: 'Blood pressure & muscles',
      roleFr: "Contribue au maintien d'une pression sanguine normale et à une fonction musculaire normale.",
      roleEn: 'Contributes to the maintenance of normal blood pressure and to normal muscle function.',
      foodsFr: 'pomme de terre · banane · légumineuses · avocat', foodsEn: 'potato · banana · legumes · avocado',
      amount: (m) => _g(m, 'Potassium_mg_100g')),
  EssentialNutrient('vitC', 'Vitamine C', 'Vitamin C', 'mg', 80, 'C', NutrientKind.vitamin,
      titleFr: 'Immunité & collagène', titleEn: 'Immunity & collagen',
      roleFr: 'Contribue au fonctionnement normal du système immunitaire et à la formation normale du collagène.',
      roleEn: 'Contributes to the normal function of the immune system and to normal collagen formation.',
      foodsFr: 'poivron · kiwi · agrumes · brocoli', foodsEn: 'bell pepper · kiwi · citrus · broccoli',
      amount: (m) => _g(m, 'Vitamine_C_mg_100g')),
  EssentialNutrient('zn', 'Zinc', 'Zinc', 'mg', 10, 'Zn', NutrientKind.mineral,
      titleFr: 'Défenses & peau', titleEn: 'Defences & skin',
      roleFr: "Contribue au fonctionnement normal du système immunitaire et au maintien d'une peau normale.",
      roleEn: 'Contributes to the normal function of the immune system and to the maintenance of normal skin.',
      foodsFr: 'huîtres · bœuf · graines de courge · lentilles', foodsEn: 'oysters · beef · pumpkin seeds · lentils',
      amount: (m) => _g(m, 'Zinc_mg_100g')),
  EssentialNutrient('se', 'Sélénium', 'Selenium', 'µg', 55, 'Se', NutrientKind.mineral,
      titleFr: 'Protection cellulaire', titleEn: 'Cell protection',
      roleFr: 'Contribue à protéger les cellules contre le stress oxydatif et à une fonction thyroïdienne normale.',
      roleEn: 'Contributes to the protection of cells from oxidative stress and to normal thyroid function.',
      foodsFr: 'noix du Brésil · poissons · œufs', foodsEn: 'Brazil nuts · fish · eggs',
      amount: (m) => _g(m, 'Sélénium_µg_100g')),
  EssentialNutrient('i', 'Iode', 'Iodine', 'µg', 150, 'I', NutrientKind.mineral,
      titleFr: 'Thyroïde', titleEn: 'Thyroid',
      roleFr: 'Contribue à une fonction thyroïdienne normale et à des fonctions cognitives normales.',
      roleEn: 'Contributes to normal thyroid function and to normal cognitive function.',
      foodsFr: 'poissons de mer · crustacés · produits laitiers · sel iodé', foodsEn: 'sea fish · shellfish · dairy · iodised salt',
      amount: (m) => _g(m, 'Iode_µg_100g')),
  EssentialNutrient('ca', 'Calcium', 'Calcium', 'mg', 800, 'Ca', NutrientKind.mineral,
      titleFr: 'Os & dents', titleEn: 'Bones & teeth',
      roleFr: "Nécessaire au maintien d'une ossature et d'une dentition normales.",
      roleEn: 'Needed for the maintenance of normal bones and teeth.',
      foodsFr: 'fromages · yaourts · sardines avec arêtes · chou kale', foodsEn: 'cheese · yoghurt · sardines with bones · kale',
      amount: (m) => _g(m, 'Calcium_mg_100g')),
  EssentialNutrient('fe', 'Fer', 'Iron', 'mg', 14, 'Fe', NutrientKind.mineral,
      titleFr: 'Oxygénation', titleEn: 'Oxygen transport',
      roleFr: "Contribue au transport normal de l'oxygène dans l'organisme et à réduire la fatigue.",
      roleEn: 'Contributes to normal oxygen transport in the body and to the reduction of tiredness.',
      foodsFr: 'lentilles · viande rouge · moules · épinards (avec une source de vitamine C)',
      foodsEn: 'lentils · red meat · mussels · spinach (with a vitamin C source)',
      amount: (m) => _g(m, 'Fer_mg_100g')),
  EssentialNutrient('vitE', 'Vitamine E', 'Vitamin E', 'mg', 12, 'E', NutrientKind.vitamin,
      titleFr: 'Protection cellulaire', titleEn: 'Cell protection',
      roleFr: 'Contribue à protéger les cellules contre le stress oxydatif.',
      roleEn: 'Contributes to the protection of cells from oxidative stress.',
      foodsFr: 'graines de tournesol · amandes · huile de colza', foodsEn: 'sunflower seeds · almonds · rapeseed oil',
      amount: (m) => _g(m, 'Vitamine_E_mg_100g')),
  EssentialNutrient('vitA', 'Vitamine A', 'Vitamin A', 'µg', 800, 'A', NutrientKind.vitamin,
      titleFr: 'Vision & peau', titleEn: 'Vision & skin',
      roleFr: "Contribue au maintien d'une vision normale et d'une peau normale.",
      roleEn: 'Contributes to the maintenance of normal vision and normal skin.',
      foodsFr: 'carotte · patate douce · épinards · œufs', foodsEn: 'carrot · sweet potato · spinach · eggs',
      // Équivalents rétinol : rétinol + bêta-carotène / 6 (EFSA).
      amount: (m) => _g(m, 'Rétinol_µg_100g') + _g(m, 'Beta-Carotène_µg_100g') / 6),
  EssentialNutrient('b1', 'Vitamine B1', 'Vitamin B1', 'mg', 1.1, 'B1', NutrientKind.vitamin,
      titleFr: 'Métabolisme énergétique', titleEn: 'Energy metabolism',
      roleFr: 'Contribue à un métabolisme énergétique normal et à une fonction cardiaque normale.',
      roleEn: 'Contributes to normal energy-yielding metabolism and to the normal function of the heart.',
      foodsFr: 'céréales complètes · légumineuses · porc', foodsEn: 'whole grains · legumes · pork',
      amount: (m) => _g(m, 'Vitamine_B1_mg_100g')),
  EssentialNutrient('b6', 'Vitamine B6', 'Vitamin B6', 'mg', 1.4, 'B6', NutrientKind.vitamin,
      titleFr: 'Énergie & immunité', titleEn: 'Energy & immunity',
      roleFr: 'Contribue à réduire la fatigue et au fonctionnement normal du système immunitaire.',
      roleEn: 'Contributes to the reduction of tiredness and to the normal function of the immune system.',
      foodsFr: 'banane · poissons · volaille · pomme de terre', foodsEn: 'banana · fish · poultry · potato',
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
  String get symbol => def.symbol;
  NutrientKind get kind => def.kind;
  double get reference => def.reference;
  double get percent => def.reference > 0 ? amount / def.reference * 100 : 0;
}

/// Repère fibres de l'ANSES (adulte).
const double kRefFiberG = 30;
/// Acides gras essentiels — repères ANSES (adulte, 2 000 kcal).
const double kRefAlaG = 2.22; // 1 % de l'énergie
const double kRefLaG = 8.9; // 4 % de l'énergie
const double kRefEpaDhaMg = 500;
const double kMaxLaAlaRatio = 5;

/// Profil des acides gras essentiels.
class FattyAcidProfile {
  final double alaG, laG, epaDhaMg;
  const FattyAcidProfile({required this.alaG, required this.laG, required this.epaDhaMg});
  /// Rapport oméga-6 / oméga-3 TOTAL (ALA + EPA + DHA) — cible < 5.
  /// CORRIGÉ (27/10/2026) : calculé auparavant sur l'ALA seul (rapport des
  /// précurseurs de l'ANSES), il affichait 10,3 et conseillait "ajoute du
  /// lin" pour un plat de sardines apportant 1,9 g d'oméga-3 marins —
  /// exact au sens strict, mais trompeur pour un lecteur. Le rapport
  /// grand public compte tous les oméga-3.
  double? get laAlaRatio {
    final omega3 = alaG + epaDhaMg / 1000;
    return omega3 > 0.01 ? laG / omega3 : null;
  }
  bool get hasData => alaG + laG + epaDhaMg / 1000 > 0.05;
}

/// Le repas (ou la journée) à partager, totaux déjà calculés.
class MealShareData {
  final String title;
  final DateTime date;
  final List<MealShareItem> items;
  final double kcal, protein, carbs, fat, fiber;
  /// Micronutriments TOTAUX (pas /100 g), clés Ciqual.
  final Map<String, double> micros;
  /// Partage d'une journée entière (accroches et seuils adaptés).
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

  /// Ingrédients sans donnée de micronutriments : les micros affichés sont
  /// alors sous-estimés — signalé sur le visuel, jamais caché.
  int get itemsWithoutMicroData => items.where((i) => !i.hasMicroData).length;

  double get totalGrams => items.fold(0.0, (s, i) => s + i.grams);

  /// Végétaux DIFFÉRENTS dans l'assiette (un aliment = un végétal).
  int get plantCount => items.where((i) => i.isPlant).length;

  /// kcal pour 100 g d'assiette (densité énergétique).
  double get energyDensity => totalGrams > 0 ? kcal / totalGrams * 100 : 0;

  /// Part (0-1) du poids de l'assiette en aliments bruts ou peu transformés
  /// (NOVA 1). Null si le degré de transformation est inconnu pour plus
  /// d'un quart du poids : jamais un pourcentage bâti sur trop peu.
  double? get rawShare {
    final known = items.where((i) => i.nova != null);
    final knownG = known.fold(0.0, (s, i) => s + i.grams);
    if (totalGrams <= 0 || knownG < totalGrams * 0.75) return null;
    final rawG = known.where((i) => i.nova == 1).fold(0.0, (s, i) => s + i.grams);
    return rawG / knownG;
  }

  /// Part de l'énergie de chaque macro (4/4/9 kcal par g ; fibres non
  /// comptées, comme sur l'étiquetage). Somme = 1 si énergie > 0.
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

  /// Micronutriments essentiels classés par % de la référence. 15 % =
  /// seuil de "quantité significative" de l'étiquetage européen.
  List<NutrientHighlight> highlights({bool english = false, double minPercent = 15, int max = 6,
      ShareFocus focus = ShareFocus.balance}) {
    final out = [for (final d in essentialNutrients) _highlight(d, english)]
      ..removeWhere((h) => h.percent < minPercent);
    final order = {for (var i = 0; i < essentialNutrients.length; i++) essentialNutrients[i].key: i};
    // Angle choisi : ses micronutriments passent devant, puis les autres.
    final preferred = kFocusNutrients[focus] ?? const <String>[];
    out.sort((a, b) {
      final pa = preferred.contains(a.key), pb = preferred.contains(b.key);
      if (pa != pb) return pa ? -1 : 1;
      final c = b.percent.compareTo(a.percent);
      return c != 0 ? c : order[a.key]!.compareTo(order[b.key]!);
    });
    return out.take(max).toList();
  }

  /// Seuil "peu couvert" : un repas représente environ un tiers de la
  /// journée — sous 25 % de la référence, il reste de la marge à combler
  /// ailleurs ; pour une journée entière, sous 75 %.
  double get gapThreshold => isFullDay ? 75 : 25;

  /// Essentiels encore peu couverts, dans l'ordre de priorité santé.
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

/// "vitamine B12", "oméga-3 EPA+DHA" : seule la 1re lettre passe en minuscule.
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

/// Quantité d'un nutriment, lisible (pas de "0.0", décimale à la française).
String formatAmount(double v, String unit, {bool english = false}) {
  if (v >= 100) return fmtNum(v, english: english);
  if (v >= 10) return fmtNum(v, english: english);
  final t = fmtNum(v, decimals: 1, english: english);
  return t.endsWith(english ? '.0' : ',0') ? t.substring(0, t.length - 2) : t;
}

/// Accroche du 1er visuel : un titre court + une ligne, construits
/// UNIQUEMENT à partir des chiffres réels (jamais de promesse santé).
({String headline, String subline}) hookFor(MealShareData d,
    {bool english = false, ShareFocus focus = ShareFocus.balance}) {
  final top = d.highlights(english: english, max: 1);
  final n30 = d.essentialsAtLeast(30);
  final total = essentialNutrients.length;
  final scope = d.isFullDay
      ? (english ? 'in one day of eating' : 'en une journée')
      : (english ? 'in one plate' : 'dans une seule assiette');
  final sub = english
      ? '$n30 of $total essential micronutrients above 30% of the reference.'
      : '$n30 micronutriments essentiels sur $total au-dessus de 30 % de la référence.';
  final split = d.energySplit;
  switch (focus) {
    case ShareFocus.sport when d.protein >= 15:
      return (
        headline: english
            ? '${d.protein.round()} g protein & ${d.carbs.round()} g carbs $scope'
            : '${d.protein.round()} g de protéines et ${d.carbs.round()} g de glucides $scope',
        subline: english
            ? 'Protein ${(split.protein * 100).round()}% · carbs ${(split.carbs * 100).round()}% · fat ${(split.fat * 100).round()}% of the energy.'
            : 'Protéines ${(split.protein * 100).round()} % · glucides ${(split.carbs * 100).round()} % · lipides ${(split.fat * 100).round()} % de l\'énergie.',
      );
    case ShareFocus.satiety when d.totalGrams > 0:
      return (
        headline: english
            ? '${fmtNum(d.kcal, english: true)} kcal for ${fmtNum(d.totalGrams, english: true)} g of food'
            : '${fmtNum(d.kcal)} kcal pour ${fmtNum(d.totalGrams)} g dans l\'assiette',
        subline: english
            ? '${d.protein.round()} g protein and ${d.fiber.round()} g fiber · ${d.energyDensity.round()} kcal per 100 g.'
            : '${d.protein.round()} g de protéines et ${d.fiber.round()} g de fibres · ${d.energyDensity.round()} kcal pour 100 g.',
      );
    case ShareFocus.longevity when d.plantCount >= 3:
      return (
        headline: english
            ? '${d.plantCount} different plants $scope'
            : '${d.plantCount} végétaux différents $scope',
        subline: english
            ? 'Benchmark: $kPlantsPerWeekRef different plants a week (American Gut Project, 2018).'
            : 'Repère : $kPlantsPerWeekRef végétaux différents par semaine (American Gut Project, 2018).',
      );
    default:
      break;
  }
  if (top.isNotEmpty && top.first.percent >= 100) {
    final h = top.first;
    return (
      headline: english
          ? '${h.percent.round()}% of the daily ${h.label} reference $scope'
          : '${h.percent.round()} % de la référence en ${lowerFirst(h.label)} $scope',
      subline: sub,
    );
  }
  if (d.protein >= 30) {
    return (
      headline: english ? '${d.protein.round()} g of protein $scope' : '${d.protein.round()} g de protéines $scope',
      subline: sub,
    );
  }
  return (
    headline: english ? 'What this plate really contains' : 'Ce que contient vraiment cette assiette',
    subline: english
        ? 'Macros, micronutrients and essential fats, decoded.'
        : 'Macros, micronutriments et acides gras essentiels, décryptés.',
  );
}

/// "À retenir" : 2-3 constats factuels tirés des données.
List<String> insightsFor(MealShareData d, {bool english = false, ShareFocus focus = ShareFocus.balance}) {
  final out = <String>[];
  final n30 = d.essentialsAtLeast(30);
  final total = essentialNutrients.length;
  final split = d.energySplit;
  switch (focus) {
    case ShareFocus.sport:
      if (d.protein >= 20) {
        out.add(english
            ? '${d.protein.round()} g of protein (${(split.protein * 100).round()}% of the energy) — protein contributes to the maintenance of muscle mass.'
            : '${d.protein.round()} g de protéines (${(split.protein * 100).round()} % de l\'énergie) — les protéines contribuent au maintien de la masse musculaire.');
      }
      if (d.carbs >= 30) {
        out.add(english
            ? '${d.carbs.round()} g of carbohydrates, the main fuel for intense efforts.'
            : '${d.carbs.round()} g de glucides, le carburant principal des efforts intenses.');
      }
    case ShareFocus.satiety:
      out.add(d.energyDensity <= 120
          ? (english
              ? '${d.energyDensity.round()} kcal per 100 g: a generous plate for relatively few calories.'
              : '${d.energyDensity.round()} kcal pour 100 g : une assiette généreuse pour relativement peu de calories.')
          : (english
              ? 'Energy density: ${d.energyDensity.round()} kcal per 100 g of food.'
              : 'Densité énergétique : ${d.energyDensity.round()} kcal pour 100 g d\'assiette.'));
    case ShareFocus.longevity:
      if (d.plantCount >= 2) {
        out.add(english
            ? '${d.plantCount} different plants: plant diversity is linked to a more diverse gut microbiota (American Gut Project).'
            : '${d.plantCount} végétaux différents : la diversité végétale est associée à un microbiote intestinal plus diversifié (American Gut Project).');
      }
      final raw = d.rawShare;
      if (raw != null && raw >= 0.5) {
        out.add(english
            ? '${(raw * 100).round()}% of the plate by weight is raw or minimally processed food (NOVA estimate).'
            : '${(raw * 100).round()} % du poids de l\'assiette en aliments bruts ou peu transformés (estimation NOVA).');
      }
    case ShareFocus.balance:
      break;
  }
  if (n30 >= 3) {
    out.add(english
        ? '$n30 of the $total essential micronutrients tracked are above 30% of the reference — with real food only.'
        : '$n30 des $total micronutriments essentiels suivis dépassent 30 % de la référence — uniquement avec de vrais aliments.');
  }
  if (d.protein >= 25) {
    out.add(english
        ? '${d.protein.round()} g of protein: a solid base for satiety and muscle maintenance.'
        : '${d.protein.round()} g de protéines : une base solide pour la satiété et le maintien musculaire.');
  }
  if (d.fiber >= 8) {
    out.add(english
        ? '${d.fiber.round()} g of fiber, i.e. ${(d.fiber / kRefFiberG * 100).round()}% of the 30 g recommended each day.'
        : '${d.fiber.round()} g de fibres, soit ${(d.fiber / kRefFiberG * 100).round()} % des 30 g conseillés chaque jour.');
  }
  final ratio = d.fattyAcids.laAlaRatio;
  if (ratio != null && ratio <= kMaxLaAlaRatio && out.length < 3) {
    out.add(english
        ? 'Omega-6/omega-3 ratio of ${fmtNum(ratio, decimals: 1, english: true)}: within the recommended target (below 5).'
        : 'Rapport oméga-6/oméga-3 de ${fmtNum(ratio, decimals: 1)} : dans la cible recommandée (moins de 5).');
  }
  // Doublons possibles entre la ligne d'angle et les lignes générales
  // (protéines) : on garde la 1re formulation.
  final seen = <String>{};
  return out.where((l) => seen.add(l.split(' ').take(3).join(' '))).take(3).toList();
}

/// Mots-dièse : 5 maximum (limite d'Instagram depuis décembre 2025),
/// généralistes, choisis selon le contenu réel.
List<String> hashtagsFor(MealShareData d, {bool english = false, ShareFocus focus = ShareFocus.balance}) {
  final tags = <String>[
    english ? '#nutrition' : '#nutrition',
    switch (focus) {
      ShareFocus.sport => english ? '#sportsnutrition' : '#nutritionsportive',
      ShareFocus.satiety => english ? '#mindfuleating' : '#reequilibragealimentaire',
      ShareFocus.longevity => english ? '#plantdiversity' : '#diversitevegetale',
      ShareFocus.balance => english ? '#micronutrients' : '#micronutrition',
    },
    english ? '#healthyeating' : '#alimentationsaine',
    focus == ShareFocus.sport
        ? (english ? '#fitfood' : '#mealprep')
        : (english ? '#longevity' : '#longevite'),
  ];
  if (d.epaDhaMg >= 500) {
    tags.add('#omega3');
  } else if (d.protein >= 30) {
    tags.add(english ? '#protein' : '#proteines');
  } else {
    tags.add(english ? '#wholefood' : '#mangersain');
  }
  return tags.take(5).toList();
}

/// Légende prête à coller : accroche, macros, essentiels avec leur rôle,
/// acides gras, ingrédients, appels à l'action, 5 mots-dièse max. Pas
/// d'emoji pour les nutriments (texte clair, lisible par tous).
String captionFor(MealShareData d,
    {bool english = false, String handle = '', bool mentionTotum = true, ShareFocus focus = ShareFocus.balance}) {
  final b = StringBuffer();
  final hook = hookFor(d, english: english, focus: focus);
  b.writeln(d.title);
  b.writeln(hook.headline);
  b.writeln();
  b.writeln(english
      ? '${fmtNum(d.kcal, english: true)} kcal · Protein ${d.protein.round()} g · Carbs ${d.carbs.round()} g · Fat ${d.fat.round()} g · Fiber ${d.fiber.round()} g'
      : '${fmtNum(d.kcal)} kcal · Protéines ${d.protein.round()} g · Glucides ${d.carbs.round()} g · Lipides ${d.fat.round()} g · Fibres ${d.fiber.round()} g');
  final hs = d.highlights(english: english, max: 4, focus: focus);
  if (focus == ShareFocus.longevity && d.plantCount > 0) {
    b.writeln(english
        ? '${d.plantCount} different plants in this plate'
        : '${d.plantCount} végétaux différents dans cette assiette');
  }
  if (hs.isNotEmpty) {
    b.writeln();
    b.writeln(english ? 'Essential micronutrients (% of the adult reference):' : 'Micronutriments essentiels (% de la référence adulte) :');
    for (final h in hs) {
      b.writeln('• ${h.label} ${h.percent.round()} % — ${h.def.role(english)}');
    }
  }
  final fa = d.fattyAcids;
  if (fa.hasData) {
    b.writeln();
    b.writeln(english ? 'Essential fats:' : 'Acides gras essentiels :');
    final ratio = fa.laAlaRatio;
    b.writeln(english
        ? '• EPA+DHA ${fmtNum(fa.epaDhaMg, english: true)} mg · omega-3 ALA ${fmtNum(fa.alaG, decimals: 1, english: true)} g · omega-6 ${fmtNum(fa.laG, decimals: 1, english: true)} g'
            '${ratio != null ? ' · omega-6/omega-3 ratio ${fmtNum(ratio, decimals: 1, english: true)}' : ''}'
        : '• EPA+DHA ${fmtNum(fa.epaDhaMg)} mg · oméga-3 ALA ${fmtNum(fa.alaG, decimals: 1)} g · oméga-6 ${fmtNum(fa.laG, decimals: 1)} g'
            '${ratio != null ? ' · rapport oméga-6/oméga-3 ${fmtNum(ratio, decimals: 1)}' : ''}');
  }
  if (d.items.isNotEmpty && !d.isFullDay) {
    b.writeln();
    b.writeln(english ? 'Ingredients:' : 'Ingrédients :');
    for (final it in d.items) {
      b.writeln('• ${it.grams.round()} g ${english ? it.name : _withDe(it.name)}');
    }
  }
  b.writeln();
  b.writeln(english ? '💾 Save it for your next plate' : '💾 Enregistre-le pour ta prochaine assiette');
  b.writeln(english ? '✈️ Send it to someone who cares about their health' : '✈️ Envoie-le à quelqu\'un qui prend soin de sa santé');
  b.writeln(english ? 'Which nutrient surprised you most?' : 'Quel nutriment t\'a le plus surpris ?');
  b.writeln();
  if (handle.trim().isNotEmpty) b.writeln(handle.trim());
  b.writeln(mentionTotum
      ? (english
          ? 'Analysed with Totum — values per serving (Ciqual table by ANSES, EU reference values).'
          : 'Analyse réalisée avec Totum — valeurs pour la portion (table Ciqual de l\'ANSES, références UE).')
      : (english
          ? 'Values per serving (Ciqual table by ANSES, EU reference values).'
          : 'Valeurs pour la portion (table Ciqual de l\'ANSES, références UE).'));
  b.writeln();
  b.write(hashtagsFor(d, english: english, focus: focus).join(' '));
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
  /// Végétal ? + degré NOVA de l'aliment (facultatif : sans lui, la
  /// diversité végétale et la part d'aliments bruts restent inconnues).
  ({bool isPlant, int? nova}) Function(String id)? classify,
}) {
  double kcal = 0, p = 0, c = 0, f = 0, fi = 0;
  final micros = <String, double>{};
  // Un même aliment présent plusieurs fois (journée entière) = une ligne.
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
    final hasMicros = itemMicros.values.any((v) => v > 0);
    final name = shortFoodName(food?.displayName ?? rawName);
    final cls = classify?.call(id);
    final prev = byName[name];
    if (prev == null) {
      byName[name] = MealShareItem(
        name: name, emoji: food?.emoji ?? '🍽️', grams: grams, kcal: num_('kcal'),
        micros: itemMicros, hasMicroData: hasMicros,
        isPlant: cls?.isPlant ?? false, nova: cls?.nova,
      );
    } else {
      final merged = Map<String, double>.from(prev.micros);
      itemMicros.forEach((k, v) => merged[k] = (merged[k] ?? 0) + v);
      byName[name] = MealShareItem(
        name: name, emoji: prev.emoji, grams: prev.grams + grams, kcal: prev.kcal + num_('kcal'),
        micros: merged, hasMicroData: prev.hasMicroData || hasMicros,
        isPlant: prev.isPlant || (cls?.isPlant ?? false),
        nova: prev.nova == null || cls?.nova == null
            ? (prev.nova ?? cls?.nova)
            : (prev.nova! > cls!.nova! ? prev.nova : cls.nova),
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

/// Un aliment est-il d'origine végétale (diversité végétale) ? Groupes
/// Ciqual et taxonomie USDA de l'app ; huiles, sucres, boissons et plats
/// composés exclus (un végétal = un aliment végétal identifiable).
bool isPlantFood({String? groupe, String? sousGroupe}) {
  const plantGroups = {
    'fruits, légumes, légumineuses et oléagineux',
    'fruits', 'légumes', 'légumineuses', 'fruits à coque et graines',
  };
  const plantSubgroups = {
    'pâtes, riz et céréales', 'farines', 'herbes', 'épices', 'algues',
    'Cereal Grains and Pasta', 'Spices and Herbs',
  };
  if (groupe != null && plantGroups.contains(groupe)) return true;
  return sousGroupe != null && plantSubgroups.contains(sousGroupe);
}

/// Taille max d'une liste d'ingrédients lisible sur un visuel 1080 px.
int maxIngredientsOnSlide(int available) => available < 9 ? available : 9;
