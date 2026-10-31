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
  'autres matières grasses': [HouseholdPortion('1 c. à soupe', '1 tbsp', 10)],
  'fromages et alternatives végétales': [_cheese],
  'laits': [_glass, HouseholdPortion('1 bol', '1 bowl', 250)],
  'produits laitiers frais et alternatives végétales': [HouseholdPortion('1 pot', '1 pot', 125)],
  'crèmes et spécialités à base de crème': [HouseholdPortion('1 c. à soupe', '1 tbsp', 15)],
  'fruits à coque et graines oléagineuses': [_handful],
  'céréales de petit-déjeuner': [HouseholdPortion('1 portion', '1 serving', 30), HouseholdPortion('1 bol', '1 bowl', 45)],
  'sucres, miels et assimilés': [HouseholdPortion('1 c. à café', '1 tsp', 5)],
  'confitures et assimilés': [HouseholdPortion('1 c. à soupe', '1 tbsp', 20), HouseholdPortion('1 c. à café', '1 tsp', 7)],
  'sauces': [_tbspSauce],
  'condiments': [HouseholdPortion('1 c. à café', '1 tsp', 5)],
  'herbes': [HouseholdPortion('1 c. à soupe', '1 tbsp', 3)],
  'épices': [HouseholdPortion('1 c. à café', '1 tsp', 2)],
  'sels': [HouseholdPortion('1 pincée', '1 pinch', 0.5), HouseholdPortion('1 c. à café', '1 tsp', 5)],
  'boissons sans alcool': [_glass, HouseholdPortion('1 canette (33 cl)', '1 can (330 ml)', 330)],
  'eaux': [_glass],
  'légumineuses': [_plateLegume],
  'pâtes, riz et céréales': [_plateStarch],
  'viandes crues': [HouseholdPortion('1 portion', '1 serving', 125)],
  'viandes cuites': [HouseholdPortion('1 portion', '1 serving', 100)],
  'poissons crus': [HouseholdPortion('1 filet', '1 fillet', 130)],
  'poissons cuits': [HouseholdPortion('1 filet', '1 fillet', 110)],
  'mollusques et crustacés crus': [HouseholdPortion('1 portion', '1 serving', 100)],
  'mollusques et crustacés cuits': [HouseholdPortion('1 portion', '1 serving', 100)],
  'oeufs': [HouseholdPortion('1 œuf', '1 egg', 50), HouseholdPortion('2 œufs', '2 eggs', 100)],
  'soupes': [HouseholdPortion('1 bol', '1 bowl', 250)],
  'salades composées et crudités': [HouseholdPortion('1 assiette', '1 plate', 250)],
  'plats composés': [HouseholdPortion('1 assiette', '1 plate', 300)],
  'glaces': [HouseholdPortion('1 boule', '1 scoop', 50), HouseholdPortion('2 boules', '2 scoops', 100)],
  'sorbets': [HouseholdPortion('1 boule', '1 scoop', 50), HouseholdPortion('2 boules', '2 scoops', 100)],
  'compléments protéinés': [HouseholdPortion('1 dose', '1 scoop', 30)],
  'algues': [HouseholdPortion('1 c. à café', '1 tsp', 3)],
  'farines': [HouseholdPortion('1 c. à soupe', '1 tbsp', 10)],
  'desserts glacés': [HouseholdPortion('1 part', '1 serving', 100)],
};

/// Portions par mot-clé du nom, dans une famille donnée (après les codes
/// précis, avant le repère de la famille). Poids de la partie comestible ;
/// boissons alcoolisées : VERRE STANDARD de Santé publique France (10 g
/// d'alcool pur : 10 cl de vin, 25 cl de bière, 3 cl d'alcool fort).
/// (familles concernées, mots-clés, mots exclus, portions)
const List<(Set<String>, List<String>, List<String>, List<HouseholdPortion>)> _byKeyword = [
  // Fruits (frais, partie comestible)
  ({'fruits'}, ['pomme'], ['compote', 'jus', 'sirop', 'seche', 'puree', 'cajou', 'cannelle', 'liane', 'pomme d\'eau', 'etoile'],
      [HouseholdPortion('1 pomme moyenne', '1 medium apple', 150)]),
  ({'fruits'}, ['poire'], ['compote', 'jus', 'sirop', 'seche'], [HouseholdPortion('1 poire moyenne', '1 medium pear', 160)]),
  ({'fruits'}, ['banane'], ['seche', 'chips'], [HouseholdPortion('1 banane moyenne', '1 medium banana', 120)]),
  ({'fruits'}, ['orange'], ['jus', 'confite', 'amere'], [HouseholdPortion('1 orange moyenne', '1 medium orange', 140)]),
  ({'fruits'}, ['clementine', 'mandarine'], ['jus'], [HouseholdPortion('1 clémentine', '1 clementine', 60)]),
  ({'fruits'}, ['pamplemousse', 'pomelo'], ['jus'], [HouseholdPortion('½ pamplemousse', '½ grapefruit', 130)]),
  ({'fruits'}, ['kiwi'], ['jus'], [HouseholdPortion('1 kiwi', '1 kiwi', 75)]),
  ({'fruits'}, ['peche', 'nectarine', 'brugnon'], ['sirop', 'jus', 'compote'], [HouseholdPortion('1 pêche', '1 peach', 130)]),
  ({'fruits'}, ['abricot'], ['sirop', 'jus', 'compote', 'sec'], [HouseholdPortion('1 abricot', '1 apricot', 40)]),
  ({'fruits'}, ['abricot'], ['sirop', 'jus', 'compote'], [HouseholdPortion('3 abricots secs', '3 dried apricots', 24)]),
  ({'fruits'}, ['pruneau'], [], [HouseholdPortion('3 pruneaux', '3 prunes', 30)]),
  ({'fruits'}, ['prune', 'mirabelle', 'quetsche', 'reine-claude'], ['jus', 'cythere', 'sirop'], [HouseholdPortion('3 prunes', '3 plums', 100)]),
  ({'fruits'}, ['figue'], ['barbarie'], [HouseholdPortion('1 figue', '1 fig', 50)]),
  ({'fruits'}, ['datte'], [], [HouseholdPortion('1 datte', '1 date', 8), HouseholdPortion('3 dattes', '3 dates', 24)]),
  ({'fruits'}, ['fraise'], ['jus'], [HouseholdPortion('1 portion', '1 serving', 150), HouseholdPortion('1 fraise', '1 strawberry', 15)]),
  ({'fruits'}, ['framboise', 'myrtille', 'mure', 'groseille', 'cassis', 'fruits rouges'], ['jus', 'coulis'],
      [HouseholdPortion('1 barquette', '1 punnet', 125), HouseholdPortion('1 poignée', '1 handful', 50)]),
  ({'fruits'}, ['cerise'], ['acerola', 'jus'], [HouseholdPortion('1 poignée', '1 handful', 100)]),
  ({'fruits'}, ['raisin'], ['jus', 'sec'], [HouseholdPortion('1 grappe', '1 bunch', 125)]),
  ({'fruits'}, ['raisin sec'], [], [HouseholdPortion('1 c. à soupe', '1 tbsp', 15)]),
  ({'fruits'}, ['ananas'], ['jus', 'sirop'], [HouseholdPortion('1 tranche', '1 slice', 80)]),
  ({'fruits'}, ['mangue'], ['jus', 'nectar'], [HouseholdPortion('½ mangue', '½ mango', 150)]),
  ({'fruits'}, ['melon'], [], [HouseholdPortion('1 tranche', '1 slice', 150)]),
  ({'fruits'}, ['pasteque'], [], [HouseholdPortion('1 tranche', '1 slice', 200)]),
  ({'fruits'}, ['litchi'], ['sirop'], [HouseholdPortion('5 litchis', '5 lychees', 50)]),
  ({'fruits'}, ['avocat'], [], [HouseholdPortion('½ avocat', '½ avocado', 75)]),
  ({'fruits', 'condiments'}, ['olive'], ['huile'], [HouseholdPortion('5 olives', '5 olives', 20)]),
  ({'condiments'}, ['cornichon'], [], [HouseholdPortion('3 cornichons', '3 gherkins', 30)]),
  ({'fruits'}, ['compote', 'puree de'], [], [HouseholdPortion('1 pot', '1 pot', 100)]),
  ({'fruits'}, ['jus'], [], [_glass]),
  ({'fruits'}, ['zeste'], [], [HouseholdPortion('1 c. à café', '1 tsp', 2)]),
  ({'fruits'}, ['citron', 'lime'], [], [HouseholdPortion('1 citron', '1 lemon', 60)]),
  ({'fruits'}, ['seche', 'sechee', 'sec,', 'goji'], [], [HouseholdPortion('1 poignée', '1 handful', 30)]),
  // Fruit sans repère propre (exotiques, au sirop, macédoines) : portion
  // de fruit du PNNS (80-100 g).
  ({'fruits'}, [''], [], [HouseholdPortion('1 portion', '1 serving', 100)]),
  // Légumes
  ({'légumes'}, ['tomate cerise'], [], [HouseholdPortion('5 tomates cerises', '5 cherry tomatoes', 75)]),
  ({'légumes'}, ['tomate'], ['sechee', 'puree', 'coulis', 'concentre', 'jus'], [HouseholdPortion('1 tomate moyenne', '1 medium tomato', 120)]),
  ({'légumes'}, ['carotte'], ['jus', 'puree', 'petits pois', 'printaniere', 'jardiniere', 'macedoine'],
      [HouseholdPortion('1 carotte moyenne', '1 medium carrot', 80)]),
  ({'légumes'}, ['courgette'], ['puree'], [HouseholdPortion('½ courgette', '½ zucchini', 100), HouseholdPortion('1 portion', '1 serving', 150)]),
  ({'légumes'}, ['poivron'], [], [HouseholdPortion('½ poivron', '½ pepper', 75)]),
  ({'légumes'}, ['oignon'], [], [HouseholdPortion('1 oignon moyen', '1 medium onion', 100)]),
  ({'légumes'}, ['echalote'], [], [HouseholdPortion('1 échalote', '1 shallot', 20)]),
  ({'légumes'}, ['concombre'], [], [HouseholdPortion('½ concombre', '½ cucumber', 150)]),
  ({'légumes'}, ['laitue', 'salade', 'mache', 'roquette', 'cresson', 'pousse', 'chicoree', 'endive crue', 'mesclun'], [],
      [HouseholdPortion('1 bol', '1 bowl', 50)]),
  ({'légumes'}, ['champignon'], [], [HouseholdPortion('1 portion', '1 serving', 100)]),
  ({'légumes'}, ['betterave'], [], [HouseholdPortion('1 betterave', '1 beetroot', 100)]),
  ({'légumes'}, ['artichaut'], [], [HouseholdPortion('1 fond', '1 heart', 40)]),
  ({'légumes'}, ['graine germee', 'germe', 'pousses'], [], [HouseholdPortion('1 poignée', '1 handful', 20)]),
  ({'légumes'}, ['radis'], ['graine', 'germe'], [HouseholdPortion('5 radis', '5 radishes', 50)]),
  ({'légumes'}, ['piment'], [], [HouseholdPortion('1 piment', '1 chili', 10)]),
  ({'légumes', 'herbes', 'épices'}, ['gingembre'], [], [HouseholdPortion('1 c. à café', '1 tsp', 5)]),
  ({'légumes', 'herbes'}, ['ail,', 'ail '], ['ailes'], [HouseholdPortion('1 gousse', '1 clove', 5)]),
  ({'légumes'}, [''], [], [_plateVeg]),
  // Pommes de terre et tubercules
  ({'pommes de terre et autres tubercules'}, ['frite'], [], [HouseholdPortion('1 portion', '1 serving', 125)]),
  ({'pommes de terre et autres tubercules'}, ['puree'], [], [HouseholdPortion('1 portion', '1 serving', 200)]),
  ({'pommes de terre et autres tubercules'}, ['pomme de terre', 'patate douce', 'igname', 'manioc', 'topinambour'], ['chips', 'flocons'],
      [HouseholdPortion('1 pomme de terre moyenne', '1 medium potato', 150)]),
  ({'pommes de terre et autres tubercules'}, [''], [], [HouseholdPortion('1 portion', '1 serving', 150)]),
  ({'biscuits apéritifs'}, [''], [], [HouseholdPortion('1 petit bol', '1 small bowl', 30)]),
  // Légumineuses et céréales sèches (crues)
  ({'légumineuses'}, ['sec', 'seche', 'crue', 'cru'], ['cuit'], [HouseholdPortion('1 portion (sec)', '1 serving (dry)', 60)]),
  ({'pâtes, riz et céréales'}, ['cru', 'seche', 'sec', 'farine'], ['cuit'], [HouseholdPortion('1 portion (sec)', '1 serving (dry)', 70)]),
  ({'oeufs'}, ['omelette', 'tortilla', 'brouille'], [], [HouseholdPortion('1 omelette (2 œufs)', '1 omelette (2 eggs)', 120)]),
  ({'oeufs'}, ['blanc'], [], [HouseholdPortion('1 blanc', '1 white', 30)]),
  ({'oeufs'}, ['jaune'], [], [HouseholdPortion('1 jaune', '1 yolk', 17)]),
  // Pains, viennoiseries
  ({'pains et assimilés'}, ['baguette', 'pain blanc', 'pain de tradition'], [], [HouseholdPortion('¼ de baguette', '¼ baguette', 62), HouseholdPortion('1 tranche', '1 slice', 30)]),
  ({'pains et assimilés'}, ['pain de mie'], [], [HouseholdPortion('1 tranche', '1 slice', 25), HouseholdPortion('2 tranches', '2 slices', 50)]),
  ({'pains et assimilés'}, ['biscotte', 'pain grille'], [], [HouseholdPortion('1 tranche', '1 slice', 8), HouseholdPortion('3 tranches', '3 slices', 24)]),
  ({'pains et assimilés'}, ['burger', 'hot dog'], [], [HouseholdPortion('1 pain', '1 bun', 60)]),
  ({'pains et assimilés'}, ['tortilla', 'wrap'], [], [HouseholdPortion('1 galette', '1 wrap', 60)]),
  ({'pains et assimilés'}, ['pita'], [], [HouseholdPortion('1 pain pita', '1 pita', 60)]),
  ({'pains et assimilés'}, ['galette de riz', 'galette de mais', 'galette de cereale'], [], [HouseholdPortion('1 galette', '1 cake', 8)]),
  ({'pains et assimilés'}, ['pain'], [], [HouseholdPortion('1 tranche', '1 slice', 35)]),
  ({'pains et assimilés'}, [''], [], [HouseholdPortion('1 portion', '1 serving', 30)]),
  ({'viennoiseries'}, ['croissant'], [], [HouseholdPortion('1 croissant', '1 croissant', 45)]),
  ({'viennoiseries'}, ['pain au chocolat', 'chocolatine'], [], [HouseholdPortion('1 pain au chocolat', '1 pain au chocolat', 60)]),
  ({'viennoiseries'}, ['pain aux raisins'], [], [HouseholdPortion('1 pièce', '1 piece', 80)]),
  ({'viennoiseries'}, ['chausson'], [], [HouseholdPortion('1 chausson', '1 turnover', 100)]),
  ({'viennoiseries'}, ['pain au lait'], [], [HouseholdPortion('1 pain au lait', '1 milk bun', 35)]),
  ({'viennoiseries'}, ['brioche'], [], [HouseholdPortion('1 tranche', '1 slice', 35)]),
  ({'viennoiseries'}, ['chouquette'], [], [HouseholdPortion('1 chouquette', '1 choux bun', 10), HouseholdPortion('5 chouquettes', '5 choux buns', 50)]),
  ({'viennoiseries', 'gâteaux et pâtisseries'}, ['beignet', 'donut'], [], [HouseholdPortion('1 beignet', '1 doughnut', 70)]),
  ({'viennoiseries'}, [''], [], [HouseholdPortion('1 pièce', '1 piece', 60)]),
  // Laitiers frais
  ({'produits laitiers frais et alternatives végétales'}, ['petit suisse', 'petit-suisse'], [], [HouseholdPortion('1 petit-suisse', '1 pot', 60)]),
  ({'produits laitiers frais et alternatives végétales'}, ['fromage blanc', 'faisselle'], [], [HouseholdPortion('1 pot individuel', '1 single pot', 100)]),
  ({'produits laitiers frais et alternatives végétales'}, ['mousse'], [], [HouseholdPortion('1 pot', '1 pot', 60)]),
  ({'produits laitiers frais et alternatives végétales'}, ['grecque', 'skyr', 'riche en proteines'], [], [HouseholdPortion('1 pot', '1 pot', 150)]),
  ({'fromages et alternatives végétales'}, ['mozzarella'], [], [HouseholdPortion('1 boule', '1 ball', 125), _cheese]),
  ({'fromages et alternatives végétales'}, ['rape'], [], [HouseholdPortion('1 c. à soupe', '1 tbsp', 7)]),
  // Charcuterie
  ({'charcuteries et alternatives végétales'}, ['saucisson', 'chorizo', 'salami', 'rosette', 'coppa', 'pancetta'], [],
      [HouseholdPortion('5 rondelles', '5 slices', 25)]),
  ({'charcuteries et alternatives végétales'}, ['knack', 'strasbourg', 'francfort', 'saucisse cocktail'], [], [HouseholdPortion('1 saucisse', '1 sausage', 35)]),
  ({'charcuteries et alternatives végétales'}, ['merguez', 'chipolata'], [], [HouseholdPortion('1 saucisse', '1 sausage', 50)]),
  ({'charcuteries et alternatives végétales'}, ['saucisse'], [], [HouseholdPortion('1 saucisse', '1 sausage', 100)]),
  ({'charcuteries et alternatives végétales'}, ['jambon cru', 'jambon sec', 'bayonne', 'parme', 'serrano', 'bresaola', 'grisons'], [],
      [HouseholdPortion('1 tranche', '1 slice', 15), HouseholdPortion('3 tranches', '3 slices', 45)]),
  ({'charcuteries et alternatives végétales'}, ['jambon', 'blanc de poulet', 'blanc de dinde'], [], [HouseholdPortion('1 tranche', '1 slice', 40)]),
  ({'charcuteries et alternatives végétales'}, ['lardon'], [], [HouseholdPortion('1 portion', '1 serving', 50)]),
  ({'charcuteries et alternatives végétales'}, ['bacon', 'poitrine'], [], [HouseholdPortion('1 tranche', '1 rasher', 12)]),
  ({'charcuteries et alternatives végétales'}, ['pate', 'terrine', 'rillettes', 'mousse', 'foie gras'], [], [HouseholdPortion('1 portion (tartine)', '1 serving', 30)]),
  ({'charcuteries et alternatives végétales'}, ['andouillette'], [], [HouseholdPortion('1 andouillette', '1 andouillette', 150)]),
  ({'charcuteries et alternatives végétales'}, ['boudin'], [], [HouseholdPortion('1 boudin', '1 sausage', 125)]),
  ({'charcuteries et alternatives végétales'}, [''], [], [HouseholdPortion('1 portion', '1 serving', 50)]),
  // Produits de la mer transformés
  ({'produits à base de poissons et produits de la mer'}, ['surimi'], [], [HouseholdPortion('1 bâtonnet', '1 stick', 15), HouseholdPortion('5 bâtonnets', '5 sticks', 75)]),
  ({'produits à base de poissons et produits de la mer'}, ['sardine', 'maquereau', 'thon', 'anchois', 'hareng', 'pilchard'],
      ['rillettes', 'pate', 'mousse'], [HouseholdPortion('1 boîte égouttée', '1 can, drained', 90)]),
  ({'produits à base de poissons et produits de la mer'}, ['fume'], [], [HouseholdPortion('1 tranche', '1 slice', 25)]),
  ({'produits à base de poissons et produits de la mer'}, ['rillettes', 'tarama', 'mousse', 'pate', 'oeufs de'], [], [HouseholdPortion('1 portion (tartine)', '1 serving', 30)]),
  ({'produits à base de poissons et produits de la mer'}, [''], [], [HouseholdPortion('1 portion', '1 serving', 100)]),
  ({'tartinables végétariens'}, [''], [], [HouseholdPortion('1 c. à soupe', '1 tbsp', 20)]),
  ({'ingrédients pour végétariens'}, [''], [], [HouseholdPortion('1 portion', '1 serving', 100)]),
  // Plats, tartes, sandwichs
  ({'pizzas, tartes et crêpes salées'}, ['pizza'], [], [HouseholdPortion('1 part', '1 slice', 120)]),
  ({'pizzas, tartes et crêpes salées'}, ['quiche', 'tarte', 'tourte'], [], [HouseholdPortion('1 part', '1 slice', 130)]),
  ({'pizzas, tartes et crêpes salées'}, ['crepe', 'galette'], [], [HouseholdPortion('1 galette', '1 crêpe', 120)]),
  ({'sandwichs'}, ['baguette'], [], [HouseholdPortion('1 sandwich', '1 sandwich', 250)]),
  ({'sandwichs'}, ['pain de mie', 'club'], [], [HouseholdPortion('1 sandwich', '1 sandwich', 150)]),
  ({'sandwichs'}, ['burger'], [], [HouseholdPortion('1 burger', '1 burger', 170)]),
  ({'sandwichs'}, ['panini', 'wrap', 'kebab'], [], [HouseholdPortion('1 pièce', '1 piece', 200)]),
  ({'sandwichs'}, [''], [], [HouseholdPortion('1 sandwich', '1 sandwich', 200)]),
  ({'pizzas, tartes et crêpes salées'}, [''], [], [HouseholdPortion('1 part', '1 slice', 130)]),
  ({'feuilletées et autres entrées'}, ['nem', 'rouleau de printemps'], [], [HouseholdPortion('1 pièce', '1 piece', 40)]),
  ({'feuilletées et autres entrées'}, ['samoussa', 'samosa', 'accra'], [], [HouseholdPortion('1 pièce', '1 piece', 30)]),
  ({'feuilletées et autres entrées'}, [''], [], [HouseholdPortion('1 pièce', '1 piece', 100)]),
  // Sucré
  ({'chocolats et produits à base de chocolat'}, ['tablette'], [], [HouseholdPortion('1 carré', '1 square', 5), HouseholdPortion('1 rangée', '1 row', 20)]),
  ({'chocolats et produits à base de chocolat'}, ['pate a tartiner'], [], [HouseholdPortion('1 c. à café', '1 tsp', 10)]),
  ({'chocolats et produits à base de chocolat'}, ['barre'], [], [HouseholdPortion('1 barre', '1 bar', 45)]),
  ({'chocolats et produits à base de chocolat'}, ['bouchee', 'bonbon', 'praline', 'truffe'], [], [HouseholdPortion('1 bouchée', '1 piece', 10)]),
  ({'chocolats et produits à base de chocolat'}, [''], [], [HouseholdPortion('1 carré', '1 square', 5), HouseholdPortion('1 rangée', '1 row', 20)]),
  ({'confiseries non chocolatées'}, ['bonbon', 'pastille', 'chewing', 'guimauve', 'caramel', 'dragee', 'reglisse'], [],
      [HouseholdPortion('1 bonbon', '1 sweet', 5), HouseholdPortion('5 bonbons', '5 sweets', 25)]),
  ({'confiseries non chocolatées'}, [''], [], [HouseholdPortion('1 portion', '1 serving', 20)]),
  ({'biscuits sucrés'}, ['petit beurre', 'sable', 'biscuit sec'], [], [HouseholdPortion('1 biscuit', '1 biscuit', 8), HouseholdPortion('4 biscuits', '4 biscuits', 32)]),
  ({'biscuits sucrés'}, [''], [], [HouseholdPortion('1 biscuit', '1 biscuit', 10), HouseholdPortion('3 biscuits', '3 biscuits', 30)]),
  ({'gâteaux et pâtisseries'}, ['crepe'], [], [HouseholdPortion('1 crêpe', '1 crêpe', 60)]),
  ({'gâteaux et pâtisseries'}, ['madeleine'], [], [HouseholdPortion('1 madeleine', '1 madeleine', 25)]),
  ({'gâteaux et pâtisseries'}, ['gaufre'], [], [HouseholdPortion('1 gaufre', '1 waffle', 60)]),
  ({'gâteaux et pâtisseries'}, [''], [], [HouseholdPortion('1 part', '1 slice', 80)]),
  ({'barres céréalières'}, [''], [], [HouseholdPortion('1 barre', '1 bar', 25)]),
  ({'sucres, miels et assimilés'}, ['miel', 'sirop'], [], [HouseholdPortion('1 c. à café', '1 tsp', 7), HouseholdPortion('1 c. à soupe', '1 tbsp', 20)]),
  ({'sucres, miels et assimilés'}, ['sucre'], [], [HouseholdPortion('1 morceau', '1 cube', 5), HouseholdPortion('1 c. à café', '1 tsp', 5)]),
  // Boissons
  ({'boissons sans alcool'}, ['expresso'], [], [HouseholdPortion('1 expresso', '1 espresso', 40)]),
  ({'boissons sans alcool'}, ['cafe', 'chicoree'], ['poudre', 'moulu'], [HouseholdPortion('1 tasse', '1 cup', 150), _mug]),
  ({'boissons sans alcool'}, ['the', 'tisane', 'infusion'], ['boisson au the', 'feuille'], [_cup, _mug]),
  ({'boissons sans alcool'}, ['poudre', 'moulu', 'soluble'], [], [HouseholdPortion('1 c. à café', '1 tsp', 2)]),
  ({'boissons sans alcool'}, ['energisante'], [], [HouseholdPortion('1 canette (25 cl)', '1 can (250 ml)', 250)]),
  ({'boisson alcoolisées'}, ['biere', 'panache'], [], [HouseholdPortion('1 demi (25 cl)', '1 half-pint (250 ml)', 250)]),
  ({'boisson alcoolisées'}, ['vin', 'champagne', 'mousseux', 'cidre', 'kir'], ['eau de vie', 'apéritif', 'aperitif'],
      [HouseholdPortion('1 verre (10 cl)', '1 glass (100 ml)', 100)]),
  ({'boisson alcoolisées'}, [''], ['sans alcool'], [HouseholdPortion('1 verre standard (3 cl)', '1 standard shot (30 ml)', 28)]),
];

List<HouseholdPortion> householdPortionsFor({int? ciqualCode, String? sousGroupe, String? name}) {
  final byCode = ciqualCode == null ? null : _byCode[ciqualCode];
  if (byCode != null) return byCode;
  if (sousGroupe == null) return const [];
  if (name != null) {
    final n = _fold(name);
    for (final (subgroups, keywords, excludes, portions) in _byKeyword) {
      if (!subgroups.contains(sousGroupe)) continue;
      if (!keywords.any((k) => k.isEmpty || n.contains(k))) continue;
      if (excludes.any((x) => n.contains(x))) continue;
      return portions;
    }
  }
  return _bySubgroup[sousGroupe] ?? const [];
}

/// Minuscules sans accents (comparaison des mots-clés).
String _fold(String s) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüÿœ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyo';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : (ch == 'œ' ? 'oe' : to[i]));
  }
  return b.toString();
}

/// Codes CIQUAL ayant des portions précises (tests).
Iterable<int> get householdPortionCodes => _byCode.keys;
