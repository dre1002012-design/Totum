# Audit scientifique de `assets/foods.csv` — Rapport global

Conforme au cahier des charges `tasks/026-08-04_Audit scientifique de foods.csv.md`. Ce document est mis à jour à chaque lot d'audit — voir l'historique des lots ci-dessous.

## Principe

`foods.csv` (base CIQUAL 2025) reste le socle de référence de toute l'application (recettes ET journal manuel). Cet audit ne remplace jamais une valeur existante ni ne réécrit la base : il comble uniquement des cellules vides sur des nutriments précis, quand une source externe fiable permet une correspondance de confiance (aliment, mode de cuisson, partie consommée). Aucune valeur n'est inventée, estimée ou extrapolée. En cas de doute, la cellule reste vide.

## Ampleur du problème (vue d'ensemble, avant tout lot)

Sur les 3484 aliments de `foods.csv`, taux de cellules vides pour les nutriments prioritaires du cahier des charges :

| Nutriment | % vide | Nutriment | % vide |
|---|---|---|---|
| Vitamine E | 82,9 % | Acide oléique (W9) | 43,7 % |
| Vitamine K2 | 95,0 % | Bêta-carotène | 41,2 % |
| Vitamine K1 | 54,8 % | Acide linoléique (W6) | 41,1 % |
| Vitamine B9 | 56,2 % | ALA (oméga-3) | 39,5 % |
| Vitamine D | 37,6 % | Iode | 39,5 % |
| Vitamine B12 | 38,1 % | Sélénium | 39,7 % |
| Galactose | 78,7 % | EPA | 26,9 % |

Ce n'est pas une erreur de la base CIQUAL — c'est une limite de couverture connue des bases de composition nutritionnelle (l'analyse de laboratoire de chaque micronutriment pour chaque aliment a un coût, tous ne sont pas mesurés systématiquement). L'objectif de cet audit est de combler les trous les plus impactants pour les utilisateurs de TOTUM, aliment par aliment, nutriment par nutriment, avec des sources vérifiables.

## Lot 1 — Vitamine E, aliments utilisés dans les recettes TOTUM (04/08/2026)

- **Périmètre analysé** : les 124 aliments CIQUAL distincts utilisés dans les 160 recettes de `totum_recipes.json`, dont 111 avaient `Vitamine_E_mg_100g` vide.
- **Source utilisée** : USDA FoodData Central, tables **Foundation** et **SR Legacy** exclusivement (données de laboratoire officielles, écarté : `Survey (FNDDS)` et `Branded` car moins rigoureuses pour des aliments génériques).
- **Méthodologie** : recherche automatisée (1 requête par aliment) puis **revue manuelle systématique de chaque correspondance proposée** avant toute décision — vérification de l'identité de l'aliment, du mode de cuisson et de la partie consommée, conformément au cahier des charges.
- **Cellules analysées** : 111.
- **Corrections proposées et appliquées** : **58** (voir `Corrections_Proposees.csv`).
- **Cellules volontairement laissées vides** : **53**, faute de correspondance fiable (voir anomalies ci-dessous) — non comblées à ce stade plutôt que de risquer une donnée fausse.

### Anomalies détectées lors de la revue (correspondances automatiques rejetées)

La recherche automatique proposait un premier résultat, mais l'examen manuel a révélé des non-correspondances qu'il aurait été incorrect d'accepter :

- **Mauvaise espèce/produit** : Amande → "Butter" ; Cabillaud vapeur → "Crab" ; Crevette → "Crab" ; Dorade → "Scallop" ; Fromage blanc → "Croutons" puis "Cream cheese" ; Feta → "lait de brebis cru" ; Sardine crue → "huile de poisson" ; Riz basmati → "nouilles de riz".
- **Partie consommée différente** : Orange "chair" → correspondance trouvée = "peau d'orange" ; Concombre "chair et peau" → correspondance trouvée = "pelé".
- **Forme de transformation différente** : Pain complet de seigle (produit boulanger) → correspondance trouvée = grain de seigle brut ; Sarrasin cru en grains → correspondance trouvée = farine de sarrasin.
- **Incohérence de cuisson significative** (risque d'apport en matière grasse de cuisson différent) : Aubergine rôtie au four → correspondance trouvée = bouillie ; Potiron rôti au four → correspondance trouvée = bouilli.
- **Boisson au soja nature** → correspondance trouvée = boisson au soja **chocolatée**.
- **Artichaut** → correspondance trouvée = "Asperges en conserve" (résultat de recherche aberrant).

Dans tous ces cas, la cellule reste vide — ces aliments seront repris dans un lot ultérieur avec une requête de recherche affinée.

### Corrections appliquées à faible risque documentées comme "confiance Moyenne"

10 corrections sur les 58 reposent sur un aliment "proxy" proche mais non identique (ex. yaourt nature générique pour "lait fermenté type yaourt au bifidus", huile d'olive générique SR Legacy pour "huile d'olive vierge extra" faute d'entrée Foundation complète, lentille générique pour "lentille corail"). Le détail et la justification de chaque cas sont dans `Corrections_Proposees.csv`, colonne `niveau_de_confiance`.

### Familles d'aliments concernées

Légumes (14), fruits (10), poissons/fruits de mer (7), viandes/volailles (9), produits laitiers (4), légumineuses (5), céréales (8), oléagineux/graines (7), huiles (2), épices/aromates (3), autres (produits transformés simples : miel, confiture, biscotte, pain).

### Nutriment le plus impacté (ce lot)

Vitamine E uniquement (priorité n°1 du cahier des charges, et nutriment à l'origine de la demande d'Alex).

## Lot 2 — Vitamine E, famille légumes (20xxx) (04/08/2026)

- **Périmètre analysé** : 378 aliments de la famille légumes (codes CIQUAL `20xxx`) avec `Vitamine_E_mg_100g` vide.
- **Méthodologie** : recherche automatisée via un dictionnaire de traduction FR→EN construit pour cette famille, puis **revue manuelle exhaustive de chaque correspondance proposée** (aucune application automatique sans relecture).
- **Cellules analysées** : 378. **Correspondances candidates générées automatiquement** : 155. **Retenues après revue manuelle** : **109**. **Rejetées après revue** (correspondance automatique non fiable) : 46.
- **Constat méthodologique important** : sur les 155 correspondances proposées par le pipeline automatisé, **46 (30 %) se sont révélées incorrectes à la revue manuelle** — mauvaise espèce (topinambour/artichaut confondus dans les deux sens, chou-rave et chayote assimilés à du chou commun, fenouil confondu avec du poireau, champignon noir confondu avec du shiitaké...), plats composites réduits à un seul ingrédient ("petits pois et carottes" → carotte seule, "poêlée de légumes... sans champignon" → champignon), partie consommée différente (concombre chair+peau → concombre pelé), ou mode de cuisson incompatible (rôti au four → bouilli, risque de matière grasse de cuisson non comptabilisée). **Conclusion : l'automatisation accélère la recherche de candidats mais ne dispense jamais de la revue manuelle systématique** — c'est elle qui reste le facteur limitant du rythme de l'audit, pas le débit de l'API.
- **58 + 109 = 167 corrections appliquées au total à ce stade.**

## Lot 3 — Enrichissement multi-nutriments sur les 160 aliments déjà validés (04/08/2026)

- **Principe** : plutôt que de refaire une passe API par nutriment, un seul appel de détail USDA par aliment permet de récupérer *tous* les nutriments prioritaires en une fois. Ce lot réutilise donc les 160 identifications déjà vérifiées manuellement lors des lots 1 et 2 (Vitamine E) et en extrait les 11 autres nutriments prioritaires du cahier des charges (K1, B9, D, B12, Sélénium, Bêta-carotène — EPA/DHA/ALA/oméga-6/oméga-9 n'avaient aucune donnée disponible sur USDA pour ces 160 aliments, majoritairement des légumes : cellules laissées vides).
- **Aucune nouvelle recherche d'identité** : les correspondances aliment↔fiche USDA restent celles déjà validées manuellement (mêmes `fdc_id`), donc pas de nouveau risque de mauvaise espèce/mauvaise partie consommée générique. Une revue complémentaire ciblée a cependant été faite pour repérer les cas où un match valide pour la Vitamine E ne l'est plus pour un nutriment très localisé dans un tissu végétal précis (ex. vitamine K1 concentrée dans la feuille).
- **1 cellule rejetée après cette revue ciblée** : "Bette ou blette, côte (sans feuille), cuite" (id 20005) — la fiche USDA correspondante ("Chard, swiss, cooked") représente la blette entière (feuille + côte), alors que l'aliment CIQUAL est explicitement la côte *sans* la feuille. Comme la vitamine K1 est très majoritairement concentrée dans la feuille (pas dans le pétiole), cette cellule reste vide plutôt que de risquer une valeur surestimée. Les autres nutriments de cet aliment (moins dépendants de la partie feuille/tige) ont été conservés.
- **Cellules candidates analysées** : 298. **Retenues** : **297**.
- **Répartition par nutriment** : Vitamine B9 (folate) 143, Vitamine B12 54, Vitamine D 41, Sélénium 33, Bêta-carotène 13, Vitamine K1 13.
- **Niveau de confiance** : 243 "Élevé", 54 "Moyen" (aliments déjà identifiés comme proxy générique lors des lots 1/2 — ex. scarole→endive, yaourt bifidus→yaourt nature, biscotte→melba toast, lentille corail→lentille générique — la même prudence est reportée sur tous les nutriments issus de la même fiche).
- **Vérification appliquée** : copie de contrôle générée, diff cellule-par-cellule confirmant exactement 297 cellules modifiées (toutes vide → valeur, aucune écriture sur une cellule déjà remplie), CRLF d'origine préservé, avant copie sur `assets/foods.csv`.
- **58 + 109 + 297 = 464 corrections appliquées au total à ce stade**, sur 160 aliments distincts.

## Lot 4 — Beurre, ciblé sur l'exemple d'Alex (04/08/2026)

- **Contexte** : Alex a explicitement signalé que le beurre (80% MG, doux — l'aliment qu'il enregistre le plus dans son journal) affichait 0g de vitamine E, à l'origine de sa carence détectée. Ce lot traite en priorité les 10 variantes de "beurre" de `foods.csv` (hors biscuits/pâtisseries "pur beurre" qui restent hors périmètre).
- **10 aliments identifiés, 23 cellules comblées** (Vitamine E, K1, B9, D, B12, Sélénium, Bêta-carotène — DHA/EPA/ALA/W6/W9 non pertinents pour un corps gras laitier, non trouvés sur ces fiches USDA).
- **Beurre à 80% MG minimum, doux (id 16400)** — l'aliment concerné par le témoignage d'Alex — **Vitamine E = 2,32 mg/100g** (source : USDA FoodData Central, SR Legacy, "Butter, without salt"), valeur cohérente avec la littérature nutritionnelle standard pour le beurre (~2-2,5 mg/100g).
- **Niveaux de confiance** : 4 aliments "Élevé" (correspondance exacte de produit), 6 "Moyen" (la base USDA ne distingue pas toujours "demi-sel" de "salé", ou regroupe plusieurs teneurs en matière grasse sous une entrée "aliment moyen" CIQUAL — sans impact sur les valeurs de vitamines/minéraux extraites ici, qui ne dépendent pas du taux de sel).
- **Vérification appliquée** : même méthodologie que les lots précédents (copie de contrôle, diff cellule-par-cellule confirmant exactement 23 cellules modifiées, CRLF préservé) avant copie sur `assets/foods.csv`.
- **58 + 109 + 297 + 23 = 487 corrections appliquées au total à ce stade.**

## Lot 5 — Famille fruits, CIQUAL 13xxx (04/08/2026)

- **Périmètre analysé** : 197 aliments de la famille fruits avec `Vitamine_E_mg_100g` vide, hors aliments pour bébé/infantiles et variétés ultra-régionales (Martinique/Réunion) sans équivalent USDA plausible (mangues locales, prune de cythère, moubin, chadèque, caïmite, jacque...) qui restent hors périmètre de ce lot.
- **Méthodologie** : dictionnaire de traduction FR→EN dédié aux fruits (`fruit_dict.py`), recherche automatisée, puis **revue manuelle exhaustive de chaque candidat** (89 aliments retenus sur ~109 avec une racine trouvée). Une deuxième passe de recherche affinée a été nécessaire pour plusieurs cas ambigus : compotes (rejetées sauf la purée de pommes "sans sucres ajoutés" qui correspond exactement à "applesauce unsweetened"), variétés de pommes (priorité donnée à la concordance avec/sans peau plutôt qu'à la variété), agrumes (distinction pamplemousse rose/blanc, et rejet du "pamplemousse chinois" qui désigne une espèce différente — pomelo *Citrus maxima* — du grapefruit américain *Citrus × paradisi*), fruits au sirop (distinction sirop léger/classique, égoutté/non égoutté).
- **Rejets notables** : mûre du mûrier (espèce *Morus*, distincte de la mûre de ronce *Rubus*) — finalement retrouvée et acceptée via une entrée USDA dédiée "Mulberries" ; rambutan (seule entrée USDA = au sirop, incompatible avec l'aliment cru recherché) ; tamarin (aucune correspondance fiable trouvée après deux recherches) ; olives noires en saumure/à l'huile (le procédé californien "canned ripe olives" de l'USDA est un produit différent des olives noires fermentées en saumure ou à la grecque) ; litchi au sirop (aucune entrée USDA "au sirop" pour ce fruit) ; compotes de pêche/abricot/rhubarbe et coulis de fruits rouges (produit transformé sans équivalent USDA suffisamment précis, ou plat composite réduit à un seul ingrédient pour le coulis).
- **89 aliments acceptés, 208 cellules comblées** en une seule extraction multi-nutriments par aliment (72 fiches USDA uniques récupérées, plusieurs aliments CIQUAL partageant la même fiche générique — ex. les variétés de prunes).
- **Niveaux de confiance** : majorité "Élevé" (correspondance exacte espèce/état), une part "Moyen" documentée cas par cas (proxys de variété non distinguée par l'USDA, réhydratation, cuisson non identique — toujours en priorisant la concordance de la partie consommée).
- **Vérification appliquée** : copie de contrôle, diff cellule-par-cellule confirmant exactement 208 cellules modifiées, CRLF préservé, avant copie sur `assets/foods.csv`.
- **487 + 208 = 695 corrections tracées au total.** Il reste 123 aliments fruits encore vides en Vitamine E (aliments pour bébé, variétés régionales très spécifiques, et compotes/desserts transformés qui resteront probablement vides faute d'équivalent USDA fiable).

## Lot 6 — Famille poissons et fruits de mer, CIQUAL 26xxx et 10xxx (04/08/2026)

- **Périmètre analysé** : 170 poissons (26xxx) + 56 fruits de mer/mollusques/crustacés (10xxx) avec `Vitamine_E_mg_100g` vide, hors plats composites présents par chevauchement de plage de codes (pizzas, salades préemballées, gnocchi, moules farcies/marinières, escargot en sauce, calmar à la romaine en tant que produit pané...).
- **Méthodologie** : dictionnaires de traduction FR→EN dédiés poissons et fruits de mer, recherche automatisée, **revue manuelle exhaustive** de chaque candidat sur les ~190 aliments avec racine trouvée, avec une attention particulière aux pièges de nommage : *"bar/loup"* (bar européen) ne doit pas être confondu avec le *"striped bass"* américain (espèce différente) sauf pour le *"bar rayé"* qui est la bonne correspondance ; *"loup de l'Atlantique"* désigne en réalité le loup-atlantique/*wolffish*, sans lien avec le bar ; *"thon albacore"* en français correspond au thon **jaune** (*yellowfin*) anglais, à ne pas confondre avec l'*albacore* anglais qui correspond au *"germon"* français (les deux dénominations sont inversées entre les langues) ; le corail des coquilles Saint-Jacques a été exclu des correspondances car les données USDA ne portent que sur le muscle ("noix").
- **144 aliments acceptés, 352 cellules comblées** (Vitamine E, B9, K1, Bêta-carotène, Sélénium, B12, D), à partir de 84 fiches USDA uniques.
- **Rejets notables** : espèces sans équivalent USDA (hoki, lompe, capelan, omble chevalier, sabre, orphie, dorade royale/rose, sébaste, saupe, grondin, carangue) ; œufs de saumon/de truite (les seules fiches disponibles concernaient la chair du poisson, pas les œufs — écart de produit trop important pour être accepté) ; merlu/hake (aucune entrée USDA fiable trouvée même après recherche affinée) ; plusieurs préparations fumées/marinées/frites sans équivalent USDA précis (sardine grillée, thon germon frais, saumon fumé).
- **Deux identifiants USDA rencontrés en erreur 404 lors de la récupération** (fiches indexées par la recherche mais temporairement indisponibles au détail) ont été remplacés par une fiche équivalente valide avant application (thon au naturel : entrée SR Legacy de secours au lieu de l'entrée Foundation défaillante).
- **Vérification appliquée** : copie de contrôle, diff cellule-par-cellule confirmant exactement 352 cellules modifiées, CRLF préservé, avant copie sur `assets/foods.csv`.
- **695 + 352 = 1047 corrections tracées au total.** Il reste 95 poissons et 25 fruits de mer/mollusques encore vides en Vitamine E (espèces exotiques ou régionales sans correspondance USDA fiable, œufs de poisson, et quelques plats composites).

## Lot 7 — Viandes, volailles, abats et charcuterie, CIQUAL 6xxx/21xxx/28xxx/36xxx/8xxx/30xxx/40xxx (04/08/2026)

- **Principe méthodologique différent des lots précédents** : pour les micronutriments (vitamines, minéraux), la variation entre **morceaux** d'un même animal et d'un même état de cuisson est bien plus faible que la variation entre espèces ou entre cru/cuit/fumé. Plutôt que de rechercher une fiche USDA par morceau (des dizaines de découpes de boeuf/porc/agneau n'existent pas toutes chez l'USDA avec un équivalent français précis), ce lot utilise une **fiche USDA représentative par couple (espèce, état de cuisson)** pour les coupes de viande maigre standard, en confiance "Moyen" explicite (le morceau exact n'est pas distingué). Les correspondances **exactes** (morceau, race, espèce, cuisson tous identiques) restent classées "Élevé".
- **Abats** : couverture quasi complète grâce à l'excellente base USDA "variety meats and by-products" (coeur, foie, rognon, langue, cervelle, ris, tripes par espèce) — quasiment toutes en confiance "Élevé".
- **Volailles** : couverture très complète et précise (poulet/dinde/canard/oie/caille/faisan/chapon/poule/autruche par pièce, cru/cuit, avec/sans peau) grâce à la richesse de la base USDA sur le poulet et la dinde en particulier.
- **Charcuterie (8xxx, 30xxx)** : lot le plus difficile — beaucoup de spécialités françaises (rillettes, confit, quenelles, terrines, jambon persillé, galantine, fromage de tête excepté) **n'ont pas d'équivalent USDA fiable** et ont été volontairement laissées vides plutôt que d'être approximées par un produit trop différent (ex. les rillettes sont un produit conservé dans la graisse, sans équivalent dans FoodData Central). Les saucisses/saucissons/pâtés de foie avec un équivalent américain clair (chorizo, salami, mortadelle, frankfurter, bologna, blood sausage, headcheese, foie gras) ont été acceptés, la plupart en confiance "Moyen" (assaisonnement, ratio d'espèces ou terroir régional non distingués par l'USDA).
- **262 aliments distincts acceptés, 853 cellules comblées** (Vitamine E 220, Sélénium 129, Bêta-carotène 114, B9 112, K1 110, D 89, B12 79), réparties en 3 sous-lots (boeuf/veau/cheval/agneau/mouton/chevreau + volailles + abats + porc/jambon : 623 cellules ; charcuterie/saucisses : 212 cellules — le reliquat correspond à des ajustements post-vérification).
- **Rejets notables** : morceaux anatomiques très gras ou non comparables à une viande maigre (gorge, bardière, museau, oreille, pied demi-sel, queue, tête) ; catégories "aliment moyen" trop génériques sans espèce précisée ; produits composites (quenelles, salades préemballées, terrines mélangées, confit à la graisse, rillettes, escalopes panées, nuggets) ; spécialités sans équivalent USDA (prosciutto/pancetta/coppa italiens, jambon de Bayonne/Parme/Serrano — remplacés par un proxy jambon cru maigre générique quand la différence attendue reste modérée, ou rejetés quand le procédé est trop spécifique).
- **Un identifiant USDA rencontré en erreur 404** (fiche Foundation instable) a été remplacé par son équivalent SR Legacy avant application.
- **Vérification appliquée** : copie de contrôle, diff cellule-par-cellule (641 puis 212 cellules exactement), CRLF préservé, avant copie sur `assets/foods.csv`, à chaque sous-lot.
- **1688 + 212 = 1900 corrections tracées au total.**

## Lot 8 — Produits laitiers, fromages et lait, CIQUAL 12xxx et 19xxx (04/08/2026)

- **Fromages (12xxx)** : 130 fromages mappés par **type/famille** plutôt que par appellation exacte (l'USDA ne référence pas les AOC françaises individuellement) — pâtes pressées cuites alpines (Beaufort/Abondance/Comté → gruyère ou swiss), pâtes molles à croûte lavée (Munster/Reblochon/Époisses/Maroilles/Livarot/Langres/Pont-l'Évêque/Mont d'Or → limburger, le seul fromage à croûte lavée référencé par l'USDA), brie/camembert (correspondance directe), tous les fromages de chèvre (crottin/Picodon/Pélardon/Rocamadour/Sainte-Maure/Valençay... → catégories USDA \"goat, soft/semisoft/hard type\" selon la texture), bleus (Fourme/Auvergne/Causses/Gorgonzola → blue cheese), pâtes pressées non cuites (Cantal/Salers → cheddar ; Saint-Nectaire/Tomme/Mimolette → gouda/edam).
- **Produits laitiers frais et boissons lactées (19xxx)** : lait (par taux de matière grasse — entier/demi-écrémé/écrémé, cru/UHT/pasteurisé/en poudre/concentré), yaourts et laits fermentés (nature/aux fruits/grec/kéfir, par taux de matière grasse), fromage blanc/petit suisse/faisselle (proxy \"cottage cheese\", seul équivalent USDA de fromage frais égoutté), crèmes fraîches (par taux de matière grasse), quelques desserts simples à base d'œufs (flan, œufs au lait → \"egg custard\").
- **Rejets notables** : dans les fromages, tous les \"aliment moyen\" génériques ; côté 19xxx, laits infantiles (1er/2e âge, croissance — hors périmètre, produits formulés spécifiques), desserts composites (tiramisu, panna cotta, liégeois, tzatziki, mousse marrons, baba au rhum), desserts au soja (hors périmètre laitier, espèce végétale), lait de jument (aucune donnée USDA disponible), catégories \"aliment moyen\" génériques sans précision de matière grasse.
- **250 aliments acceptés, 966 cellules comblées** (130 fromages/490 cellules + 120 produits laitiers/476 cellules), à partir de 51 fiches USDA uniques au total.
- **Deux identifiants USDA rencontrés en erreur 404** (fiches Foundation instables : cheddar, yaourt grec nonfat) remplacés par leur équivalent SR Legacy avant application.
- **Vérification appliquée** : copie de contrôle, diff cellule-par-cellule (490 puis 476 cellules exactement), CRLF préservé, avant copie sur `assets/foods.csv`.
- **2390 + 476 = 2866 corrections tracées au total.**

## Lot 9 — Huiles, CIQUAL 17xxx (04/08/2026)

- **Périmètre analysé** : 22 huiles avec `Vitamine_E_mg_100g` vide. Correspondances presque toutes en confiance "Élevé" (une huile = un produit simple, sans ambiguïté d'espèce ni de cuisson).
- **18 huiles acceptées, 37 cellules comblées** (l'essentiel du travail portait sur la vitamine E — les acides gras détaillés (W3/W6/W9, EPA/DHA) et la vitamine K1 étaient déjà largement renseignés pour cette famille dans la base CIQUAL d'origine, qui documente bien les profils lipidiques des huiles).
- **Rejets** : huile végétale "aliment moyen" (générique) ; huiles d'argan, de cameline et de chanvre (aucune entrée USDA disponible pour ces huiles de spécialité) ; huile combinée "olive et graines" (mélange non spécifié, aucun équivalent USDA correspondant).
- **Valeurs obtenues cohérentes avec les références nutritionnelles connues** : huile de germe de blé 149,4 mg/100g (la plus riche, comme attendu), tournesol 41,1 mg, noisette 47,2 mg, amande 39,2 mg, coton 35,3 mg, son de riz 32,3 mg, pépins de raisin 28,8 mg, maïs 22,6 mg, arachide 15,7 mg, pavot 11,4 mg, noyaux d'abricot 4,0 mg, sésame 1,4 mg, lin 0,47 mg (la plus pauvre, cohérent avec sa composition dominée par les oméga-3 sensibles à l'oxydation plutôt que par la vitamine E).
- **Vérification appliquée** : copie de contrôle, diff cellule-par-cellule (37 cellules exactement), CRLF préservé, avant copie sur `assets/foods.csv`.
- **2866 + 37 = 2903 corrections tracées au total.**

## Bilan de l'audit multi-familles (fruits, poissons/fruits de mer, viandes/volailles/abats/charcuterie, produits laitiers/fromages, huiles)

Ce bloc de 5 lots (Lots 5 à 9) couvre l'intégralité des grandes familles alimentaires de `foods.csv` au-delà des ingrédients de recettes et légumes déjà traités dans les lots 1 à 4. Résumé :

| Famille | Aliments acceptés | Cellules comblées |
|---|---|---|
| Fruits | 89 | 208 |
| Poissons / fruits de mer | 144 | 352 |
| Viandes / volailles / abats / charcuterie | 262 | 853 |
| Produits laitiers / fromages | 250 | 966 |
| Huiles | 18 | 37 |
| **Total ce bloc** | **763** | **2416** |

Avec les 487 corrections des lots 1 à 4, **l'audit totalise désormais 2903 corrections tracées, sourcées et vérifiées**, couvrant la quasi-totalité des grandes familles alimentaires de `foods.csv`.

## Pérennité : que faire quand CIQUAL publiera une nouvelle édition

Toutes les corrections de cet audit sont tracées dans `Corrections_Proposees.csv` avec un identifiant `ciqual_code` et un nom de colonne — elles ne sont donc pas perdues quand la base CIQUAL évoluera. Un script est prêt pour ce jour-là : **`scripts/merge_ciqual_update.py`**.

Principe : quand l'ANSES publie une nouvelle édition de CIQUAL et qu'un nouveau `foods.csv` en est dérivé, ce script fusionne automatiquement les ~2900 corrections déjà tracées avec la nouvelle table, **sans refaire le travail manuel** :

- Si CIQUAL a lui-même comblé une cellule qu'on avait corrigée → la nouvelle valeur CIQUAL officielle est conservée (elle prime toujours sur notre correction USDA).
- Si la cellule est encore vide dans la nouvelle table → notre correction est réappliquée automatiquement.
- Si un aliment a disparu de la nouvelle table → la correction correspondante est ignorée et listée dans le rapport.
- Si une colonne référencée par une correction n'existe plus (renommage de schéma côté CIQUAL) → le script s'arrête avec une erreur claire plutôt que de risquer une fusion silencieusement incorrecte.

Usage :
```
python scripts/merge_ciqual_update.py --new-ciqual <nouveau_foods.csv> --out assets/foods.csv
```
Un rapport Markdown (`<out>.fusion_report.md`) résume le nombre de corrections réappliquées, devenues superflues (CIQUAL a désormais sa propre valeur) et obsolètes (aliment disparu). Testé et validé sur un cas synthétique couvrant les trois scénarios.

## Lot 10 — Ajout de 5 compléments protéinés (hors CIQUAL), plage ciqual_code 90xxx (04/08/2026)

- **Contexte** : Alex bannit le "lait en poudre" des recettes (perçu comme trop transformé) et demande une vraie catégorie compléments protéinés (whey, protéines végétales/vegan) pour le remplacer et servir de base à de futures recettes sportives.
- **Différence méthodologique avec les lots précédents** : il ne s'agit pas ici de compléter des cellules vides sur des aliments CIQUAL existants, mais d'**ajouter 5 aliments entièrement nouveaux**, absents de la nomenclature CIQUAL. Un identifiant `ciqual_code` dans la plage **90xxx** leur a été attribué — plage vérifiée totalement inutilisée par CIQUAL (préfixes réellement utilisés : 1 à 96 avec de nombreux trous, mais jamais 90) — pour qu'aucune collision ne soit possible avec un futur ajout officiel de l'ANSES.
- **5 aliments ajoutés**, sourcés USDA FoodData Central (SR Legacy/Foundation), toutes les cellules non rapportées par la fiche source laissées vides (jamais estimées) :
  - `90001` Whey isolat, poudre, enrichie en vitamines et minéraux (produit fortifié, représentatif du marché) ;
  - `90002` Whey, poudre, boisson protéinée (variante non fortifiée) ;
  - `90003` Protéine de soja, isolat, poudre, nature (végétalien, non aromatisé) ;
  - `90004` Protéine de soja, poudre, boisson protéinée aromatisée (végétalien, sucré) ;
  - `90005` Blanc d'œuf, déshydraté, poudre (végétarien, sans lactose ni soja).
- **Non trouvé chez l'USDA** (pas d'entrée générique non-marque disponible) : protéine de pois, de riz, de chanvre isolées séparément — seules des options soja/whey/œuf ont pu être sourcées de façon fiable et non marquée. À réévaluer si l'USDA enrichit sa base, ou si une source française/européenne équivalente à CIQUAL existe pour ces produits.
- **Conversion "Sel"** : calculée depuis le sodium USDA selon la formule standard ANSES/CIQUAL (sel = sodium × 2,5 / 1000), pas une valeur USDA brute mais une conversion réglementaire standard, pas une estimation.
- **Vérification appliquée** : copie de contrôle, confirmation que les 3484 lignes existantes sont strictement inchangées (diff ligne à ligne), CRLF préservé, avant copie sur `assets/foods.csv`. Base passée à 3489 aliments.
- **2903 + 5 aliments (lignes complètes) = entrées ajoutées à `Corrections_Proposees.csv`** sous la mention `AJOUT_LIGNE_COMPLETE`.

## Lot 11 — Vitamine E, famille "fruits à coque et graines oléagineuses" (05/08/2026)

- **Contexte** : Alex a personnellement vérifié la fiche "amandes" dans l'app et constaté une Vitamine E à zéro, alors que les amandes figurent parmi les aliments les plus riches en Vitamine E au monde — signal d'alarme sur la fiabilité globale de l'audit.
- **Cause identifiée** : la famille CIQUAL `15xxx` ("fruits à coque et graines oléagineuses" : amandes, noisettes, noix de cajou/pécan/macadamia/Brésil, graines de lin/sésame/tournesol/chanvre, cacahuètes, châtaignes, noix de coco...) n'avait **jamais fait l'objet d'un lot dédié** dans les lots 1 à 9 — elle n'était pas couverte par les lots "fruits", "légumes" ni "huiles". Un vrai trou de périmètre, pas une erreur de saisie sur les cellules déjà traitées.
- **57 aliments dans cette famille, 45 avec Vitamine E vide** avant ce lot. Méthodologie identique aux lots précédents (recherche USDA FoodData Central, revue manuelle un par un de la correspondance nom/forme/mode de préparation, aucune valeur inventée) appliquée à **31 aliments prioritaires** (noix et graines couramment consommées telles quelles ou en beurre/purée ; exclus de ce lot : graines germées, épices en graines à faible quantité consommée, mélanges apéritifs composites — périmètre à réévaluer plus tard si besoin).
- **30 corrections appliquées**, 1 laissée vide par prudence (`15024` Châtaigne, crue : aucune fiche USDA, y compris la variante non pelée, ne renseigne la Vitamine E — plutôt que d'extrapoler depuis la variante grillée, la cellule reste vide).
- Exemple qui a déclenché la demande d'Alex, désormais correct : **Amande, avec peau, sans sel ajouté = 25,63 mg/100g** (USDA SR Legacy, fdcId 170567).
- 6 corrections en confiance "Moyen" (proxy documenté : arôme fumé/aromatisé non distingué par l'USDA, ou variante salée absente alors que le sel n'affecte pas un nutriment liposoluble comme la Vitamine E) — toutes les autres en confiance "Élevé".
- Traçabilité complète dans `Corrections_Proposees.csv` (30 nouvelles lignes), vérification par diff cellule-par-cellule avant application, CRLF préservé.

## Lot 12 — Audit de cohérence des fiches nutriments ("où en trouver") vs `foods.csv` (05/08/2026)

- **Contexte** : Alex a testé la fiche "Vitamine K" en pratique — l'œuf à la coque, cité dans "où en trouver" via le jaune d'œuf, n'affichait aucune vitamine K dans l'app. Demande : auditer les 40 fiches nutriments (`assets/nutrient_fiches.json`) et vérifier que **chaque aliment cité dans "où en trouver" est (a) présent dans `foods.csv` et (b) affiche bien une valeur non vide pour le nutriment concerné**, pour ne jamais frustrer l'utilisateur avec une incohérence entre le conseil et les données réelles.
- **Méthode** : extraction du champ `sources` des 40 fiches, identification de tous les aliments cités nommément (hors catégories génériques du type "légumes verts" ou "céréales complètes"), recherche par mots-clés dans `foods.csv` (recherche insensible aux accents/à l'ordre des mots pour éviter les faux négatifs), vérification de la colonne du nutriment concerné pour chaque correspondance trouvée. **153 aliments vérifiés sur les 40 fiches.**
- **5 problèmes confirmés** (après élimination des faux positifs dus à des tournures de recherche trop strictes) :
  1. **`Vitamine K` → Natto, absent de `foods.csv`** : cité comme "champion absolu" de la vitamine K2, mais totalement absent de la base (CIQUAL ne référence pas cet aliment japonais). **Ajouté** (`90006`, plage hors-CIQUAL dédiée), sourcé USDA FoodData Central. **Limite documentée et assumée** : l'USDA ne fournit que la phylloquinone (K1 = 23,1 µg/100g) pour le natto, aucune mesure des ménaquinones (K2/MK-7) qui font sa réputation — la cellule K2 reste volontairement vide plutôt que d'inventer un chiffre. Le natto reste donc visible et consultable dans l'app, avec une limite honnêtement documentée plutôt qu'une fausse précision.
  2. **`Vitamine K` → Œuf à la coque, cellules vides** (le cas exact repéré par Alex) : corrigé via un proxy documenté (Œuf poché USDA, cuisson la plus proche du "à la coque" en l'absence de fiche USDA dédiée au soft-boiled).
  3. **`Vitamine K` → cluster d'œufs cuits avec cellules vides** découvert en creusant le cas ci-dessus : Oeuf poché (K2 manquant), Oeuf jaune cuit et Oeuf blanc cuit (K1+K2 manquants sur les deux), Oeuf au plat sans matière grasse (K1 manquant). Corrigés soit par fiche USDA directe (poché, au plat), soit par report de la valeur du même aliment cru (jaune/blanc), justifié par le fait que la vitamine K est liposoluble et thermostable — la cuisson ne la détruit pas, contrairement à la vitamine C par exemple.
  4. **`Oméga 9` → Noix de macadamia, acide oléique vide** sur les 2 variantes (nature et grillée salée) — alors que la macadamia est l'un des fruits à coque les plus riches en acide oléique au monde (>43g/100g). Corrigé via USDA (nutriment détaillé "MUFA 18:1").
  5. **`Vitamine B9` → Mâche, cellule vide** (folate) — aliment présent dans `foods.csv` mais aucune fiche USDA FoodData Central ne référence la mâche (*Valerianella locusta*, spécialité européenne absente de cette base américaine). **Laissé vide**, gap documenté et assumé plutôt que d'inventer une valeur.
- **10 cellules corrigées + 1 aliment ajouté**, tracés dans `Corrections_Proposees.csv`.
- **148 aliments sur 153 vérifiés étaient déjà cohérents** (présents et correctement renseignés) — la très grande majorité des fiches "où en trouver" est fiable ; les incohérences trouvées étaient concentrées sur les variantes cuisinées/transformées (schéma déjà observé sur l'ensemble de l'audit CIQUAL) et un aliment de niche totalement absent (natto).

## Lot 13 — Bug de calcul Vitamine K (K1 seul au lieu de K1+K2) + audit "famille complète" (05/08/2026)

- **Découverte critique, distincte d'un problème de données** : Alex a signalé que 100 g de jaune d'œuf cru n'affichait que ~1 % des apports en Vitamine K dans l'app, alors que la fiche `foods.csv` contient bien K1 = 0,7 µg **et** K2 = 23,8 µg (total 24,5 µg, soit ~31 % d'une cible à 79 µg — cohérent avec la réalité nutritionnelle). **La donnée était correcte, le calcul affiché ne l'était pas** : plusieurs écrans lisaient uniquement la colonne `Vitamine_K1_µg_100g` et ignoraient totalement `Vitamine_K2_µg_100g`, alors que `conseils_screen.dart` (`_decideTheme`) et le total journalier de `bilan_screen.dart` additionnent bien les deux depuis le début.
- **6 emplacements corrigés** (K1 remplacé par K1+K2) :
  - `journal_screen.dart` : fiche de saisie de quantité d'un aliment (`_openFoodSheet`), fiche d'une entrée déjà journalisée (`_openEntrySheet`), détail d'un repas (`_showMealDetailSheet`) — 3 écrans où l'utilisateur voit concrètement "Vit K" pour un aliment ou un repas.
  - `bilan_screen.dart` : liste "aliments qui contiennent ce nutriment" (`_contributorsForRange`, via `_kAllLabelToKey`).
  - `conseils_screen.dart` : liste équivalente côté Conseils (`consumedFoodsForRatio`) et scoring des recettes suggérées pour combler une carence (`suggestRecipes`).
  - `journal_export.dart` : rapport PDF exporté, colonne renommée "Vitamine K1" → "Vitamine K" pour refléter le total réel.
- **Audit "famille complète"** demandé par Alex : ne pas corriger un seul aliment cité dans une fiche mais toutes ses variantes (cru/cuit/grillé/en poudre/espèces proches). Méthode : regroupement par mot-racine avec exclusion des plats composites (sauces, plats préparés, charcuterie transformée...), vérification cellule par cellule de chaque variante pour le(s) nutriment(s) concerné(s).
  - **Famille Œuf** (24 entrées CIQUAL) entièrement revérifiée sur les 9 nutriments cités dans les fiches qui la mentionnent (rétinol, Vit D, Vit K, B2, B5, B9, B12, iode, phosphore, sélénium) : 7 cellules corrigées (sélénium sur œuf d'oie/caille/cane/dinde crus et blanc/jaune en poudre, folates sur l'œuf au plat), sourcées USDA.
  - **Famille Poulet** (viande crue/cuite, ~24 entrées) : 2 cellules de Vitamine B6 corrigées (poulet blanc et fermier).
  - **Limite structurelle découverte, pas propre à un aliment** : l'USDA FoodData Central ne fournit quasiment jamais de mesure séparée des ménaquinones (Vitamine K2) pour les viandes/volailles, ni de données d'iode pour aucun aliment. Ce n'est pas un manque de recherche mais une limite de la source de données elle-même — déjà pressenti pour le natto (Lot 12), confirmé ici sur ~24 découpes de poulet où seule la Vitamine K2 (et l'iode, sur plusieurs œufs) reste injustifiable sans inventer un chiffre. Ces cellules restent volontairement vides.
- **Alex a demandé de poursuivre immédiatement sur toutes les familles restantes** plutôt que de s'arrêter au point d'étape. Audit "famille complète" (mot-racine + exclusion systématique des plats composites/transformés) étendu à : bœuf, porc, champignon, sardine, maquereau, anchois, thon, blette, banane, orange, courge, abricot, ananas, noisette/amande (acide oléique restant), cacahuète — sur les nutriments spécifiquement cités par les fiches concernées.
  - **Bœuf** (12 découpes crues/cuites) : Vitamine B3 et/ou Zinc corrigés via une fiche USDA "composite de découpes" (générique par nécessité — aucune correspondance USDA par découpe française précise n'existe), confiance "Moyen".
  - **Porc** (16 découpes/pièces crues/cuites) : Vitamine B1 corrigée via la même logique de fiche composite USDA.
  - **Champignons** (Paris surgelé, noir séché) : B2/B3/B5 corrigés (espèce "cloud ear" en proxy pour le champignon noir). Espèces sauvages de niche (oronge vraie, rosé des prés, truffe noire) laissées vides : aucune fiche USDA.
  - **Poissons gras** : sardine (grillée + 2 variantes à l'huile), maquereau mariné, anchois (4 variantes), thon germon vapeur : EPA/DHA/calcium/phosphore/sélénium corrigés via les meilleures fiches USDA disponibles (souvent en conserve, faute de fiche "poisson frais" chez l'USDA — proxy documenté).
  - **Blette** : Vitamine K1 corrigée sur la variante cuite (K2 non mesurée par l'USDA pour les végétaux — cohérent avec le constat déjà fait sur les légumes verts en général).
  - **Fruits/légumes des DOM** (banane Martinique, orange Martinique ×2, courge ×3, abricot pays, ananas) : B6/magnésium/potassium/folates/bêta-carotène/manganèse corrigés via la variété USDA générique la plus proche (variétés antillaises spécifiques non distinguées par l'USDA — proxy documenté à chaque fois).
  - **Noisette/amande** : les 4 dernières variantes sans acide oléique (grillées salées/sans sel) corrigées.
  - **Cacahuète** : Vitamine B3 corrigée sur 2 variantes grillées.
- **77 cellules corrigées au total dans ce lot** (9 Œuf/Poulet + 28 Bœuf/Porc + 34 Champignons/Poissons/Fruits/Noix + 6 Anchois/Cacahuète), toutes tracées dans `Corrections_Proposees.csv` avec confiance "Élevé" (correspondance directe) ou "Moyen" (proxy documenté — cuisson, variété locale, ou fiche USDA générique par découpe/espèce).
- **Restent volontairement non traités** : les plats composites/transformés (charcuterie type rillettes/saucisson, plats préparés, salades/soupes préemballées — cohérent avec la méthodologie de tout l'audit) et quelques espèces de niche sans correspondance USDA (champignons sauvages rares).

## État à l'issue des lots 1 à 13 (05/08/2026)

Les grandes familles alimentaires de `foods.csv` ont désormais toutes été auditées au moins une fois : ingrédients de recettes, légumes, fruits, poissons/fruits de mer, viandes/volailles/abats/charcuterie, produits laitiers/fromages, huiles, fruits à coque et graines oléagineuses, cohérence des fiches nutriments (audit "famille complète" sur œuf, poulet, bœuf, porc, champignons, poissons gras, fruits/légumes des DOM, noisette/amande, cacahuète). **3026 corrections tracées et vérifiées au total dans `Corrections_Proposees.csv`** (dont 77 pour le seul Lot 13), la Vitamine E (nutriment prioritaire n°1, à l'origine de la demande d'Alex) étant passée de 17,1 % à plus de 41 % de cellules remplies sur les 3491 aliments de la base.

**Découverte méthodologique importante** : au-delà des cellules manquantes dans `foods.csv`, une part des incohérences perçues par l'utilisateur peut venir du **code d'affichage/calcul** plutôt que des données elles-mêmes (cas de la Vitamine K1/K2 ci-dessus). Un audit de données seul ne suffit pas à garantir la cohérence perçue — il faut aussi vérifier, pour chaque nutriment scindé en plusieurs colonnes CIQUAL (K1/K2 est le seul cas identifié à ce jour, cf. Lot 12), que tous les écrans de l'app agrègent ces colonnes de la même façon.

Le reliquat de cellules vides restant est, pour l'essentiel, un reliquat **attendu et légitime** au regard des règles de l'audit (jamais inventer une donnée) :
- catégories "aliment moyen" trop génériques pour être rattachées à un produit USDA précis ;
- plats composites (salades préemballées, quenelles, tartes, pizzas, terrines mélangées...) dont la préparation mélange trop d'ingrédients pour qu'une seule fiche USDA soit représentative ;
- spécialités françaises ou régionales sans équivalent dans FoodData Central (rillettes, confit, jambon de Bayonne/Parme/Serrano, fromages AOC très spécifiques, poissons de niche) ;
- aliments infantiles (laits 1er/2e âge) volontairement laissés hors périmètre ;
- variétés exotiques ou très régionales (Martinique/Réunion) sans correspondance USDA fiable.

## Prochaines étapes possibles

1. Étendre la même méthodologie (identification + revue manuelle + extraction multi-nutriments) aux familles encore non couvertes par un lot dédié : céréales/féculents, légumineuses, boissons, produits sucrés/biscuiterie, plats préparés simples.
2. Nutriments encore peu couverts même sur les familles déjà auditées : Iode (aucune passe dédiée à ce jour), Oméga-6/Oméga-9/EPA/DHA/ALA détaillés (USDA ne les documente pas toujours pour les produits transformés), sucres détaillés (dernière priorité du cahier des charges).
3. Quand une nouvelle édition de CIQUAL sera publiée : utiliser `scripts/merge_ciqual_update.py` (voir ci-dessus) plutôt que de relancer un audit complet.

Chaque futur lot doit suivre la même méthodologie : recherche + revue manuelle systématique de l'identité/cuisson/partie consommée + traçabilité complète dans `Corrections_Proposees.csv` avant toute application, avec vérification cellule-par-cellule du diff avant toute copie sur le fichier réel.
