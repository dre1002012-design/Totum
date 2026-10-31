// lib/services/staple_foods.dart
//
// « Les essentiels du quotidien » (31/10/2026, demande d'Alex) : à
// l'ouverture du « + », un nouvel utilisateur voyait les 3 490 aliments
// CIQUAL par ordre alphabétique (« Abat, cuit », « Abondance », « Abricot
// au sirop »…), faute d'historique pour le tri « fréquents ». Les apps de
// référence (MyFitnessPal, Yazio, Cronometer, MacroFactor) ouvrent toutes
// sur l'historique de l'utilisateur, complété par des aliments courants.
//
// Liste curée d'aliments génériques, bruts ou peu transformés, que l'on
// pèse et logue au quotidien dans une alimentation orientée santé,
// longévité ou performance — dans l'ordre d'affichage (groupes d'un repas
// type : protéines, laitiers, féculents, légumes, fruits, oléagineux,
// matières grasses, boissons, condiments). Uniquement des codes CIQUAL
// complets (énergie + macros connues) ; le libellé affiché court et clair
// vient de la colonne nom_generique de assets/foods.csv.
//
// N'influence QUE la liste par défaut (sans recherche), après les aliments
// déjà utilisés par la personne. La recherche (food_search.dart) garde son
// propre classement : pertinence, favoris, fréquence, aliments courants.

const List<int> kStapleCiqualCodes = [
  // ── Œufs, viandes, poissons ────────────────────────────────────────
  22000, // Œuf entier, cru
  22010, // Œuf dur
  22001, // Blanc d'œuf, cru
  36017, // Blanc de poulet, cru
  36018, // Blanc de poulet, grillé
  36304, // Escalope de dinde, crue
  36306, // Escalope de dinde, grillée
  6250, // Steak haché 5 % MG, cru
  6251, // Steak haché 5 % MG, cuit
  6255, // Steak haché 15 % MG, cuit
  6201, // Steak de bœuf, cru
  28902, // Jambon blanc découenné
  28203, // Filet mignon de porc, cuit
  26036, // Saumon, cru
  26229, // Saumon, grillé
  26037, // Saumon fumé
  26039, // Thon au naturel (boîte)
  26043, // Cabillaud, cru
  26023, // Cabillaud, cuit au four
  26129, // Colin (lieu jaune), cru
  26051, // Maquereau, cru
  26040, // Sardines à l'huile d'olive (boîte)
  10007, // Crevette, cuite
  // ── Produits laitiers et alternatives ─────────────────────────────
  19033, // Lait demi-écrémé
  19050, // Lait écrémé
  19023, // Lait entier
  19593, // Yaourt nature
  19594, // Yaourt nature 0 %
  19860, // Yaourt grec nature
  19724, // Skyr / spécialité laitière riche en protéines
  19644, // Fromage blanc 0 %
  19646, // Fromage blanc 3 %
  12115, // Emmental
  12110, // Comté
  19590, // Mozzarella
  12120, // Parmesan
  12066, // Feta
  12812, // Chèvre (bûche)
  18900, // Boisson soja nature
  18107, // Boisson amande nature
  18899, // Boisson avoine nature
  90002, // Whey (protéine en poudre)
  // ── Protéines végétales, légumineuses ─────────────────────────────
  20904, // Tofu nature
  20917, // Tempeh
  20360, // Lentilles, cuites
  20507, // Pois chiches, cuits
  20532, // Pois chiches en boîte
  20503, // Haricots rouges, cuits
  25621, // Houmous
  // ── Féculents, céréales, pains ───────────────────────────────────
  9104, // Riz blanc, cuit
  9100, // Riz blanc, cru
  9103, // Riz complet, cuit
  9125, // Riz basmati, cuit
  9811, // Pâtes, cuites
  9810, // Pâtes, crues
  9871, // Pâtes complètes, cuites
  9341, // Quinoa, cuit
  9340, // Quinoa, cru
  32140, // Flocons d'avoine
  4003, // Pomme de terre, cuite à l'eau
  4026, // Pomme de terre, au four
  4102, // Patate douce, cuite
  9683, // Semoule (couscous), cuite
  9691, // Boulgour, cuit
  7001, // Pain blanc / baguette
  7110, // Pain complet
  7200, // Pain de mie
  7352, // Galette de riz complet
  // ── Légumes ──────────────────────────────────────────────────────
  20057, // Brocoli, cru
  20304, // Brocoli, cuit vapeur
  20020, // Courgette, crue
  20021, // Courgette, cuite
  20009, // Carotte, crue
  20353, // Carotte, cuite
  20385, // Tomate, crue
  20172, // Tomate cerise
  20019, // Concombre
  20031, // Salade verte (laitue)
  20099, // Mâche
  20217, // Roquette
  20059, // Épinards, crus
  20027, // Épinards, cuits
  20030, // Haricots verts, cuits
  20087, // Poivron rouge, cru
  20056, // Champignon de Paris, cru
  20034, // Oignon, cru
  11000, // Ail, cru
  13004, // Avocat
  20016, // Chou-fleur, cru
  20037, // Petits pois, cuits
  20053, // Aubergine, crue
  20003, // Betterave rouge, cuite
  20346, // Chou kale, cru
  20327, // Poireau, cuit
  // ── Fruits ───────────────────────────────────────────────────────
  13005, // Banane
  13039, // Pomme
  13034, // Orange
  13021, // Kiwi
  13024, // Clémentine / mandarine
  13014, // Fraise
  13028, // Myrtille
  13015, // Framboise
  13037, // Poire
  13395, // Raisin
  13025, // Mangue
  13002, // Ananas
  13043, // Pêche
  13000, // Abricot
  13008, // Cerise
  13026, // Melon
  13036, // Pastèque
  13011, // Datte sèche
  13046, // Raisin sec
  13187, // Compote sans sucres ajoutés
  // ── Oléagineux, graines ──────────────────────────────────────────
  15000, // Amande
  15005, // Noix
  15004, // Noisette
  15054, // Noix de cajou
  15001, // Cacahuète
  15202, // Beurre de cacahuète
  15047, // Graines de chia
  15034, // Graines de lin
  15064, // Graines de courge
  // ── Matières grasses ─────────────────────────────────────────────
  17270, // Huile d'olive vierge extra
  17130, // Huile de colza
  16400, // Beurre doux
  19410, // Crème fraîche épaisse
  // ── Boissons, sucré, condiments ──────────────────────────────────
  18004, // Café noir
  18071, // Café expresso
  18020, // Thé
  18155, // Thé vert
  18022, // Tisane
  2070, // Jus d'orange, pur jus
  31008, // Miel
  31016, // Sucre
  31074, // Chocolat noir 70 %
  11013, // Moutarde
  11108, // Vinaigrette à l'huile d'olive
  11104, // Sauce soja
  11054, // Mayonnaise
  11008, // Ketchup
];

final Map<String, int> _rank = {
  for (var i = 0; i < kStapleCiqualCodes.length; i++) 'ciqual:${kStapleCiqualCodes[i]}': i,
};

/// Position d'un aliment dans la liste des essentiels (0 = premier), ou
/// null s'il n'en fait pas partie.
int? stapleRank(String id) => _rank[id];

bool isStapleFood(String id) => _rank.containsKey(id);
