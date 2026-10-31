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

import 'dart:math' as math;

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

/// Grandes fonctions du corps auxquelles contribuent les micronutriments —
/// regroupement des allégations de santé AUTORISÉES dans l'UE (règlement
/// (UE) 432/2012), au sujet des nutriments (jamais une promesse sur un
/// plat). Version 2.0 du partage (31/10/2026, retour d'Alex : « parler à
/// tout le monde », cohérence système nerveux/endocrinien/immunitaire…).
enum BodySystem { brain, energy, immunity, bones, heart, hormones, cells, skin }

String bodySystemLabel(BodySystem s, bool en) => switch (s) {
      BodySystem.brain => en ? 'Brain & mood' : 'Cerveau & moral',
      BodySystem.energy => en ? 'Energy & vitality' : 'Énergie & vitalité',
      BodySystem.immunity => en ? 'Immunity' : 'Immunité',
      BodySystem.bones => en ? 'Bones & muscles' : 'Os & muscles',
      BodySystem.heart => en ? 'Heart & circulation' : 'Cœur & circulation',
      BodySystem.hormones => en ? 'Hormones & thyroid' : 'Hormones & thyroïde',
      BodySystem.cells => en ? 'Cell protection' : 'Protection des cellules',
      BodySystem.skin => en ? 'Skin, hair & vision' : 'Peau, cheveux & vue',
    };

/// Un micronutriment essentiel : nom en clair (jamais un symbole chimique —
/// retour d'Alex : « les gens ne connaissent pas le tableau de
/// Mendeleïev »), apport conseillé ANSES pour un adulte, priorité santé,
/// fonctions (allégations UE) et aliments qui en apportent.
class EssentialNutrient {
  final String key, labelFr, labelEn, unit;
  /// Ancien symbole (Mg, D…) — conservé pour compatibilité, jamais affiché.
  final String symbol;
  final NutrientKind kind;
  /// Apport conseillé ANSES, adulte (le plus exigeant des deux sexes quand
  /// ils diffèrent ; B1 et B3 sur la base de 2 000 kcal).
  final double reference;
  /// Priorité santé publique/longévité (1 = standard) : nutriments souvent
  /// insuffisants en France (INCA 3, Esteban) ou clés pour les systèmes
  /// nerveux, hormonal et immunitaire — vitamine D, oméga-3, magnésium, iode…
  /// La B12, abondante dans toute alimentation omnivore, pèse moins.
  final double weight;
  final List<BodySystem> systems;
  final String titleFr, titleEn, roleFr, roleEn, foodsFr, foodsEn;
  final double Function(Map<String, double> m) amount;
  const EssentialNutrient(this.key, this.labelFr, this.labelEn, this.unit, this.reference, this.symbol, this.kind,
      {required this.titleFr, required this.titleEn,
      required this.roleFr, required this.roleEn,
      required this.foodsFr, required this.foodsEn,
      required this.amount, this.weight = 1, this.systems = const []});
  String label(bool en) => en ? labelEn : labelFr;
  String title(bool en) => en ? titleEn : titleFr;
  String role(bool en) => en ? roleEn : roleFr;
  String foods(bool en) => en ? foodsEn : foodsFr;
}

const _bS = BodySystem.brain, _eS = BodySystem.energy, _iS = BodySystem.immunity, _oS = BodySystem.bones,
    _hS = BodySystem.heart, _tS = BodySystem.hormones, _cS = BodySystem.cells, _sS = BodySystem.skin;

/// Ordre = priorité santé/longévité (départage à score égal, ordre des
/// nutriments à compléter).
final List<EssentialNutrient> essentialNutrients = [
  EssentialNutrient('epaDha', 'Oméga-3 marins (EPA+DHA)', 'Marine omega-3 (EPA+DHA)', 'mg', 500, 'ω3', NutrientKind.fattyAcid,
      weight: 1.6, systems: [_hS, _bS],
      titleFr: 'Cœur & cerveau', titleEn: 'Heart & brain',
      roleFr: 'Contribuent à une fonction cardiaque normale et, pour le DHA, au fonctionnement normal du cerveau.',
      roleEn: 'Contribute to the normal function of the heart and, for DHA, to normal brain function.',
      foodsFr: 'sardine · maquereau · saumon · hareng', foodsEn: 'sardine · mackerel · salmon · herring',
      amount: (m) => (_g(m, 'EPA_g_100g') + _g(m, 'DHA_g_100g')) * 1000),
  EssentialNutrient('vitD', 'Vitamine D', 'Vitamin D', 'µg', 15, 'D', NutrientKind.vitamin,
      weight: 1.6, systems: [_iS, _oS],
      titleFr: 'Immunité & os', titleEn: 'Immunity & bones',
      roleFr: "Contribue au fonctionnement normal du système immunitaire et au maintien d'une ossature et de muscles normaux.",
      roleEn: 'Contributes to the normal function of the immune system and the maintenance of normal bones and muscles.',
      foodsFr: 'poissons gras · jaune d\'œuf · soleil', foodsEn: 'oily fish · egg yolk · sunlight',
      amount: (m) => _g(m, 'Vitamine_D_µg_100g')),
  EssentialNutrient('mg', 'Magnésium', 'Magnesium', 'mg', 380, 'Mg', NutrientKind.mineral,
      weight: 1.45, systems: [_eS, _bS, _oS],
      titleFr: 'Anti-fatigue & nerfs', titleEn: 'Energy & nerves',
      roleFr: 'Contribue à réduire la fatigue, au fonctionnement normal du système nerveux et des muscles.',
      roleEn: 'Contributes to the reduction of tiredness and to normal nervous system and muscle function.',
      foodsFr: 'graines de courge · amandes · chocolat noir · légumineuses',
      foodsEn: 'pumpkin seeds · almonds · dark chocolate · legumes',
      amount: (m) => _g(m, 'Magnésium_mg_100g')),
  EssentialNutrient('ala', 'Oméga-3 végétal (ALA)', 'Plant omega-3 (ALA)', 'g', kRefAlaG, 'ω3', NutrientKind.fattyAcid,
      weight: 1.25, systems: [_hS],
      titleFr: 'Cholestérol & cœur', titleEn: 'Cholesterol & heart',
      roleFr: 'Contribue au maintien d\'une cholestérolémie normale.',
      roleEn: 'Contributes to the maintenance of normal blood cholesterol levels.',
      foodsFr: 'graines de lin · noix · chia · huile de colza', foodsEn: 'flaxseed · walnuts · chia · rapeseed oil',
      amount: (m) => _g(m, 'Acide_alpha-linolénique_W3_ALA_g_100g')),
  EssentialNutrient('i', 'Iode', 'Iodine', 'µg', 150, 'I', NutrientKind.mineral,
      weight: 1.35, systems: [_tS, _bS],
      titleFr: 'Thyroïde', titleEn: 'Thyroid',
      roleFr: 'Contribue à la production normale d\'hormones thyroïdiennes et à des fonctions cognitives normales.',
      roleEn: 'Contributes to the normal production of thyroid hormones and to normal cognitive function.',
      foodsFr: 'poissons de mer · crustacés · laitages · sel iodé', foodsEn: 'sea fish · shellfish · dairy · iodised salt',
      amount: (m) => _g(m, 'Iode_µg_100g')),
  EssentialNutrient('b9', 'Folates (vitamine B9)', 'Folate (vitamin B9)', 'µg', 330, 'B9', NutrientKind.vitamin,
      weight: 1.25, systems: [_bS, _eS, _iS],
      titleFr: 'Renouvellement des cellules', titleEn: 'Cell renewal',
      roleFr: 'Contribue à réduire la fatigue, à la formation normale du sang et au fonctionnement normal du système immunitaire.',
      roleEn: 'Contributes to the reduction of tiredness, normal blood formation and normal immune function.',
      foodsFr: 'épinards · lentilles · avocat · brocoli', foodsEn: 'spinach · lentils · avocado · broccoli',
      amount: (m) => _g(m, 'Vitamine_B9_µg_100g')),
  EssentialNutrient('fe', 'Fer', 'Iron', 'mg', 11, 'Fe', NutrientKind.mineral,
      weight: 1.25, systems: [_eS, _bS, _iS],
      titleFr: 'Oxygène & énergie', titleEn: 'Oxygen & energy',
      roleFr: "Contribue au transport normal de l'oxygène dans l'organisme et à réduire la fatigue.",
      roleEn: 'Contributes to normal oxygen transport in the body and to the reduction of tiredness.',
      foodsFr: 'lentilles · viande rouge · moules · épinards + vitamine C',
      foodsEn: 'lentils · red meat · mussels · spinach + vitamin C',
      amount: (m) => _g(m, 'Fer_mg_100g')),
  EssentialNutrient('ca', 'Calcium', 'Calcium', 'mg', 950, 'Ca', NutrientKind.mineral,
      weight: 1.2, systems: [_oS],
      titleFr: 'Os & dents', titleEn: 'Bones & teeth',
      roleFr: "Nécessaire au maintien d'une ossature et d'une dentition normales, et à une fonction musculaire normale.",
      roleEn: 'Needed for the maintenance of normal bones and teeth, and for normal muscle function.',
      foodsFr: 'fromages · yaourts · sardines avec arêtes · chou kale', foodsEn: 'cheese · yoghurt · sardines with bones · kale',
      amount: (m) => _g(m, 'Calcium_mg_100g')),
  EssentialNutrient('k', 'Potassium', 'Potassium', 'mg', 3500, 'K', NutrientKind.mineral,
      weight: 1.2, systems: [_hS, _oS],
      titleFr: 'Tension & muscles', titleEn: 'Blood pressure & muscles',
      roleFr: "Contribue au maintien d'une pression sanguine normale et à une fonction musculaire normale.",
      roleEn: 'Contributes to the maintenance of normal blood pressure and to normal muscle function.',
      foodsFr: 'pomme de terre · banane · légumineuses · avocat', foodsEn: 'potato · banana · legumes · avocado',
      amount: (m) => _g(m, 'Potassium_mg_100g')),
  EssentialNutrient('zn', 'Zinc', 'Zinc', 'mg', 11, 'Zn', NutrientKind.mineral,
      weight: 1.15, systems: [_iS, _tS, _sS, _cS, _bS],
      titleFr: 'Défenses & hormones', titleEn: 'Defences & hormones',
      roleFr: 'Contribue au fonctionnement normal du système immunitaire, au maintien d\'une testostéronémie normale et d\'une peau normale.',
      roleEn: 'Contributes to normal immune function, to the maintenance of normal testosterone levels and of normal skin.',
      foodsFr: 'huîtres · bœuf · graines de courge · lentilles', foodsEn: 'oysters · beef · pumpkin seeds · lentils',
      amount: (m) => _g(m, 'Zinc_mg_100g')),
  EssentialNutrient('se', 'Sélénium', 'Selenium', 'µg', 70, 'Se', NutrientKind.mineral,
      weight: 1.15, systems: [_tS, _cS, _iS, _sS],
      titleFr: 'Thyroïde & protection', titleEn: 'Thyroid & protection',
      roleFr: 'Contribue à une fonction thyroïdienne normale et à protéger les cellules contre le stress oxydatif.',
      roleEn: 'Contributes to normal thyroid function and to the protection of cells from oxidative stress.',
      foodsFr: 'noix du Brésil · poissons · œufs', foodsEn: 'Brazil nuts · fish · eggs',
      amount: (m) => _g(m, 'Sélénium_µg_100g')),
  EssentialNutrient('vitC', 'Vitamine C', 'Vitamin C', 'mg', 110, 'C', NutrientKind.vitamin,
      weight: 1.05, systems: [_iS, _cS, _eS, _sS, _bS],
      titleFr: 'Immunité & collagène', titleEn: 'Immunity & collagen',
      roleFr: 'Contribue au fonctionnement normal du système immunitaire, à la formation du collagène et à réduire la fatigue.',
      roleEn: 'Contributes to normal immune function, normal collagen formation and the reduction of tiredness.',
      foodsFr: 'poivron · kiwi · agrumes · brocoli', foodsEn: 'bell pepper · kiwi · citrus · broccoli',
      amount: (m) => _g(m, 'Vitamine_C_mg_100g')),
  EssentialNutrient('vitK', 'Vitamine K', 'Vitamin K', 'µg', 79, 'K', NutrientKind.vitamin,
      weight: 1.0, systems: [_oS],
      titleFr: 'Os & coagulation', titleEn: 'Bones & clotting',
      roleFr: "Contribue au maintien d'une ossature normale et à une coagulation sanguine normale.",
      roleEn: 'Contributes to the maintenance of normal bone and to normal blood clotting.',
      foodsFr: 'légumes verts à feuilles · brocoli · fromages affinés', foodsEn: 'leafy greens · broccoli · aged cheeses',
      amount: (m) => _g(m, 'Vitamine_K1_µg_100g') + _g(m, 'Vitamine_K2_µg_100g')),
  EssentialNutrient('vitE', 'Vitamine E', 'Vitamin E', 'mg', 10, 'E', NutrientKind.vitamin,
      weight: 1.0, systems: [_cS],
      titleFr: 'Protection des cellules', titleEn: 'Cell protection',
      roleFr: 'Contribue à protéger les cellules contre le stress oxydatif.',
      roleEn: 'Contributes to the protection of cells from oxidative stress.',
      foodsFr: 'graines de tournesol · amandes · huile de colza', foodsEn: 'sunflower seeds · almonds · rapeseed oil',
      amount: (m) => _g(m, 'Vitamine_E_mg_100g')),
  EssentialNutrient('vitA', 'Vitamine A', 'Vitamin A', 'µg', 750, 'A', NutrientKind.vitamin,
      weight: 0.95, systems: [_sS, _iS],
      titleFr: 'Vue & peau', titleEn: 'Vision & skin',
      roleFr: "Contribue au maintien d'une vision normale, d'une peau normale et au fonctionnement du système immunitaire.",
      roleEn: 'Contributes to the maintenance of normal vision and skin, and to normal immune function.',
      foodsFr: 'carotte · patate douce · épinards · œufs', foodsEn: 'carrot · sweet potato · spinach · eggs',
      // Équivalents rétinol : rétinol + bêta-carotène / 6 (EFSA).
      amount: (m) => _g(m, 'Rétinol_µg_100g') + _g(m, 'Beta-Carotène_µg_100g') / 6),
  EssentialNutrient('b6', 'Vitamine B6', 'Vitamin B6', 'mg', 1.7, 'B6', NutrientKind.vitamin,
      weight: 0.95, systems: [_tS, _eS, _iS, _bS],
      titleFr: 'Hormones & énergie', titleEn: 'Hormones & energy',
      roleFr: "Contribue à réguler l'activité hormonale, à réduire la fatigue et au fonctionnement du système immunitaire.",
      roleEn: 'Contributes to the regulation of hormonal activity, the reduction of tiredness and normal immune function.',
      foodsFr: 'banane · poissons · volaille · pomme de terre', foodsEn: 'banana · fish · poultry · potato',
      amount: (m) => _g(m, 'Vitamine_B6_mg_100g')),
  EssentialNutrient('b2', 'Vitamine B2', 'Vitamin B2', 'mg', 1.6, 'B2', NutrientKind.vitamin,
      weight: 0.8, systems: [_eS, _cS, _sS],
      titleFr: 'Énergie & protection', titleEn: 'Energy & protection',
      roleFr: 'Contribue à réduire la fatigue, à protéger les cellules contre le stress oxydatif et au maintien d\'une vision normale.',
      roleEn: 'Contributes to the reduction of tiredness, protection of cells from oxidative stress and normal vision.',
      foodsFr: 'laitages · œufs · amandes · champignons', foodsEn: 'dairy · eggs · almonds · mushrooms',
      amount: (m) => _g(m, 'Vitamine_B2_mg_100g')),
  EssentialNutrient('b1', 'Vitamine B1', 'Vitamin B1', 'mg', 0.84, 'B1', NutrientKind.vitamin,
      weight: 0.8, systems: [_eS, _hS, _bS],
      titleFr: 'Énergie & cœur', titleEn: 'Energy & heart',
      roleFr: 'Contribue à un métabolisme énergétique normal et à une fonction cardiaque normale.',
      roleEn: 'Contributes to normal energy-yielding metabolism and to the normal function of the heart.',
      foodsFr: 'céréales complètes · légumineuses · porc', foodsEn: 'whole grains · legumes · pork',
      amount: (m) => _g(m, 'Vitamine_B1_mg_100g')),
  EssentialNutrient('b3', 'Vitamine B3', 'Vitamin B3', 'mg', 13.4, 'B3', NutrientKind.vitamin,
      weight: 0.7, systems: [_eS, _bS, _sS],
      titleFr: 'Énergie & peau', titleEn: 'Energy & skin',
      roleFr: 'Contribue à réduire la fatigue, à des fonctions psychologiques normales et au maintien d\'une peau normale.',
      roleEn: 'Contributes to the reduction of tiredness, normal psychological function and the maintenance of normal skin.',
      foodsFr: 'volaille · poissons · arachides · champignons', foodsEn: 'poultry · fish · peanuts · mushrooms',
      amount: (m) => _g(m, 'Vitamine_B3_mg_100g')),
  EssentialNutrient('b5', 'Vitamine B5', 'Vitamin B5', 'mg', 6, 'B5', NutrientKind.vitamin,
      weight: 0.65, systems: [_eS, _bS],
      titleFr: 'Énergie & concentration', titleEn: 'Energy & focus',
      roleFr: 'Contribue à réduire la fatigue et à des performances intellectuelles normales.',
      roleEn: 'Contributes to the reduction of tiredness and to normal mental performance.',
      foodsFr: 'champignons · œufs · avocat · lentilles', foodsEn: 'mushrooms · eggs · avocado · lentils',
      amount: (m) => _g(m, 'Vitamine_B5_mg_100g')),
  EssentialNutrient('b12', 'Vitamine B12', 'Vitamin B12', 'µg', 4, 'B12', NutrientKind.vitamin,
      weight: 0.7, systems: [_bS, _eS, _iS],
      titleFr: 'Nerfs & énergie', titleEn: 'Nerves & energy',
      roleFr: 'Contribue au fonctionnement normal du système nerveux et à réduire la fatigue.',
      roleEn: 'Contributes to normal functioning of the nervous system and to the reduction of tiredness.',
      foodsFr: 'poissons · fruits de mer · œufs · viande', foodsEn: 'fish · seafood · eggs · meat',
      amount: (m) => _g(m, 'Vitamine_B12_µg_100g')),
];

/// Un micronutriment mis en avant, avec son % de l'apport conseillé et sa
/// source principale dans l'assiette.
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

/// Note de pertinence d'un nutriment pour CE repas : priorité santé ×
/// couverture à rendement décroissant (au-delà de ~100 % de l'apport
/// conseillé, plus rien ne compte — 686 % de B12 ne passe plus devant 45 %
/// de magnésium). Stress-testé dans meal_share_screenshot_test.dart.
double nutrientRelevance(NutrientHighlight h, {ShareFocus focus = ShareFocus.balance}) {
  final cover = 100 * (1 - math.exp(-h.percent / 60));
  var w = h.def.weight;
  if ((kFocusNutrients[focus] ?? const <String>[]).contains(h.key)) w *= 1.35;
  return cover * w;
}

/// Couverture d'une grande fonction du corps par le repas.
class BodySystemScore {
  final BodySystem system;
  /// Moyenne (0-100) des couvertures plafonnées à 100 % des nutriments qui
  /// y contribuent.
  final double coverage;
  /// Les nutriments qui y contribuent le plus dans ce repas (2 max).
  final List<NutrientHighlight> top;
  const BodySystemScore(this.system, this.coverage, this.top);
}

/// Équivalence ludique : « autant de X que N repères » — valeur CIQUAL de
/// l'aliment repère pour une portion usuelle (food_portions.dart).
class FoodEquivalent {
  final double perUnit;
  final String unitFr, unitEn, emoji;
  const FoodEquivalent(this.perUnit, this.unitFr, this.unitEn, this.emoji);
}

const Map<String, FoodEquivalent> kFoodEquivalents = {
  'protein': FoodEquivalent(6.4, 'œufs', 'eggs', '🥚'), // 1 œuf 50 g × 12,8 g
  'fiber': FoodEquivalent(2.1, 'pommes', 'apples', '🍎'), // 1 pomme 150 g × 1,4 g
  'vitC': FoodEquivalent(66.5, 'oranges', 'oranges', '🍊'), // 1 orange 140 g × 47,5 mg
  'k': FoodEquivalent(384, 'bananes', 'bananas', '🍌'), // 1 banane 120 g × 320 mg
  'mg': FoodEquivalent(33.6, 'bananes', 'bananas', '🍌'), // 1 banane 120 g × 28 mg
  'ca': FoodEquivalent(242, 'verres de lait', 'glasses of milk', '🥛'), // 200 g × 121 mg
  'fe': FoodEquivalent(3.7, 'assiettes de lentilles', 'plates of lentils', '🫘'), // 150 g × 2,45 mg
  'vitD': FoodEquivalent(1.0, 'œufs', 'eggs', '🥚'), // 1 œuf 50 g × 2 µg
  'ala': FoodEquivalent(2.25, 'poignées de noix', 'handfuls of walnuts', '🌰'), // 30 g × 7,5 g
};

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
  /// Les « stars » du repas : micronutriments couverts à au moins
  /// [minPercent] % (15 % = quantité significative de l'étiquetage UE),
  /// classés par PERTINENCE (priorité santé × couverture à rendement
  /// décroissant, voir nutrientRelevance) et non plus par pourcentage brut ;
  /// au plus 2 vitamines B, pour un trio varié et parlant.
  List<NutrientHighlight> highlights({bool english = false, double minPercent = 15, int max = 6,
      ShareFocus focus = ShareFocus.balance}) {
    final all = [for (final d in essentialNutrients) _highlight(d, english)]
      ..removeWhere((h) => h.percent < minPercent);
    final order = {for (var i = 0; i < essentialNutrients.length; i++) essentialNutrients[i].key: i};
    all.sort((a, b) {
      final c = nutrientRelevance(b, focus: focus).compareTo(nutrientRelevance(a, focus: focus));
      return c != 0 ? c : order[a.key]!.compareTo(order[b.key]!);
    });
    final out = <NutrientHighlight>[];
    var bVitamins = 0;
    for (final h in all) {
      final isB = h.key.length <= 3 && h.key.startsWith('b');
      if (isB && bVitamins >= 2) continue;
      if (isB) bVitamins++;
      out.add(h);
      if (out.length == max) break;
    }
    return out;
  }

  /// Tous les nutriments d'une famille (vitamines ou minéraux), du mieux au
  /// moins couvert — pour les tableaux complets.
  List<NutrientHighlight> panel(NutrientKind kind, {bool english = false}) =>
      [for (final d in essentialNutrients) if (d.kind == kind) _highlight(d, english)]
        ..sort((a, b) => b.percent.compareTo(a.percent));

  /// D'où vient chaque nutriment : part (0-1) de chaque ingrédient, de la
  /// plus grande à la plus petite.
  List<({MealShareItem item, double share})> contributions(EssentialNutrient d) {
    final total = d.amount(micros);
    if (total <= 0) return const [];
    final out = <({MealShareItem item, double share})>[
      for (final it in items)
        if (d.amount(it.micros) > 0) (item: it, share: d.amount(it.micros) / total),
    ]..sort((a, b) => b.share.compareTo(a.share));
    return out;
  }

  /// Ce que le repas apporte à chaque grande fonction du corps, de la mieux
  /// à la moins bien nourrie.
  List<BodySystemScore> bodySystems({bool english = false}) {
    final hs = [for (final d in essentialNutrients) _highlight(d, english)];
    final out = <BodySystemScore>[];
    for (final s in BodySystem.values) {
      final members = hs.where((h) => h.def.systems.contains(s)).toList();
      if (members.isEmpty) continue;
      final cov = members.fold(0.0, (t, h) => t + h.percent.clamp(0, 100)) / members.length;
      final top = members.where((h) => h.percent >= 10).toList()
        ..sort((a, b) => nutrientRelevance(b).compareTo(nutrientRelevance(a)));
      out.add(BodySystemScore(s, cov, top.take(2).toList()));
    }
    out.sort((a, b) => b.coverage.compareTo(a.coverage));
    return out;
  }

  /// « autant de … que N … » si N ≥ 1,5 (sinon null).
  ({double count, FoodEquivalent eq})? equivalent(String key) {
    final eq = kFoodEquivalents[key];
    if (eq == null) return null;
    final double amount = switch (key) {
      'protein' => protein,
      'fiber' => fiber,
      _ => essentialNutrients.where((d) => d.key == key).map((d) => d.amount(micros)).firstOrNull ?? 0,
    };
    final n = amount / eq.perUnit;
    return n >= 1.5 ? (count: n, eq: eq) : null;
  }

  /// Seuil "peu couvert" : un repas représente environ un tiers de la
  /// journée — sous 25 % de la référence, il reste de la marge à combler
  /// ailleurs ; pour une journée entière, sous 75 %.
  double get gapThreshold => isFullDay ? 75 : 25;

  /// Essentiels encore peu couverts, dans l'ordre de priorité santé.
  List<NutrientHighlight> gaps({bool english = false, int max = 4}) => ([
        for (final d in essentialNutrients) _highlight(d, english),
      ].where((h) => h.percent < gapThreshold).toList()
        ..sort((a, b) => b.def.weight.compareTo(a.def.weight)))
          .take(max)
          .toList();

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
  final stars = d.highlights(english: english, max: 3, focus: focus);
  final n25 = d.essentialsAtLeast(25);
  final scope = d.isFullDay
      ? (english ? 'in one day of eating' : 'en une journée')
      : (english ? 'in one plate' : 'dans une seule assiette');
  final sub = english
      ? '$n25 essential vitamins, minerals and omega-3 above 25% of the daily recommended intake.'
      : '$n25 vitamines, minéraux et oméga-3 essentiels à plus de 25 % de l\'apport conseillé de la journée.';
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
  String pct(NutrientHighlight h) => english ? '${h.percent.round()}%' : '${h.percent.round()} %';
  if (stars.isNotEmpty && stars.first.percent >= 100 && stars.first.def.weight >= 1.15) {
    final h = stars.first;
    return (
      headline: english
          ? '${h.label}: ${pct(h)} of the daily recommended intake $scope'
          : '${h.label} : ${pct(h)} de l\'apport conseillé de la journée $scope',
      subline: sub,
    );
  }
  if (n25 >= 5 && stars.length >= 2) {
    final list = stars.map((h) => '${english ? h.label : lowerFirst(h.label)} (${pct(h)})').toList();
    final joined = list.length == 3
        ? '${list[0]}, ${list[1]} ${english ? 'and' : 'et'} ${list[2]}'
        : '${list[0]} ${english ? 'and' : 'et'} ${list[1]}';
    return (
      headline: english ? '$n25 essential nutrients $scope' : '$n25 nutriments essentiels réunis $scope',
      subline: english ? 'Including $joined of the daily recommended intake.' : 'Dont $joined de l\'apport conseillé de la journée.',
    );
  }
  if (d.protein >= 25) {
    final eq = d.equivalent('protein');
    return (
      headline: english ? '${d.protein.round()} g of protein $scope' : '${d.protein.round()} g de protéines $scope',
      subline: eq == null
          ? sub
          : (english
              ? 'As much protein as ${eq.count.round()} ${eq.eq.unitEn} ${eq.eq.emoji}'
              : 'Autant de protéines que ${eq.count.round()} ${eq.eq.unitFr} ${eq.eq.emoji}'),
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
  final stars = d.highlights(english: english, max: 3, focus: focus);
  if (stars.length >= 2) {
    final names = stars.map((h) => english ? h.label : lowerFirst(h.label)).toList();
    final joined = names.length == 3
        ? '${names[0]}, ${names[1]} ${english ? 'and' : 'et'} ${names[2]}'
        : '${names[0]} ${english ? 'and' : 'et'} ${names[1]}';
    out.add(english ? 'Its strong points: $joined.' : 'Ses points forts : $joined.');
  }
  final systems = d.bodySystems(english: english).where((b) => b.coverage >= 25).take(2).toList();
  if (systems.isNotEmpty) {
    final names = systems.map((b) => english ? bodySystemLabel(b.system, true) : lowerFirst(bodySystemLabel(b.system, false))).join(english ? ' and ' : ' et ');
    out.add(english
        ? 'Its nutrients contribute above all to: $names.'
        : 'Ses nutriments contribuent surtout à : $names.');
  }
  // Une équivalence parlante (aliment repère, portion usuelle).
  for (final k in const ['k', 'vitC', 'mg', 'ca', 'fiber', 'protein', 'ala', 'fe']) {
    final eq = d.equivalent(k);
    if (eq == null || eq.count < 2) continue;
    final what = switch (k) {
      'protein' => english ? 'protein' : 'protéines',
      'fiber' => english ? 'fibre' : 'fibres',
      _ => english
          ? essentialNutrients.firstWhere((e) => e.key == k).labelEn
          : lowerFirst(essentialNutrients.firstWhere((e) => e.key == k).labelFr),
    };
    out.add(english
        ? 'As much $what as ${eq.count.round()} ${eq.eq.unitEn} ${eq.eq.emoji}'
        : 'Autant de $what que ${eq.count.round()} ${eq.eq.unitFr} ${eq.eq.emoji}');
    break;
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
    b.writeln(english ? 'Strong points (% of the daily recommended intake, adult):' : 'Points forts (% de l\'apport conseillé de la journée, adulte) :');
    for (final h in hs) {
      b.writeln('• ${h.label} ${h.percent.round()} % — ${h.def.role(english)}');
    }
  }
  final systems = d.bodySystems(english: english).where((x) => x.coverage >= 25).take(3).toList();
  if (systems.isNotEmpty) {
    b.writeln();
    b.writeln(english
        ? 'Its nutrients contribute above all to: ${systems.map((x) => bodySystemLabel(x.system, true).toLowerCase()).join(', ')}.'
        : 'Ses nutriments contribuent surtout à : ${systems.map((x) => lowerFirst(bodySystemLabel(x.system, false))).join(', ')}.');
  }
  final fa = d.fattyAcids;
  if (fa.hasData) {
    b.writeln();
    b.writeln(english ? 'Essential fats:' : 'Acides gras essentiels :');
    final ratio = fa.laAlaRatio;
    b.writeln(english
        ? '• Marine omega-3 (EPA+DHA) ${fmtNum(fa.epaDhaMg, english: true)} mg · plant omega-3 (ALA) ${fmtNum(fa.alaG, decimals: 1, english: true)} g · omega-6 ${fmtNum(fa.laG, decimals: 1, english: true)} g'
            '${ratio != null ? ' · omega-6/omega-3 ratio ${fmtNum(ratio, decimals: 1, english: true)}' : ''}'
        : '• Oméga-3 marins (EPA+DHA) ${fmtNum(fa.epaDhaMg)} mg · oméga-3 végétal (ALA) ${fmtNum(fa.alaG, decimals: 1)} g · oméga-6 ${fmtNum(fa.laG, decimals: 1)} g'
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
          ? 'Analysed with Totum — values per serving (ANSES Ciqual table; ANSES recommended intakes for adults).'
          : 'Analyse réalisée avec Totum — valeurs pour la portion (table Ciqual et apports conseillés de l\'ANSES pour un adulte).')
      : (english
          ? 'Values per serving (ANSES Ciqual table; ANSES recommended intakes for adults).'
          : 'Valeurs pour la portion (table Ciqual et apports conseillés de l\'ANSES pour un adulte).'));
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
