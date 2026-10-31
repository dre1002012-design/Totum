// lib/services/food_portions.dart
//
// Portions ménagères des aliments CIQUAL (31/10/2026, demande d'Alex :
// « les dosages prédéfinis du + sont-ils cohérents ? »). Jusqu'ici, seuls
// les aliments USDA avaient des portions ; un premier ajout CIQUAL
// proposait 100 g quel que soit l'aliment — 100 g d'huile d'olive
// (≈ 900 kcal), 100 g de café, et personne ne sait ce que pèse un œuf.
//
// Valeurs USUELLES, toujours affichées avec « ≈ » et modifiables : repères
// du manuel « Portions alimentaires » (étude SU.VI.MAX, Hercberg et al.,
// 2002), repères du PNNS (portion de fromage 30 g, poignée d'oléagineux
// 30 g, pot de yaourt 125 g) et poids courants des produits vendus en
// France (tranche de jambon, pot de skyr, galette de riz…). Poids de la
// partie COMESTIBLE (fruit épluché, œuf sans coquille), cuit quand
// l'aliment est cuit.
//
// 1) Portions précises pour les essentiels du quotidien (staple_foods.dart).
// 2) Repères par famille (sous-groupe ANSES) pour le reste de la base,
//    uniquement là où une mesure ménagère a un sens stable (huiles,
//    fromages, laitages, oléagineux, sauces, épices…).

class HouseholdPortion {
  final String fr;
  final String en;
  final double grams;
  const HouseholdPortion(this.fr, this.en, this.grams);
}

const _tbspOil = HouseholdPortion('1 c. à soupe', '1 tbsp', 10);
const _tspOil = HouseholdPortion('1 c. à café', '1 tsp', 4);
const _cheese = HouseholdPortion('1 portion', '1 serving', 30);
const _handful = HouseholdPortion('1 poignée', '1 handful', 30);
const _glass = HouseholdPortion('1 verre (20 cl)', '1 glass (200 ml)', 200);
const _tbspSeeds = HouseholdPortion('1 c. à soupe', '1 tbsp', 10);
const _tbspSauce = HouseholdPortion('1 c. à soupe', '1 tbsp', 15);
const _plateStarch = HouseholdPortion('1 assiette', '1 plate', 180);
const _platePasta = HouseholdPortion('1 assiette', '1 plate', 200);
const _plateVeg = HouseholdPortion('1 portion', '1 serving', 150);
const _plateLegume = HouseholdPortion('1 portion', '1 serving', 150);
const _cup = HouseholdPortion('1 tasse', '1 cup', 200);
const _mug = HouseholdPortion('1 mug', '1 mug', 300);

/// Portions des essentiels, par code CIQUAL (la 1re = quantité proposée
/// par défaut lors d'un premier ajout).
const Map<int, List<HouseholdPortion>> _byCode = {
  // Œufs, viandes, poissons
  22000: [HouseholdPortion('1 œuf', '1 egg', 50), HouseholdPortion('2 œufs', '2 eggs', 100), HouseholdPortion('3 œufs', '3 eggs', 150)],
  22010: [HouseholdPortion('1 œuf', '1 egg', 50), HouseholdPortion('2 œufs', '2 eggs', 100)],
  22001: [HouseholdPortion('1 blanc', '1 white', 30), HouseholdPortion('3 blancs', '3 whites', 90)],
  36017: [HouseholdPortion('1 filet', '1 fillet', 150)],
  36018: [HouseholdPortion('1 filet', '1 fillet', 110)],
  36304: [HouseholdPortion('1 escalope', '1 cutlet', 120)],
  36306: [HouseholdPortion('1 escalope', '1 cutlet', 100)],
  6250: [HouseholdPortion('1 steak haché', '1 patty', 100)],
  6251: [HouseholdPortion('1 steak haché', '1 patty', 80)],
  6255: [HouseholdPortion('1 steak haché', '1 patty', 80)],
  6201: [HouseholdPortion('1 steak', '1 steak', 150)],
  28902: [HouseholdPortion('1 tranche', '1 slice', 40), HouseholdPortion('2 tranches', '2 slices', 80)],
  28203: [HouseholdPortion('1 portion', '1 serving', 120)],
  26036: [HouseholdPortion('1 pavé', '1 fillet', 125)],
  26229: [HouseholdPortion('1 pavé', '1 fillet', 110)],
  26037: [HouseholdPortion('1 tranche', '1 slice', 25), HouseholdPortion('2 tranches', '2 slices', 50)],
  26039: [HouseholdPortion('1 boîte égouttée', '1 can, drained', 100)],
  26043: [HouseholdPortion('1 filet', '1 fillet', 130)],
  26023: [HouseholdPortion('1 filet', '1 fillet', 110)],
  26129: [HouseholdPortion('1 filet', '1 fillet', 130)],
  26051: [HouseholdPortion('1 filet', '1 fillet', 100)],
  26040: [HouseholdPortion('1 boîte égouttée', '1 can, drained', 90), HouseholdPortion('1 sardine', '1 sardine', 20)],
  10007: [HouseholdPortion('10 crevettes', '10 shrimps', 100)],
  // Laitiers et alternatives
  19033: [_glass, HouseholdPortion('1 bol', '1 bowl', 250)],
  19050: [_glass, HouseholdPortion('1 bol', '1 bowl', 250)],
  19023: [_glass, HouseholdPortion('1 bol', '1 bowl', 250)],
  19593: [HouseholdPortion('1 pot', '1 pot', 125)],
  19594: [HouseholdPortion('1 pot', '1 pot', 125)],
  19860: [HouseholdPortion('1 pot', '1 pot', 150)],
  19724: [HouseholdPortion('1 pot', '1 pot', 150)],
  19644: [HouseholdPortion('1 pot individuel', '1 single pot', 100), HouseholdPortion('2 c. à soupe', '2 tbsp', 40)],
  19646: [HouseholdPortion('1 pot individuel', '1 single pot', 100), HouseholdPortion('2 c. à soupe', '2 tbsp', 40)],
  12115: [_cheese],
  12110: [_cheese],
  19590: [HouseholdPortion('1 boule', '1 ball', 125), _cheese],
  12120: [HouseholdPortion('1 c. à soupe râpé', '1 tbsp grated', 5), _cheese],
  12066: [_cheese],
  12812: [_cheese],
  18900: [_glass],
  18107: [_glass],
  18899: [_glass],
  90002: [HouseholdPortion('1 dose', '1 scoop', 30)],
  // Protéines végétales, légumineuses
  20904: [HouseholdPortion('1 portion', '1 serving', 100)],
  20917: [HouseholdPortion('1 portion', '1 serving', 100)],
  20360: [_plateLegume],
  20507: [_plateLegume],
  20532: [_plateLegume, HouseholdPortion('1 boîte égouttée', '1 can, drained', 250)],
  20503: [_plateLegume],
  25621: [HouseholdPortion('1 c. à soupe', '1 tbsp', 20)],
  // Féculents
  9104: [_plateStarch],
  9100: [HouseholdPortion('1 portion (sec)', '1 serving (dry)', 60)],
  9103: [_plateStarch],
  9125: [_plateStarch],
  9811: [_platePasta],
  9810: [HouseholdPortion('1 portion (sec)', '1 serving (dry)', 80)],
  9871: [_platePasta],
  9341: [_plateStarch],
  9340: [HouseholdPortion('1 portion (sec)', '1 serving (dry)', 60)],
  32140: [HouseholdPortion('1 portion', '1 serving', 40), HouseholdPortion('1 c. à soupe', '1 tbsp', 10)],
  4003: [HouseholdPortion('1 pomme de terre moyenne', '1 medium potato', 150)],
  4026: [HouseholdPortion('1 pomme de terre moyenne', '1 medium potato', 150)],
  4102: [HouseholdPortion('1 portion', '1 serving', 150)],
  9683: [_plateStarch],
  9691: [_plateStarch],
  7001: [HouseholdPortion('¼ de baguette', '¼ baguette', 62), HouseholdPortion('1 tranche', '1 slice', 30)],
  7110: [HouseholdPortion('1 tranche', '1 slice', 35)],
  7200: [HouseholdPortion('1 tranche', '1 slice', 25), HouseholdPortion('2 tranches', '2 slices', 50)],
  7352: [HouseholdPortion('1 galette', '1 cake', 8), HouseholdPortion('2 galettes', '2 cakes', 16)],
  // Légumes
  20057: [_plateVeg],
  20304: [_plateVeg],
  20020: [HouseholdPortion('1 courgette moyenne', '1 medium zucchini', 200), _plateVeg],
  20021: [_plateVeg],
  20009: [HouseholdPortion('1 carotte moyenne', '1 medium carrot', 80)],
  20353: [_plateVeg],
  20385: [HouseholdPortion('1 tomate moyenne', '1 medium tomato', 120)],
  20172: [HouseholdPortion('5 tomates cerises', '5 cherry tomatoes', 75)],
  20019: [HouseholdPortion('½ concombre', '½ cucumber', 150)],
  20031: [HouseholdPortion('1 bol de salade', '1 bowl of salad', 50)],
  20099: [HouseholdPortion('1 poignée', '1 handful', 30)],
  20217: [HouseholdPortion('1 poignée', '1 handful', 20)],
  20059: [HouseholdPortion('1 poignée', '1 handful', 30)],
  20027: [_plateVeg],
  20030: [_plateVeg],
  20087: [HouseholdPortion('1 poivron moyen', '1 medium pepper', 150)],
  20056: [HouseholdPortion('1 portion', '1 serving', 100)],
  20034: [HouseholdPortion('1 oignon moyen', '1 medium onion', 100)],
  11000: [HouseholdPortion('1 gousse', '1 clove', 5)],
  13004: [HouseholdPortion('½ avocat', '½ avocado', 75), HouseholdPortion('1 avocat', '1 avocado', 150)],
  20016: [_plateVeg],
  20037: [_plateVeg],
  20053: [HouseholdPortion('1 aubergine', '1 eggplant', 250)],
  20003: [HouseholdPortion('1 betterave', '1 beetroot', 100)],
  20346: [HouseholdPortion('1 poignée', '1 handful', 30)],
  20327: [_plateVeg],
  // Fruits (partie comestible)
  13005: [HouseholdPortion('1 banane moyenne', '1 medium banana', 120)],
  13039: [HouseholdPortion('1 pomme moyenne', '1 medium apple', 150)],
  13034: [HouseholdPortion('1 orange moyenne', '1 medium orange', 140)],
  13021: [HouseholdPortion('1 kiwi', '1 kiwi', 75)],
  13024: [HouseholdPortion('1 clémentine', '1 clementine', 60)],
  13014: [HouseholdPortion('1 portion', '1 serving', 150), HouseholdPortion('1 fraise', '1 strawberry', 15)],
  13028: [HouseholdPortion('1 barquette', '1 punnet', 125), HouseholdPortion('1 poignée', '1 handful', 50)],
  13015: [HouseholdPortion('1 barquette', '1 punnet', 125), HouseholdPortion('1 poignée', '1 handful', 50)],
  13037: [HouseholdPortion('1 poire moyenne', '1 medium pear', 160)],
  13395: [HouseholdPortion('1 portion', '1 serving', 125)],
  13025: [HouseholdPortion('½ mangue', '½ mango', 150)],
  13002: [HouseholdPortion('1 tranche', '1 slice', 80)],
  13043: [HouseholdPortion('1 pêche', '1 peach', 130)],
  13000: [HouseholdPortion('1 abricot', '1 apricot', 40), HouseholdPortion('3 abricots', '3 apricots', 120)],
  13008: [HouseholdPortion('1 poignée', '1 handful', 100)],
  13026: [HouseholdPortion('1 tranche', '1 slice', 150)],
  13036: [HouseholdPortion('1 tranche', '1 slice', 200)],
  13011: [HouseholdPortion('1 datte', '1 date', 8), HouseholdPortion('3 dattes', '3 dates', 24)],
  13046: [HouseholdPortion('1 c. à soupe', '1 tbsp', 15)],
  13187: [HouseholdPortion('1 pot', '1 pot', 100)],
  // Oléagineux, graines
  15000: [_handful],
  15005: [_handful, HouseholdPortion('1 noix (2 cerneaux)', '1 walnut (2 halves)', 5)],
  15004: [_handful],
  15054: [_handful],
  15001: [_handful],
  15202: [HouseholdPortion('1 c. à soupe', '1 tbsp', 15), HouseholdPortion('1 c. à café', '1 tsp', 5)],
  15047: [_tbspSeeds],
  15034: [_tbspSeeds],
  15064: [_tbspSeeds],
  // Matières grasses
  17270: [_tbspOil, _tspOil],
  17130: [_tbspOil, _tspOil],
  16400: [HouseholdPortion('1 portion individuelle', '1 single portion', 10), HouseholdPortion('1 c. à café', '1 tsp', 5)],
  19410: [HouseholdPortion('1 c. à soupe', '1 tbsp', 15)],
  // Boissons, sucré, condiments
  18004: [HouseholdPortion('1 tasse', '1 cup', 150), _mug],
  18071: [HouseholdPortion('1 expresso', '1 espresso', 40)],
  18020: [_cup, _mug],
  18155: [_cup, _mug],
  18022: [_cup, _mug],
  2070: [_glass],
  31008: [HouseholdPortion('1 c. à café', '1 tsp', 7), HouseholdPortion('1 c. à soupe', '1 tbsp', 20)],
  31016: [HouseholdPortion('1 morceau', '1 cube', 5), HouseholdPortion('1 c. à café', '1 tsp', 5)],
  31074: [HouseholdPortion('1 carré', '1 square', 5), HouseholdPortion('2 carrés', '2 squares', 10)],
  11013: [HouseholdPortion('1 c. à café', '1 tsp', 5)],
  11108: [_tbspSauce],
  11104: [_tbspSauce],
  11054: [_tbspSauce],
  11008: [_tbspSauce],
};

/// Repères par sous-groupe ANSES pour les aliments hors essentiels.
const Map<String, List<HouseholdPortion>> _bySubgroup = {
  'huiles et graisses végétales': [_tbspOil, _tspOil],
  'huiles de poissons': [_tspOil],
  'margarines': [HouseholdPortion('1 c. à café', '1 tsp', 5), HouseholdPortion('1 portion individuelle', '1 single portion', 10)],
  'beurres': [HouseholdPortion('1 portion individuelle', '1 single portion', 10), HouseholdPortion('1 c. à café', '1 tsp', 5)],
  'fromages et alternatives végétales': [_cheese],
  'laits': [_glass],
  'fruits à coque et graines oléagineuses': [_handful],
  'céréales de petit-déjeuner': [HouseholdPortion('1 portion', '1 serving', 30)],
  'sucres, miels et assimilés': [HouseholdPortion('1 c. à café', '1 tsp', 5)],
  'confitures et assimilés': [HouseholdPortion('1 c. à soupe', '1 tbsp', 20)],
  'sauces': [_tbspSauce],
  'condiments': [HouseholdPortion('1 c. à café', '1 tsp', 5)],
  'herbes': [HouseholdPortion('1 c. à soupe', '1 tbsp', 3)],
  'épices': [HouseholdPortion('1 c. à café', '1 tsp', 2)],
  'boissons sans alcool': [_glass, HouseholdPortion('1 canette (33 cl)', '1 can (330 ml)', 330)],
  'eaux': [_glass],
};

List<HouseholdPortion> householdPortionsFor({int? ciqualCode, String? sousGroupe}) {
  final byCode = ciqualCode == null ? null : _byCode[ciqualCode];
  if (byCode != null) return byCode;
  return sousGroupe == null ? const [] : (_bySubgroup[sousGroupe] ?? const []);
}

/// Codes CIQUAL ayant des portions précises (tests).
Iterable<int> get householdPortionCodes => _byCode.keys;
