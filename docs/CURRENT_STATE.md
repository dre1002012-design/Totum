# TOTUM — État actuel du code

✅ Vérifié le 04/08/2026 : les blocs Smart Match Score / badges livrés lors d'une session précédente sont bien appliqués dans le code réel (voir `TODO.md`, Priorité 3 — rien n'a dû être réappliqué).

## 1. Profil 2.0

### Gestion podomètre web / mobile (`profile_screen.dart`)
- **Mobile (natif)** : podomètre inchangé (APK/iOS).
- **Web (`kIsWeb`)** : bloc podomètre masqué, remplacé par une saisie manuelle des pas (`_webStepsCtrl`, `FilteringTextInputFormatter.digitsOnly`).
  - Badge "Estimé" (bleu) sur web vs "Mesuré" sur mobile.
  - Persistance : clé SharedPreferences `profile_web_manual_steps`, sauvegardée dans `_saveHolisticAndRefresh`, chargée au démarrage.
  - Branchement calcul : `_effectiveActivityForCalc` → `workStyleFromSteps(webSteps)` → même pipeline que le podomètre natif.
- Section "Ton quotidien" unifiée via `Builder` + variables `nativeSteps` / `webSteps` / `effectiveSteps` / `badgeLabel` (3 sources : mesuré mobile / estimé web / déclaratif 3 cartes).

### Historisation des objectifs nutritionnels (`profile.dart`)
- `saveNutritionTargets()` appelle `_appendGoalsSnapshot(sp, t)` avec l'objet `NutritionTargets t` complet.
- `_appendGoalsSnapshot` sérialise **37 champs** en JSON sous la clé `goals_snapshots_v1` (5 macros + 8 acides gras essentiels/à surveiller + 11 minéraux + 13 vitamines).
- Rétention : 1 instantané/jour max (remplacé si déjà existant), 200 derniers conservés (~6-7 mois), triés par date.

## 2. Bilan (`bilan_screen.dart`)

### Historisation exploitée
- `_GoalsSnapshot` (37 champs, noms identiques aux clés JSON).
- `_readGoalsSnapshots()` : repli champ-par-champ sur `fallback` (objectifs actuels) pour compatibilité ascendante avec anciens instantanés partiels (5 macros seulement).
- `_goalsRawForDay(day, snapshots, current)` : dernier instantané ≤ ce jour (sex/weightKg/activityIdx toujours depuis `current`, non historisés).
- `_averageGoalsRawForRange(daysWithData, snapshots, current)` : moyenne pondérée des 37 champs sur les jours avec données réelles.
- `_computeBilanForSpan` : charge une fois `currentGoals` + `goalsSnapshots`, puis calcule `goals` par jour ou en moyenne selon le mode.

### Graphique d'énergie modernisé
- `DailyEnergyPoint.goalKcal` : objectif kcal historisé du jour, peuplé via `_goalsRawForDay(...).kcal`.
- `_EnergyChartCard` : couleur de barre selon l'objectif du jour (`barColorFor`), tooltip "Objectif ce jour-là : X kcal", note explicative, légende "Objectif actuel : X kcal (ligne pointillée)".

✅ **Bug historique résolu par ce chantier** : le bilan 30/60/90 jours comparait auparavant les données passées aux objectifs *actuels* au lieu des objectifs *historiques du jour* — c'est précisément ce que corrige l'historisation ci-dessus.

## 3. Coach / Conseils (`conseils_screen.dart` + `coach_advices.json`)

### Base de conseils enrichie
- 100 → **180 conseils**, 5 piliers : Nutrition 22→44, Mouvement 20→38, Sommeil 18→31, Stress 20→32, Mindset 20→35.
- Triggers limités aux clés confirmées dans le vrai code (`micro`: magnesium/iron/omega3/vitD/vitC/zinc/calcium/fibers ; `goal`: loss/gain ; `activity`: low ; `sleep_below`/`sleep_above` ; `stress_above`/`stress_below`).
- **Découverte** : `CoachContext.ratios` accepte en réalité **30 micronutriments** (oméga9/oméga6/oméga3_ALA/oméga3/oméga3_marins/EPA/DHA/vitA/vitD/vitE/vitK/vitC/B1-B6/B9/B12/calcium/cuivre/fer/iode/magnésium/manganèse/phosphore/potassium/sélénium/sodium/zinc/fibres) + `goal: "maintain"` + `activity: "normal"` — **non exploités** à ce jour, marge d'enrichissement confirmée.

### Corrections UX livrées
- **Seuils de sommeil recalibrés** (NSF Hirshkowitz 2015) — 6 paliers : <5h 😵 Très insuffisant / 5-6h 😴 Insuffisant / 6-7h 😕 Un peu court / 7-9h 😃 Idéal / 9-10h 😐 Un peu long / >10h 😌 Long. Corrige le bug où 6h30 s'affichait comme "Correct".
- **Tips ludiques par palier** (sommeil + stress) : `_sleepTip()`/`_stressTip()`, passés à `_pillarBlock()` via le paramètre `tip`, affichés en italique sous le slider.
- **Anti-flash au rafraîchissement** : `AdviceScript? _lastData` + `bool _refreshing`, `FutureBuilder` affiche les anciennes données avec `LinearProgressIndicator` en `Positioned`/`Stack` au lieu d'une page blanche pendant le chargement. ⚠️ Ajustement d'indentation nécessaire pour les enfants de la `ListView`.
- **Copy** : sous-titre WellbeingCard clarifié ("...puis mets à jour pour recalculer tes conseils.").

### Manques identifiés (audit réel, non corrigés à ce stade)
1. Aucune vue directe calories/protéines du jour sur l'écran principal Conseils (abstrait derrière le Score TOTUM).
2. Les 180 conseils enrichis sont cachés derrière un tap, peu visibles.

## 4. Recettes

### Fondations
- `goalTags` par portion : `perte_poids` *(⚠️ à renommer "léger", voir `TODO.md`)* si kcal < 100 (collation)/500 (repas) ; `hyperproteine` si prot ≥ 15g (collation)/30g (repas) ; `equilibre` sinon.
- `healthyScore` /100 : 7 composantes (sProt/sFiber/sMicro/sLipid/sDensity/sSugar/sSodium) sur macros + micros CIQUAL réels (vit C, fer, magnésium, potassium, calcium, zinc, B9, bêta-carotène, oméga 9/6/3, sucres, sodium).

### Smart Match Score + badges + filtres (10 blocs livrés cette session)
1. `RemainingToday` (kcal/prot/carb/fat/hasTargets) + `computeRemainingToday()` (réutilise `_readGoalsForAdvice`/`_buildAdviceTargets`/`_computeDayTotalsForAdviceDate`).
2. `smartMatchScore(recipe, remaining)` : /100, pondération 40% kcal / 30% prot / 15% glucides / 15% lipides, malus -35 si `Recipe_kcal > RC_kcal + 100`.
3. `AllRecipesScreen` : `_activeTag` (exclusif, remplace `_activeTags` Set), `_smartFitOn`, `_remaining` chargé en `initState`.
4. Quick filters rendus exclusifs entre eux.
5. Bouton **"Pour toi"** (`FilterChip`) dans l'AppBar : trie par `smartMatchScore` décroissant.
6. Bannière "Pour toi aujourd'hui" mise à jour sur `_activeTag == null`.
7. Badges sur `_buildRecipeRow` : ❤️ Healthy Score coloré + 🎯 "Fit X%" (si ≥60%).
8-9. `RecipeDetailScreen` : `_remaining` en `initState`, badges Healthy Score + Fit affichés.
10. Barre de projection post-consommation ("Après ce repas, il te restera : X kcal | Y g Prot | Z g Gluc | W g Lip").

### Filtres — set final validé (recherche apps de référence)
Aucune app de référence (MyFitnessPal, Cronometer, MyNetDiary, Yazio, recipecard.io, That Clean Life, Chloe Ting) n'utilise "perte de poids" comme filtre de recette — c'est une propriété du plat, jamais une promesse de résultat.

**Set retenu (validé, pas encore appliqué dans le code)** : Hyperprotéiné · **Léger** (remplace Perte de poids, même seuil) · Rapide · Sans gluten · Sans lactose · **Végétarien** (nouveau) · **Végétalien** (nouveau).

### Bug cru/cuit dans les recettes — ✅ corrigé (04/08/2026)
- ✅ OK : légumineuses/pâtes utilisent déjà les bonnes entrées CIQUAL cuites. Épinards : le bug supposé n'était pas reproductible (les 2 seuls usages crus en base sont légitimement crus — smoothie, Buddha bowl).
- Périmètre réel du bug, plus large qu'initialement identifié : **riz complet, poulet blanc, saumon coho, quinoa, boulgour, cabillaud, truite, colin, œuf** (omelettes) — 35 ingrédients dans 30 recettes sur 111, corrigés le 04/08/2026 (entrée CIQUAL cuite/vapeur/grillée/rôtie sélectionnée selon le mode de cuisson décrit dans chaque recette, macros/micros recalculés par moyenne pondérée).
- Impact le plus sévère confirmé : le **riz** (cru ≈350 kcal/100g vs cuit ≈187 kcal/100g) → recettes riz corrigées de -15 à -55 kcal/100g. À l'inverse, poulet/poisson corrigés **à la hausse** (la cuisson concentre, ne dilue pas, ces aliments — cru 122-147 kcal/100g vs cuit 150-224 kcal/100g selon l'aliment).
- **Limite CIQUAL découverte, contredit l'hypothèse de `PROJECT_CONTEXT.md` §2** : CIQUAL ne fournit pas systématiquement une entrée cuite pour chaque aliment. Aucune entrée cuite n'existe pour "Poulet blanc" ni "Saumon argenté du Pacifique (coho)" sous ce nom exact (substituts réels utilisés : poitrine de poulet rôtie/cuite au four ; saumon élevage cuit vapeur/poêlé/fumé selon la recette). **Aucune entrée cuite n'existe du tout pour le sarrasin** dans CIQUAL — 2 recettes (`Porridge sarrasin, poire & noisette`, `Bowl de sarrasin, saumon & avocat`) laissées en `cru` faute de donnée fiable, à trancher avec Alex.
- Conséquence sur le tri des recettes : 10 recettes sur 30 changent de `goalTags` suite au recalcul (majoritairement gain du tag "léger"), voir détail dans `TODO.md`.

## 5. Cahier des charges externe V2 (reçu, analysé, partiellement retenu)
- Migration Supabase complète — **rejetée** (voir `PROJECT_CONTEXT.md`).
- Facteurs de rendement de cuisson — **rejetés en tant que système** (CIQUAL suffit), mais a déclenché la découverte du vrai bug cru/cuit ci-dessus.
- `protein_source_type`, `is_gluten_free`, `is_lactose_free`, `is_vegan`, `is_vegetarian` — retenu en partie via les nouveaux filtres Végétarien/Végétalien/Sans gluten/Sans lactose.
- Formules Healthy Score / Smart Match Score — déjà implémentées de façon équivalente, pas de reprise nécessaire.
- UI (`RecipeCardWidget`, badges, barre de projection) — déjà livrés. `AddToJournalBottomSheet` et "Mes Recettes Perso" — **non traités, idée conservée sans priorité**.
- Filtre "Vide-frigo" (≥75% d'ingrédients disponibles) — **idée non committée**.

## 6. Autres sujets connus, hors chantier actif
- Icône PWA absente sur écran d'accueil iPhone/Safari (non urgent).
- Google Play Billing 8.0.0+ : dépendances mises à jour (22/07/2026), reste à tester le parcours d'achat et publier avant le 31/08/2026 (extension possible 01/11/2026).