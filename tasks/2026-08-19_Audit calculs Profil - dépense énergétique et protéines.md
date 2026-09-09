# Audit — calculs Profil (dépense énergétique, protéines) et écran Dépense énergétique

Déclenché par un retour d'Alex (19/08/2026) : sur son propre profil (H, 41 ans, 181cm, 72,7kg, 10-13% MG, actif, maintien), l'objectif calorique est passé de **3090 kcal (formule pure) à 2530 kcal**, et les protéines de **~153g à 115g/j**, sans aucune explication à l'écran — plus un écran "Dépense énergétique" affichant un chiffre isolé (1478 kcal) sans graphique ni cohérence entre les deux compteurs de progression affichés ("10/10 j" vs "18/8 j").

**Verdict : bug réel, avec impact santé réel — pas une fausse alerte.** Cause racine identifiée, reproduite exactement (au kcal près), corrigée, testée. Détail ci-dessous.

---

## 1. Bug critique — protéines et calories entraînées vers le bas par une simple fluctuation de poids

### Reproduction exacte du cas d'Alex
Profil : H, 41 ans, 181cm, 72,7kg, MG 12% (plage 10-13%), palier **Actif**, objectif Maintien.

- BMR (Cunningham, LBM = 72,7 × 0,88 = 63,98kg) = 500 + 22×63,98 = **1907,5 kcal**
- TDEE formule (PAL Actif = 1,62) = 1907,5 × 1,62 = **3090,1 kcal** ✅ correspond exactement au "3090 théorique" rapporté.
- Protéines formule (palier Actif = 2,4 g/kg LBM, pas d'ajustement senior car <50 ans) = 2,4 × 63,98 = **153,5g** — c'est la valeur qu'Alex attendait.

Avec la calibration adaptative active (fenêtre minimale : "Écart entre 2 pesées 10/10j", `blendWeight` = 0,25 au minimum de la fenêtre) :
```
blendedKcal = 3090 × 0,75 + empiricalTdee × 0,25
```
En reconstruisant `empiricalTdee ≈ 850 kcal` à partir du blend observé : `3090×0,75 + 850×0,25 = 2317,5 + 212,5 = 2530,0` — **correspond exactement** au chiffre affiché à Alex.

### Cause racine (double)

**A) Le TDEE empirique lui-même est aberrant.** `CalibrationService.computeCalibration()` (et `expenditureHistory()`, qui alimente le graphique) déduisent le "vrai" métabolisme en comparant le poids RÉEL au début/fin d'une fenêtre de 10-20 jours aux calories réellement loguées (équation d'équilibre énergétique, ×7700 kcal/kg). Le graphique poids d'Alex (capture jointe) montre un pic net de rétention d'eau (~+1kg) en toute fin de fenêtre — un phénomène courant (sel, glycogène, cycle hormonal, horaire de pesée), **pas un vrai changement de masse grasse**. Le calcul utilisait le poids **BRUT** à ces deux extrémités, jamais lissé — un pic d'eau isolé de quelques jours suffit donc, une fois multiplié par 7700 kcal/kg, à faire chuter le TDEE calculé de plusieurs centaines de kcal. Le fichier contient pourtant déjà `emaTrend()` (lissage exponentiel, la même méthode qui donne la courbe "Poids tendance" affichée à l'utilisateur) — **jamais appelé** par le moteur de calibration lui-même.

**B) Cette valeur bruitée contaminait aussi les protéines.** `blendCalibratedTargets()` (`profile.dart`) reconstruisait un "palier d'activité équivalent" à partir du PAL calibré (`nearestActivityLevel(calibratedPal)`) et l'utilisait ensuite pour TOUT recalculer — y compris les protéines (g/kg de masse maigre) et plusieurs micronutriments. Avec un `blendedKcal` de 2530 kcal, le PAL calibré retombe à 1,326 → reclassé **"Léger"** (1,8 g/kg LBM) au lieu de "Actif" (2,4 g/kg LBM) → 1,8 × 63,98 = **115,2g**, exactement le chiffre observé. **Un simple pic d'eau reclassait silencieusement un utilisateur qui s'entraîne quotidiennement en "Léger"**, sans que rien ne s'affiche à l'écran pour l'expliquer — le profil affiché restait "Actif" partout, seul le calcul interne divergeait.

C'est scientifiquement incorrect dans son principe même : le besoin protéique dépend de la **fréquence/intensité d'entraînement** (littérature ISSN, Iraki et al. 2021 — le fondement déjà cité dans le code pour les paliers protéiques), pas du niveau calorique mesuré. Faire dépendre les protéines d'un TDEE bruité crée mécaniquement ce genre d'incident.

### Corrections appliquées
1. **`lib/services/calibration_service.dart`** — `computeCalibration()` et `expenditureHistory()` utilisent désormais le poids **tendance** (`emaTrend`, déjà existant dans ce même fichier) pour toute comparaison début/fin de fenêtre, jamais le poids brut. Un pic d'eau isolé ne peut plus, à lui seul, faire dévier fortement l'estimation.
2. **`lib/services/profile.dart`** (`blendCalibratedTargets`) — le PAL calibré ne pilote plus QUE les calories/TDEE (`activityPalOverride`). Le palier déclaré par l'utilisateur (`activity`, jamais modifié) reste désormais la SEULE source pour les protéines et les micronutriments dépendant du palier. Les calories peuvent toujours être affinées par la calibration (c'est le but), les protéines n'en dépendent plus.
3. Documentation du code mise à jour (`nearestActivityLevel`, `activityPalOverride`, `_effectivePal`) pour que cette séparation soit explicite et ne soit pas réintroduite par erreur plus tard.

### Test de non-régression
`test/services/profile_test.dart` — nouveau groupe reproduisant exactement ce scénario (calibration avec `empiricalTdee: 850`, `blendWeight: 0.25` sur un profil Actif) : vérifie que les calories peuvent baisser mais que les protéines restent celles du palier déclaré. **36/36 tests passent**, `flutter analyze` propre sur les 3 fichiers touchés.

---

## 2. Bug d'affichage — "1478 kcal" isolé, sans graphique, contredisant "arrive bientôt"

`ExpenditureScreen._summary()` s'affichait dès que `data.isNotEmpty` (≥1 point), alors que `ExpenditureChart` exige `data.length >= 2` pour tracer une vraie courbe et retombe sinon sur le message "arrive bientôt". Avec exactement 1 point disponible (cas fréquent en tout début de calibration, sur une fenêtre de données encore courte), l'écran affichait donc un chiffre nu et non expliqué **en même temps** que le message disant que l'estimation n'est pas encore prête — exactement la capture jointe. Ce point unique est lui-même la valeur la plus instable de toutes (calculée sur le minimum de données possible), ce qui explique aussi pourquoi il ne correspondait à rien de cohérent (1478 kcal, sans lien avec 2530 ni 3090).

**Correction** : le résumé chiffré n'apparaît plus que si le graphique apparaît aussi (même seuil `data.length >= 2` des deux côtés) — `lib/screens/expenditure_screen.dart`.

---

## 3. Bug d'affichage — "10/10 j" et "18/8 j" lus comme deux fractions incohérentes

Le libellé "18/8 j" (repas renseignés) est mathématiquement correct — `daysWithFoodLogged/minFoodDays`, un minimum, pas un total — mais se lit visuellement comme une fraction cassée (18 sur 8 ?) dès que le seuil est dépassé, ce qui est le cas normal pour un utilisateur assidu. Comparé côte à côte à "10/10 j" (qui, lui, plafonne toujours à son minimum), la juxtaposition donne une impression d'incohérence entre les deux compteurs.

**Correction** : nouveau format d'affichage (`_thresholdLabel`) — reste "x/y j" tant que x ≤ y (lecture en fraction naturelle), bascule sur "x j (min. y)" une fois le minimum dépassé. Appliqué aux deux barres, sur l'écran dédié et sur la vignette compacte du tableau de bord (même widget réutilisé).

---

## 4. Ce qui a été vérifié et n'est PAS un bug

- **Le socle scientifique des formules est solide et sourcé** (déjà documenté en commentaires dans `profile.dart`, vérifié ligne à ligne pendant cet audit) : Mifflin-St Jeor / Cunningham (BMR), Boer (LBM estimée), protéines par palier basées sur la littérature ISSN/Iraki et al. 2021, répartition lipides/glucides calée sur l'AMDR (Institute of Medicine) et la cohorte PURE (Dehghan et al. 2017, The Lancet), plancher calorique de sécurité anti-RED-S (consensus CIO, Mountjoy et al.), micronutriments sur les repères ANSES/EFSA. Rien de tout cela n'a été trouvé inventé ou incohérent — le problème était spécifiquement dans le **pont** entre "poids réel mesuré" et "objectifs recalculés" (la calibration adaptative), pas dans les formules elles-mêmes.
- **L'écart "10/10 j" vs "18/8 j"** vient de deux métriques légitimement différentes (l'une compare 2 pesées précises, l'autre compte des jours de journal sur une fenêtre glissante de 20 jours) — corrigé côté lisibilité (§3), pas un bug de calcul.
- **36 tests unitaires existants** couvrant BMR/TDEE/macros/micronutriments/bornes de sécurité passaient déjà avant cet audit et continuent de passer après — aucune régression introduite par les correctifs.

---

## 5. Reporté (hors périmètre de cet audit, non lié à la fiabilité des calculs)

- **Aspect visuel du curseur de pesée** ("ce n'est pas moderne") — remarque UX/esthétique, sans impact sur la justesse des chiffres. À traiter dans une session dédiée au design (`/design`), pas mêlé à un audit de fiabilité scientifique.
- **Fenêtre minimale de calibration (10 jours)** — le lissage EMA (§1) réduit fortement le risque qu'un pic d'eau isolé fausse le résultat, mais une fenêtre de 10 jours reste courte au regard de la littérature. Recommandation pour une prochaine itération : envisager d'élargir la fenêtre minimale ou d'abaisser le poids du blend (`blendWeight`) tant que la fenêtre reste proche du minimum — à valider avec toi avant de changer ce comportement, car cela retarde le moment où la calibration "prend le relais" de la formule, ce qui a aussi un coût UX.

---

## 6. Deuxième passe (même jour) — demande explicite d'Alex : "je ne veux pas de faille", parité de méthode avec MacroFactor, refonte UX "premiers jours"

Suite au retour d'Alex demandant un audit encore plus poussé ("tu te débrouilles pour trouver toutes les failles"), une deuxième passe a été faite sur tout le moteur de calibration, avec 3 nouvelles corrections trouvées (pas de simple "aucun problème trouvé" — cf. l'exigence explicite d'Alex de ne plus jamais entendre ça sans vérification poussée) :

1. **Trou de garde-fou "pause" supplémentaire trouvé** : `expenditureReadiness()` (l'indicateur d'avancement affiché à l'écran) n'excluait PAS les jours de pause déclarés, contrairement à `computeCalibration()` et `expenditureHistory()` juste à côté — un utilisateur pouvait donc voir "prêt" sur l'indicateur alors que le calcul réel (lui, excluant les pauses) concluait encore "pas assez de données". Corrigé : les 3 méthodes utilisent maintenant exactement les mêmes règles d'exclusion.
2. **Incohérence d'unité entre les 2 barres de progression** ("10/10 j" = écart de DATES entre 2 pesées vs "18/8 j" = COMPTE de jours sur 20 jours — 2 échelles différentes présentées comme comparables, cause du "ça ne fonctionne pas, on ne peut pas avoir une valeur à 18 jours et une autre à 10 jours" remonté par Alex). Corrigé : les deux métriques sont désormais un COMPTE de jours sur la MÊME fenêtre de 20 jours (`_minWeighDays` remplace `_minSpanDays`) — mathématiquement, 10 jours distincts pesés sur 20 implique déjà un écart de dates d'au moins 9 jours, donc l'ancien critère reste couvert de fait.
3. **Densité énergétique incohérente entre 2 parties du moteur** : les objectifs (§3.2 du document de méthodologie) utilisaient déjà un modèle de densité énergétique variable (7000-8400 kcal/kg selon le rythme, Hall 2008) — mais la calibration adaptative utilisait encore une constante fixe de 7700 kcal/kg pour convertir un changement de poids réel en TDEE empirique. Recalibrage à la baisse ou à la hausse traité différemment selon l'endroit du moteur = incohérence interne. Corrigé : `effectiveEnergyDensityKcalPerKg()` (rendue publique dans `profile.dart`) est maintenant utilisée partout, y compris par la calibration.

**Refonte UX "premiers jours"** (`expenditure_screen.dart`) :
- Message d'attente dynamique : "Encore X jours de suivi" (compte à rebours concret, dérivé des mêmes compteurs) au lieu du texte statique "arrive bientôt" qui ne disait rien du temps réellement restant.
- Écran dédié : 2 anneaux "donut" (même composant visuel que le reste de l'onglet Profil — `PieChart` + `TotumProgress`, jamais un nouveau vocabulaire visuel) remplacent les 2 barres fines pour un premier écran plus immédiatement lisible ; la carte compacte du tableau de bord garde les barres fines (contrainte de hauteur) mais corrige leur couleur.
- Bug de charte graphique trouvé au passage : les barres de progression basculaient en dur sur `TotumColors.positive` (vert) une fois complètes — la charte du fichier `totum_style.dart` réserve pourtant explicitement positive/negative à la direction d'un delta chiffré, jamais à un état "terminé" (règle 5 du fichier). Corrigé : utilisation de la rampe unique `TotumProgress.forFraction`, comme partout ailleurs dans l'app.
- Libellés fr/en mis à jour ("Jours pesés" au lieu d'"Écart entre 2 pesées").

**Document de synthèse scientifique complet** (demande explicite d'Alex — "je veux un document de synthèse... comment on calcule les objectifs, comment on calcule les macros... avec les références scientifiques, les dates, les méta-analyses") : `docs/METHODOLOGIE_SCIENTIFIQUE_CALCULS.md`, nouveau fichier vivant à tenir à jour, couvrant TOUTES les formules du moteur (BMR, TDEE, ajustement objectif, calibration adaptative, protéines, lipides/glucides, fibres, micronutriments) avec citation précise (auteurs, année, revue) pour chacune, plus une section §0 qui clarifie honnêtement ce qu'une "parité avec MacroFactor" peut et ne peut pas vouloir dire (leur algorithme exact n'est pas public — nécessaire pour ne jamais prétendre une reproduction qui n'est matériellement pas vérifiable). Inclut aussi une section §10 listant les limites connues non dissimulées (ex. la table de paliers PAL est un recalibrage interne, pas une citation académique unique).

**Nouveaux tests de non-régression** : `test/services/calibration_service_test.dart` (nouveau fichier — verrouille le comportement du lissage de tendance face à un pic isolé façon "cheat meal", et la composition de l'alpha sur un écart de plusieurs jours), plus 2 tests supplémentaires dans `profile_test.dart` sur `effectiveEnergyDensityKcalPerKg`. **51/51 tests passent**, `flutter analyze` propre sur l'ensemble du projet (pas seulement les fichiers touchés).

## 8. Troisième passe (même jour, après test réel sur appareil d'Alex) — bug pause + incohérence "presque prêt" malgré 10/10

Alex a désinstallé/réinstallé l'app et testé en conditions réelles (APK release). Deux nouveaux problèmes réels remontés, avec captures d'écran à l'appui :

1. **Objectif calorique 3090→2660 kcal confirmé cohérent** (calcul à la main : blend formule/empirique conforme à la méthode documentée) — aucune anomalie ici.
2. **"Presque prêt" affiché malgré 10/10 jours pesés et 17 jours de repas (min. 8)** — semblait contredire des compteurs déjà pleins. **Cause identifiée, pas un bug de calcul mais un besoin structurel non expliqué** : l'objectif calorique lui-même ne nécessite qu'**une seule** fenêtre d'analyse (satisfaite dès 10/10) pour être affiné, mais le **graphique** (la ligne tracée dans le temps) a besoin d'**au moins 2 fenêtres glissantes indépendantes** pour tracer une ligne à 2 points — donc structurellement toujours au moins 1 jour de suivi de plus que le seuil de calibration lui-même. Avant ce correctif, le message ne faisait pas cette distinction et semblait donc se contredire. **Corrigé** : le panneau d'attente reçoit maintenant le VRAI nombre de points déjà produits par `expenditureHistory()` (`chartPointsSoFar`, transmis directement par `ExpenditureChart`, jamais recalculé indépendamment) et affiche un message dédié — "Ton objectif calorique est déjà affiné avec tes résultats réels — le graphique d'évolution, lui, a besoin d'encore 1 jour de suivi" — au lieu du message générique qui laissait croire à une contradiction.
3. **Bug réel et sérieux trouvé** : activer le bouton pause puis le désactiver AUSSITÔT (quelques secondes après, même jour) a fait perdre 1 jour de suivi (10→9 pesées, 17→16 repas) et a fait retomber l'objectif calorique de 2660 (calibré) à 3090 (formule pure) — **de façon permanente et invisible**, sans aucun moyen pour l'utilisateur de comprendre ou d'annuler. Cause : `PauseService.endActivePause()` clôturait la pause avec `end = aujourd'hui` même si `start = aujourd'hui` (pause de durée quasi nulle) — `PausePeriod.contains()` compare des DATES, pas des horodatages précis, donc cette journée entière restait exclue de toute calibration future pour toujours, alors qu'aucune vraie pause n'a eu lieu. **Corrigé** : annuler une pause commencée le jour même **supprime** entièrement la période (local + Supabase) au lieu de la clôturer — seule une pause ayant réellement duré au moins un jour calendaire complet reste une période d'exclusion.

**Capture d'écran demandée par Alex du graphique fini** : générée via un test Flutter dédié (`test/screens/expenditure_chart_screenshot_test.dart`) qui rend le VRAI composant `ExpenditureChart` (celui de production, aucune maquette) avec des données synthétiques réalistes (convergence 3090→~2660 kcal sur 45 jours, bande d'incertitude qui se resserre avec le volume de données) — fichier généré : `build/expenditure_chart_demo.png` (non versionné, regénérable à tout moment en relançant ce test). Deux obstacles techniques rencontrés et résolus au passage : `pumpAndSettle()` bouclait à l'infini (animation interne de fl_chart qui ne converge jamais dans le binding de test — remplacé par une attente bornée) ; le texte s'affichait en blocs gris (aucune police système dans l'environnement de test headless — corrigé en chargeant Roboto directement depuis le SDK Flutter local).

**52/52 tests passent**, `flutter analyze` propre (2 infos de style sans rapport).

## 10. Quatrième passe (même jour) — ergonomie Profil/Compte/Journal, bug barres macro, respiration

Nouvelle série de retours après test réel (web app) :

1. **Barres/anneaux macro passant en rouge "dépassé" à exactement 0 d'écart** (ex. protéines pile à la cible) : comparaisons `value > target` sur des `double` bruts, sensibles au bruit de calcul en virgule flottante. Corrigé aux 4 endroits identifiés (`journal_screen.dart` `_MacroBarRow`, `bilan_screen.dart`, `profile_screen.dart` ring kcal + rings macro) — comparaison désormais sur les valeurs ARRONDIES, celles réellement affichées à l'utilisateur.
2. **Carte "Aujourd'hui" — répartition métabolisme de base / mouvement** : ajout d'une mini-barre à 2 segments + légende ("Métabolisme de base {bmr} · Mouvement +{reste}") sous "Objectif de base", pour que l'affinement par la calibration soit immédiatement compréhensible. BMR recalculé via `computeBmr()` (jamais affecté par la calibration — formule Mifflin-St Jeor/Cunningham) ; "Mouvement" = solde de l'objectif déjà calibré (`_kcal - bmr`), donc automatiquement cohérent sans dupliquer la logique de blend. Hauteur du carrousel KPI portée de 220 à 246px pour l'accueillir.
3. **Vignette compacte "Dépense énergétique" sans interaction tactile** (contrairement à la vignette Poids) : `ExpenditureChart` utilise maintenant le même tooltip flottant natif que `WeightTrendChart` en mode compact (`showDetailCard: false`), la fiche persistante restant réservée à l'écran dédié.
4. **Compte — carte Abonnement non cliquable** : les 3 états (Premium à vie / abonnement actif / essai) sont désormais entièrement cliquables (`TotumCard.onTap`), menant respectivement à une confirmation informative, la gestion Play Store/Stripe, ou l'achat.
5. **À propos — mention nominative retirée** : remplacée par un bouton d'info (icône "i") à côté du titre "TOTUM", dont le contenu ne mentionne ni nom ni qualification — uniquement la valeur ajoutée de l'app et la rigueur scientifique des calculs/de la base alimentaire.
6. **Troncature au milieu d'un mot dans les listes d'aliments** : nouvelle fonction `truncateAtWordBoundary()` (journal_screen.dart) pré-tronque le nom à la dernière espace avant ~60 caractères plutôt que de laisser `TextOverflow.ellipsis` couper au niveau du caractère — appliquée aux 3 listes concernées (recherche recette, composition de repas, liste principale Journal).
7. **Respiration — écran figé au démarrage sur web** : `BreathAudioEngine` expose désormais un `_sessionReadyFuture` partagé — l'animation démarre immédiatement (`_runPhase()`/`_runRapidBreathing()` non bloqués), l'initialisation audio (potentiellement longue sur web — WASM) tourne en parallèle ; `startPhase()`/`playTick()`/`stopSession()` attendent ce Future en interne, donc le tout premier carillon n'est plus jamais perdu (préserve le correctif du 14/08/2026) malgré le découplage. Garde-fou ajouté contre une course dispose()/init() concurrente (`_disposed`).
8. **Hyperventilation — bouton "Arrêter" manquant** : le "X" de l'AppBar (`_exitEarly`, déjà fonctionnellement correct) est peu visible comparé au bouton "Arrêter" explicite des autres techniques — ajouté aux 3 phases actives (respiration rapide, rétention, récupération), même composant visuel, réutilise `_exitEarly`.

**Confirmation Supabase** (question d'Alex) : l'export CSV fourni confirme que les colonnes `image_url`/`nova_score` de `custom_foods` existent et sont peuplées pour les scans récents — migration bien appliquée en production, rien à corriger. Les scans plus anciens (avant migration) n'ont simplement pas de photo rétroactivement.

**52/52 tests passent**, `flutter analyze` propre sur l'ensemble du projet.

## 9. Comment revérifier concrètement

1. `flutter test` (suite complète) → 52/52, dont les régressions protéines/calibration, lissage de tendance, et le générateur de capture d'écran du graphique.
2. `flutter analyze` (projet entier) → aucune erreur.
3. Dans l'app : recharger l'écran Profil et l'écran Dépense énergétique — les protéines doivent revenir à ~153g pour ce profil précis dès la prochaine sauvegarde/recalcul, indépendamment de ce que fait la calibration sur les calories ; le chiffre "kcal" isolé sans graphique ne doit plus apparaître ; les 2 compteurs de progression doivent afficher la même unité (jours sur 20) et ne plus jamais se lire comme une fraction cassée ; l'écran dédié affiche désormais 2 anneaux + un message qui distingue "objectif déjà affiné" de "graphique pas encore prêt" ; activer puis désactiver la pause le même jour ne doit plus faire perdre de jour de suivi.
4. Lire `docs/METHODOLOGIE_SCIENTIFIQUE_CALCULS.md` pour la justification scientifique complète, formule par formule.
5. Voir `build/expenditure_chart_demo.png` (regénérable via `flutter test test/screens/expenditure_chart_screenshot_test.dart`) pour un exemple concret du graphique fini.
