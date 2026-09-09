# TOTUM — Méthodologie scientifique des calculs (Profil, objectifs, calibration)

Document de référence vivant, à tenir à jour à chaque changement de formule. Décrit **tout** ce qui alimente les objectifs affichés à l'utilisateur (calories, macros, micronutriments, calibration adaptative) : la formule exacte, la source scientifique, et — quand c'est le cas — les limites honnêtes de cette source. Rédigé suite à l'audit du 19/08/2026 (voir `tasks/2026-08-19_Audit calculs Profil - dépense énergétique et protéines.md` pour l'historique du bug qui a déclenché cette revue complète).

**Principe de rédaction** : chaque formule ci-dessous est soit (a) une citation directe d'une source publiée et vérifiable, soit (b) explicitement marquée comme un choix d'implémentation propre à TOTUM (avec la justification). Aucune des deux catégories n'est présentée comme l'autre.

---

## 0. Point de franchise nécessaire — parité avec MacroFactor

Alex a demandé à plusieurs reprises "la même puissance que MacroFactor" et "un copier-coller de ce qu'elle fait". Il faut être honnête sur ce que ça veut dire concrètement :

- **L'algorithme propriétaire exact de MacroFactor n'est pas public.** Ni son code, ni ses constantes internes (poids exact de chaque donnée, seuils de confiance précis, gestion des cas limites) n'ont jamais été publiés — confirmé par l'audit du 09/08/2026 (`tasks/026-08-09_Audit scientifique de Macro factor.md`). Aucune IA, aucun développeur extérieur à leur équipe ne peut le reproduire au bit près — l'affirmer serait mentir.
- **Ce qui EST public et vérifiable**, et que TOTUM implémente réellement : le **principe général** de la méthode — comparer le poids réellement mesuré (lissé pour filtrer le bruit) à l'évolution attendue compte tenu des calories réellement loguées, pour en déduire une estimation de dépense énergétique réelle qui remplace progressivement une formule anthropométrique générique. C'est un principe d'**équilibre énergétique** connu de longue date en physiologie (pas une invention de MacroFactor), qu'ils ont rendu accessible au grand public via une UX soignée.
- **Ce que fait TOTUM concrètement** : une implémentation **indépendante** de ce même principe général, construite sur des formules et constantes chacune sourcées (Mifflin-St Jeor, Cunningham, ISSN, AMDR, ANSES/EFSA, consensus RED-S — détail ci-dessous), pas une rétro-ingénierie du code de MacroFactor.
- **Conséquence assumée** : les chiffres exacts produits par TOTUM et par MacroFactor sur un même profil ne seront jamais identiques au kcal près — ce n'est physiquement pas possible sans avoir accès à leur code. En revanche, l'**ordre de grandeur et la méthode** doivent être scientifiquement défendables et cohérents entre eux, ce qui est l'objet de ce document et de l'audit du 19/08/2026.

Cette clarification n'affaiblit pas l'objectif d'Alex ("être la meilleure application de compteur de calories qui existe") — elle le sert : une méthode indépendante, sourcée et vérifiable est un argument de confiance plus solide qu'une prétention de copie invérifiable.

---

## 1. Métabolisme de base (BMR)

**Fichier** : `lib/services/profile.dart`, `_computeBmr()` / `computeBmr()`.

### 1.1 Sans % de masse grasse connu — Mifflin-St Jeor
```
Homme : BMR = 10×poids(kg) + 6.25×taille(cm) − 5×âge + 5
Femme : BMR = 10×poids(kg) + 6.25×taille(cm) − 5×âge − 161
```
**Source** : Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. *A new predictive equation for resting energy expenditure in healthy individuals.* Am J Clin Nutr. 1990;51(2):241-247. — Reste, à ce jour, l'équation la plus validée pour une population générale (précision généralement considérée supérieure à Harris-Benedict par les revues de validation ultérieures, ex. Frankenfield et al., *J Am Diet Assoc*, 2005).

### 1.2 Avec % de masse grasse connu (2%-60%) — Cunningham, sur masse maigre (LBM)
```
LBM(kg) = poids × (1 − %MG/100)
BMR = 500 + 22 × LBM(kg)
```
**Source** : Cunningham JJ. *A reanalysis of the factors influencing basal metabolic rate in normal adults.* Am J Clin Nutr. 1980;33(11):2372-2374. — Formule spécifiquement basée sur la masse maigre, plus précise que Mifflin-St Jeor dès qu'on connaît la composition corporelle réelle (le métabolisme de repos dépend directement de la masse maigre, pas du poids total). **C'est la formule utilisée par MacroFactor comme point de départ initial** (vérifié par l'audit du 09/08/2026) — bascule volontaire sur cette même formule pour cohérence de méthode.

### 1.3 Estimation de la masse maigre si le %MG n'est pas renseigné — Boer
```
Homme : LBM = 0.407×poids(kg) + 0.267×taille(cm) − 19.2
Femme : LBM = 0.252×poids(kg) + 0.473×taille(cm) − 48.3
```
**Source** : Boer P. *Estimated lean body mass as an index for normalization of body fluid volumes in humans.* Am J Physiol. 1984;247(4 Pt 2):F632-636. Utilisée uniquement pour les besoins internes (répartition protéique) quand le %MG n'est pas connu — le BMR lui-même reste Mifflin-St Jeor dans ce cas (§1.1), pas Cunningham sur une LBM elle-même estimée par une formule tierce (éviter d'empiler deux approximations).

---

## 2. Dépense énergétique totale (TDEE) — formule pure, avant calibration

**Fichier** : `profile.dart`, `_activityFactor()` / `computeGoals()`.

```
TDEE = BMR × PAL
```
avec un PAL (Physical Activity Level) par palier déclaré :

| Palier | PAL |
|---|---|
| Sédentaire | 1.20 |
| Léger | 1.35 |
| Modéré | 1.48 |
| Actif | 1.62 |
| Très actif | 1.78 |
| Extrême | 1.90 |

**Statut de cette table** : choix d'implémentation propre à TOTUM, **pas une citation directe** d'une seule source. Elle s'inspire de la structure des catégories publiées par la FAO/OMS/UNU (*Human energy requirements*, Food and Nutrition Technical Report Series 1, Rome, 2004 — qui définit des paliers PAL indicatifs de ~1.40 à ~2.40 pour une population générale), mais a été **délibérément recalibrée à la baisse** : les paliers grand public FAO/OMS/UNU visent une population large et surestiment régulièrement la dépense réelle par rapport aux mesures de terrain (montres connectées, eau doublement marquée) pour l'utilisateur type de l'app, un biais documenté dans la littérature de validation des trackers d'activité (ex. Shcherbina et al., *J Pers Med*, 2017, sur la précision variable des wearables — utilisé ici comme repère de prudence, pas comme source directe de la table elle-même). **Point à vérifier en priorité** si un désaccord chiffré systématique est observé en usage réel : cette table reste la pièce la moins directement sourcée du moteur de calcul.

---

## 3. Ajustement objectif (perte / prise / maintien)

**Fichier** : `profile.dart`, `_goalRateBwPerWeek()` / `_goalEnergyAdjustmentKcal()`.

### 3.1 Vitesse cible en %poids/semaine (pas un %TDEE fixe)
| Objectif | Vitesse (standard) | Vitesse (conservateur : 60 ans+ OU déjà sec) |
|---|---|---|
| Perte | −1,0 %/sem | −0,7 %/sem |
| Perte modérée | −0,5 %/sem | −0,35 %/sem |
| Maintien | 0 | 0 |
| Prise modérée | +0,25 %/sem | (inchangé) |
| Prise | +0,4 %/sem | (inchangé) |

**Source** : Iraki J, Fitschen P, Espinar S, Helms E. *Nutrition Recommendations for Bodybuilders in the Off-Season: A Narrative Review.* Nutrients. 2021;13(6):1849 — revue de synthèse recommandant un déficit de 0,5-1,0 %/semaine pour préserver la masse musculaire (borne basse retenue), et une prise de 0,25-0,5 %/semaine en phase de volume (Iraki 2021 ; voir aussi Aragon AA, Schoenfeld BJ. *Magnitude of Surplus Energy Intake Influences Gains in Fat-Free Mass.* Nutrients. 2019 pour la justification du rythme de prise lent). **Exprimer l'objectif en %poids/semaine plutôt qu'en %TDEE fixe** est le principe documenté de MacroFactor (le déficit réel diminue automatiquement à mesure que le poids baisse) — principe repris, valeurs sourcées indépendamment.

### 3.2 Densité énergétique variable (jamais 7700 kcal/kg fixe)
```
Rythme lent  (≤0,25%/sem) → 8400 kcal/kg (proche graisse pure)
Rythme rapide (≥1,2%/sem) → 7000 kcal/kg (mélange eau/glycogène/masse maigre)
(interpolation linéaire entre les deux)
```
**Justification** : la composition d'une variation de poids dépend de sa vitesse — bien documenté depuis Hall KD. *What is the required energy deficit per unit weight loss?* Int J Obes. 2008;32(3):573-576, qui montre explicitement que la règle classique unique (3500 kcal/lb ≈ 7700 kcal/kg) est une **simplification connue et imprécise**, la vraie relation étant dynamique et dépendante du rythme et de la composition corporelle. Les deux ancrages (7000/8400) sont un choix d'implémentation TOTUM cohérent avec ce principe — **audit du 19/08/2026 : ce modèle est désormais appliqué de façon cohérente PARTOUT** (objectifs ET calibration adaptative, voir §5 — avant cet audit, la calibration utilisait encore 7700 fixe, une incohérence interne corrigée).

### 3.3 Maintien dynamique (avec poids cible optionnel)
Sans poids cible : ajustement nul (kcal = TDEE). Avec un poids cible : zone morte de ±0,7 kg (aucun ajustement dans cette plage), puis correction douce de ±0,15 %/semaine au-delà — logique de stabilisation progressive, choix d'implémentation TOTUM.

---

## 4. Plancher calorique de sécurité (anti-RED-S)

**Fichier** : `profile.dart`, `minSafeKcalFor()`.

```
plancher = max( plancher absolu par sexe [1200 kcal ♀ / 1500 kcal ♂] , 90% du BMR )
```
**Source** : Mountjoy M, Sundgot-Borgen J, Burke L, et al. *The IOC consensus statement: beyond the Female Athlete Triad—Relative Energy Deficiency in Sport (RED-S).* Br J Sports Med. 2014;48(7):491-497, et sa mise à jour : Mountjoy M, et al. *IOC consensus statement on relative energy deficiency in sport (RED-S): 2018 update.* Br J Sports Med. 2018;52(11):687-697. Un déficit énergétique trop sévère et prolongé est associé à un dérèglement hormonal, une perte de densité osseuse et un ralentissement thyroïdien — ce plancher est un **garde-fou de sécurité absolu**, jamais contourné même en mode manuel (avertissement affiché, jamais un blocage total — voir `profile_screen.dart`). Les seuils absolus (1200/1500 kcal) reprennent les repères cliniques usuels (Academy of Nutrition and Dietetics / NIH Body Weight Planner).

---

## 5. Calibration adaptative — le moteur "façon MacroFactor"

**Fichier** : `lib/services/calibration_service.dart`.

### 5.1 Principe
Compare le poids **réellement mesuré** à l'évolution **attendue** compte tenu des calories réellement loguées, sur une fenêtre glissante de 20 jours, pour en déduire un TDEE empirique qui vient progressivement **remplacer** (jamais écraser brutalement) la formule anthropométrique du §2.

```
TDEE empirique = calories moyennes loguées − (changement de poids réel × densité énergétique) / durée
```
C'est l'équation d'équilibre énergétique de base (physiologie standard, pas une invention propriétaire) — la valeur ajoutée de la méthode est dans la **qualité du signal** injecté dans cette équation (§5.2-5.4), pas dans l'équation elle-même.

### 5.2 Poids : tendance lissée, jamais brut (correctif du 19/08/2026)
```
tendance[j] = tendance[j-1] + α × (poids_brut[j] − tendance[j-1])     [α = 0.1, composé sur l'écart réel en jours]
```
**Source du principe** : lissage exponentiel popularisé pour le suivi de poids par des outils comme *Trendweight* et *Happy Scale* (grand public, largement utilisés dans la communauté fitness/nutrition evidence-based) — filtre le bruit jour-à-jour (rétention d'eau, sel, horaire de pesée, cycle hormonal, glycogène) pour ne garder que la tendance de fond. **C'est le même principe qu'utilise MacroFactor** pour sa propre courbe de poids tendance (confirmé par leurs communications publiques sur leur méthode). **Avant l'audit du 19/08/2026, ce lissage existait dans le code mais n'était PAS utilisé par le moteur de calibration lui-même** (seulement pour l'affichage de la courbe) — c'est la cause racine du bug qui a déclenché cette revue complète (pic de rétention d'eau lu comme un vrai changement de poids, TDEE empirique aberrant). Corrigé : la calibration compare désormais des segments de poids **tendance**, jamais bruts.

### 5.3 Robustesse — moyenne de segments, pas 2 points isolés
Le changement de poids est mesuré entre la moyenne des 30% premiers jours et la moyenne des 30% derniers jours de la fenêtre (sur poids tendance) — jamais un simple point de départ/arrivée, pour amortir encore l'effet d'un jour atypique isolé.

### 5.4 Confiance croissante avec le volume de données
```
blend = clamp( (jours_pesés − 10) / (20 − 10) , 0.25 , 0.65 )
kcal_final = formule × (1 − blend) + (TDEE_empirique + ajustement_objectif) × blend
```
Minimum 10 jours pesés sur 20 pour activer la calibration (montée en confiance progressive), jamais plus de 65% de poids sur l'empirique — **la formule anthropométrique reste toujours un plancher de sécurité**, même à confiance maximale (choix délibéré : ne jamais laisser un signal 100% empirique, intrinsèquement bruité, dicter seul l'objectif).

### 5.5 Congés/pauses/week-ends — ne pollue pas le calcul
Les jours déclarés en pause (bouton "Je pars en pause") sont **totalement exclus** de l'analyse : ni les pesées prises pendant la pause (souvent gonflées par le sel/l'hydratation/les horaires de voyage), ni les calories de ces jours dans la moyenne "vie normale". La fenêtre d'analyse s'élargit automatiquement en arrière d'autant de jours que la pause en a "mangé" (plafonné à 60 jours), pour ne pas perdre des semaines de calibration à cause d'une coupure ponctuelle.

**Un cheat-meal NON déclaré comme pause (le cas normal, "2-3 kilos un week-end") n'est PAS exclu** — ce n'est pas une anomalie à retirer, c'est un vrai élément de la vie normale de l'utilisateur. Il est **absorbé par le lissage** du §5.2 : un pic isolé de +3kg sur un jour ne déplace la tendance que de 0,1×3 = 0,3kg ce jour-là (10% de son amplitude), puis la tendance redescend naturellement les jours suivants — jamais un saut permanent. Vérifié par un test dédié (`test/services/calibration_service_test.dart`).

### 5.6 Cohérence de tous les seuils (correctif du 19/08/2026)
Avant cet audit, 3 méthodes proches (`computeCalibration`, `expenditureHistory`, `expenditureReadiness`) recalculaient chacune leurs propres seuils de suffisance de données, avec un risque de dérive entre elles déjà matérialisé par le passé (retours d'Alex des 12-14/08/2026). Elles partagent désormais **une seule définition** : minimum 10 jours **distincts pesés** (pas un écart de dates) et 8 jours de journal renseigné, sur une fenêtre de 20 jours — identique partout, y compris pour l'indicateur d'avancement affiché à l'écran, qui exclut maintenant lui aussi les jours de pause (trou de cohérence supplémentaire trouvé et corrigé ce même jour).

---

## 6. Protéines

**Fichier** : `profile.dart`, `computeGoals()`.

```
g de protéines/kg de masse maigre, par palier d'activité DÉCLARÉ (jamais recalculé depuis le PAL calibré — voir §5, correctif du 19/08/2026) :
Sédentaire 1.6 · Léger 1.8 · Modéré 2.1 · Actif 2.4 · Très actif 2.6 · Extrême 2.8
+0.3 g/kg si objectif "Perte" · +0.15 g/kg si "Perte modérée" · +0.2 g/kg si 50 ans+
Borné entre 1.0×poids total et 2.5×poids total (garde-fou)
```
**Source** : Jäger R, Kerksick CM, Campbell BI, et al. *International Society of Sports Nutrition Position Stand: protein and exercise.* J Int Soc Sports Nutr. 2017;14:20 — recommandation ISSN de référence, 1.4-2.0 g/kg de poids total pour la population active générale, avec des besoins plus élevés en déficit calorique ou pour les sportifs entraînés en résistance. Affinage sur la masse maigre (plus précis que le poids total, notamment pour les profils avec %MG connu) et paliers différenciés par intensité : Iraki et al. 2021 (déjà cité §3.1) — recommandation jusqu'à 2.3-3.1 g/kg de LBM pour les sportifs entraînés en déficit prononcé, cohérent avec le haut de la table TOTUM (2.6-2.8 pour Très actif/Extrême + bonus déficit).

**Point de vigilance directement lié au bug du 19/08/2026** : cette table ne doit **jamais** être indexée sur un PAL recalculé depuis les calories (calibrées ou non) — le besoin protéique dépend de la fréquence/intensité d'entraînement, pas du niveau calorique. C'est exactement l'erreur corrigée cette session.

---

## 7. Lipides et glucides

**Fichier** : `profile.dart`, `computeGoals()`. Ordre de calcul : Calories → Protéines (§6) → répartition du **solde** entre lipides et glucides — principe documenté chez MacroFactor (audit du 09/08/2026), pas des pourcentages fixes des calories totales.

### 7.1 Plancher/plafond lipidique (sauf Kéto)
```
20% des calories totales ≤ lipides ≤ 35% des calories totales
```
**Source** : AMDR (Acceptable Macronutrient Distribution Range) — Institute of Medicine (National Academies of Sciences), *Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids*, 2005 : lipides 20-35%, glucides 45-65%, protéines 10-35% de l'énergie totale, pour l'adulte. **Point à vérifier** : le code source contient une note mentionnant "une révision 2024 toujours en vigueur" — je n'ai pas pu vérifier ni sourcer précisément cette révision 2024 lors de cet audit ; la valeur AMDR elle-même (20-35%) est bien établie depuis le rapport IOM 2005 cité ci-dessus et n'a pas connu de changement matériel connu à ma connaissance, mais la référence exacte à une "révision 2024" doit être vérifiée auprès d'une source primaire avant d'être citée publiquement comme telle.

### 7.2 Répartition du solde selon le style alimentaire
| Style | Fraction lipidique du solde non-protéique |
|---|---|
| Équilibré | 40% |
| Riche en glucides | 28% |
| Riche en lipides | 48% (plafonné à 35% des calories totales, jamais dépassé) |
| Kéto | glucides fixés à 30g, le reste en lipides |

**Recalibrage volontaire vs MacroFactor** : leur style "Balanced" pousse régulièrement les lipides au-delà de 35% des calories totales sur un profil-type (jusqu'à ~37%, constaté et signalé par Alex) — au-delà du plafond AMDR. Recalibré (Priorité 19, 10/08/2026) sur l'AMDR **et** sur la zone associée à la mortalité totale la plus basse dans une grande cohorte prospective : Dehghan M, Mente A, Zhang X, et al. *Associations of fats and carbohydrate intake with cardiovascular disease and mortality in 18 countries from five continents (PURE): a prospective cohort study.* Lancet. 2017;390(10107):2050-2062 (~135 000 participants, 18 pays) — zone ~30-35% lipides / ~50% glucides / ~15-20% protéines associée au risque le plus bas, invalidant aussi le dogme "low-fat" à l'autre extrême. Ni un excès de lipides (MacroFactor Balanced), ni un déficit dogmatique.

---

## 8. Fibres

**Fichier** : `profile.dart`, `computeGoals()`.
```
14g / 1000 kcal, borné entre 25g et 45g/jour
```
**Source** : dérivé de l'Apport Suffisant (AI) établi par l'Institute of Medicine (2005, même rapport que §7.1) — 25g/jour (femmes, base ~2000 kcal) et 38g/jour (hommes, base ~2900 kcal), d'où le ratio ~14g/1000kcal couramment utilisé en éducation nutritionnelle comme règle proportionnelle. **Précision utile** : l'ANSES (France) recommande, indépendamment, un apport ≥25-30g/jour pour la population générale adulte (*Actualisation des repères alimentaires du PNNS*, avis et rapport de l'Anses, 2016) — cohérent avec le plancher de 25g retenu ici, mais la règle "14g/1000kcal" elle-même provient de la littérature nord-américaine (IOM), pas d'un texte ANSES dédié — à corriger dans les commentaires de code qui l'attribuaient implicitement à l'ANSES.

---

## 9. Micronutriments (vue d'ensemble)

**Fichier** : `profile.dart`, `computeNutritionTargets()`. Détail complet des ~30 cibles (minéraux, vitamines, acides gras) dans le code — familles de sources :
- **ANSES** (France) — *Actualisation des repères alimentaires du PNNS* (avis et rapport, 2016) et références nutritionnelles associées : calcium, fer, iode, magnésium, potassium, sodium, zinc, vitamines B1/B2/B3 (exprimées en mg/MJ d'énergie consommée, pas en valeur fixe — corrigé lors de l'audit du 17/08/2026), vitamine K (exprimée en µg/kg de poids corporel, idem).
- **EFSA** (Union Européenne) — avis NDA Panel par nutriment (plusieurs publications 2013-2017 selon le nutriment) pour les valeurs de référence complémentaires.
- Ajustements par profil documentés dans le code : femmes <50 ans (fer relevé, cycle menstruel), 50 ans+ (calcium relevé, tous sexes depuis l'audit du 17/08/2026 — la perte de densité osseuse liée à l'âge touche aussi les hommes), 65 ans+ (vitamine E, sélénium relevés), haute activité (magnésium, potassium, zinc, EPA/DHA relevés).

**Aucun changement apporté à cette section lors de l'audit du 19/08/2026** — vérifiée ligne à ligne, cohérente avec les audits précédents (Priorité 71, 17/08/2026) déjà documentés dans `KNOWN_ISSUES.md`.

---

## 10. Ce qui reste une limite connue (honnêteté, pas dissimulé)

- **§2 (table PAL)** : la moins directement sourcée des formules — recalibrage empirique interne, pas une citation académique unique. À revoir si des écarts systématiques sont rapportés.
- **AMDR "révision 2024"** (§7.1) : référence non vérifiée lors de cet audit — la valeur (20-35%) est correcte et bien établie depuis 2005, la date de révision citée dans le code doit être confirmée avant d'être republiée comme fait vérifié.
- **Historisation partielle** (déjà documenté dans `KNOWN_ISSUES.md`) : sexe/poids/niveau d'activité ne sont pas historisés jour par jour dans les bilans passés — limitation acceptée, sans lien avec la fiabilité du calcul du jour.
- **Parité MacroFactor** : voir §0 — jamais une reproduction bit-à-bit, une méthode indépendante et sourcée visant le même principe scientifique.

---

## 11. Traçabilité

- Audit déclencheur (bug 3090→2530 kcal, 153g→115g protéines) : `tasks/2026-08-19_Audit calculs Profil - dépense énergétique et protéines.md`.
- Audit scientifique MacroFactor (09/08/2026) : `tasks/026-08-09_Audit scientifique de Macro factor.md`.
- Audit micronutriments (17/08/2026), historique : `docs/KNOWN_ISSUES.md`.
- Tests de non-régression : `test/services/profile_test.dart` (BMR, TDEE, macros, micronutriments, calibration), `test/services/calibration_service_test.dart` (lissage de tendance).
- Dernière vérification complète : 19/08/2026 — 51/51 tests passent, `flutter analyze` propre sur l'ensemble du projet.
