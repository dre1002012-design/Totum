# TOTUM — Contexte du projet

## Vue d'ensemble
TOTUM est une application de suivi nutritionnel développée par Alex, naturopathe et coach sportif certifié (également fondateur de FIT'TRUCK 1384, concept de fitness outdoor mobile — projet distinct, sans lien technique avec TOTUM).

TOTUM combine :
- Suivi calorique et nutritionnel (macro + micronutriments)
- Un "coach" algorithmique donnant des conseils personnalisés (nutrition, mouvement, sommeil, stress, mindset)
- Un module de recettes avec scoring santé et matching contextuel au reste-à-consommer du jour
- Un profil utilisateur avec calcul de dépense énergétique (formules officielles + activité déclarée/mesurée)

URL de production : https://totum-app-2026.web.app

## Vision produit (fil rouge de tout développement)
Application éducative qui donne à l'utilisateur une compréhension élevée de ce qu'il consomme, pour le rendre autonome et acteur de sa santé au quotidien. Se démarquer par la fiabilité et la profondeur — créée par un passionné naturopathe qui l'utilise lui-même. Novice comme expert doivent y apprendre quelque chose. Objectif de fond : prouver qu'on peut tout trouver dans l'alimentation brute, locale, de saison. Approche holistique : au-delà de la nutrition, la santé est un tout (mouvement, sommeil, stress, mental). Cible aussi les professionnels de santé (coachs, nutritionnistes, naturopathes) susceptibles de recommander l'app à leurs clients.

Cette vision conditionne les choix UX/texte : voir `CLAUDE_RULES.md` § Philosophie produit (ex. jamais de promesse de résultat corporel dans un libellé de filtre).

## Stack technique
- Frontend : Flutter / Dart (Web + Android)
- Backend / Auth / Data : Supabase (toutes les données et l'auth)
- Hosting : Firebase Hosting (sert uniquement de hosting, pas de logique backend)
- Graphiques : fl_chart
- Activité physique (mobile natif) : pedometer, permission_handler
- Stockage local léger : SharedPreferences (historisation, snapshots, préférences)
- Base nutritionnelle de référence : CIQUAL (`foods.csv`) — utilisée pour la génération/enrichissement des recettes

## Contrainte externe à surveiller
Google Play Console impose le passage à Google Play Billing 8.0.0+ avant le **31 août 2026** (extension possible jusqu'au 1er novembre 2026). Mise à jour des dépendances faite le 22 juillet 2026 (`in_app_purchase` 3.3.0 / `in_app_purchase_android` 0.5.0) — il reste à **tester le parcours d'achat et publier**. Voir `TODO.md`.

## Décisions d'architecture actées

### 1. Pas de migration Supabase complète pour Recettes/Ingrédients
Un cahier des charges externe (généré par une autre IA, non familière avec le code réel) a proposé une migration complète vers 3 tables Supabase (`ingredients`, `recipes`, `recipe_ingredients`) avec pipeline d'ingestion de `foods.csv` côté serveur.
**Décision : rejetée.** L'architecture actuelle — recettes en JSON (`totum_recipes.json`) chargées et calculées côté client Flutter (classes `TotumRecipe`, `TotumRecipeIngredient`) — fonctionne déjà et couvre tous les besoins (Healthy Score, Smart Match Score, badges, filtres, barre de projection). Migrer signifierait reconstruire à l'identique en plus lourd, sans bénéfice utilisateur mesurable. Seules les *idées* pertinentes de ce CDC externe sont retenues au cas par cas (voir `CURRENT_STATE.md` et `TODO.md`), jamais son architecture.

### 2. La base CIQUAL fournit déjà les valeurs "cuites" nativement
Pas besoin d'un système de facteurs de rendement de cuisson (yield factors) séparé : CIQUAL contient nativement des entrées distinctes "cru" et "cuit"/"bouilli"/"grillé" pour la quasi-totalité des aliments (ex. "Lentille, bouillie/cuite à l'eau", "Riz complet, cru"). Il suffit de sélectionner la bonne entrée CIQUAL selon l'état réel de l'ingrédient dans la recette. (Un bug lié à un mauvais choix d'entrée a été identifié — voir `CURRENT_STATE.md` et `TODO.md`.)

### 3. Philosophie des filtres recettes : propriété du plat, jamais promesse de résultat
Un filtre de recette doit décrire une caractéristique nutritionnelle réelle du plat (calories, protéines...), jamais un résultat corporel promis. "Perte de poids" a été identifié comme une erreur de langage (aucune app de référence — MyFitnessPal, Cronometer, MyNetDiary, Yazio — n'utilise ce type de libellé) et remplacé par "Léger" (même seuil de calcul, formulation honnête).

### 4. Historisation par snapshot journalier
Pattern retenu pour historiser des objectifs qui évoluent dans le temps : un instantané JSON par jour maximum (clé SharedPreferences dédiée), remplacé s'il existe déjà un instantané du jour, avec une fenêtre glissante de conservation (200 derniers instantanés ≈ 6-7 mois). Les recalculs de bilan sur une période vont chercher, pour chaque jour, le dernier instantané ≤ à ce jour (fallback sur les objectifs courants si un champ est absent, pour compatibilité ascendante avec d'anciens instantanés partiels).

## Fichiers clés du projet
| Fichier | Rôle |
|---|---|
| `profile_screen.dart` | Écran profil : renseignement activité (podomètre natif mobile / saisie manuelle web), calcul dépense énergétique |
| `profile.dart` | Modèle + logique de calcul des objectifs nutritionnels (`NutritionTargets`), historisation des objectifs |
| `bilan_screen.dart` | Écran bilan : agrégation des données sur 30/60/90j, graphique d'énergie historisé |
| `conseils_screen.dart` | Écran coach : sélection de conseils contextuels, pilier sommeil/stress, moteur Recettes (Smart Match Score, filtres, badges) |
| `coach_advices.json` | Base des 180 conseils du coach, organisée par pilier et déclenchée par triggers |
| `totum_recipes.json` | Base des recettes (111 actuellement), macros/micros calculées depuis CIQUAL |
| `foods.csv` | Base CIQUAL brute — source pour la génération/correction des recettes |

## Conventions de code et de collaboration
- **Toujours vérifier le vrai fichier avant d'éditer** — ne jamais halluciner le contenu existant. Ce pattern a évité plusieurs erreurs (fichiers envoyés parfois périmés ou dupliqués par relance de script) et doit être conservé systématiquement.
- **Format de modification imposé** : bloc "cherche ceci" / "remplace par cela" exploitable au Ctrl+F, jamais de description libre du type "insère dans telle classe à tel endroit".
- Modifications ciblées et chirurgicales privilégiées plutôt que des réécritures complètes, avec spécification explicite du fichier/de l'emplacement avant toute intégration.
- Langue de travail : français.
- Toute clé de trigger dans `coach_advices.json` (champ `micro`) doit correspondre exactement à une clé réellement présente dans `decision.microRatios` (`_decideTheme()` de `conseils_screen.dart`) — 30 clés valides confirmées (voir `CURRENT_STATE.md`).
- `CoachContext.goalKey` : `'loss'` (goalIndex ≤ 0), `'maintain'` (1 ou 2), `'gain'` (≥ 3).
- `CoachContext.activityKey` : `'low'` (activityIdx ≤ 0) ou `'normal'`.
- `_kRatioToFicheKey` (`conseils_screen.dart`) : mapping ratio → clé de fiche nutriment (30 entrées).