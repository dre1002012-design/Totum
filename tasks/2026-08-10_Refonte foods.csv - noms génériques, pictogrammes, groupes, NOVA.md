# Cahier des charges — Refonte de la recherche d'aliments (noms génériques, pictogrammes, groupes, score NOVA, photo scan)

**Contexte** : conversation initiale perdue suite à un plantage (compression du fichier CSV joint). Cahier des charges reconstitué par Alex le 10/08/2026 puis reconfirmé par un ré-audit technique complet (voir `docs/TODO.md`, Priorité 25) avant toute implémentation.

## Constat de départ

`assets/foods.csv` (base CIQUAL 2025, 3490 aliments) utilise les libellés officiels ANSES, souvent longs et techniques (ex : *"Abricot au sirop léger, appertisé, non égoutté"*). Les applications concurrentes (MacroFactor, Yazio, MyFitnessPal, Chronometer) utilisent des noms courts et génériques + un pictogramme par aliment, ce qui rend la recherche quasi instantanée. Alex veut la même expérience, sans rien perdre de la richesse de la base CIQUAL existante.

## Demandes (4 chantiers + 1 sous-chantier)

1. **Reclassement par groupe alimentaire** — conserver l'intégralité des 3490 aliments, ajouter un classement par famille.
2. **Nom générique par aliment** — nouvelle colonne, libellé court et intuitif, en plus (jamais à la place) du nom CIQUAL complet.
3. **Pictogramme par aliment** — rendu visuel façon MacroFactor (capture d'écran fournie par Alex).
4. **Score NOVA** :
   - Sur les aliments scannés (Open Food Facts) : afficher le NOVA officiel, déjà présent dans la réponse API OFF.
   - Sur la base CIQUAL (3490 aliments) : CIQUAL ne fournit pas nativement de NOVA (classification absente de la nomenclature ANSES) → estimation TOTUM par règles, clairement identifiée comme telle dans l'UI (jamais confondue avec une donnée officielle).
5. **Photo du produit scanné** — Open Food Facts fournit une photo (`image_front_url`), à afficher comme le fait Yazio. Non applicable à la base CIQUAL (pas de photos officielles).

## Principes directeurs (identiques à l'audit nutriments précédent)

- **Jamais de perte de données** : les 3490 lignes et toutes leurs colonnes existantes restent intactes. On *ajoute* des colonnes, on ne remplace rien.
- **Jamais d'invention silencieuse** : toute donnée dérivée par une règle (nom générique, pictogramme, NOVA estimé) doit être **documentée comme telle**, avec sa méthode, jamais présentée comme une donnée officielle CIQUAL.
- **Positionnement de marque** ([[project_brand_positioning]] en mémoire) : santé/longévité/vitalité/bien-être/performance — la refonte visuelle doit rester cohérente avec la charte graphique déjà en place (`lib/theme/totum_style.dart`), pas un ajout hétérogène.
- **Rigueur** ([[feedback_score_rigor]] en mémoire) : le score NOVA affiché doit être fiable — jamais une estimation présentée avec la même autorité qu'une donnée officielle OFF.

## Découverte clé qui a débloqué le chantier

`assets/Table Ciqual 2025.csv` (export officiel ANSES, 84 colonnes) est déjà présent dans le repo et contient la hiérarchie de classement complète (`alim_grp_nom_fr` / `alim_ssgrp_nom_fr`, 12 groupes / 64 sous-groupes), indexée par `alim_code` = notre `ciqual_code`. Jointure vérifiée : **3484/3484 aliments officiels retrouvés à 100 %**. Seuls les 6 aliments hors-CIQUAL ajoutés lors de l'audit nutriments précédent (compléments protéinés 90001-90005, natto 90006) n'ont pas de groupe officiel et sont classés manuellement.

Une première approche par préfixe numérique du `ciqual_code` a été testée et **rejetée** : le préfixe "76" mélangeait par coïncidence des viennoiseries (codes à 4 chiffres) et des eaux minérales (codes à 5 chiffres). La jointure sur la table officielle évite ce risque.

## Méthodologie par chantier

- **Groupe/sous-groupe** : jointure directe, zéro approximation, 100 % de couverture (3484 officiels + 6 classés manuellement).
- **Pictogramme** : mapping par défaut au niveau du sous-groupe (~65 entrées éditoriales contrôlées une à une), avec surcharges par mot-clé pour les aliments les plus courants au sein des sous-groupes hétérogènes (fruits, légumes, poissons...), pour un rendu aussi riche que la capture MacroFactor.
- **Score NOVA (base CIQUAL)** : règle par défaut au niveau du sous-groupe + surcharges par mots-clés (ex : "préemballé"/"industriel"/"extrudé" → tendance NOVA 4 ; "cru"/"nature"/"frais" → tendance NOVA 1 ; "appertisé"/"fumé"/"salé" → NOVA 3 ; "farine"/"huile"/"sucre"/"sel" utilisés comme ingrédients culinaires → NOVA 2). Explicitement documenté comme estimation, pas une donnée officielle.
- **Nom générique** : génération par règles, différenciées selon la structure de nommage CIQUAL (les sous-groupes viandes/poissons/volailles suivent la convention "Espèce, découpe, cuisson" → réordonnancement "Découpe de espèce" ; les autres suivent "Nom, variante, préparation" → segment avant la première virgule, qualificatifs techniques retirés). Première passe automatisée puis revue par échantillonnage (méthodologie identique à l'audit nutriments : l'automatisation seule n'est jamais fiable à 100 %, cf. Lot 2 de `Audit_Global.md` où 30 % des correspondances automatiques étaient fausses).

## Statut

✅ Livré (v1, Priorité 25) puis affiné (Priorité 26, retours d'usage réel + incident) — voir `docs/TODO.md` pour le détail complet.

**⚠️ Incident du 10/08/2026** : `assets/foods.csv` a été accidentellement écrasé par un `git checkout` (la version aboutie — 3490 lignes, ~3026 corrections tracées — n'avait jamais été committée). Entièrement reconstruit et vérifié (voir Priorité 26 dans `docs/TODO.md`) à partir de `assets/Table Ciqual 2025.csv` + `Corrections_Proposees.csv` + re-sourçage USDA des 6 aliments hors-CIQUAL. Scripts de reconstruction conservés : `scripts/rebuild_foods_base.py`, `scripts/rebuild_custom_foods.py`.

Script de génération de la taxonomie (groupe/pictogramme/NOVA/nom générique) : `scripts/build_food_taxonomy.py`.
