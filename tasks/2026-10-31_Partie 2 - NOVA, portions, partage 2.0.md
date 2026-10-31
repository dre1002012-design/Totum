# 31/10/2026 — partie 2 : NOVA, portions, noms USDA, partage de repas 2.0

Suite de `2026-10-31_Audit global - bases, recettes, liste par défaut, partage.md`.

## 1. Score NOVA (degré de transformation) — refait aliment par aliment

**Problème signalé** : flocons d'avoine en NOVA 4 (« ultra-transformé »). Cause : le score n'est pas une donnée ANSES, il était *estimé* par famille (« céréales de petit-déjeuner » → 4 pour tout le monde). Mêmes erreurs systématiques ailleurs : café, thé, tisane et jus purs en NOVA 4 ; tofu nature en 4 ; yaourt nature et fromage blanc nature en 3 ; sirop d'érable en 4 ; gin, vodka et whisky en 3 ; base de pizza industrielle en 1.

**Correction** : nouveau classificateur `scripts/nova_classify.py`. Il applique des règles par aliment (nom + famille), d'après la définition et les exemples officiels de Monteiro et al. (*Public Health Nutrition*, 2019) et le guide FAO (2019). Il couvre les 3 490 aliments CIQUAL et les 7 839 USDA ; seule la colonne NOVA est réécrite.

| | NOVA 1 | NOVA 2 | NOVA 3 | NOVA 4 |
|---|---|---|---|---|
| CIQUAL après | 1 448 | 85 | 553 | 1 404 |

Exemples remis d'aplomb :
- **NOVA 1** : flocons d'avoine, café, thé, tisane, jus pur, tofu, tempeh, yaourt et fromage blanc nature, son d'avoine.
- **NOVA 2** : sirops d'érable et d'agave, crèmes fraîches, amidons, sel.
- **NOVA 3** : légumes en conserve, oléagineux salés, jambon cuit ou cru, fruits au sirop, plats et pâtisseries « faits maison » ou « artisanaux ».
- **NOVA 4** : alcools distillés, beurres allégés, chantilly en bombe, fromages fondus, saucisses, pains de mie, produits végétaux reconstitués.

Garde-fou : `test/services/nova_estimate_test.dart` vérifie 42 aliments repères. ⚠️ C'est toujours une **estimation** (l'app l'affiche comme telle) ; seul le NOVA d'un produit scanné (Open Food Facts) est officiel.

## 2. Portions — toutes vérifiées, et étendues à 97 % de la base

- **Vérifiées** :
  - 1 c. à soupe d'huile ≈ 10 g (repère pratique officiel suisse : 2 c. à soupe = 20 g/jour ; 15 ml pèsent 13,8 g en réalité) ;
  - fromage 30 g, pot de yaourt 125 g (PNNS) ;
  - fruits pesés sans peau ni noyau ; œuf ≈ 50 g sans coquille.
- **Étendues** : avant, seuls les 141 essentiels et quelques familles avaient une portion. Désormais **3 381 aliments CIQUAL sur 3 490**, avec des repères :
  - par aliment : figue, croissant, chouquette, saucisse, tranche de jambon cru, boîte de sardines, part de pizza, sandwich, boule de glace… ;
  - par famille : assiette de plat composé 300 g, bol de soupe 250 g, portion de fruit 100 g (PNNS) ;
  - pour les boissons alcoolisées, le **verre standard** de Santé publique France (10 cl de vin, 25 cl de bière, 3 cl d'alcool fort).
- Restent sans portion, volontairement : aides culinaires, laits et petits pots infantiles, pâtes à tarte (aucune mesure ménagère stable).
- Relecture humaine possible : `build/portions_report.tsv` (une ligne par aliment, régénéré par `test/services/food_portions_test.dart`).

## 3. Base USDA : noms et emojis

- **1 564 intitulés français corrigés** : « Poulet, poulets de chair ou friteuses, cuisse » (*fryers* traduit par l'appareil !) devient « Poulet, cuisse » ; « maigre séparable seulement » devient « maigre seul » ; « au choix » et « sélectionné » (grades USDA) deviennent « qualité Choice » et « qualité Select » ; « paré à 0" de gras » devient « sans gras ».
- **352 emojis réalignés** : 354 légumes avaient 🥦 par défaut (14 brocolis seulement). Désormais 🥬 feuilles, 🫛 haricots verts, 🫑 poivrons, 🍠 tubercules, etc. Côté fruits : 🍊 agrumes, 🟤 prunes, 🫒 olives.
- Script : `scripts/usda_names_emojis_fix.py` (idempotent).

## 4. Partage d'un repas 2.0

Ce qui ne te satisfaisait pas, et ce qui change :

| Avant | Maintenant |
|---|---|
| Symboles chimiques (Mg, Zn, Se, K…) | **Noms complets** partout (« Magnésium », « Oméga-3 marins (EPA+DHA) », « Folates (vitamine B9) »), testé |
| Nutriments choisis par % brut (686 % de B12 en vedette) | **Pertinence santé** : priorité du nutriment (vitamine D, oméga-3, magnésium, iode… souvent insuffisants en France) × couverture à rendement décroissant ; au plus 2 vitamines B |
| VNR d'étiquetage (vitamine D 5 µg) | **Apports conseillés ANSES** pour un adulte (vitamine D 15 µg…), relevés sur anses.fr |
| Source n°1 seulement | **D'où vient chaque nutriment** : barre de proportions par aliment |
| — | **« Ce que ce repas apporte à ton corps »** : 8 fonctions (cerveau & moral, énergie, immunité, os & muscles, cœur, hormones & thyroïde, protection des cellules, peau & vue), construites à partir des allégations de santé autorisées dans l'UE |
| — | Tableaux complets **vitamines** et **minéraux** |
| — | **Équivalences ludiques** : « autant de potassium que 7 bananes 🍌 », « ≈ 9 œufs » de protéines |
| — | **Atout de chaque aliment** : « Sardine — oméga-3 marins · 100 % du total » |

**Ton petit-déjeuner** (œufs, graines de lin, huile d'olive, banane) fait maintenant ressortir Oméga-3 végétal 217 %, Iode 38 % et Fer 39 %, au lieu de la B12 des œufs. Ce cas est figé dans un test.

Carrousel en **9 visuels** (6 à 12 recommandés en 2026) :
1. Couverture : accroche et 3 stars en pastilles.
2. Énergie et macros (dont sucres et graisses saturées).
3. Ton corps.
4. Les stars et d'où elles viennent.
5. Vitamines.
6. Minéraux.
7. Bonnes graisses (oméga-6/oméga-3, saturées).
8. Dans l'assiette (atouts).
9. L'essentiel, à compléter dans la journée, appel à l'action.

Story, post, paysage et bannière reprennent les mêmes données ; les 4 angles (Équilibre / Sport / Satiété / Longévité) sont conservés.

## 5. Tests

Nouveaux : `nova_estimate_test`, `food_portions_test`. Étendus : `meal_share_screenshot_test` (pertinence, systèmes du corps, petit-déjeuner réel, aucun symbole chimique), `staple_foods_test`. Captures : `build/share/` (régénérables).

## 6. À valider ou tester par toi

1. Le carrousel sur ton téléphone, avec une vraie photo : lisibilité des 9 visuels.
2. Le choix des **apports ANSES** à la place des VNR européennes dans les visuels publics : plus exigeant donc plus honnête (vitamine D 3 fois plus exigeante), mais les % affichés baissent.
3. Les portions « ≈ » dans le « + » sur quelques aliments du quotidien.
