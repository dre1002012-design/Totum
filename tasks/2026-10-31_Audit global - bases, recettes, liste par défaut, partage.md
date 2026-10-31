# Audit global du 31/10/2026 — bases d'aliments, recettes, « + », partage, calculs

Vérifications finales : `flutter analyze` 0 problème · tests : voir §11 · captures régénérables (`build/screens/`, `build/share/`).

---

## 1. Ce qui était vraiment faux (et corrigé)

| # | Problème | Impact réel | Correction |
|---|---|---|---|
| 1 | **Valeurs des 168 recettes calculées sur une ancienne version de `foods.csv`** | Folates (B9) moitié trop bas, sélénium ×2, vitamine C/zinc/iode surestimés, vitamine E absente de 162 recettes, B9 de 42 | Les 192 recettes recalculées depuis la base actuelle, avec **tous** les nutriments (E, B9, K2, sucres détaillés, eau…) |
| 2 | Recettes déjà importées chez les utilisateurs = **copies figées** | Corriger le fichier ne suffisait pas | Recalcul automatique au chargement de toute recette dont tous les ingrédients sont retrouvés ; réenregistrement en arrière-plan des seules recettes modifiées |
| 3 | **Glucides USDA fibres comprises** (convention américaine) dans la même colonne que les glucides CIQUAL (fibres exclues) | 3 877 aliments USDA surestimés : avocat 8,5 g → 1,8 g ; haricots noirs 23,7 → 15,0 | Conversion dans la base embarquée, le script de construction, la recherche USDA en ligne et les produits de marque |
| 4 | Filtre recettes **cétogène** : fibres soustraites une 2ᵉ fois | Laissait passer des plats trop riches en glucides | Glucides CIQUAL utilisés tels quels (ce sont déjà des glucides « nets ») |
| 5 | Étiquette **Hyperprotéiné** posée à la main de façon erratique | En-cas à 7 g et 10 g de protéines affichés « hyperprotéinés », 36 plats à 30-50 g oubliés | Règle unique du code : ≥ 30 g par repas, ≥ 15 g par collation → 75 recettes |
| 6 | 3 recettes **végétaliennes contenant du miel** | Étiquette fausse pour un public végan | Étiquette retirée (restent végétariennes) |
| 7 | **Export de période** (diététicien/naturopathe) : 5 niveaux d'activité au lieu de 6, objectifs « −20 % » abandonnés en août | Un profil « Très actif » apparaissait en « Très intense (2×/jour) » | Libellés exacts du profil ; recherche d'aliment indexée ; aliments USDA inclus dans les micronutriments |
| 8 | **Vitamine D** : 20 µg dès 50 ans | Ne correspond à aucune référence (ANSES/EFSA : 15 µg pour tous les adultes ; IOM : 20 µg après 70 ans) | 15 µg pour tous les adultes, conforme à l'ANSES (vérifié sur anses.fr le 31/10) ; majoration « senior » de la vitamine E retirée (absente de la référence). Vitamine E 10/9 mg et B5 6/5 mg : déjà exactes |
| 9 | Respiration — **soupir physiologique** : « a fait mieux que la respiration carrée, l'hyperventilation ET la méditation » | Surinterprétation de l'étude de Stanford (2023) | Reformulé : plus forte amélioration de l'humeur, et la respiration a fait mieux que la méditation |

## 2. Base d'aliments CIQUAL (3 490) et USDA (7 839)

- **Contrôle ligne à ligne contre la table ANSES CIQUAL 2025** : 0 écart sur toutes les valeurs présentes des deux côtés. Les ~3 000 cases complétées viennent du fichier tracé `Corrections_Proposees.csv` (USDA), uniquement là où l'ANSES ne donne rien ; les « traces » ANSES restent vides (jamais inventées).
- **Cohérence physique** (énergie vs macros, masse > 100 g, sucres > glucides, AG saturés > lipides) : les rares alertes CIQUAL sont des polyols (bonbons sans sucre) et des données source ANSES. Côté USDA, l'anomalie systémique était celle des glucides (§1, n° 3).
- **Emojis** : distribution cohérente, issue de 15 audits successifs. Une correction (tisane 🥤 → 🍵). Le 🧴 des huiles et margarines est **ta décision des audits 8, 10, 13 et 15** (pas l'ingrédient d'origine, pas le beurre pour un produit végétal) : je ne l'ai pas touché. Alternative possible si tu veux : 🫗 (« liquide versé »), mais absent des téléphones sous Android 12 et plus anciens.
- **Libellés** : 114 essentiels ont désormais un nom court et clair (« Riz blanc, cuit » au lieu de « Riz blanc, cuit, sans sel ajouté » ; « Blanc de poulet, grillé » au lieu de « Poulet, filet sans peau grillé/poêlé »), en FR et EN. Le nom ANSES complet reste cherchable et visible dans la fiche. Unicité garantie par un test.

## 3. Liste par défaut du « + » (ta demande)

Avant : un nouvel utilisateur voyait les 3 490 aliments CIQUAL par ordre alphabétique (« Abat, cuit », « Abondance », « Abricot au sirop »…), faute d'historique pour le tri « fréquents ».

Maintenant, sans recherche, avec trois intertitres discrets :
1. **Tes aliments habituels** : ton historique (fréquents ou récents selon le tri choisi), inchangé ;
2. **Les essentiels du quotidien** : 141 aliments génériques curés, dans l'ordre d'un repas (œufs, volaille, poissons, laitiers, légumineuses, féculents, légumes, fruits, oléagineux, matières grasses, boissons, condiments) ;
3. **Tous les aliments** : le reste, de A à Z.

**Inchangé** : la recherche (favoris, fréquents, phrase, fautes tolérées), les tris A→Z / Z→A, Favoris, Perso. Fichier : `lib/services/staple_foods.dart`.

## 4. Quantités prédéfinies (« dosages » du +)

Avant : pour un aliment CIQUAL, premier ajout à **100 g quel que soit l'aliment** (100 g d'huile = 900 kcal ; 100 g de café ; « combien pèse un œuf ? »), avec seulement les puces 50/100/150/200 g.

Maintenant : **portions ménagères** affichées avec « ≈ » (1 œuf ≈ 50 g, 1 banane ≈ 120 g, 1 c. à soupe d'huile ≈ 10 g, 1 pot de yaourt ≈ 125 g, 1 tranche de jambon ≈ 40 g, 1 poignée d'amandes ≈ 30 g…) pour les 141 essentiels, plus des repères par famille (huiles, fromages, laitages, oléagineux, sauces, épices, boissons). **La première portion devient la quantité proposée par défaut.** Aucune portion pour les plats composés (trop variables). Repères : manuel « Portions alimentaires » SU.VI.MAX et PNNS. ⚠️ Cela revient sur la décision d'août « rien côté CIQUAL » : à toi de valider. Fichier : `lib/services/food_portions.dart`.

## 5. Vignettes Aliments / Recettes / Repas (onglet Perso)

Les largeurs étaient des pourcentages fixes (40/30/30 %) : sur 360 px, avec une police système agrandie ou le compteur « 168 », le mot était coupé. Chaque vignette est maintenant **mesurée** (mot + icône + compteur, zoom du téléphone compris). Quand la place manque, les vignettes non sélectionnées masquent d'abord leur icône. **Le mot sélectionné n'est jamais coupé ni réduit.** Testé automatiquement sur 320 dp, 360 dp avec police ×1,3 et 393 dp (`test/screens/perso_chips_layout_test.dart`).

## 6. Recettes : base enrichie et entonnoir

- **24 nouvelles recettes** (192 au total), ciblées sur les manques mesurés : petits-déjeuners et collations riches en protéines (overnight oats, pancakes protéinés, skyr…), post-entraînement (shake, lait chocolaté de récupération, poke bowl, chili), grands classiques sains (salade niçoise, shakshuka, ratatouille-poulet, wrap, bolognaise de lentilles, curry léger), dîners pauvres en glucides (saumon-épinards-avocat : 1 g de glucides ; poulet-courgettes : 7 g) et protéines végétales (tempeh, tofu-cacahuète, porridge végétal à 31 g). FR + EN, ingrédients CIQUAL pesés, étapes rédigées.
- **Recherche** : nom de recette **et** ingrédients, mots dans le désordre, accents, pluriels, une faute tolérée, et aussi en anglais (« curry », « poulet riz », « chicken »). Avant : sous-chaîne exacte sur les seuls ingrédients français.
- **Filtres cumulables** : Végétarien + Hyperprotéiné + Rapide, etc. (avant : un seul à la fois). Ta sélection précédente est conservée.
- **Tri** : pertinence, plus protéinées, moins caloriques, meilleur score santé.
- **Garde-fou** : `test/services/library_recipes_integrity_test.dart` recalcule chaque recette depuis la base ; toute dérive future fait échouer les tests.

## 7. Partage d'un repas (visuel réseaux / site / pro)

- **Angle du visuel**, nouveau choix : Équilibre · Sport · Satiété · Longévité. Le même repas est raconté pour ton public : l'accroche de couverture, les 3 chiffres clés, l'ordre des micronutriments mis en avant, « À retenir » et les mots-dièse changent ; les données jamais.
  - Sport : « 57 g de protéines et 108 g de glucides » ; magnésium, potassium, fer et vitamines B passent devant.
  - Satiété : « 1 030 kcal pour 888 g dans l'assiette », densité énergétique, protéines et fibres.
  - Longévité : **nombre de végétaux différents** (repère 30 par semaine, American Gut Project 2018), **part d'aliments bruts** (estimation NOVA, affichée seulement si le degré de transformation est connu pour au moins 75 % du poids), oméga-3 et antioxydants en avant.
- **Couverture sans photo** : une assiette stylisée (ingrédient principal au centre, les autres autour) remplace l'ancienne rangée d'emojis.
- Noms d'ingrédients courts sur les visuels grâce aux nouveaux libellés (fin de « Chocolat noir 70 % de cacao envir… »).
- Règles conservées : références UE/ANSES, aucune allégation « riche en », 5 mots-dièse maximum, pas d'emoji pour les nutriments.

## 8. Parcours d'inscription

L'écran final « Tout est prêt » contient maintenant **« Comment ça marche » en 3 gestes** : noter avec le +, se peser 2-3 fois par semaine (pourquoi), regarder Bilan et Conseils. Cela répond aux questions de tes testeurs au moment exact où ils arrivent dans l'app, sans tutoriel à faire défiler.

## 9. Ce qui a été vérifié et laissé tel quel

- **Calcul calorique et calibration** : non modifiés (vérifiés sur tes données réelles le 25/10). Seules les cibles vitamine D et vitamine E ont été alignées sur l'ANSES (§1, n° 8).
- **Banque d'exercices de respiration** : 6 techniques, sources réelles et correctement citées (Stanford 2023 ; Vierra et al., *Physiological Reports* 2022 pour le 4-7-8). Seule correction : le texte du soupir physiologique (§1, n° 9).
- **Pas de gamification** (séries, points, badges) : règle respectée.

## 10. Veille concurrence (2026)

- **MacroFactor** (juillet 2026) : scanner d'étiquettes multilingue et accélération de la saisie et des recettes par IA ; journalisation par IA depuis mars 2025.
- **Cronometer** (février 2026) : saisie par photo.
- Pour **Yazio**, aucune annonce officielle 2026 trouvée ; les comparatifs disponibles viennent de concurrents.

Tendance : la saisie assistée (photo, étiquette, voix) devient le standard. Piste prioritaire pour Totum : **lecture de l'étiquette nutritionnelle par l'appareil photo**. Elle est fiable car elle lit des chiffres réels et complète idéalement le scan de code-barres. Elle nécessite une brique OCR et ta validation (coût, confidentialité).

## 11. Tests et fichiers

Nouveaux tests : `library_recipes_integrity_test`, `staple_foods_test` (essentiels + portions), `perso_chips_layout_test` ; tests étendus : `usda_branded_mapping_test` (glucides), `meal_share_screenshot_test` (4 angles), `add_food_page_screenshot_test` (intertitres).

Fichiers principaux : `assets/foods.csv`, `assets/usda_foods.csv`, `assets/totum_recipes*.json`, `lib/services/staple_foods.dart` (nouveau), `lib/services/food_portions.dart` (nouveau), `lib/services/meal_share.dart`, `lib/widgets/meal_share_slides.dart`, `lib/screens/meal_share_screen.dart`, `lib/screens/journal_screen.dart`, `lib/screens/conseils_screen.dart`, `lib/screens/onboarding_screen.dart`, `lib/services/usda_service.dart`, `lib/services/export/journal_export.dart`, `lib/services/profile.dart`, `scripts/build_usda_foods.py`.

## 12. À tester sur téléphone

1. Le « + » avec un compte neuf : intertitres, essentiels, portions « ≈ ».
2. Bibliothèque de recettes : recherche « poulet riz », filtres combinés, tri.
3. Partage d'un repas : les 4 angles, avec et sans photo.
4. Une recette importée avant cette version : ses valeurs se mettent à jour à l'ouverture du +.
5. Export de période : libellés d'activité et d'objectif.
