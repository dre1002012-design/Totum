Oui. J’ai fait l’audit en partant de la documentation technique actuelle de MacroFactor et en la confrontant à la littérature scientifique sur le BMR/RMR, le TDEE, la thermogenèse et les limites des calculateurs classiques.

**La conclusion importante est la suivante : MacroFactor n’est pas particulièrement révolutionnaire parce qu’il aurait une formule de BMR secrète. Sa vraie différence est qu’il transforme progressivement le problème d’une *prédiction* du TDEE en un problème d’*estimation personnalisée à partir de données observées*.**

Autrement dit : les autres applications demandent souvent *« combien devrais-tu brûler ? »* ; MacroFactor cherche plutôt à répondre à *« combien sembles-tu réellement brûler, compte tenu de ce que tu manges et de ce que fait ton poids ? »*.

---

# 1. Le problème fondamental : BMR ≠ TDEE

Il faut d'abord distinguer plusieurs niveaux.

![Image](https://images.openai.com/static-rsc-4/71xD2nSnHvr86y3R-so4wTQ02xRtRUPKCl5oftdaMzfFoP8idw0Vc0QaNdlnmG5ZQVPbTmwJpfRH8mOlxqBRJFMx9TFqZ9uG13s_LmuqcADyKwRblwQdhHKJ0U-6eRwbIG1JA3C-nfzxZY7As4KlAZgIkm0UPPqQKa0B8hY17Y_7R7kXKUuH1seQ_AW5oQRj?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/xdBYFzUjG1X8POvKSX8Im34Ac5SFGdtVNrkZbgRniK3NkijrHETYOZmqr7EP2aPHGTtDp92nIM9Jrq8zIcwnbkkkckcTlX4NRIMI_RKwU9Pjv9ZSPkP9SqwSot3ZmSfcy8CjAa4C9sjZu1Iy6DNfKXdoSY-SVEiS28Yp_wLD_ybDg_t8hs0eMVxseX1Ze8Di?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/0ewlLwAOgkYxxdNMnw9EnHNlADeXAsLQ8msZnlKxTW8_qlFreZJKjRdTOCHkAaJ1u42vz5cVjgEh-tJ4v46Ib0e3tjTBF4iWQViZ_inPFQ6A9qpX7aW-cH7xJOtO5nsViaGGlyTuXfbv5XPIp9lJcxltG5Mt9GN1EQQFTYbbsS7aYlMZIl4xNjISzQex9ur3?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/MYQoLeIvWGJ5Q_lpBOsiToiYcLUmMcajNGqXK-6K7-NI9xoNV-tHx6TAOMLzlKPBj1kUn5hbyq14FSO5Vv7Y_IyPWXe8zFykeHqvOcezLmIpkMMt-ZZOJ2ep_lFIYY_qPHEOcnvHE68LSd8uHjNkkYDKzSai3Yx_ewuie8yGauETVXLqA2Ph4kd_7uTMuYEl?purpose=fullsize)

Le **TDEE** (*Total Daily Energy Expenditure*) est la dépense énergétique totale quotidienne :

**TDEE = BMR/RMR + TEF + EAT + NEAT**

où :

* **BMR/RMR** = métabolisme basal/de repos ;
* **TEF** = thermic effect of food, énergie dépensée pour digérer et métaboliser les aliments ;
* **EAT** = exercice volontaire/structuré ;
* **NEAT** = activité non sportive : marcher, travailler debout, bouger, faire le ménage, gesticuler, etc.

MacroFactor donne comme ordre de grandeur général environ **70 % BMR, 10 % TEF, 5 % EAT et 15 % NEAT**, mais ces proportions peuvent énormément varier d'une personne à l'autre. ([MacroFactor Help][1])

Et c'est précisément là que les calculateurs classiques commencent à avoir un problème.

---

# 2. Comment fonctionne normalement un calculateur TDEE

Prenons une personne hypothétique :

* homme
* 80 kg
* 180 cm
* 35 ans

Un calculateur classique fait grosso modo :

### Étape 1 — estimer le BMR

Avec une équation comme Mifflin-St Jeor, Harris-Benedict ou Cunningham.

Puis :

### Étape 2 — multiplier par un facteur d'activité

Par exemple :

**BMR × 1,5 = TDEE**

Et voilà.

Le problème est que **deux erreurs sont multipliées l'une par l'autre** :

1. le BMR est déjà une estimation ;
2. le facteur d'activité est encore une estimation.

La littérature montre effectivement que les équations de RMR/BMR peuvent présenter des erreurs individuelles importantes. Une étude de validation rapporte par exemple des limites d'accord de plusieurs centaines de kcal/jour selon l'équation et les individus. ([PubMed][2])

MacroFactor estime lui-même que l'erreur typique des équations de BMR est de l'ordre de **100–200 kcal/jour**, avec des erreurs individuelles pouvant être beaucoup plus importantes ; une fois le facteur d'activité ajouté, l'erreur du TDEE peut facilement devenir de plusieurs centaines de kcal. ([MacroFactor Help][3])

Et il y a un problème encore plus subtil :

> **Personne ne sait réellement dans quelle case “sédentaire / légèrement actif / modérément actif / très actif” il faut placer un individu.**

Deux personnes ayant exactement le même BMR théorique peuvent avoir des TDEE très différents.

---

# 3. Ce que MacroFactor fait de fondamentalement différent

Le cœur du système peut être résumé par une équation extrêmement simple :

**Calories ingérées − énergie stockée = énergie dépensée**

ou :

**TDEE ≈ Calories ingérées − variation des réserves énergétiques**

C'est une application pratique de la conservation de l'énergie.

MacroFactor observe donc deux choses :

### A. Ce que tu manges

Par exemple :

**2 650 kcal/jour**

### B. Ce que fait ton poids sur la durée

Supposons que ton poids diminue à une vitesse correspondant approximativement à :

**−350 kcal/jour**

Alors :

**TDEE ≈ 2 650 + 350**

soit :

**≈ 3 000 kcal/jour**

C'est extrêmement puissant parce qu'on n'a plus besoin de savoir précisément :

* combien tu as brûlé en marchant ;
* combien ton entraînement a brûlé ;
* combien ton NEAT représente ;
* combien ton travail physique représente ;
* combien ton métabolisme est supérieur ou inférieur à la moyenne ;
* combien ton Apple Watch estime que tu as brûlé.

**Tout cela est implicitement contenu dans le résultat final observé.**

MacroFactor décrit explicitement son calcul comme une estimation déterministe basée sur **l'apport énergétique et la variation de la tendance de poids**. ([MacroFactor Help][4])

---

# 4. C'est probablement LA caractéristique la plus importante de MacroFactor

Imaginons deux personnes.

### Personne A

Calculateur classique :

> BMR = 1 700
> facteur activité = 1,5
> TDEE = 2 550

Mais son vrai TDEE est 2 850.

### Personne B

Même calcul :

> TDEE estimé = 2 550

Mais son vrai TDEE est 2 300.

Le calculateur donne **exactement la même réponse**.

MacroFactor, lui, va observer :

### Personne A

Elle mange 2 550 kcal.

Son poids diminue rapidement.

L'algorithme comprend :

> « 2 550 kcal sont probablement beaucoup plus bas que son véritable TDEE. »

Son estimation va monter.

### Personne B

Elle mange 2 550 kcal.

Son poids ne bouge pratiquement pas.

L'algorithme comprend :

> « Son TDEE est probablement proche de 2 550. »

Et il converge vers cette réalité.

---

# 5. Le génie n'est donc pas le BMR

C'est un point très important.

**MacroFactor n'a pas besoin de connaître parfaitement ton BMR.**

Il utilise effectivement une estimation initiale basée sur la formule de Cunningham et des multiplicateurs d'activité personnalisés. Mais MacroFactor reconnaît lui-même que cette estimation initiale peut être très imparfaite : l'erreur individuelle peut atteindre **400–500 kcal ou davantage**. ([MacroFactor Help][3])

Et ce n'est pas considéré comme un échec.

C'est volontaire.

L'idée est :

> **Le jour 1, je fais une bonne estimation.
> Les semaines suivantes, je remplace progressivement cette estimation par des observations de ta physiologie.**

C'est une différence conceptuelle majeure.

---

# 6. Pourquoi Cunningham est utilisé au départ

Cunningham est particulièrement intéressant parce qu'il donne davantage de poids à la **masse maigre**.

La formulation historique est :

**BMR ≈ 500 + 22 × masse maigre (kg)**

La recherche originale de Cunningham trouvait que la masse maigre était le prédicteur individuel le plus important du métabolisme basal dans son analyse. ([PubMed][5])

Cela a du sens physiologiquement :

un kilogramme de tissu adipeux et un kilogramme de tissu maigre ne consomment pas la même quantité d'énergie au repos.

Et Cunningham reste une équation intéressante chez les populations sportives. Une étude chez des athlètes récréatifs a notamment trouvé de bonnes performances de Cunningham par rapport à d'autres équations. ([PubMed][6])

Mais il faut absolument nuancer :

**Cunningham n'est pas “la formule parfaite”.**

Des travaux plus récents montrent que même les équations de RMR basées sur la composition corporelle peuvent avoir des erreurs importantes chez certains individus. ([PubMed][7])

Et c'est justement pourquoi le système adaptatif de MacroFactor est plus intéressant que la formule initiale.

---

# 7. La véritable innovation : le poids est utilisé comme signal énergétique

C'est probablement le deuxième élément fondamental.

Le poids corporel quotidien est extrêmement bruité.

Tu peux avoir :

**Lundi : 80,0 kg**
**Mardi : 80,8 kg**
**Mercredi : 79,7 kg**
**Jeudi : 80,4 kg**

Cela ne signifie évidemment pas que tu as gagné puis perdu plusieurs kilos de graisse.

Les variations viennent notamment de :

* eau ;
* glycogène ;
* sodium ;
* contenu intestinal ;
* inflammation ;
* entraînement ;
* hormones ;
* quantité de glucides ;
* etc.

MacroFactor ne cherche donc pas à interpréter naïvement chaque pesée.

Il utilise une **Weight Trend**, une tendance de poids qui filtre une partie du bruit à court terme. ([MacroFactor Help][8])

---

# 8. Pourquoi c'est extrêmement important

Imagine :

Tu fais un gros repas salé samedi.

Dimanche :

**+1,2 kg**

Un calculateur naïf pourrait interpréter :

> « Tu as pris du poids → il faut réduire les calories. »

MacroFactor cherche au contraire la tendance.

Si les jours suivants reviennent à la normale :

**80,0 → 80,2 → 80,1 → 80,0**

il comprend que le +1,2 kg était essentiellement du bruit hydrique.

C'est beaucoup plus rationnel.

---

# 9. Le calcul ne regarde donc pas simplement “ton poids”

Il regarde essentiellement :

### 1. Ton apport énergétique

**Calories IN**

### 2. La tendance de ton poids

**variation du poids réel à moyen terme**

### 3. La vitesse de cette variation

**rate of weight change**

MacroFactor indique que son calcul de *change rate* utilise la variation de la tendance de poids sur environ **20 jours**, exprimée sous forme hebdomadaire, afin d'estimer le déficit/surplus énergétique. ([MacroFactor Help][9])

Cela permet de transformer :

> « Je perds 400 g/semaine »

en :

> « Mon organisme semble actuellement fonctionner avec un déficit énergétique moyen d'environ X kcal/jour. »

Puis :

> **TDEE = calories consommées + déficit estimé**

---

# 10. Et il y a un détail particulièrement intelligent : la composition énergétique du poids perdu/gagné

C'est une subtilité importante.

**1 kg de variation corporelle n'est pas toujours 1 kg de graisse.**

MacroFactor ne traite donc pas naïvement :

> 1 kg = 7 700 kcal.

Son modèle tient compte du fait que le poids perdu ou gagné peut avoir des compositions énergétiques différentes : graisse, tissu maigre, eau, etc.

La documentation précise notamment que le modèle tient compte de la densité énergétique différente du tissu adipeux et du tissu maigre et ajuste ses hypothèses selon la vitesse de perte ou de prise de poids. ([MacroFactor Help][4])

C'est une différence importante par rapport au simpliste :

**1 kg = 7 700 kcal**

qui est souvent utilisé comme approximation pédagogique.

---

# 11. Pourquoi 1 kg ≠ toujours 7 700 kcal

Prenons deux scénarios.

### Scénario A — perte très rapide

Une personne perd énormément de poids rapidement.

Une partie peut provenir de :

* glycogène ;
* eau ;
* contenu intestinal ;
* masse maigre ;
* graisse.

Le déficit énergétique réellement associé à cette variation de poids n'est donc pas nécessairement :

**1 kg × 7 700 = 7 700 kcal**

### Scénario B — perte lente

Une personne perd lentement du poids sur plusieurs mois.

Une plus grande proportion de cette perte peut correspondre à de la graisse.

Le bilan énergétique implicite est alors différent.

C'est pourquoi les modèles sérieux de dynamique du poids sont plus complexes qu'une simple règle linéaire.

---

# 12. MacroFactor fait donc quelque chose de très intéressant : il mesure indirectement le TDEE

Et c'est là qu'on arrive au cœur du système.

Il n'a pas besoin de dire :

> « Ton entraînement de mardi a brûlé 437 kcal. »

Cette information est en réalité assez peu importante pour son objectif.

Il veut savoir :

> **« Combien d'énergie as-tu dépensé au total ? »**

Si tu as :

* marché 12 000 pas ;
* fait 1 h de musculation ;
* travaillé debout ;
* beaucoup bougé inconsciemment ;
* mangé davantage de protéines ;
* dépensé plus en digestion ;
* etc.

tout cela est déjà reflété dans le TDEE final.

---

# 13. C'est pourquoi MacroFactor refuse volontairement les calories des montres

C'est probablement l'une des décisions les plus contre-intuitives de l'application.

MacroFactor **n'utilise pas les calories brûlées estimées par les wearables pour calculer son expenditure**. ([MacroFactor Help][10])

Pourquoi ?

Parce que tu introduirais une deuxième estimation dans une estimation.

Par exemple :

La montre dit :

> « Tu as brûlé 650 kcal avec ton entraînement. »

Mais supposons qu'en réalité ce soit 430.

Tu donnes alors à l'algorithme une donnée erronée.

Et cette erreur peut ensuite contaminer les recommandations alimentaires.

MacroFactor préfère :

> **observer directement les conséquences de ton activité sur ton bilan énergétique.**

C'est conceptuellement beaucoup plus robuste.

---

# 14. Le NEAT est ainsi pris en compte sans être explicitement calculé

C'est très important.

Le NEAT est extrêmement variable.

Deux individus peuvent :

* avoir le même BMR ;
* faire exactement trois séances de sport ;
* manger exactement 2 500 kcal ;

mais l'un peut avoir un TDEE de 2 700 et l'autre de 3 100.

Pourquoi ?

Parce que le premier :

> travaille assis + prend la voiture + marche peu.

Le second :

> travaille debout + marche beaucoup + bouge énormément.

Le facteur d'activité classique a du mal à représenter cela.

MacroFactor n'a pas besoin de connaître séparément le NEAT.

Il voit simplement :

> « Avec 2 500 kcal, cette personne perd 500 kcal/jour. »

Donc :

**TDEE ≈ 3 000 kcal**

Le NEAT est implicitement inclus.

---

# 15. Et cela permet aussi de capturer l'adaptation métabolique

C'est encore plus intéressant.

Pendant une perte de poids, la dépense énergétique peut diminuer.

Il existe plusieurs mécanismes :

* poids corporel plus faible ;
* moins de masse maigre ;
* diminution du coût de déplacement ;
* diminution de certains mouvements spontanés ;
* changements hormonaux ;
* adaptations de la dépense énergétique ;
* etc.

La littérature décrit ce phénomène sous le terme de **thermogenèse adaptative**, même si son ampleur et son importance clinique varient selon les individus et les protocoles. ([PubMed][11])

Un calculateur classique pourrait continuer à croire :

> « Ton TDEE est 2 700 parce que tu fais du sport 4 fois/semaine. »

MacroFactor observe :

> « Il mange maintenant 2 300 kcal mais son poids ne baisse plus comme avant. »

Donc son estimation de TDEE diminue.

**Il n'a pas besoin de modéliser parfaitement pourquoi.**

Il mesure le résultat net.

---

# 16. C'est une différence philosophique majeure

### Approche classique

**Physiologie théorique → estimation du TDEE → calories recommandées**

### MacroFactor

**Apport réel + réponse réelle du poids → estimation du TDEE → calories recommandées**

C'est une boucle de rétroaction.

On pourrait la représenter comme ceci :

**Calories consommées**
↓
**Organisme**
↓
**Variation du poids**
↓
**Algorithme**
↓
**TDEE estimé**
↓
**Nouvelle cible calorique**
↓
**Nouvelle réponse du poids**
↓
**Nouvelle correction**

C'est presque un système de contrôle automatique.

---

# 17. Et c'est probablement là que MacroFactor est supérieur à la majorité des applications

Je nuancerais cependant fortement l'affirmation :

> « MacroFactor est scientifiquement beaucoup plus fiable que toutes les applications concurrentes. »

On ne peut pas démontrer cela universellement sans essais comparatifs indépendants suffisamment solides.

En revanche, on peut dire quelque chose de beaucoup plus précis :

> **Son architecture de calcul possède une propriété particulièrement intéressante : elle est personnalisée à partir de données longitudinales observées plutôt que de dépendre principalement d'une estimation statique du TDEE.**

Et ça, scientifiquement, est très défendable.

---

# 18. Pourquoi cette approche est supérieure à un facteur d'activité

Prenons deux individus ayant :

**BMR = 1 700 kcal**

Un calculateur dit :

**× 1,5 = 2 550 kcal**

Mais :

### Individu A

TDEE réel :

**2 950**

### Individu B

TDEE réel :

**2 250**

L'erreur est :

### A

**−400 kcal**

### B

**+300 kcal**

Et cela suffit largement à faire échouer une stratégie de perte de poids.

À **300 kcal/jour**, l'écart représente environ :

**2 100 kcal/semaine**

soit une différence potentielle considérable sur plusieurs semaines.

---

# 19. MacroFactor peut progressivement découvrir ces différences individuelles

Après suffisamment de données :

### Personne A

2 950 kcal TDEE

### Personne B

2 250 kcal TDEE

Et ces valeurs ne viennent plus principalement d'une catégorie :

> « actif / très actif »

Elles viennent de la relation :

**apport énergétique ↔ évolution du poids**

C'est une personnalisation beaucoup plus profonde.

---

# 20. Il y a cependant une condition absolument essentielle

Et c'est le talon d'Achille du système :

## Il faut que les données soient bonnes.

MacroFactor a besoin de deux choses :

### Nutrition

Il faut enregistrer correctement ce que tu manges.

### Poids

Il faut fournir suffisamment de mesures.

MacroFactor recommande idéalement des pesées quotidiennes, dans des conditions similaires, et indique qu'au minimum une pesée hebdomadaire permet au système de continuer à fonctionner. ([MacroFactor Help][12])

Pour la nutrition, une fréquence régulière est également nécessaire ; la documentation indique actuellement qu'une fréquence minimale de plusieurs jours par semaine est nécessaire pour que l'algorithme puisse continuer ses mises à jour, avec une utilisation quotidienne comme idéal. ([MacroFactor Help][13])

---

# 21. C'est donc un système “garbage in → garbage out”

Si tu manges réellement :

**2 500 kcal**

mais que tu enregistres :

**2 000 kcal**

MacroFactor va observer :

> 2 000 kcal → poids stable

et peut conclure :

> TDEE ≈ 2 000

alors que ton vrai TDEE est peut-être 2 500.

L'algorithme ne peut pas savoir que tu as oublié :

* l'huile ;
* les sauces ;
* les boissons ;
* les grignotages ;
* les portions ;
* les repas au restaurant.

C'est fondamental.

**MacroFactor n'est pas un calorimètre magique.**

Il est très puissant lorsque les données d'entrée sont raisonnablement fidèles.

---

# 22. Mais il possède une propriété très intéressante : l'adhérence n'a pas besoin d'être parfaite

MacroFactor appelle cela une approche **“adherence-neutral”**.

L'idée est subtile.

Supposons que ta cible soit :

**2 200 kcal**

mais que tu manges finalement :

**2 350 kcal**

Si tu enregistres réellement 2 350 kcal et que ton poids répond en conséquence, l'algorithme peut recalculer ton TDEE et adapter les recommandations.

Il ne suppose pas :

> « L'utilisateur a forcément mangé exactement ce que je lui avais prescrit. »

Il regarde ce qui s'est réellement passé. ([MacroFactor Help][4])

C'est extrêmement utile dans la vraie vie.

---

# 23. Le système est également “prospectif”

MacroFactor ne se contente pas de calculer :

> « Tu as perdu du poids. »

Il transforme cette information en nouvelle prescription.

Supposons :

### TDEE observé

**2 800 kcal**

### Objectif

Perdre environ **0,5 kg/semaine**

Le système détermine alors un déficit correspondant à l'objectif et peut proposer une nouvelle cible énergétique.

Puis il observe la réponse.

Si la perte est trop lente :

→ ajustement.

Si elle est trop rapide :

→ ajustement.

Si elle correspond :

→ maintien approximatif.

C'est donc une boucle :

**mesure → estimation → prescription → mesure → correction**

---

# 24. C'est particulièrement puissant pour la prise de poids

C'est souvent là que les applications basiques sont encore moins intéressantes.

Pour une prise de masse :

Tu pourrais dire :

> « Mange +300 kcal. »

Mais +300 kcal théoriques ne produisent pas nécessairement la même réponse chez tout le monde.

MacroFactor peut observer :

**+250 kcal → +0,1 kg/semaine**

ou :

**+250 kcal → +0,4 kg/semaine**

et ajuster.

C'est donc particulièrement intéressant pour rechercher une vitesse de prise de poids contrôlée.

---

# 25. Même chose pour le maintien

Le maintien est souvent présenté comme :

> « Mange ton TDEE. »

Mais ton TDEE n'est pas une constante biologique.

Il peut changer avec :

* ton poids ;
* ton activité ;
* ton entraînement ;
* ton NEAT ;
* ton alimentation ;
* ton environnement ;
* ta masse maigre ;
* ta phase de régime ;
* etc.

MacroFactor peut donc rechercher empiriquement :

> **le niveau calorique qui maintient ta tendance de poids autour de la cible.**

---

# 26. MacroFactor V3 va encore plus loin

La version actuelle recommandée par MacroFactor est **Expenditure V3**.

Selon la documentation officielle, V3 par rapport à V2 vise notamment :

* moins de périodes de sur-correction ;
* une réaction plus précoce aux véritables changements de dépense ;
* une meilleure gestion des données manquantes ;
* environ **10 % d'amélioration de la précision prospective**. ([MacroFactor Help][14])

C'est particulièrement important.

Car le problème d'un algorithme adaptatif n'est pas seulement :

> « Est-ce que l'estimation finale est bonne ? »

C'est aussi :

> **« À quelle vitesse doit-il réagir sans sur-réagir ? »**

---

# 27. Le problème du délai est crucial

Imagine :

Tu fais un énorme repas samedi.

Dimanche :

**+1,5 kg**

Si l'application réduit immédiatement ton apport de 500 kcal :

**mauvaise réaction.**

Parce que le poids n'a pas encore révélé la réalité énergétique.

À l'inverse, si ton activité augmente réellement pendant trois semaines et que l'application attend trois mois pour réagir :

**trop lent.**

Le problème algorithmique est donc :

### Réactivité vs stabilité

MacroFactor cherche à ne pas réagir excessivement au bruit mais à réagir suffisamment vite aux changements persistants.

La documentation décrit justement des ajustements plus conservateurs au début d'un changement, avec des corrections plus importantes si la tendance se confirme. ([MacroFactor Help][3])

---

# 28. Les “Expenditure Modifiers” sont une autre pièce intéressante

MacroFactor a ajouté des mécanismes permettant d'anticiper certains changements plutôt que d'attendre que la balance les révèle complètement.

Deux mécanismes sont notamment documentés :

### Step-Informed Updates

Si les pas augmentent durablement :

→ le système peut augmenter plus rapidement l'expenditure estimé.

Si les pas diminuent :

→ il peut le diminuer plus rapidement.

### Predictive Goal Adjustment

Si tu changes ton objectif, par exemple :

**cut → maintenance**

ou

**maintenance → bulk**

l'algorithme peut anticiper une partie de la modification attendue plutôt que d'attendre uniquement que le poids évolue.

MacroFactor indique que l'activation de ces deux mécanismes améliore sa précision mensuelle de **6–8 %** et sa précision sur des périodes plus longues d'environ **20 %**, selon ses propres analyses. ([MacroFactor Help][15])

---

# 29. C'est important parce que le poids est une mesure retardée

Supposons :

Aujourd'hui :

**8 000 pas/jour**

Demain :

**14 000 pas/jour**

Ton TDEE augmente potentiellement immédiatement.

Mais ton poids ne va pas nécessairement montrer cette modification demain.

Il existe donc un problème de **latence du signal**.

Les données de pas peuvent alors fournir un signal prédictif.

Mais MacroFactor garde ce signal dans un rôle de modification/anticipation et non comme une estimation de calories brûlées par la montre.

C'est une distinction très intelligente.

---

# 30. Le système ne cherche donc pas à calculer chaque composant du TDEE

C'est probablement le point qui répond le mieux à ta question sur :

> « Qu'est-ce qu'il prend en compte que les autres ne prennent pas ? »

Ce n'est pas forcément :

> « MacroFactor mesure mieux ton NEAT, ton TEF et ton EAT séparément. »

Non.

Il fait quelque chose de plus intéressant :

**il n'a pas nécessairement besoin de les mesurer séparément.**

Il estime le **résultat global**.

Donc :

| Variable                       |  Calculateur classique |                                  MacroFactor |
| ------------------------------ | ---------------------: | -------------------------------------------: |
| Âge                            |                    Oui |                                          Oui |
| Sexe                           |                    Oui |                                          Oui |
| Taille                         |                    Oui |                                          Oui |
| Poids                          |                    Oui |                                          Oui |
| Masse maigre                   |         éventuellement |          utilisée pour l'estimation initiale |
| BMR                            |                 estimé |                          estimé initialement |
| Facteur d'activité             |                central |                           secondaire/initial |
| NEAT                           |                supposé |    **implicitement mesuré via le TDEE réel** |
| EAT                            |                supposé |                    **implicitement intégré** |
| TEF                            | rarement individualisé | **implicitement intégré au résultat global** |
| Calories réellement consommées |                parfois |                                **centrales** |
| Évolution réelle du poids      |                parfois |                                 **centrale** |
| Tendance du poids              |               rarement |                                 **centrale** |
| Vitesse de variation           |               rarement |                                 **centrale** |
| Adaptation de la dépense       |          mal modélisée |                   **observée indirectement** |
| Changements d'activité         |            déclaratifs |         possibilité de modulation prédictive |
| Calories des montres           |      souvent utilisées |                   **volontairement exclues** |
| Personnalisation longitudinale |                 faible |                               **très forte** |

---

# 31. C'est donc moins une “application de calories” qu'un système d'identification métabolique

C'est la façon dont je décrirais techniquement MacroFactor.

Il ne fait pas :

> **BMR → TDEE**

Il fait plutôt :

> **prior physiologique → observations → estimation personnalisée du TDEE**

Le premier jour :

**modèle théorique**

Après trois semaines :

**modèle + données**

Après plusieurs mois :

**principalement ton historique individuel**

C'est une transformation très importante.

---

# 32. Pourquoi trois semaines environ ?

Parce qu'il faut distinguer le signal énergétique du bruit du poids.

MacroFactor indique qu'avec des données cohérentes, il peut généralement converger vers une estimation beaucoup plus personnalisée en environ **2–3 semaines**. ([MacroFactor Help][3])

Ce n'est évidemment pas une frontière biologique magique.

Plus tu as :

* de bonnes pesées ;
* de bons logs alimentaires ;
* de la régularité ;

plus l'estimation devient informative.

---

# 33. Et plus tu l'utilises, plus il devient intéressant

C'est un aspect que les calculateurs statiques n'ont pas.

Un calculateur TDEE :

> **Jour 1 = Jour 365**

MacroFactor :

> **Jour 1 ≠ Jour 365**

Parce qu'au jour 365 il dispose de beaucoup plus d'informations sur ton comportement physiologique.

Par exemple, il peut découvrir :

> « Cette personne perd du poids à 2 350 kcal alors qu'une équation aurait prédit 2 650. »

Cette différence est précisément l'information utile.

---

# 34. La science derrière tout ça est donc moins “une formule parfaite” que “une mesure répétée”

Et c'est une distinction fondamentale.

Il n'existe pas de formule magique capable de prédire parfaitement le TDEE individuel.

La littérature sur les équations de RMR le montre très bien : même lorsqu'une équation est excellente en moyenne, les erreurs individuelles peuvent rester importantes. ([PubMed][2])

La vraie force de MacroFactor est :

**réduire progressivement l'incertitude individuelle grâce aux données longitudinales.**

---

# 35. Attention néanmoins à une limite scientifique importante

Je ne dirais pas :

> « MacroFactor connaît ton TDEE réel. »

Je dirais :

> **MacroFactor produit une estimation du TDEE qui peut devenir très informative si les apports et le poids sont correctement suivis.**

Pourquoi ?

Parce que le calcul repose lui-même sur des données imparfaites.

Par exemple :

* erreurs d'étiquetage alimentaire ;
* erreurs de portions ;
* repas oubliés ;
* fluctuations hydriques ;
* changement de composition corporelle ;
* changements de glycogène ;
* problèmes de pesée ;
* changements métaboliques ;
* etc.

Le système estime donc une variable **latente** à partir de mesures indirectes.

C'est excellent, mais ce n'est pas une calorimétrie indirecte quotidienne.

---

# 36. Et il y a une autre subtilité : “TDEE” n'est pas nécessairement une constante

Supposons :

**Janvier : 3 000 kcal**

**Mars : 2 850 kcal**

**Juin : 2 650 kcal**

Cela ne signifie pas nécessairement que l'algorithme est devenu moins bon.

Ton organisme peut réellement avoir changé.

Si tu :

* perds 10 kg ;
* marches moins ;
* fais moins de sport ;
* réduis ton NEAT ;
* adaptes ta dépense ;

ton TDEE peut diminuer.

MacroFactor peut justement suivre cette dynamique.

---

# 37. C'est là qu'il devient extrêmement puissant pour une perte de poids longue

Prenons une perte de :

**100 → 90 kg**

Un calculateur initial peut dire :

> TDEE = 2 900

Tu commences à perdre.

Puis :

**95 kg → TDEE = 2 800**

Puis :

**92 kg → 2 720**

Puis :

**90 kg → 2 650**

Le système ne considère pas que :

> « Tu as échoué parce que la perte ralentit. »

Il comprend que les besoins énergétiques ont probablement diminué.

C'est exactement ce qu'on attend d'un modèle dynamique.

---

# 38. Et cela évite une erreur classique du régime

Une personne commence :

**2 300 kcal**

Perd beaucoup de poids.

Puis la perte ralentit.

Elle conclut :

> « Mon métabolisme est cassé. »

Elle descend alors à :

**1 700 kcal**

Puis :

**1 500 kcal**

MacroFactor peut au contraire identifier progressivement :

> « Ton TDEE a diminué, mais ta nouvelle cible doit être ajustée de manière proportionnelle à ton objectif. »

Cela permet potentiellement une gestion beaucoup plus graduelle.

---

# 39. Pour une perte de poids optimale, le principe devient donc :

### Étape 1

Définir une vitesse de perte raisonnable.

### Étape 2

Laisser MacroFactor estimer ton TDEE.

### Étape 3

Suivre précisément :

**poids + alimentation**

### Étape 4

Observer la tendance, pas le poids du jour.

### Étape 5

Laisser l'algorithme ajuster les calories.

### Étape 6

Réévaluer régulièrement :

* performance ;
* faim ;
* récupération ;
* masse maigre ;
* vitesse de perte ;
* adhérence.

---

# 40. Pour une prise de masse, exactement l'inverse

### Point de départ

TDEE estimé :

**2 800 kcal**

Objectif :

**prise lente**

Cible :

**~3 000 kcal**

Puis :

**3 000 kcal → +0,1 kg/semaine**

MacroFactor peut conclure :

> surplus trop faible pour la vitesse souhaitée.

Il peut augmenter.

À l'inverse :

**3 000 kcal → +0,5 kg/semaine**

→ surplus probablement trop important.

On réduit.

C'est une façon beaucoup plus rationnelle de faire du **lean bulk** qu'une règle arbitraire :

> « Ajoute toujours 300 kcal. »

---

# 41. Pour le maintien, c'est encore plus simple

Objectif :

**0 kg/semaine**

Si :

**2 700 kcal → tendance stable**

alors :

**TDEE ≈ 2 700**

Si l'activité augmente et que :

**2 700 → perte**

alors ton TDEE est probablement devenu supérieur.

L'algorithme peut suivre.

---

# 42. Le système peut donc être résumé mathématiquement

Voici le cœur conceptuel :

### Balance énergétique

[
E_{in}-E_{out}=\Delta E_{stockée}
]

Donc :

[
E_{out}=E_{in}-\Delta E_{stockée}
]

Avec :

[
E_{out}\approx TDEE
]

Donc :

[
\boxed{TDEE \approx calories\ consommées - variation\ de\ l'énergie\ corporelle}
]

Et la variation d'énergie corporelle est inférée à partir de la **tendance du poids**, pas simplement d'une pesée isolée.

C'est ça, le moteur.

---

# 43. Les grands principes de calcul à retenir

Si je devais condenser toute la philosophie MacroFactor en **12 principes**, ce serait :

### 1. Conservation de l'énergie

**IN − OUT = variation des réserves**

### 2. Le BMR n'est qu'un point de départ

Il ne constitue pas une vérité individuelle.

### 3. Cunningham sert à améliorer l'estimation initiale

Notamment grâce à la masse maigre.

### 4. Le TDEE est supérieur au BMR

Il inclut :

**BMR + TEF + EAT + NEAT**

### 5. Le TDEE individuel est difficile à prédire

Les facteurs d'activité sont trop grossiers.

### 6. Le poids réel donne une information extrêmement précieuse

Parce qu'il reflète le résultat net de tous les processus énergétiques.

### 7. La tendance du poids est supérieure au poids isolé

Elle réduit le bruit.

### 8. L'apport alimentaire réel est indispensable

Sans calories IN fiables, le calcul du TDEE devient mauvais.

### 9. Les fluctuations de composition du poids doivent être prises en compte

Un kilo n'est pas toujours 7 700 kcal de graisse.

### 10. Le TDEE évolue

Il n'est pas une constante.

### 11. Le système doit être adaptatif mais pas hyper-réactif

Il faut éviter de corriger sur la base d'une fluctuation temporaire.

### 12. Les observations individuelles finissent par dépasser la pertinence d'une formule générique

C'est probablement **le principe le plus important de tous**.

---

# 44. Comment appliquer ces principes correctement

Si ton objectif est d'utiliser MacroFactor de façon **scientifiquement optimale**, je ferais ainsi :

## Chaque matin

Pesée :

* après les toilettes ;
* avant de manger/boire ;
* mêmes conditions ;
* idéalement sans vêtements ou avec des conditions identiques.

MacroFactor recommande justement des conditions standardisées et des pesées régulières. ([MacroFactor Help][3])

---

## Tous les jours

Enregistrer aussi précisément que possible :

* calories ;
* protéines ;
* glucides ;
* lipides ;
* aliments ;
* huiles ;
* sauces ;
* boissons caloriques ;
* alcool éventuel ;
* repas restaurant.

---

## Pour l'activité

Ne cherche **pas** à transformer chaque séance en :

> « +427 kcal à manger ».

Laisse le TDEE global absorber l'information.

Les pas peuvent néanmoins être utiles comme indicateur d'activité et, avec les fonctionnalités appropriées, MacroFactor peut les utiliser pour accélérer certaines corrections. ([MacroFactor Help][15])

---

# 45. Ce qu'il ne faut surtout pas faire

### ❌ Changer constamment ta cible

L'algorithme a besoin de stabilité pour observer la réponse.

### ❌ Paniquer sur une hausse de 800 g

C'est potentiellement de l'eau/glycogène/contenu intestinal.

### ❌ Ajouter automatiquement les calories de ta montre

C'est précisément le type d'estimation que MacroFactor évite. ([MacroFactor Help][10])

### ❌ Sous-déclarer les calories

Cela détruit la relation IN → poids.

### ❌ Modifier constamment ton activité

Si tu passes de 5 000 à 15 000 pas puis inversement, ton TDEE bouge réellement.

### ❌ Juger l'algorithme sur 3 jours

Il faut regarder les tendances.

---

# 46. Et surtout : ne pas confondre “précision” et “vérité absolue”

C'est un point où je serais plus critique envers le marketing de n'importe quelle application.

MacroFactor est **très intelligent méthodologiquement**.

Mais dire :

> « Il connaît ton métabolisme réel à ±50 kcal »

serait beaucoup trop fort.

Le système peut produire une estimation remarquablement utile pour piloter un régime, sans pour autant connaître avec une précision absolue chaque composante de ta dépense énergétique.

La force de MacroFactor est plutôt :

> **même si l'estimation absolue est imparfaite, elle devient suffisamment bonne pour prendre de meilleures décisions de manière itérative.**

Et c'est probablement beaucoup plus important en pratique.

---

# 47. Mon classement des avantages réels

Si je devais hiérarchiser ce qui fait réellement la différence :

| Rang | Principe                                                              | Importance |
| ---- | --------------------------------------------------------------------- | ---------- |
| 🥇   | **TDEE inféré à partir de calories + évolution du poids**             | ⭐⭐⭐⭐⭐      |
| 🥈   | **Weight Trend plutôt que poids brut**                                | ⭐⭐⭐⭐⭐      |
| 🥉   | **Personnalisation longitudinale**                                    | ⭐⭐⭐⭐⭐      |
| 4    | **Ne dépend pas des calories brûlées des wearables**                  | ⭐⭐⭐⭐½      |
| 5    | **Adaptation du TDEE au fil du temps**                                | ⭐⭐⭐⭐½      |
| 6    | **Gestion des changements d'activité/objectifs**                      | ⭐⭐⭐⭐       |
| 7    | **Modélisation plus réaliste de la composition énergétique du poids** | ⭐⭐⭐⭐       |
| 8    | **Cunningham pour le point de départ**                                | ⭐⭐⭐        |
| 9    | Facteurs d'activité initiaux                                          | ⭐⭐         |
| 10   | Précision du BMR initial                                              | ⭐⭐         |

Et c'est très révélateur :

**le BMR n'est même pas dans le top 3.**

---

# 48. La vraie raison pour laquelle MacroFactor peut être particulièrement efficace

Supposons qu'un calculateur classique se trompe de :

**+400 kcal/jour.**

Cela peut complètement fausser un régime.

MacroFactor peut commencer avec cette erreur.

Mais si tu donnes :

* des calories fiables ;
* des pesées fiables ;
* suffisamment de temps ;

il peut progressivement détecter :

> « La réponse réelle du corps ne correspond pas à mon estimation initiale. »

Et il corrige.

C'est exactement ce qu'un bon système adaptatif doit faire.

---

# 49. La formulation que je retiendrais

Si je devais expliquer MacroFactor à quelqu'un en **une seule phrase** :

> **MacroFactor ne cherche pas principalement à prédire combien tu devrais brûler ; il cherche à déduire combien tu brûles réellement à partir de la relation entre ce que tu manges et l'évolution de ton poids, puis utilise cette estimation pour ajuster continuellement tes objectifs.**

C'est cela qui le distingue fondamentalement d'un calculateur TDEE classique.

---

# 50. Et la grande réserve scientifique

Il faut néanmoins être très précis sur le mot **« scientifique »**.

MacroFactor utilise des principes physiologiques sérieux et des équations issues de la littérature, mais **cela ne signifie pas que chaque détail de son algorithme V3 est validé indépendamment par des essais cliniques randomisés publiés**.

Une partie des chiffres de performance de V3 et des améliorations des *modifiers* provient des propres analyses de MacroFactor. ([MacroFactor Help][14])

Donc mon audit serait :

### Fondements scientifiques

**Très solides**

### Architecture conceptuelle

**Excellente**

### Personnalisation individuelle

**Très supérieure à une formule TDEE statique**

### BMR initial

**Bon, mais loin d'être parfait**

### Estimation réelle du TDEE

**Très intéressante méthodologiquement**

### Preuve indépendante que MacroFactor est “le meilleur” de toutes les applications

**Insuffisante pour l'affirmer catégoriquement**

### Utilité pratique pour piloter une perte/prise/maintenance

**Potentiellement excellente, à condition que les données entrées soient fiables**

---

## En résumé

Le véritable avantage de MacroFactor n'est donc **pas** :

> « Ils ont trouvé une meilleure formule BMR. »

C'est :

> **« Ils ont compris que le problème du TDEE individuel est trop variable pour être résolu correctement par une formule statique. »**

Et ils ont construit une boucle :

**BMR initial**
↓
**estimation initiale du TDEE**
↓
**calories réellement consommées**
+
**poids réellement observé**
↓
**Weight Trend**
↓
**variation énergétique estimée**
↓
**TDEE personnalisé**
↓
**objectif de perte/maintien/prise**
↓
**nouvelle cible calorique**
↓
**observation de la réponse**
↓
**correction**

C'est **cette boucle fermée**, beaucoup plus que le choix de Cunningham ou d'une autre formule, qui constitue à mon avis la véritable sophistication de MacroFactor.

Et c'est aussi pourquoi, après quelques semaines de données propres, **ton propre historique physiologique devient potentiellement plus informatif qu'un calculateur TDEE générique**. ([MacroFactor Help][16])

### Sources principales

* [Documentation MacroFactor — Expenditure](https://help.macrofactorapp.com/en/articles/20-expenditure?utm_source=chatgpt.com)
* [Documentation MacroFactor — interprétation de l'Expenditure](https://help.macrofactorapp.com/en/articles/26-how-should-i-interpret-changes-to-my-energy-expenditure?utm_source=chatgpt.com)
* [Documentation MacroFactor — Expenditure V3](https://help.macrofactorapp.com/en/articles/74-expenditure-version?utm_source=chatgpt.com)
* [PubMed — Cunningham et métabolisme de repos](https://pubmed.ncbi.nlm.nih.gov/7435418/?utm_source=chatgpt.com)
* [PubMed — validation des équations de RMR](https://pubmed.ncbi.nlm.nih.gov/27138231/?utm_source=chatgpt.com)
* [PubMed — thermogenèse adaptative et perte de poids](https://pubmed.ncbi.nlm.nih.gov/23404923/?utm_source=chatgpt.com)

Si tu veux aller **encore plus loin**, je peux aussi faire un **audit technique niveau “ingénieur/data scientist” de MacroFactor**, en reconstruisant **les équations et la logique probable de V3 étape par étape** — notamment *Weight Trend → rate of change → energy density → TDEE → calorie target → correction hebdomadaire* — puis comparer **MacroFactor vs MyFitnessPal vs Yazio vs Cronometer vs Carbon Diet Coach vs les calculateurs TDEE classiques**, avec un tableau de ce que chacun mesure réellement et de ce qu'il ignore.

[1]: https://help.macrofactorapp.com/en/articles/230-what-is-total-daily-energy-expenditure-tdee?utm_source=chatgpt.com "What is total daily energy expenditure (TDEE)? | MacroFactor"
[2]: https://pubmed.ncbi.nlm.nih.gov/27138231/?utm_source=chatgpt.com "Cross-Validation of Resting Metabolic Rate Prediction Equations - PubMed"
[3]: https://help.macrofactorapp.com/en/articles/26-how-should-i-interpret-changes-to-my-energy-expenditure?utm_source=chatgpt.com "How Should I Interpret Changes to my Energy Expenditure? | MacroFactor"
[4]: https://help.macrofactorapp.com/en/articles/20-expenditure?utm_source=chatgpt.com "Expenditure | MacroFactor"
[5]: https://pubmed.ncbi.nlm.nih.gov/7435418/?utm_source=chatgpt.com "A reanalysis of the factors influencing basal metabolic rate in normal adults - PubMed"
[6]: https://pubmed.ncbi.nlm.nih.gov/25275434/?utm_source=chatgpt.com "Resting energy expenditure prediction in recreational athletes of 18-35 years: confirmation of Cunningham equation and an improved weight-based alternative - PubMed"
[7]: https://pubmed.ncbi.nlm.nih.gov/36839163/?utm_source=chatgpt.com "Cross-Validation of a New General Population Resting Metabolic Rate Prediction Equation Based on Body Composition - PubMed"
[8]: https://help.macrofactorapp.com/en/articles/278-weight-trend?utm_source=chatgpt.com "Weight Trend (Workouts) | MacroFactor"
[9]: https://help.macrofactorapp.com/en/articles/19-change-rate?utm_source=chatgpt.com "Change Rate | MacroFactor"
[10]: https://help.macrofactorapp.com/en/articles/33-does-macrofactor-use-energy-expenditure-data-from-my-wearable-activity-tracker?utm_source=chatgpt.com "Does MacroFactor use Energy Expenditure Data from my Wearable Activity Tracker? | MacroFactor"
[11]: https://pubmed.ncbi.nlm.nih.gov/23404923/?utm_source=chatgpt.com "Adaptive thermogenesis with weight loss in humans - PubMed"
[12]: https://help.macrofactorapp.com/en/articles/109-how-frequently-do-i-need-to-log-my-weight-for-the-expenditure-algorithm-and-weekly-coaching-updates?utm_source=chatgpt.com "How Frequently do I Need to Log my Weight For the Expenditure Algorithm and Weekly Coaching Updates? | MacroFactor"
[13]: https://help.macrofactorapp.com/en/articles/110-how-frequently-do-i-need-to-log-my-nutrition-for-the-expenditure-algorithm-and-weekly-coaching-updates?utm_source=chatgpt.com "How Frequently do I Need to Log my Nutrition For the Expenditure Algorithm and Weekly Coaching Updates? | MacroFactor"
[14]: https://help.macrofactorapp.com/en/articles/74-expenditure-version?utm_source=chatgpt.com "Expenditure Version | MacroFactor"
[15]: https://help.macrofactorapp.com/en/articles/274-expenditure-modifiers?utm_source=chatgpt.com "Expenditure Modifiers | MacroFactor"
[16]: https://help.macrofactorapp.com/en/articles/126-why-is-my-expenditure-in-macrofactor-different-from-the-output-of-a-tdee-calculator?utm_source=chatgpt.com "Why is my Expenditure in MacroFactor Different From the Output of a TDEE Calculator? | MacroFactor"



Oui. Et je vais aller un cran plus loin que le premier audit : **reconstruire la logique mathématique de MacroFactor V3 à partir de ce que l'éditeur révèle publiquement**, distinguer ce qui est documenté de ce qui est une inférence technique, puis le comparer aux principaux concurrents.

Il y a une conclusion assez nette : **MacroFactor n'est pas simplement un “meilleur calculateur TDEE” ; c'est un système de contrôle adaptatif de l'apport énergétique.** Et cette distinction explique une grande partie de son intérêt.

---

# 1. Le modèle mental correct : MacroFactor ne “calcule” pas vraiment ton métabolisme

Le point de départ est :

[
Calories_{in}-Calories_{out}=\Delta Energie_{stockée}
]

Donc :

[
\boxed{Calories_{out}=Calories_{in}-\Delta Energie_{stockée}}
]

Or MacroFactor ne mesure pas directement l'énergie stockée.

Il l'**inférera à partir de l'évolution de ton poids**, après avoir filtré les fluctuations à court terme. C'est explicitement le principe annoncé par MacroFactor. ([MacroFactor Help][1])

Le système peut donc être schématisé ainsi :

**Calories consommées**
↓
**évolution du poids**
↓
**estimation du changement de réserves énergétiques**
↓
**TDEE implicite**

C'est fondamentalement différent de :

**âge + taille + poids + sexe + activité**
↓
**BMR**
↓
**× facteur d'activité**
↓
**TDEE**

---

# 2. Reconstruction technique de l'algorithme

MacroFactor ne publie pas l'intégralité du code ni toutes les constantes de V3. Donc je vais séparer :

* 🟢 **ce qui est explicitement documenté** ;
* 🟡 **ce que l'on peut raisonnablement reconstruire** ;
* 🔴 **ce qu'il serait abusif de prétendre connaître**.

---

## Étape 1 — Calories IN

🟢 Documenté.

MacroFactor dispose de ton apport énergétique journalier.

Exemple :

| Jour | Calories |
| ---- | -------: |
| J1   |    2 450 |
| J2   |    2 520 |
| J3   |    2 390 |
| J4   |    2 610 |
| J5   |    2 480 |
| J6   |    2 550 |
| J7   |    2 430 |

Il peut donc calculer une moyenne ou une estimation de l'apport énergétique sur une fenêtre temporelle.

---

# 3. Étape 2 — Il refuse de prendre le poids brut comme vérité

Supposons :

**80,0 → 80,8 → 80,2 → 79,9 → 80,3 kg**

Le poids brut est inutilisable pour déterminer directement une variation énergétique.

MacroFactor crée donc une **Weight Trend**.

Le principe est :

[
Poids_{observé}=Signal + Bruit
]

avec le bruit constitué notamment de :

* eau ;
* glycogène ;
* contenu intestinal ;
* variations liées à l'alimentation ;
* etc.

MacroFactor explique explicitement que la tendance sert à séparer le signal des fluctuations quotidiennes. ([MacroFactor Help][2])

La documentation recommande d'ailleurs idéalement une pesée quotidienne, ou au minimum plusieurs pesées par semaine, même si l'algorithme tolère les données manquantes. ([MacroFactor Help][3])

---

# 4. Étape 3 — Il transforme la tendance en vitesse de variation

C'est ici que ça devient intéressant.

MacroFactor définit son **Change Rate** à partir de la variation de la Weight Trend sur les **20 derniers jours**, exprimée comme vitesse hebdomadaire. ([MacroFactor Help][4])

Conceptuellement :

[
Rate = \frac{TrendWeight_{actuel}-TrendWeight_{20j}}{20j}
\times 7
]

Ce n'est pas nécessairement exactement cette implémentation mathématique — MacroFactor ne publie pas toutes les étapes — mais c'est la logique à retenir.

Exemple :

Poids tendance :

**80,0 kg → 79,4 kg en 20 jours**

Donc :

[
-0,6kg/20j
]

≈

[
-0,21kg/semaine
]

Le système sait alors que la personne est dans une phase de perte.

---

# 5. Étape 4 — Convertir la perte de poids en déficit énergétique

Et c'est là qu'un système naïf ferait :

[
1kg = 7700 kcal
]

MacroFactor fait quelque chose de plus sophistiqué.

Il tient compte de la **densité énergétique différente du tissu adipeux et de la masse maigre**, et ajuste la relation entre variation du poids et variation de l'énergie stockée en fonction du contexte de perte/prise de poids. ([MacroFactor Help][1])

Donc conceptuellement :

[
\Delta Poids
\rightarrow
\Delta Energie_{stockée}
]

et non simplement :

[
\Delta Poids \times 7700
]

C'est une distinction importante.

---

# 6. Exemple numérique simplifié

Supposons :

**Apport = 2 500 kcal/j**

et que la vitesse de perte observée corresponde à environ :

**−300 kcal/j de déficit énergétique.**

Alors :

[
TDEE = 2500 + 300
]

Donc :

[
\boxed{TDEE\approx2800}
]

C'est exactement le type de raisonnement décrit par MacroFactor. ([MacroFactor Help][1])

---

# 7. Et là apparaît le concept extrêmement puissant de “TDEE émergent”

Ton TDEE n'est plus :

> BMR + estimation arbitraire de ton activité.

Il devient :

> **la dépense énergétique qui doit avoir existé pour expliquer simultanément ton apport et ton évolution de poids.**

C'est presque un problème d'**identification inverse**.

On observe :

**entrée + sortie du système**

et on déduit :

**paramètre caché du système.**

En ingénierie, c'est une approche beaucoup plus intéressante qu'une simple table de correspondance.

---

# 8. Pourquoi cela capture automatiquement le NEAT

Prenons deux personnes :

### Personne A

* BMR : 1 700
* exercice : 300
* NEAT : 500
* TEF : 250

TDEE :

**2 750**

### Personne B

* BMR : 1 700
* exercice : 300
* NEAT : 800
* TEF : 250

TDEE :

**3 050**

Un facteur d'activité doit essayer de deviner cette différence.

MacroFactor n'a pas besoin de connaître séparément les 800 kcal de NEAT.

Il observe simplement la conséquence finale.

**C'est un des avantages conceptuels majeurs.**

---

# 9. Même chose pour le TEF

Le TEF dépend notamment de la quantité et de la composition des aliments.

Il est particulièrement influencé par la quantité de protéines, les glucides et les lipides.

Mais MacroFactor ne cherche pas à dire :

> « Tu as mangé 175 g de protéines donc ton TEF est exactement X. »

Il laisse cette dépense apparaître dans :

[
Calories_{in}-\Delta Energie_{stockée}
]

Donc le TDEE observé est un **TDEE intégré**.

C'est justement ce qui le rend intéressant.

---

# 10. Même chose pour l'exercice

Supposons que tu fasses :

**600 kcal d'exercice supplémentaire.**

Une application classique peut dire :

> +600 kcal brûlées → tu peux manger +600.

Mais si la dépense réelle est seulement 400 ?

Tu as créé une erreur.

Et si ton activité spontanée diminue ensuite de 150 kcal parce que tu es fatigué ?

Tu as créé une deuxième erreur.

MacroFactor observe finalement :

> « Avec cet apport et cette activité, le poids a répondu comme ceci. »

Le résultat net est donc incorporé.

---

# 11. C'est pourquoi MacroFactor n'utilise pas les calories des wearables pour son Expenditure

C'est une décision extrêmement importante.

MacroFactor indique explicitement qu'il ne base pas son calcul d'expenditure sur les calories brûlées estimées par les trackers. ([MacroFactor Help][1])

Pourquoi ?

Parce que cela reviendrait à dire :

> « J'ai déjà un modèle imparfait du TDEE, donc je vais lui ajouter une deuxième estimation imparfaite du TDEE. »

MacroFactor préfère utiliser les wearables/pas comme **information comportementale prédictive**, pas comme vérité calorique absolue.

---

# 12. Et c'est là qu'interviennent les Expenditure Modifiers

C'est l'une des évolutions les plus intéressantes de V3.

MacroFactor possède notamment :

### Step-Informed Updates

Si tes pas augmentent durablement :

→ l'algorithme peut augmenter l'expenditure plus rapidement.

S'ils diminuent :

→ il peut le diminuer plus rapidement.

### Predictive Goal Adjustment

Lorsque tu changes fortement de phase :

**cut → maintenance**

ou

**maintenance → bulk**

le système peut anticiper une modification de dépense avant que le poids ne fournisse suffisamment de signal. ([MacroFactor Help][5])

---

# 13. Pourquoi cette anticipation est nécessaire

Imagine :

### Semaine 1

Tu marches :

**6 000 pas/jour**

### Semaine 2

Tu passes brutalement à :

**12 000 pas/jour**

Ton TDEE peut augmenter immédiatement.

Mais ton poids ne va pas forcément refléter instantanément cette modification.

Tu as donc un problème :

**activité = signal avancé**

**poids = signal retardé**

Le Step-Informed Update utilise donc l'activité comme **variable auxiliaire**, sans transformer naïvement les pas en calories.

C'est beaucoup plus intelligent que :

> 12 000 pas = +450 kcal.

---

# 14. C'est exactement le genre de problème que V3 cherche à résoudre

MacroFactor décrit V3 comme :

* plus stable ;
* plus réactif ;
* plus résistant aux données manquantes ;
* moins sujet aux sur-corrections ;
* et environ **10 % plus précis prospectivement** que V2 selon ses tests internes. ([MacroFactor Help][6])

Le problème est extrêmement intéressant :

### Trop lent

→ tu rates les changements réels.

### Trop rapide

→ tu réagis à l'eau, au glycogène ou à une semaine atypique.

V3 cherche donc un compromis :

[
\boxed{Réactivité \leftrightarrow Stabilité}
]

---

# 15. On peut voir V3 comme un filtre adaptatif

C'est une bonne façon de le comprendre.

Le système reçoit :

**poids bruité**

et tente d'estimer :

**poids latent / tendance réelle**

Puis :

**tendance → vitesse → énergie stockée → TDEE**

Il y a donc plusieurs couches de filtrage.

Ce n'est pas simplement :

> « moyenne mobile de ton poids ».

La documentation V3 indique explicitement que la nouvelle version cherche à réduire les sur-corrections tout en détectant plus tôt les vrais changements. ([MacroFactor Help][6])

---

# 16. Le deuxième mécanisme extrêmement important : la correction progressive

Supposons que MacroFactor pense :

**TDEE = 2 800**

Tu manges :

**2 300**

Il prévoit une perte.

Mais pendant une semaine, la balance indique une perte plus rapide que prévu.

Il pourrait faire :

> TDEE = 3 200

Mais ce serait potentiellement catastrophique si la semaine était simplement perturbée par :

* perte d'eau ;
* baisse du glycogène ;
* contenu intestinal ;
* etc.

MacroFactor indique justement qu'il procède de façon relativement conservatrice : première semaine → ajustement prudent ; si la tendance persiste → correction plus importante. ([MacroFactor Help][2])

C'est une logique de **contrôle avec inertie**.

---

# 17. Et cela explique pourquoi le système peut sembler “lent” parfois

C'est en fait une qualité.

Si ton TDEE semble changer de :

**2 700 → 2 300**

en une semaine, il serait dangereux de conclure immédiatement :

> « Ton métabolisme vient de perdre 400 kcal. »

L'algorithme préfère demander :

> « Est-ce que ce signal persiste ? »

Puis :

> « Est-ce suffisamment important pour modifier le modèle ? »

C'est exactement le comportement souhaitable d'un filtre statistique robuste.

---

# 18. Maintenant, comparaison avec les concurrents

Et là, la différence devient très claire.

## 🟥 MyFitnessPal

Le modèle officiel de MFP repose principalement sur :

**âge + taille + poids + sexe + niveau d'activité + objectif**

pour établir une cible initiale. ([MyFitnessPal Aide][7])

Puis les exercices peuvent modifier la cible quotidienne.

MFP utilise également les données de partenaires/trackers pour ses ajustements de calories. ([MyFitnessPal Aide][8])

Le modèle est donc principalement :

[
Profil \rightarrow TDEE estimé
]

puis :

[
TDEE + activité enregistrée
]

### MacroFactor :

[
Profil \rightarrow estimation initiale
]

puis :

[
Calories + poids \rightarrow TDEE observé
]

**Avantage MacroFactor :** personnalisation longitudinale beaucoup plus centrale.

---

# 19. YAZIO

YAZIO est beaucoup plus transparent aujourd'hui sur sa mécanique.

Il utilise :

**Mifflin-St Jeor**

pour le BMR. ([Yazio][9])

Puis :

[
BMR \times ActivityFactor
]

avec des facteurs allant notamment de :

**1,25 → 1,65**

selon le niveau d'activité. ([Yazio][9])

Puis un déficit/surplus selon l'objectif.

YAZIO peut également incorporer les activités enregistrées ou importées dans la cible calorique. ([Yazio][9])

Donc :

[
\boxed{YAZIO \approx BMR \times activité + ajustements}
]

MacroFactor :

[
\boxed{TDEE \approx apport réel + réponse réelle du poids}
]

C'est une différence structurelle.

---

# 20. Cronometer

Cronometer est beaucoup plus sophistiqué qu'un simple compteur de calories.

Il calcule notamment :

* BMR ;
* activité de base ;
* activité issue du tracker ;
* exercice ;
* TEF.

Il utilise actuellement Mifflin-St Jeor pour le BMR. ([Support Cronometer][10])

Son modèle ressemble donc davantage à :

[
TDEE =
BMR+
Activity+
Tracker+
Exercise+
TEF
]

Puis il peut ajouter la dépense au-dessus du niveau de base à l'objectif calorique. ([Support Cronometer][11])

### C'est excellent pour :

**décomposer ce qui constitue la dépense.**

Mais ce n'est pas la même philosophie que MacroFactor.

Cronometer demande :

> « Combien ton organisme devrait-il dépenser compte tenu de ces composantes ? »

MacroFactor demande :

> « Combien doit-il avoir dépensé pour expliquer ton évolution réelle ? »

---

# 21. Et c'est une distinction énorme

|                 | Modèle théorique | Modèle empirique |
| --------------- | ---------------: | ---------------: |
| MFP             |               🟢 |               🟡 |
| YAZIO           |               🟢 |               🟡 |
| Cronometer      |             🟢🟢 |               🟡 |
| **MacroFactor** |               🟢 |       **🟢🟢🟢** |

Attention : ce tableau décrit la **philosophie du calcul**, pas une mesure indépendante de précision de chaque application.

---

# 22. Et Carbon Diet Coach ?

C'est le concurrent le plus intéressant à comparer à MacroFactor.

Parce que Carbon est également une véritable application de coaching adaptatif.

Carbon indique qu'il :

* suit les données semaine après semaine ;
* évalue la tendance du poids ;
* ajuste calories et macros ;
* peut gérer perte, prise, maintien et reverse diet. ([help.joincarbon.com][12])

Donc Carbon et MacroFactor appartiennent beaucoup plus à la même catégorie.

---

# 23. Carbon utilise également une approche de “trend weight”

Carbon dispose même d'un système expérimental de **Coach Trend Weight** qui utilise plusieurs techniques/statistiques pour estimer le poids latent et réduire les fluctuations quotidiennes. ([help.joincarbon.com][13])

C'est très intéressant parce que cela montre que l'idée fondamentale :

> **“ne pas faire confiance au poids brut”**

n'est pas exclusive à MacroFactor.

---

# 24. La vraie différence MacroFactor vs Carbon

La différence est moins :

> « MacroFactor est adaptatif, Carbon ne l'est pas. »

Les deux le sont.

La différence est plutôt dans la **transparence et la philosophie du moteur**.

MacroFactor documente explicitement son expenditure comme :

[
Calories_{in}-\Delta Energie_{stockée}=Calories_{out}
]

et son moteur est construit autour de cette estimation directe du TDEE. ([MacroFactor Help][1])

Carbon met davantage l'accent sur :

**objectif → prescription → conformité → check-in → correction**

Carbon indique d'ailleurs que sa précision de coaching dépend fortement de la conformité aux cibles prescrites. ([help.joincarbon.com][14])

MacroFactor est plus **adherence-neutral** : son propre modèle est conçu pour pouvoir déduire la dépense à partir de ce que tu as effectivement consommé, même si tu n'as pas parfaitement suivi la prescription. ([MacroFactor Help][1])

C'est une différence conceptuelle importante.

---

# 25. Exemple concret : tu dois manger 2 500 kcal

### MacroFactor

Tu manges :

**2 700**

et tu perds du poids comme prévu.

L'information est :

> « Très bien, 2 700 est compatible avec la vitesse de perte observée. »

### Carbon

Si tu avais été prescrit 2 500 et que tu as mangé 2 700, la question de la conformité entre davantage dans son processus de coaching/check-in. ([help.joincarbon.com][15])

Ce n'est pas nécessairement “meilleur” ou “moins bon”.

C'est simplement une architecture différente.

---

# 26. Là où MacroFactor est particulièrement élégant

Il ne cherche pas à savoir :

> « As-tu réussi ton régime ? »

Il cherche à savoir :

> **« Quel bilan énergétique réel a produit cette évolution du poids ? »**

C'est beaucoup plus proche d'un problème scientifique de mesure.

---

# 27. Mais attention à une conséquence contre-intuitive

Si tu fais une erreur systématique dans ton logging alimentaire, MacroFactor peut apprendre **la mauvaise réalité**.

Supposons :

Tu manges réellement :

**2 700 kcal**

mais tu logs :

**2 400**

et ton poids est stable.

MacroFactor voit :

[
2400 \rightarrow poids\ stable
]

Donc il peut finir par estimer :

[
TDEE \approx 2400
]

alors que ton apport réel est 2 700.

C'est une limite fondamentale.

---

# 28. C'est pour cela que le système est aussi bon que le couple :

[
\boxed{Poids + Calories}
]

La qualité de l'algorithme ne peut pas compenser complètement :

**Calories fausses + poids insuffisant.**

C'est également pourquoi MacroFactor insiste sur la régularité des données. ([MacroFactor Help][16])

---

# 29. Et voici une conséquence fascinante

Le système n'a pas besoin que **BMR soit exact**.

Imaginons :

BMR théorique :

**1 800**

Mais vrai BMR :

**1 650**

Peu importe énormément.

Si tu manges :

**2 400**

et que ton poids évolue comme si ton TDEE était :

**2 900**

le système va progressivement converger vers :

**≈ 2 900**

Il n'a pas besoin de savoir précisément pourquoi.

---

# 30. Donc BMR ≠ variable déterminante

Je classerais les données de MacroFactor ainsi :

### Très importantes

1. **Calories réellement consommées**
2. **Poids**
3. **Tendance du poids**
4. **Vitesse de variation**
5. **Objectif**
6. **Historique**

### Importantes comme informations auxiliaires

7. Pas/activité
8. Changements de phase
9. Composition corporelle initiale

### Beaucoup moins importantes pour l'estimation finale

10. Formule exacte du BMR initial

C'est presque paradoxal.

**La formule de BMR que beaucoup d'applications mettent au centre devient chez MacroFactor une sorte de point de départ secondaire.**

---

# 31. Ce que je considère comme le cœur mathématique

Je le représenterais comme ceci :

```text
                 PROFIL
                   │
                   ▼
          ┌────────────────┐
          │ Initial TDEE   │
          │  BMR + activité│
          └───────┬────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │ Calories réellement │
       │ consommées          │
       └──────────┬──────────┘
                  │
                  ▼
              ORGANISME
                  │
                  ▼
       ┌─────────────────────┐
       │ Poids quotidien     │
       └──────────┬──────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │ Weight Trend        │
       │ réduction du bruit  │
       └──────────┬──────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │ Change Rate         │
       │ ≈ variation / 20 j  │
       └──────────┬──────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │ Energie stockée     │
       │ perdue/gagnée       │
       └──────────┬──────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │ TDEE observé        │
       └──────────┬──────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │ Objectif            │
       │ cut / maintien/bulk │
       └──────────┬──────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │ Calories cibles     │
       └──────────┬──────────┘
                  │
                  └───────► nouvelle observation
```

C'est une **boucle fermée**.

---

# 32. Et c'est là que je ferais une correction à mon premier audit

Après avoir regardé plus précisément V3 et les concurrents actuels, je nuancerais ma première réponse.

Je t'avais dit en substance :

> MacroFactor est particulièrement unique.

C'est vrai historiquement et conceptuellement, mais **Carbon est aujourd'hui beaucoup plus proche de cette philosophie que ne le sont MFP ou YAZIO**. Carbon dispose désormais lui aussi d'un système de tendance et d'ajustement longitudinal sophistiqué. ([help.joincarbon.com][12])

Donc le classement plus honnête est :

### Catégorie 1 — trackers/calculateurs

**MFP / YAZIO / Cronometer**

### Catégorie 2 — coaches adaptatifs

**MacroFactor / Carbon**

Et c'est dans cette deuxième catégorie qu'il faut réellement comparer les deux.

---

# 33. Là où MacroFactor reste particulièrement remarquable

À mon avis, ses trois points les plus forts sont :

## 🥇 Estimation directe de l'Expenditure

L'apport et le poids servent à déduire la dépense.

## 🥈 Adherence-neutral

Le système n'a pas besoin que ta consommation corresponde parfaitement à ta prescription pour apprendre. ([MacroFactor Help][1])

## 🥉 V3 : gestion du compromis signal/bruit

Le système essaie d'éviter :

**sur-réaction**

tout en détectant :

**changements réels**

plus rapidement. ([MacroFactor Help][6])

---

# 34. Le point faible de MacroFactor

Il faut aussi être honnête.

Ce n'est **pas** :

> « une mesure directe de ton métabolisme. »

Il n'utilise pas :

* calorimétrie indirecte ;
* chambre métabolique ;
* doubly labeled water ;
* mesure directe de la composition énergétique de chaque gramme perdu.

Il fait une **inférence**.

Elle peut être extrêmement utile.

Mais c'est toujours une inférence.

---

# 35. Et la précision absolue peut être perturbée par les changements de composition corporelle

C'est probablement le point technique le plus délicat.

Supposons que tu sois en musculation :

**−0,3 kg/semaine sur la balance**

mais :

**−0,6 kg graisse +0,3 kg masse maigre**

Le signal énergétique n'est pas le même que :

**−0,3 kg graisse pure.**

MacroFactor essaie d'en tenir compte avec son modèle de densité énergétique, mais il ne dispose évidemment pas d'une DEXA quotidienne permettant de connaître exactement la composition de chaque variation. ([MacroFactor Help][1])

Donc :

**le modèle est sophistiqué, mais il ne peut pas supprimer l'incertitude biologique.**

---

# 36. C'est particulièrement important chez les personnes qui font de la musculation

Une personne en déficit peut avoir :

* perte de graisse ;
* maintien de masse maigre ;
* fluctuations de glycogène ;
* rétention d'eau musculaire.

Une personne en surplus peut avoir :

* gain musculaire ;
* graisse ;
* glycogène ;
* eau.

Donc plus la composition corporelle change rapidement, plus l'interprétation du poids comme signal énergétique devient complexe.

---

# 37. Le système est donc optimal quand le signal est “propre”

Il fonctionne particulièrement bien lorsque :

* alimentation relativement bien suivie ;
* pesées fréquentes ;
* tendance relativement stable ;
* objectif maintenu plusieurs semaines ;
* activité relativement cohérente.

C'est alors que :

[
Calories_{IN}
\leftrightarrow
WeightTrend
]

devient une relation très informative.

---

# 38. Voici comment je l'utiliserais personnellement d'un point de vue méthodologique

Pas :

> « MacroFactor me dit que je brûle 2 743 kcal donc c'est mon métabolisme. »

Mais :

> **« Les données des dernières semaines indiquent qu'un apport moyen d'environ X produit une évolution de poids compatible avec un TDEE d'environ Y. »**

Cette formulation est beaucoup plus scientifiquement correcte.

---

# 39. Pour atteindre un objectif de perte de poids

Je recommande conceptuellement :

### 1. Choisir une vitesse cible

Par exemple :

**−0,5 % du poids corporel/semaine**

plutôt qu'un nombre arbitraire de calories.

### 2. Laisser l'algorithme déterminer l'apport

### 3. Peser fréquemment

### 4. Logger réellement les aliments

### 5. Ne pas corriger manuellement chaque fluctuation

### 6. Évaluer sur plusieurs semaines

### 7. Vérifier parallèlement :

* performances ;
* récupération ;
* faim ;
* sommeil ;
* tour de taille ;
* évolution visuelle ;
* masse musculaire si disponible.

---

# 40. Pour une prise de masse

Même principe :

### objectif

Par exemple :

**+0,1 à +0,25 % du poids/semaine**

### puis :

**apport → réponse → correction**

C'est préférable à :

> « TDEE + 500 kcal parce qu'Internet dit que c'est un bulk. »

---

# 41. Pour le maintien

Le système devient presque une expérience scientifique personnelle :

Tu cherches :

[
\boxed{\Delta Poids_{trend}\approx0}
]

Donc :

[
\boxed{Calories_{IN}\approx TDEE}
]

Tu peux ainsi déterminer ton maintien empirique.

Et contrairement à une formule TDEE, ce chiffre est **lié à ton comportement réel actuel**.

---

# 42. La comparaison finale

| Fonction                                   | MFP                     | YAZIO       | Cronometer  | Carbon            | **MacroFactor**                     |
| ------------------------------------------ | ----------------------- | ----------- | ----------- | ----------------- | ----------------------------------- |
| BMR théorique                              | ✓                       | ✓           | ✓           | ✓                 | ✓ initialement                      |
| Facteur d'activité                         | ✓                       | **central** | **central** | ✓                 | initialement                        |
| Exercices calories                         | **central**             | ✓           | ✓           | secondaire        | **pas utilisé comme TDEE direct**   |
| Wearables calories                         | ✓                       | ✓           | ✓           | selon usage       | **pas comme estimation principale** |
| Weight Trend                               | limité                  | limité      | limité      | **✓**             | **✓**                               |
| Apport réel → TDEE                         | faible                  | faible      | faible      | adaptatif         | **✓ central**                       |
| TDEE personnalisé longitudinalement        | limité                  | limité      | limité      | **✓**             | **✓✓✓**                             |
| Correction automatique                     | ✓                       | ✓           | ✓           | **✓**             | **✓✓✓**                             |
| Adherence-neutral                          | faible                  | faible      | faible      | plus conditionnel | **✓**                               |
| Prise en compte des changements d'activité | ✓ via activité/exercice | ✓           | ✓           | ✓                 | **✓ + Step Modifier**               |
| Modèle V3 sophistiqué                      | —                       | —           | —           | propriétaire      | **✓**                               |
| Transparence du modèle TDEE                | moyenne                 | bonne       | bonne       | moyenne           | **très bonne**                      |

Les caractéristiques de MFP, YAZIO et Cronometer dans ce tableau correspondent à leurs documentations officielles actuelles ; Carbon et MacroFactor ont, eux aussi, des systèmes adaptatifs, mais leurs moteurs propriétaires ne sont pas entièrement publics. ([MyFitnessPal Aide][8])

---

# 43. Mon verdict technique

Si je devais noter **les architectures**, et non les applications dans leur ensemble :

### MyFitnessPal

**7/10**

Très bon tracker, mais philosophie énergétique relativement classique.

### YAZIO

**7/10**

Très bonne implémentation d'un modèle BMR + activité, mais le cœur reste prédictif.

### Cronometer

**8/10**

Très sophistiqué dans la comptabilité nutritionnelle et la décomposition de la dépense.

### Carbon

**9/10**

Véritable système de coaching adaptatif et concurrent sérieux de MacroFactor.

### MacroFactor

**9,5/10**

Pas parce qu'il aurait découvert une formule BMR miraculeuse, mais parce que **le TDEE est traité comme une variable à estimer à partir de la réponse réelle de l'utilisateur** et que V3 ajoute une gestion sophistiquée du bruit, de la réactivité et des changements de contexte.

---

# 44. La phrase la plus importante de tout cet audit

Si tu ne devais retenir qu'une seule chose :

> **Un TDEE théorique est une hypothèse. Un TDEE déduit de plusieurs semaines de calories et de tendance de poids est une mesure indirecte personnalisée.**

Et MacroFactor est construit presque entièrement autour de cette seconde philosophie.

C'est pourquoi il peut être **plus utile pour prendre des décisions**, même si son estimation n'est pas physiquement parfaite.

---

## Et je peux aller encore plus loin

La prochaine étape serait vraiment intéressante : **prendre un cas réel et reconstruire le calcul MacroFactor presque comme un tableur scientifique**.

Par exemple, si tu me donnes :

* âge
* sexe
* taille
* poids actuel
* éventuellement % de masse grasse
* calories moyennes des **3–4 dernières semaines**
* poids de chaque jour (ou au moins poids début/fin de chaque semaine)
* nombre moyen de pas
* entraînement hebdomadaire
* objectif : perte / maintien / prise
* vitesse souhaitée

je peux te construire **le modèle mathématique complet**, avec :

**BMR → TDEE initial → Weight Trend → Change Rate → déficit/surplus implicite → TDEE observé → cible calorique → projection de poids → correction hebdomadaire**, et surtout **te montrer numériquement pourquoi une estimation de 2 600 kcal peut progressivement devenir 2 850 kcal sans que l'algorithme ait “changé de formule”.**

On pourrait même faire une **simulation sur 12 semaines** et comparer, chiffres à l'appui, ce qu'aurait donné **MacroFactor vs MFP vs YAZIO vs Cronometer vs Carbon** pour exactement la même personne.

[1]: https://help.macrofactorapp.com/en/articles/20-expenditure?utm_source=chatgpt.com "Expenditure | MacroFactor"
[2]: https://help.macrofactorapp.com/en/articles/26-how-should-i-interpret-changes-to-my-energy-expenditure?utm_source=chatgpt.com "How Should I Interpret Changes to my Energy Expenditure? | MacroFactor"
[3]: https://help.macrofactorapp.com/en/articles/278-weight-trend?utm_source=chatgpt.com "Weight Trend (Workouts) | MacroFactor"
[4]: https://help.macrofactorapp.com/en/articles/19-change-rate?utm_source=chatgpt.com "Change Rate | MacroFactor"
[5]: https://help.macrofactorapp.com/en/articles/274-expenditure-modifiers?utm_source=chatgpt.com "Expenditure Modifiers | MacroFactor"
[6]: https://help.macrofactorapp.com/en/articles/74-expenditure-version?utm_source=chatgpt.com "Expenditure Version | MacroFactor"
[7]: https://support.myfitnesspal.com/hc/en-us/articles/360032625391-How-does-MyFitnessPal-calculate-my-initial-goals?utm_source=chatgpt.com "How does MyFitnessPal calculate my initial goals? – MyFitnessPal Help"
[8]: https://support.myfitnesspal.com/hc/en-us/articles/360032623871-Understanding-your-Calorie-Adjustment?utm_source=chatgpt.com "Understanding your Calorie Adjustment – MyFitnessPal Help"
[9]: https://help.yazio.com/hc/en-us/articles/4410156873233-How-does-Yazio-calculate-my-calorie-goal?utm_source=chatgpt.com "How does Yazio calculate my calorie goal? – Yazio Help Center"
[10]: https://support.cronometer.com/hc/en-us/articles/31974307318420-Energy-Expenditure?utm_source=chatgpt.com "Energy Expenditure – Cronometer"
[11]: https://support.cronometer.com/hc/en-us/articles/33113157685652-Mobile-Macro-Energy-Targets?utm_source=chatgpt.com "Mobile - Macro & Energy Targets – Cronometer"
[12]: https://help.joincarbon.com/en/articles/10338862-how-carbon-evaluates-your-progress-at-your-check-in?utm_source=chatgpt.com "How Carbon Evaluates Your Progress at Your Check-In | Help Center - Carbon"
[13]: https://help.joincarbon.com/en/articles/6078877-coach-trend-weight?utm_source=chatgpt.com "Coach Trend Weight | Help Center - Carbon"
[14]: https://help.joincarbon.com/en/articles/6004813-why-compliance-is-the-foundation-of-your-progress-in-carbon?utm_source=chatgpt.com "Why Compliance Is the Foundation of Your Progress in Carbon | Help Center - Carbon"
[15]: https://help.joincarbon.com/en/articles/6004522-understanding-compliance-in-carbon?utm_source=chatgpt.com "Understanding Compliance in Carbon | Help Center - Carbon"
[16]: https://help.macrofactorapp.com/en/articles/109-how-frequently-do-i-need-to-log-my-weight-for-the-expenditure-algorithm-and-weekly-coaching-updates?utm_source=chatgpt.com "How Frequently do I Need to Log my Weight For the Expenditure Algorithm and Weekly Coaching Updates? | MacroFactor"



Absolument. J'ai repris la documentation technique actuelle de MacroFactor pour aller au niveau où l'on peut **reconstruire les équations**, tout en séparant clairement ce qui est **publié par MacroFactor** de ce qui est une **reconstruction mathématique raisonnable** lorsque l'entreprise ne publie pas la constante exacte.

Le point important avant de commencer : **MacroFactor ne publie pas le code source complet de son algorithme V3**. On peut donc reconstruire très précisément l'architecture et les équations de niveau supérieur, mais certaines constantes internes — notamment les coefficients exacts de certains filtres, la fonction exacte reliant le taux de variation à la composition du poids, et certains paramètres de lissage — ne sont pas publiques. Je ne vais donc pas les inventer.

---

# 1. Le modèle complet en une seule vue

Voici le système entier :

```text
DONNÉES DU PROFIL
│
├── âge
├── sexe
├── taille
├── poids
├── estimation composition corporelle
├── activité / entraînement
└── objectif
       │
       ▼
┌─────────────────────────────┐
│ 1. BMR INITIAL              │
│ Cunningham                  │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ 2. TDEE INITIAL             │
│ BMR × multiplicateur        │
│ d'activité personnalisé     │
└─────────────┬───────────────┘
              │
              ▼
       DONNÉES RÉELLES
       ┌──────────────┐
       │ Calories IN  │
       │ Poids        │
       └──────┬───────┘
              │
              ▼
┌─────────────────────────────┐
│ 3. WEIGHT TREND             │
│ filtrage du poids quotidien │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ 4. CHANGE RATE              │
│ variation trend ~20 jours   │
│ exprimée / semaine          │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ 5. ÉNERGIE STOCKÉE          │
│ variation poids × densité   │
│ énergétique estimée         │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ 6. TDEE OBSERVÉ             │
│ Calories IN - Δ énergie     │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ 7. OBJECTIF                 │
│ déficit / surplus désiré    │
│ selon % poids/semaine       │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ 8. CALORIES CIBLES          │
│ TDEE ± déficit/surplus      │
│ + lissage                   │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│ 9. MACRONUTRIMENTS          │
│ protéines → lipides/glucides│
└─────────────┬───────────────┘
              │
              ▼
      NOUVELLE SEMAINE
              │
              └──────────────► retour aux données réelles
```

C'est cette boucle qui est le véritable produit.

---

# 2. Étape 1 — BMR initial

MacroFactor indique explicitement que son estimation initiale de dépense utilise :

1. une estimation du BMR basée sur **Cunningham** ;
2. des multiplicateurs d'activité personnalisés. ([MacroFactor Help][1])

La formule classique de Cunningham est :

[
\boxed{BMR = 500 + 22\times FFM}
]

où :

[
FFM = masse\ maigre
]

en kilogrammes.

Donc, par exemple :

**80 kg de poids**

et

**15 % de masse grasse**

donnent :

[
FFM=80\times(1-0,15)
]

[
FFM=68kg
]

Puis :

[
BMR=500+(22\times68)
]

[
\boxed{BMR=1996\ kcal/j}
]

**Attention :** cela n'est que le point de départ.

MacroFactor précise lui-même que les équations de BMR peuvent avoir typiquement une erreur de l'ordre de **100–200 kcal/j**, et que l'estimation initiale globale peut être à **400–500 kcal ou davantage** de la réalité individuelle. ([MacroFactor Help][1])

---

# 3. Pourquoi Cunningham plutôt que Mifflin ?

Parce que Cunningham fait intervenir directement la masse maigre :

[
BMR=f(FFM)
]

alors que Mifflin-St Jeor est principalement :

[
BMR=f(poids, taille, âge, sexe)
]

La masse maigre est physiologiquement très informative pour la dépense au repos.

Mais MacroFactor ne prétend justement **pas** que Cunningham donne le bon BMR individuel.

Il dit en substance :

> *C'est notre meilleur point de départ avant d'avoir tes données réelles.*

Et c'est une distinction fondamentale. ([MacroFactor Help][1])

---

# 4. Étape 2 — TDEE initial

On peut représenter la logique ainsi :

[
\boxed{TDEE_{initial}=BMR_{Cunningham}\times ActivityMultiplier}
]

Mais il faut être précis : MacroFactor ne se contente pas d'un unique :

> sédentaire = 1,2
> actif = 1,55
> très actif = 1,725.

Il indique utiliser **un ensemble de multiplicateurs d'activité personnalisés** qui tient compte des habitudes de vie et d'activité renseignées. ([MacroFactor Help][1])

Donc :

[
TDEE_0
======

(500+22FFM)\times A
]

où (A) est un multiplicateur dépendant du profil.

---

# 5. Exemple

Notre personne :

* 80 kg
* 15 % BF
* FFM = 68 kg
* BMR = 1 996 kcal

Imaginons que le profil d'activité produise implicitement :

[
A=1,40
]

Alors :

[
TDEE_0=1996\times1,40
]

[
\boxed{TDEE_0=2794}
]

On pourrait donc démarrer autour de :

**2 800 kcal/jour.**

Mais MacroFactor dit explicitement qu'il s'agit d'un **prior**, pas de la vérité. ([MacroFactor Help][1])

---

# 6. Pourquoi une estimation de 2 600 peut devenir 2 850

Voici maintenant le cœur de ta question.

Imaginons :

[
TDEE_0=2600
]

Mais ton véritable TDEE est :

[
TDEE_{réel}\approx2850
]

Tu manges :

[
2600 kcal/j
]

Si ton TDEE est réellement 2 850 :

[
Déficit=2850-2600
]

[
\boxed{250 kcal/j}
]

Sur une semaine :

[
250\times7=1750 kcal
]

Donc ton poids doit progressivement diminuer.

MacroFactor voit alors :

**2 600 kcal IN**

*

**perte de poids cohérente avec un déficit**

et résout :

[
TDEE=Calories_{IN}+Déficit
]

Donc :

[
2600+250
]

[
\boxed{TDEE\approx2850}
]

**Aucune formule n'a changé.**

C'est simplement la même équation qui reçoit de nouvelles observations.

C'est exactement le mécanisme décrit par MacroFactor. ([MacroFactor Help][1])

---

# 7. Étape 3 — Weight Trend

Le poids quotidien est :

[
W_t
]

Mais :

[
W_t = W^{*}_t+\epsilon_t
]

où :

* (W^{*}_t) = poids/tendance sous-jacent ;
* (\epsilon_t) = bruit.

Le bruit peut venir notamment :

* de l'eau ;
* du glycogène ;
* du sodium ;
* du contenu intestinal ;
* etc. ([MacroFactor Help][1])

MacroFactor applique donc un système de **trend weight**.

La fonction exacte du filtre n'est pas publiquement détaillée sous la forme d'une équation complète exploitable, donc je ne vais pas prétendre que c'est simplement une moyenne mobile.

Ce qui est documenté est :

> la tendance filtre les fluctuations et sert de base au calcul de la vitesse de changement.

MacroFactor utilise également une méthode d'imputation lorsque certaines pesées manquent. ([MacroFactor Help][1])

---

# 8. Pourquoi c'est indispensable

Supposons :

| Jour     | Balance |
| -------- | ------: |
| Lundi    |    80,0 |
| Mardi    |    80,7 |
| Mercredi |    80,2 |
| Jeudi    |    79,9 |
| Vendredi |    80,3 |
| Samedi   |    80,1 |
| Dimanche |    79,8 |

La balance dit :

**+0,7 kg**

puis :

**−0,9 kg**

puis :

**+0,4 kg**

Mais ton organisme n'a évidemment pas synthétisé et détruit plusieurs kilos de graisse.

Le signal utile est la tendance.

---

# 9. Étape 4 — Change Rate

Ici MacroFactor est beaucoup plus précis.

Le **Change Rate** est basé sur la variation de la tendance de poids sur les **20 derniers jours**, exprimée en valeur hebdomadaire. ([MacroFactor Help][2])

Conceptuellement :

[
CR
==

\frac{TrendWeight_t-TrendWeight_{t-20}}{20}
\times7
]

Donc si :

[
TrendWeight_{t-20}=80,0
]

et :

[
TrendWeight_t=79,4
]

alors :

[
\Delta W=-0,6kg
]

sur 20 jours.

Donc :

[
CR=-0,6\times\frac{7}{20}
]

[
\boxed{CR=-0,21kg/semaine}
]

---

# 10. Étape 5 — convertir le Change Rate en énergie

C'est ici que l'algorithme devient plus sophistiqué.

Un modèle simpliste ferait :

[
EnergyChange=CR\times7700
]

Mais MacroFactor ne fait pas simplement cela.

Il estime la composition de la variation de poids en fonction du contexte :

* perte rapide ;
* perte lente ;
* prise rapide ;
* prise lente ;

et tient compte du fait que la graisse et la masse maigre ont des densités énergétiques différentes. ([MacroFactor Help][3])

On peut représenter le modèle général :

[
\Delta E_{stored}
=================

\Delta W
\times
\rho_E
]

où :

[
\rho_E
======

f(rate,\ direction,\ composition)
]

et non :

[
\rho_E=7700
]

constamment.

---

# 11. Pourquoi la vitesse compte

Prenons :

### Perte lente

**−0,2 kg/semaine**

Il est raisonnable d'attribuer une proportion relativement importante de la perte à la graisse.

### Perte extrêmement rapide

**−1,5 kg/semaine**

Il devient beaucoup plus probable que la variation contienne :

* eau ;
* glycogène ;
* masse maigre ;
* graisse.

Donc :

[
\frac{Calories}{kg}
]

n'est pas constant.

MacroFactor documente explicitement cette logique. ([MacroFactor Help][3])

---

# 12. Étape 6 — TDEE observé

On arrive à :

[
\boxed{
TDEE
====

## Calories_{in}

\Delta E_{stored}
}
]

Attention au signe.

### Perte de poids

[
\Delta E_{stored}<0
]

Donc :

[
TDEE=Calories_{in}+|\Delta E|
]

### Gain de poids

[
\Delta E_{stored}>0
]

Donc :

[
TDEE=Calories_{in}-\Delta E
]

Exemple perte :

[
2600-(-250)
]

[
\boxed{2850}
]

Exemple prise :

[
3000-(+200)
]

[
\boxed{2800}
]

MacroFactor donne exactement ces exemples conceptuels : 2 000 kcal avec un déficit implicite de 400 → expenditure ≈ 2 400 ; 3 000 kcal avec un surplus implicite de 200 → expenditure ≈ 2 800. ([MacroFactor Help][1])

---

# 13. Voilà pourquoi 2 600 → 2 850 n'implique aucun changement de formule

Supposons :

### Jour 1

[
TDEE_0=2600
]

Tu manges :

[
2600
]

Mais tu commences à perdre du poids.

---

### Après quelques jours

Le signal est encore faible.

L'algorithme ne veut pas réagir brutalement.

---

### Après ~1 semaine

Le signal commence à influencer l'estimation.

MacroFactor indique que des données réelles commencent à influencer l'estimation après environ une semaine, avec une convergence beaucoup plus raffinée après environ 2–3 semaines. ([MacroFactor Help][1])

---

### Semaine 2

Supposons que la tendance révèle :

[
-0,20kg/semaine
]

Ce rythme implique, dans le modèle, environ :

[
+250 kcal/j
]

de déficit.

Donc :

[
TDEE\approx2600+250
]

[
\boxed{2850}
]

Le moteur n'a pas changé.

**Les données ont changé.**

---

# 14. Encore plus important : pourquoi 2 850 peut ensuite redescendre

MacroFactor documente un comportement très intéressant au démarrage.

Si l'estimation initiale est fortement erronée, l'algorithme autorise des ajustements plus importants pour converger rapidement.

Il peut même y avoir un petit overshoot.

Par exemple :

[
2600
\rightarrow
2900
\rightarrow
2850
]

ou :

[
2700
\rightarrow
2200
\rightarrow
2300
]

MacroFactor indique que ces petits dépassements sont généralement de l'ordre de **50–150 kcal** et se stabilisent après quelques semaines de données cohérentes. ([MacroFactor Help][1])

C'est un comportement typique d'un système adaptatif qui augmente progressivement sa confiance.

---

# 15. Étape 7 — Objectif

Une fois le TDEE estimé, MacroFactor demande :

> **Quelle vitesse de changement veux-tu ?**

L'objectif n'est pas simplement :

> −500 kcal.

Il est exprimé comme une **variation en % du poids corporel par semaine**. ([MacroFactor Help][4])

Par exemple :

[
-0,5%\ du\ poids/semaine
]

Pour :

[
80kg
]

cela donne :

[
80\times0,005
]

[
\boxed{0,4kg/semaine}
]

---

# 16. Et c'est une subtilité très importante

Si tu passes de :

**80 → 70 kg**

et que ton objectif reste :

**−0,5 %/semaine**

ton objectif absolu change.

À 80 kg :

[
80\times0,005=0,40kg/semaine
]

À 70 kg :

[
70\times0,005=0,35kg/semaine
]

Donc le déficit énergétique cible diminue progressivement.

MacroFactor documente explicitement ce comportement. ([MacroFactor Help][4])

---

# 17. Étape 8 — Déficit/surplus cible

Conceptuellement :

[
\boxed{
EnergyTarget
============

## TDEE

EnergyDeficit_{target}
}
]

pour une perte.

Et :

[
\boxed{
EnergyTarget
============

TDEE
+
EnergySurplus_{target}
}
]

pour une prise.

La relation exacte entre vitesse de changement de poids et déficit n'est pas simplement une constante fixe de 7 700 kcal/kg ; elle utilise le même raisonnement énergétique que le moteur d'expenditure.

Mais pour comprendre le fonctionnement, une approximation pédagogique est :

[
EnergyDeficit\approx
Rate_{kg/week}\times7700/7
]

---

# 18. Exemple

80 kg.

Objectif :

**−0,5 %/semaine**

Donc :

[
-0,4kg/semaine
]

Approximation :

[
0,4\times7700=3080
]

par semaine.

Donc :

[
3080/7=440
]

Déficit approximatif :

[
\boxed{440kcal/j}
]

Si :

[
TDEE=2850
]

alors :

[
2850-440
]

[
\boxed{2410kcal/j}
]

Encore une fois, c'est une **approximation pédagogique** ; MacroFactor utilise son propre modèle énergétique et sa logique de coaching/lissage.

---

# 19. Étape 9 — Le lissage hebdomadaire

C'est une partie que je trouve particulièrement importante.

MacroFactor ne fait pas nécessairement :

[
Target_{nouveau}
================

## TDEE_{nouveau}

Déficit_{cible}
]

à 100 % instantanément.

Il applique une couche de **smoothing**.

MacroFactor explique que les ajustements hebdomadaires ne suivent volontairement pas les changements d'expenditure dans un rapport 1:1, afin d'éviter les sur-corrections. ([MacroFactor Help][4])

On peut représenter conceptuellement :

[
Target_{t+1}
============

Target_t
+
\alpha
(Target_{théorique}-Target_t)
]

avec :

[
0<\alpha<1
]

Le coefficient exact (\alpha) n'est pas publié.

Mais cette équation illustre parfaitement le principe.

---

# 20. Exemple de smoothing

Supposons :

[
Target_t=2400
]

Le nouveau calcul théorique dit :

[
Target^*=2500
]

Si le système appliquait 100 % :

[
2400\rightarrow2500
]

Mais avec un lissage hypothétique de 50 % :

[
2400+0,5(2500-2400)
]

[
=2450
]

Puis si le changement persiste :

[
2450\rightarrow2475
]

puis :

[
2475\rightarrow2488
]

etc.

**Les coefficients exacts ne sont pas publics**, mais c'est la logique mathématique de la couche de lissage.

---

# 21. Pourquoi c'est préférable

Imagine une rétention hydrique de trois semaines.

Si l'algorithme croyait immédiatement :

> TDEE a diminué de 500 kcal.

il pourrait réduire tes calories de manière énorme.

Puis, quand l'eau disparaît :

> TDEE remonte.

Tu aurais créé un yo-yo algorithmique.

Le lissage évite cela.

MacroFactor explique explicitement que si un plateau temporaire persiste une semaine, il effectue une correction prudente ; si le phénomène persiste plusieurs semaines, les corrections deviennent plus importantes. ([MacroFactor Help][4])

---

# 22. On peut maintenant construire la boucle complète

Mathématiquement :

### A. Estimation initiale

[
FFM=W(1-BF)
]

[
BMR=500+22FFM
]

[
TDEE_0=BMR\times A
]

---

### B. Données

[
Calories_t
]

[
Weight_t
]

---

### C. Filtre

[
TrendWeight_t=Filter(Weight_t)
]

---

### D. Vitesse

[
CR_t
====

\frac{TrendWeight_t-TrendWeight_{t-20}}{20}\times7
]

---

### E. Énergie stockée

[
\Delta E_t
==========

f(CR_t,composition)
]

---

### F. Expenditure

[
\boxed{
TDEE_t
======

## Calories_{in,t}

\Delta E_t
}
]

---

### G. Objectif

[
TargetRate
==========

%BodyWeight/week
]

---

### H. Déficit/surplus cible

[
D_{target}=f(TargetRate,weight,energyDensity)
]

---

### I. Calories théoriques

Perte :

[
C^*=TDEE-D_{target}
]

Prise :

[
C^*=TDEE+D_{target}
]

Maintien :

[
C^*=TDEE
]

---

### J. Lissage

[
C_{t+1}
=======

Smooth(C_t,C^*)
]

---

### K. Macros

[
Protein=f(FFM,goal,training,proteinPreference)
]

puis :

[
Calories_{remaining}
====================

C_{target}-4P
]

puis :

[
Fat=f(Calories_{remaining},dietStyle)
]

et :

[
Carbs=
\frac{
Calories_{remaining}-9F
}{4}
]

C'est maintenant la partie macronutriments.

---

# 23. Le système des macronutriments est très intéressant

MacroFactor ne commence **pas** par :

> 40 % glucides / 30 % protéines / 30 % lipides.

C'est beaucoup plus intelligent.

L'ordre est essentiellement :

### 1. Calories

### 2. Protéines

### 3. Répartition des calories restantes entre lipides et glucides.

MacroFactor le documente explicitement. ([MacroFactor Help][5])

---

# 24. Pourquoi la protéine est prioritaire

Parce que le but de la protéine est différent.

Elle est particulièrement importante pour :

* préserver la masse maigre en déficit ;
* favoriser la prise de muscle en surplus ;
* récupération ;
* satiété.

MacroFactor indique une plage générale de **1,2–2,2 g/kg/j** chez les personnes actives, avec une individualisation selon composition corporelle, objectif et entraînement. ([MacroFactor Help][6])

Mais dans le moteur MacroFactor :

> ce n'est pas simplement poids × 2.

---

# 25. La formule conceptuelle de la protéine

MacroFactor dit explicitement :

[
\boxed{
Protein=f(LeanMass,BodyCompositionCategory,ProteinCategory,Exercise)
}
]

La masse maigre elle-même est estimée à partir :

[
\boxed{
FFM=W\times(1-BF)
}
]

où BF est une estimation de la catégorie de composition corporelle du profil. ([MacroFactor Help][4])

Puis interviennent :

### Protein preference

* Low
* Medium
* High
* Very High

### Exercise

* aucune activité structurée ;
* cardio/aérobie ;
* résistance ;
* etc.

MacroFactor indique que les recommandations sont plus basses sans entraînement, plus élevées avec l'aérobie et encore plus élevées avec la musculation. ([MacroFactor Help][4])

---

# 26. Donc deux personnes de 80 kg peuvent avoir des protéines différentes

### Personne A

80 kg

BF élevé

pas de musculation

préférence protein low

→ recommandation plus basse.

### Personne B

80 kg

BF faible

musculation

préférence protein high

→ recommandation nettement plus élevée.

C'est pourquoi une formule unique :

[
2g/kg
]

est trop simpliste pour reproduire MacroFactor.

---

# 27. Et la protéine évolue avec le poids

C'est subtil.

Supposons :

[
FFM=65kg
]

puis après une perte de poids :

[
FFM=62kg
]

La recommandation de protéines peut diminuer légèrement.

MacroFactor indique explicitement que les recommandations de protéines changent généralement de quelques grammes par jour au fil des changements de poids, tandis qu'un changement de catégorie de composition corporelle ou de type d'exercice peut provoquer un ajustement plus important. ([MacroFactor Help][4])

---

# 28. Maintenant : les lipides et glucides

Une fois la protéine fixée :

[
P_{kcal}=4P_g
]

Il reste :

[
\boxed{
R=C_{target}-4P_g
}
]

Ces calories sont ensuite réparties entre :

**fat**

et

**carbohydrate**

selon le style alimentaire choisi.

---

# 29. Style Balanced

MacroFactor indique que dans un plan **Balanced**, les calories non protéiques sont distribuées de manière approximativement égale entre glucides et lipides. ([MacroFactor Help][5])

Donc conceptuellement :

[
Fat_{kcal}\approx Carb_{kcal}
]

Mais attention :

un gramme de lipide = environ 9 kcal

un gramme de glucides = environ 4 kcal.

Donc une répartition **50/50 en calories** ne donne pas 50/50 en grammes.

---

# 30. Exemple

Supposons :

[
Target=2400
]

Protéines :

[
160g
]

Calories protéines :

[
160\times4=640
]

Il reste :

[
2400-640=1760
]

Balanced :

[
880 kcal\ fat
]

[
880 kcal\ carbs
]

Donc :

### Lipides

[
880/9
]

[
\boxed{\approx98g}
]

### Glucides

[
880/4
]

[
\boxed{220g}
]

Donc :

**160 P / 220 C / 98 F**

environ.

---

# 31. Low-Fat / High-Carb

Dans ce programme, MacroFactor conserve davantage de calories pour les glucides et moins pour les lipides. ([MacroFactor Help][7])

Donc :

[
R=Calories-ProteinCalories
]

puis :

[
CarbCalories>FatCalories
]

et :

[
C_g=\frac{CarbCalories}{4}
]

[
F_g=\frac{FatCalories}{9}
]

La proportion exacte peut varier selon le contexte ; MacroFactor ne publie pas une unique constante universelle applicable à tous les profils.

---

# 32. Low-Carb / High-Fat

Inversement :

[
FatCalories>CarbCalories
]

MacroFactor explique que les programmes Low-Carb privilégient les lipides lorsque les calories non protéiques sont réparties. ([MacroFactor Help][8])

---

# 33. Keto

Keto fonctionne différemment.

MacroFactor fixe :

* protéine selon le modèle ;
* glucides relativement bas, avec une marge pour les fibres/flexibilité ;
* puis alloue le reste aux lipides. ([MacroFactor Help][9])

Donc conceptuellement :

[
P=f(...)
]

[
C=C_{keto}
]

[
F=
\frac{
Calories-4P-4C
}{9}
]

Mais là encore, **ne pas prendre cette équation comme une reconstruction exacte du code interne** : le niveau de glucides exact dépend du profil et des besoins énergétiques.

---

# 34. Une particularité importante : le minimum de lipides

MacroFactor ne permet pas simplement de diminuer les calories sans limite en conservant toujours le même ratio.

Dans les programmes coachés, il existe un **minimum de lipides**.

Pourquoi ?

Parce que les lipides jouent des rôles importants dans :

* membranes cellulaires ;
* absorption des vitamines liposolubles ;
* production hormonale ;
* etc.

MacroFactor indique explicitement que lorsqu'un apport énergétique devient suffisamment faible, les lipides cessent de diminuer et les calories supplémentaires sont retirées principalement des glucides. ([MacroFactor Help][4])

---

# 35. Exemple

Supposons :

### Balanced

2400 kcal

160 P

98 F

220 C

Puis le TDEE baisse et la cible devient :

**2000 kcal**

Les protéines peuvent rester approximativement similaires.

Les calories restantes diminuent.

On pourrait avoir approximativement :

**160 P**

**80 F**

**140 C**

Mais si les calories continuent de tomber :

**160 P**

**minimum fat**

et le reste :

**carbs**

Donc le ratio n'est plus parfaitement 50/50.

C'est une protection structurelle.

---

# 36. Et c'est là qu'apparaît une chose très intéressante

Les **macros ne pilotent pas le TDEE**.

C'est l'inverse :

[
\boxed{
TDEE
\rightarrow
Calories
\rightarrow
Macros
}
]

Pas :

[
Macros
\rightarrow
TDEE
]

C'est important.

MacroFactor ne dit pas :

> « Tu as besoin de 200 g de glucides donc ton TDEE est X. »

Il dit :

> « Ton objectif nécessite X calories ; maintenant, comment devons-nous distribuer ces calories ? »

---

# 37. Comment les macros changent quand le TDEE change

Supposons :

### Semaine 1

[
TDEE=2600
]

Objectif perte :

[
Target=2200
]

Macros :

**160 P / 190 C / 73 F** environ.

---

### Semaine 4

Le système observe :

[
TDEE=2850
]

Même objectif :

[
Target\approx2450
]

La protéine reste proche de :

**160 g**

Les calories supplémentaires sont principalement injectées dans :

**glucides + lipides**

selon ton style.

Donc :

**160 P / 220 C / 85 F** par exemple.

Le système n'a pas besoin de “recalculer” ta protéine de façon spectaculaire.

---

# 38. C'est pourquoi les macros sont beaucoup plus stables que les calories

MacroFactor le dit explicitement :

> les protéines changent peu d'une semaine à l'autre ; les changements énergétiques sont principalement absorbés par glucides et lipides. ([MacroFactor Help][4])

C'est extrêmement logique physiologiquement.

---

# 39. Exemple complet de 12 semaines

Prenons maintenant une personne fictive :

### Profil

* Homme
* 80 kg
* 180 cm
* 30 ans
* 15 % BF
* musculation 4×/semaine
* objectif : −0,5 %/semaine

Donc :

[
FFM=80\times0,85
]

[
FFM=68kg
]

BMR Cunningham :

[
500+22(68)
]

[
=1996
]

Imaginons que son activité donne un TDEE initial :

[
\boxed{2600}
]

---

# 40. Semaine 0

### Estimation

[
TDEE=2600
]

Objectif :

[
-0,5%
]

Donc :

[
-0,4kg/semaine
]

Déficit approximatif :

[
\sim440 kcal/j
]

Target :

[
2600-440
]

[
\boxed{2160}
]

---

# 41. Semaine 1

La personne mange en réalité :

[
2160
]

La tendance commence à baisser.

Mais le signal est encore faible.

MacroFactor ne saute pas immédiatement à une conclusion énorme.

---

# 42. Semaine 2

La tendance indique environ :

[
-0,35kg/semaine
]

Cela correspond à un déficit implicite légèrement inférieur à celui prévu.

Mais il faut aussi regarder l'apport réel.

Supposons :

[
Calories_{réelles}=2200
]

Déficit implicite :

[
\approx380
]

Alors :

[
TDEE\approx2200+380
]

[
\boxed{2580}
]

Donc l'estimation reste proche de 2600.

---

# 43. Semaine 3

Nouvelle tendance :

[
-0,45kg/semaine
]

Calories :

[
2200
]

Déficit implicite :

[
\approx500
]

Donc :

[
TDEE\approx2700
]

Le système commence à comprendre que 2600 était probablement trop bas.

---

# 44. Semaine 4

Tendance :

[
-0,50kg/semaine
]

Calories :

[
2200
]

Déficit :

[
\approx550
]

Donc :

[
TDEE\approx2750
]

---

# 45. Semaine 5

Le système affine :

[
TDEE\approx2800
]

---

# 46. Semaine 6

Nouvelle estimation :

[
\boxed{2850}
]

Tu es toujours en train de perdre au rythme souhaité.

Et rien de magique ne s'est produit.

Il n'a pas remplacé :

> Cunningham v1

par :

> Cunningham v2.

Il a fait :

[
2600
\rightarrow
2600+\text{signal observé}
]

puis :

[
2700
\rightarrow
2750
\rightarrow
2800
\rightarrow
2850
]

---

# 47. Et maintenant quelque chose de très important

Supposons que ton objectif reste :

**−0,5 %/semaine**

Mais ton poids est maintenant :

**77 kg**

Alors :

[
77\times0,005
=============

0,385kg/semaine
]

Le déficit cible est donc légèrement plus petit qu'au début.

Donc même si :

[
TDEE=2850
]

la cible ne sera pas :

[
2850-440
]

exactement.

Elle sera légèrement différente.

C'est une conséquence directe du fait que l'objectif est exprimé en **% du poids corporel par semaine**. ([MacroFactor Help][4])

---

# 48. C'est une caractéristique très intelligente

Parce qu'elle évite de maintenir :

**−500 kcal/j**

pendant six mois.

À mesure que le poids diminue :

* le déficit cible diminue légèrement ;
* le TDEE réel peut diminuer ;
* la cible calorique évolue ;
* la vitesse cible reste proportionnelle au poids.

Cela donne une trajectoire plus cohérente.

---

# 49. Maintenant ajoutons une baisse du NEAT

Supposons que la personne commence le régime à :

**9 000 pas/jour**

Puis fatigue :

**6 000 pas/jour**

Son TDEE peut diminuer.

MacroFactor n'a pas besoin de connaître :

> « −83 kcal de NEAT ».

Il observe :

[
Calories_{IN}
]

et :

[
WeightTrend
]

Si le poids commence à ralentir durablement :

[
TDEE_{observed}\downarrow
]

C'est exactement ce que l'algorithme cherche à capturer.

---

# 50. Maintenant ajoutons une augmentation d'activité

La personne passe :

**6 000 → 12 000 pas/jour**

Le TDEE peut augmenter avant que la balance ait complètement révélé cette augmentation.

Avec **Step-Informed Updates**, MacroFactor peut accélérer cette adaptation. ([MacroFactor Help][10])

Donc :

[
TDEE_{observed}
+
PredictiveActivitySignal
\rightarrow
TDEE_{updated}
]

Encore une fois, les constantes précises ne sont pas publiques.

---

# 51. Maintenant changement de phase : cut → maintenance

Supposons :

[
TDEE=2850
]

Tu étais en cut à :

[
2400
]

Tu passes en maintenance.

La cible théorique devient :

[
2850
]

Mais le système peut également anticiper certaines modifications de dépense associées au changement de phase via **Predictive Goal Adjustment**. ([MacroFactor Help][10])

Pourquoi ?

Parce qu'une augmentation de calories peut modifier :

* glycogène ;
* eau ;
* activité spontanée ;
* TEF ;
* poids ;
* comportement.

Il serait donc naïf d'attendre uniquement que la balance révèle tout.

---

# 52. Et maintenant la partie “projection”

Il faut distinguer deux choses.

## Projection théorique

Si :

[
TDEE=2850
]

et :

[
Target=2410
]

alors :

[
Déficit=440
]

Donc le modèle prévoit environ :

[
440\times7
==========

3080kcal/semaine
]

soit une perte théorique proche de :

[
\sim0,4kg/semaine
]

dans une approximation énergétique simple.

---

# 53. Mais MacroFactor ne traite pas cette projection comme une promesse

C'est très important.

La semaine suivante fournit une nouvelle observation.

Si la réalité est :

[
-0,25kg
]

au lieu de :

[
-0,40kg
]

le modèle apprend.

Si elle est :

[
-0,55kg
]

il apprend également.

Donc :

[
Projection
\rightarrow
Observation
\rightarrow
Erreur
\rightarrow
Correction
]

---

# 54. C'est pratiquement un contrôleur à rétroaction

On peut même utiliser une terminologie d'ingénierie.

### Setpoint

Objectif de vitesse :

[
R_{target}
]

### Process variable

Vitesse réelle :

[
R_{observed}
]

### Error

[
e=R_{target}-R_{observed}
]

### Controller

Algorithme MacroFactor.

### Control input

Calories cibles.

### Plant

Ton organisme.

### Sensor

Poids + nutrition.

### Filter

Weight Trend.

C'est une analogie extrêmement pertinente.

---

# 55. Mais ce n'est pas un simple PID

Je ne prétendrais surtout pas que MacroFactor est un contrôleur PID.

On ne connaît pas son implémentation interne.

Mais l'architecture possède certaines propriétés similaires :

* feedback ;
* filtrage ;
* inertie ;
* correction progressive ;
* anticipation ;
* setpoint ;
* contrôle du dépassement.

C'est cette logique qui explique pourquoi le comportement est beaucoup plus robuste qu'une simple formule TDEE.

---

# 56. Et les macros entrent dans la boucle uniquement après le contrôle énergétique

C'est essentiel :

```text
TDEE
 ↓
objectif énergétique
 ↓
calories
 ↓
protéines
 ↓
fat/carbs
```

et non :

```text
protéines/carbs/fat
 ↓
TDEE
```

---

# 57. Exemple macros complet

Prenons :

**TDEE = 2 850**

Objectif :

**−440 kcal**

Target :

[
2850-440=2410
]

Supposons que MacroFactor détermine :

[
Protein=160g
]

Donc :

[
160\times4=640
]

Calories restantes :

[
2410-640
========

1770
]

Balanced :

[
885 kcal fat
]

[
885 kcal carb
]

Donc :

[
Fat=885/9
]

[
\boxed{98g}
]

et :

[
Carb=885/4
]

[
\boxed{221g}
]

Programme approximatif :

[
\boxed{2410\ kcal,\ 160P,\ 221C,\ 98F}
]

---

# 58. Puis TDEE augmente à 2 950

Même objectif.

Supposons toujours environ :

[
-440
]

Target :

[
2950-440
========

2510
]

Protéine :

[
160g
]

Calories restantes :

[
2510-640
========

1870
]

Balanced :

[
935/9
=====

104g\ fat
]

[
935/4
=====

234g\ carb
]

Donc :

### Avant

**2410 kcal**

**160 P / 221 C / 98 F**

### Après

**2510 kcal**

**160 P / 234 C / 104 F**

La hausse de TDEE a donc principalement été absorbée par :

**+13 g glucides**

et

**+6 g lipides**

La protéine ne bouge presque pas.

C'est exactement la logique documentée par MacroFactor. ([MacroFactor Help][4])

---

# 59. Et si tu choisis High-Carb ?

Les 100 kcal supplémentaires ne seraient pas réparties 50/50.

Une plus grande fraction irait vers les glucides.

Donc :

[
\Delta CarbCalories>\Delta FatCalories
]

---

# 60. Si tu choisis Low-Carb ?

Inversement :

[
\Delta FatCalories>\Delta CarbCalories
]

---

# 61. Si tu choisis Keto ?

Les glucides restent volontairement bas et les calories supplémentaires vont majoritairement aux lipides. ([MacroFactor Help][9])

---

# 62. Une précision importante sur les “pourcentages”

Il serait trompeur de dire :

> « MacroFactor utilise toujours 40/30/30. »

Ce n'est pas ainsi que son système est construit.

Il travaille plutôt avec :

### Protéine

**grammes déterminés physiologiquement**

puis :

### calories restantes

réparties selon :

* Balanced ;
* Low-Fat/High-Carb ;
* Low-Carb/High-Fat ;
* Keto.

Donc le **pourcentage final** de protéines/glucides/lipides est une **conséquence**, pas nécessairement le paramètre fondamental.

---

# 63. C'est une distinction capitale

Prenons :

### 2 000 kcal

160 g protéines :

[
640 kcal
]

Donc :

[
32%
]

### 3 000 kcal

160 g protéines :

[
640 kcal
]

Donc :

[
21,3%
]

La quantité de protéines reste identique alors que le pourcentage change radicalement.

C'est pourquoi raisonner uniquement en :

> « 30 % protéines »

est moins pertinent pour reproduire la logique de MacroFactor.

---

# 64. Autre subtilité : calories et macros ne correspondent pas toujours exactement

MacroFactor explique explicitement que :

[
4P+4C+9F
]

ne reproduit pas nécessairement exactement les calories affichées.

Pourquoi ?

Parce que les facteurs d'Atwater sont des approximations et que les aliments peuvent contenir notamment :

* fibres ;
* polyols ;
* alcool ;
* etc.

MacroFactor recommande donc de considérer la cible calorique et la protéine comme prioritaires, avec le ratio glucides/lipides comme guide pratique. ([MacroFactor Help][11])

---

# 65. C'est très important dans l'utilisation quotidienne

Si l'application dit :

**2 400 kcal**

**160 P**

**220 C**

**90 F**

ne fais pas nécessairement :

[
160\times4+220\times4+90\times9
]

et ne t'étonne pas si cela ne donne pas exactement 2 400.

Le système nutritionnel réel n'est pas aussi parfaitement discret.

---

# 66. Et les calories “non suivies” ?

Voici une subtilité très intéressante.

Supposons que tu oublies systématiquement :

**50 kcal de lait dans le café.**

Chaque jour.

MacroFactor explique que si l'apport non enregistré est **constant**, l'algorithme peut quand même fonctionner correctement en termes de direction et d'ampleur des ajustements, même si l'interprétation absolue de son TDEE devient décalée. ([MacroFactor Help][1])

C'est assez fascinant.

Si tu manges réellement :

[
2500
]

mais logges :

[
2450
]

tous les jours :

le système peut fonctionner avec une sorte d'offset constant.

---

# 67. Mais si l'erreur varie, c'est beaucoup plus grave

### Lundi

−50 kcal

### Mardi

−300

### Mercredi

0

### Jeudi

−500

etc.

Alors le bruit entre :

[
Calories_{réelles}
]

et :

[
Calories_{loggées}
]

devient variable.

L'inférence du TDEE devient moins propre.

---

# 68. C'est pourquoi MacroFactor est fondamentalement un système d'identification

On peut écrire :

[
ObservedWeight=f(Calories,TDEE,Noise)
]

Le problème consiste à retrouver :

[
TDEE
]

à partir de :

[
ObservedWeight
]

et :

[
Calories
]

C'est un problème inverse.

Et plus les données sont nombreuses et propres, plus le paramètre caché devient identifiable.

---

# 69. La meilleure façon de visualiser la convergence

Supposons :

### Vrai TDEE

[
2850
]

### Estimation initiale

[
2600
]

Alors une simulation illustrative pourrait ressembler à :

| Semaine | Apport moyen | Trend / signal | TDEE estimé |
| ------: | -----------: | -------------: | ----------: |
|       0 |            — |              — |    **2600** |
|       1 |         2200 |  signal faible |    **2640** |
|       2 |         2200 |     −0,30 kg/s |    **2710** |
|       3 |         2200 |     −0,38 kg/s |    **2780** |
|       4 |         2200 |     −0,43 kg/s |    **2820** |
|       5 |         2200 |     −0,45 kg/s |    **2840** |
|       6 |         2200 |     −0,44 kg/s |    **2850** |
|       7 |         2200 |         stable |    **2850** |

**Ces chiffres sont une simulation pédagogique, pas les sorties exactes du code MacroFactor.**

Mais c'est exactement le mécanisme conceptuel.

---

# 70. Et maintenant le scénario inverse

Vrai TDEE :

[
2300
]

Estimation initiale :

[
2600
]

Tu manges :

[
2200
]

Le système observe une perte beaucoup plus lente que ce qu'aurait prédit 2600.

Donc :

[
TDEE\downarrow
]

et peut converger :

[
2600
\rightarrow
2500
\rightarrow
2400
\rightarrow
2320
\rightarrow
2300
]

Là encore :

**même formule, données différentes.**

---

# 71. Voilà pourquoi MacroFactor peut être plus utile qu'une DEXA pour une question très particulière

Une DEXA peut être utile pour connaître :

> composition corporelle à un instant donné.

Mais elle ne mesure pas directement ton TDEE quotidien.

MacroFactor utilise :

> **des milliers de calories ingérées + des dizaines de mesures de poids**

pour estimer :

> **la dépense énergétique moyenne qui explique le comportement de ton poids.**

Pour le pilotage d'un régime, cette information peut être extrêmement pertinente.

---

# 72. Mais ce n'est pas une mesure métabolique directe

Il faut garder cette nuance.

Pour mesurer directement le métabolisme de repos :

**calorimétrie indirecte.**

Pour mesurer la dépense énergétique totale dans certaines conditions :

**doubly labeled water**, etc.

MacroFactor fait autre chose :

[
\boxed{
Estimation\ longitudinale\ du\ TDEE
}
]

---

# 73. Et c'est justement ce qui rend le système intéressant

Parce que tu ne cherches pas nécessairement :

> « Quel est mon BMR physiologique exact ? »

Tu cherches :

> **« Combien puis-je manger pour perdre 0,5 % de mon poids par semaine ? »**

Pour cette question :

**le TDEE observé est beaucoup plus utile que le BMR théorique.**

---

# 74. Les limites mathématiques à connaître

Il y en a quatre principales.

### 1. Erreur de logging alimentaire

Elle se transmet directement au TDEE.

### 2. Composition de la variation de poids

Le modèle doit estimer ce qui est graisse vs masse maigre/eau.

### 3. Bruit du poids

Même avec une excellente tendance, il subsiste.

### 4. Changements rapides

Un changement soudain de :

* sodium ;
* glucides ;
* créatine ;
* activité ;
* entraînement ;

peut perturber temporairement le signal.

MacroFactor documente même l'exemple d'une transition low-carb → high-carb ou d'une supplémentation en créatine pouvant déplacer temporairement le poids et donc perturber brièvement l'estimation d'expenditure. ([MacroFactor Help][1])

---

# 75. Pourquoi le système ne “punit” pas un retard de perte

Autre détail très intelligent.

Supposons :

Objectif :

**−0,5 kg/semaine**

Tu n'as perdu que :

**−0,2 kg**

MacroFactor ne dit pas :

> « Tu dois maintenant perdre 0,8 kg cette semaine pour rattraper. »

Il traite chaque semaine comme une nouvelle unité de pilotage. ([MacroFactor Help][4])

Donc :

[
TargetRate_{future}
===================

TargetRate_{goal}
]

et non :

[
TargetRate_{future}
===================

TargetRate_{goal}+catchup
]

Cela évite de rendre progressivement le régime absurde.

---

# 76. Maintenance : encore un mécanisme très élégant

En maintenance, MacroFactor ne cherche pas forcément immédiatement :

[
Calories=TDEE
]

s'il existe un écart important avec le poids cible.

Il utilise une logique de **Dynamic Maintenance** :

* si tu es proche de ton poids cible → véritable maintenance ;
* si tu es suffisamment au-dessus → petit déficit ;
* si tu es suffisamment au-dessous → petit surplus.

La documentation indique une zone d'environ **0,7 kg / 1,5 lb** autour du poids cible, avec un petit déficit/surplus équivalent à environ **0,15 % du poids/semaine** pour revenir progressivement vers la cible. ([MacroFactor Help][12])

---

# 77. C'est encore une fois un contrôleur

Si :

[
Weight=75kg
]

Target :

[
75kg
]

→ maintenance.

Si :

[
Weight=76kg
]

→ petit déficit.

Si :

[
Weight=74kg
]

→ petit surplus.

Puis :

[
Weight\rightarrow75
]

→ retour à la maintenance.

---

# 78. Maintenant, le point le plus subtil de tous

**Le TDEE observé n'est pas nécessairement égal à la somme de tes estimations individuelles BMR + NEAT + TEF + EAT.**

Il est plutôt :

[
\boxed{
TDEE_{observé}
==============

BMR+TEF+EAT+NEAT
}
]

mais MacroFactor **n'a pas besoin de connaître chacun de ces termes séparément**.

Il observe leur somme.

C'est pourquoi :

[
\boxed{
TDEE_{observé}

>

TDEE_{théorique}
}
]

n'est pas un problème.

Cela signifie simplement :

> ton comportement physiologique global ne correspond pas exactement à la moyenne prévue par le modèle initial.

---

# 79. Et c'est probablement la plus belle propriété du système

Supposons :

### Ton BMR réel

**1 750**

### TEF

**250**

### EAT

**400**

### NEAT

**450**

Alors :

[
TDEE=2850
]

MacroFactor n'a pas besoin de savoir que :

[
NEAT=450
]

Il sait seulement :

[
TDEE\approx2850
]

Pour programmer ton régime, c'est précisément la variable dont il a besoin.

---

# 80. Conclusion mathématique

Le modèle complet peut donc être résumé par :

[
\boxed{
FFM=W(1-BF)
}
]

[
\boxed{
BMR_0=500+22FFM
}
]

[
\boxed{
TDEE_0=BMR_0\times ActivityMultiplier
}
]

Puis, après acquisition des données :

[
\boxed{
TrendWeight=Filter(Weight)
}
]

[
\boxed{
ChangeRate=
\frac{\Delta TrendWeight}{20}\times7
}
]

[
\boxed{
\Delta E_{stored}
=================

f(ChangeRate,composition)
}
]

[
\boxed{
TDEE_{observed}
===============

Calories_{logged}-\Delta E_{stored}
}
]

Puis :

[
\boxed{
EnergyTarget
============

TDEE_{observed}
\pm
EnergyRequirement(goal)
}
]

avec une couche de :

[
\boxed{
Smoothing
}
]

Puis :

[
\boxed{
Protein
=======

f(FFM,goal,training,proteinPreference)
}
]

[
\boxed{
RemainingCalories
=================

EnergyTarget-4Protein
}
]

puis :

[
\boxed{
Fat/Carb
========

Allocation(RemainingCalories,DietStyle)
}
]

et enfin :

[
\boxed{
NewData
\rightarrow
NewTrend
\rightarrow
NewTDEE
\rightarrow
NewTarget
}
]

C'est la boucle complète.

---

## Et il y a une conclusion encore plus importante

**MacroFactor n'est pas vraiment en train d'essayer de calculer ton métabolisme.**

Il essaie de calculer **le niveau d'apport qui produit la trajectoire corporelle souhaitée**.

Le TDEE est l'intermédiaire nécessaire pour y arriver.

C'est pourquoi son architecture est aussi intéressante :

[
\boxed{
Profil
\rightarrow
Hypothèse
\rightarrow
Observation
\rightarrow
Identification
\rightarrow
Contrôle
\rightarrow
Correction
}
]

et non simplement :

[
\boxed{
Profil\rightarrow BMR\rightarrow TDEE\rightarrow Calories
}
]

---

### Une dernière nuance importante sur les formules

Je veux vraiment insister là-dessus : **les équations que je viens de donner pour Cunningham, le Change Rate et les conversions énergétiques sont les équations/reconstructions que nous pouvons établir à partir des informations publiques ; elles ne constituent pas le code source exact de MacroFactor V3.** MacroFactor confirme explicitement que les mathématiques internes de l'Expenditure sont « reasonably complex » et ne publie pas toutes les constantes. ([MacroFactor Help][1])

En revanche, la structure **Calories IN → tendance du poids → variation énergétique → TDEE → objectif → calories → macros → feedback** est explicitement documentée.

Et c'est précisément cette structure qui permet d'expliquer de façon rigoureuse comment **2 600 kcal peuvent devenir 2 850 kcal sans aucun changement de formule** : le système conserve le même modèle énergétique, mais remplace progressivement le **prior démographique** par une **estimation fondée sur la réponse individuelle observée**.

Si tu veux, je peux maintenant faire la partie la plus intéressante encore : **je peux te construire un véritable simulateur MacroFactor sur 12–16 semaines avec une personne fictive**, jour par jour/semaine par semaine, en faisant varier **poids, calories, TDEE, NEAT, entraînement, perte de graisse, masse maigre, protéines, glucides et lipides**, et te montrer exactement comment l'algorithme *devrait* réagir à un plateau, un cheat meal, une augmentation de 5 000 à 12 000 pas, une prise de créatine, une diet break et un passage cut → maintenance → bulk. Ce serait quasiment un **“MacroFactor décortiqué sous forme de modèle Excel”**.

[1]: https://help.macrofactorapp.com/en/articles/26-how-should-i-interpret-changes-to-my-energy-expenditure?utm_source=chatgpt.com "How Should I Interpret Changes to my Energy Expenditure? | MacroFactor"
[2]: https://help.macrofactorapp.com/en/articles/19-change-rate?utm_source=chatgpt.com "Change Rate | MacroFactor"
[3]: https://help.macrofactorapp.com/en/articles/20-expenditure?utm_source=chatgpt.com "Expenditure | MacroFactor"
[4]: https://help.macrofactorapp.com/en/articles/222-how-does-macrofactor-make-adjustments-for-a-weight-gain-or-weight-loss-goal?utm_source=chatgpt.com "How Does MacroFactor Make Adjustments For a Weight Gain or Weight Loss Goal? | MacroFactor"
[5]: https://help.macrofactorapp.com/en/articles/93-balanced-macro-program?utm_source=chatgpt.com "Balanced Macro Program | MacroFactor"
[6]: https://help.macrofactorapp.com/en/articles/83-how-much-protein-should-you-eat?utm_source=chatgpt.com "How much protein should you eat? | MacroFactor"
[7]: https://help.macrofactorapp.com/en/articles/84-high-carb-and-low-fat-macro-program?utm_source=chatgpt.com "High-Carb and Low-Fat Macro Program | MacroFactor"
[8]: https://help.macrofactorapp.com/en/articles/94-low-carb-and-high-fat-macro-program?utm_source=chatgpt.com "Low-Carb and High-Fat Macro Program | MacroFactor"
[9]: https://help.macrofactorapp.com/en/articles/86-keto-macro-program?utm_source=chatgpt.com "Keto Macro Program | MacroFactor"
[10]: https://help.macrofactorapp.com/en/articles/274-expenditure-modifiers?utm_source=chatgpt.com "Expenditure Modifiers | MacroFactor"
[11]: https://help.macrofactorapp.com/en/articles/37-why-don-t-my-macros-add-up-to-my-total-calories?utm_source=chatgpt.com "Why Don't My Macros Add Up to my Total Calories? | MacroFactor"
[12]: https://help.macrofactorapp.com/en/articles/125-how-does-dynamic-maintenance-work-in-macrofactor?utm_source=chatgpt.com "How Does Dynamic Maintenance Work in MacroFactor? | MacroFactor"


Oui. Je te propose de le faire comme un **vrai “MacroFactor décortiqué”**, mais avec une distinction essentielle : je vais séparer les éléments **documentés par MacroFactor** des paramètres que nous devons **simuler**, puisque les constantes internes exactes ne sont pas publiques.

J'ai aussi préparé un **fichier Excel interactif de la simulation** que tu peux utiliser comme base :

[**Télécharger le modèle Excel — simulation MacroFactor**](sandbox:/mnt/data/simulation_modele_macrofactor.xlsx)

## 1. Le scénario que j'ai simulé

J'ai pris un individu fictif de départ :

* 80 kg
* ~15 % de masse grasse
* 4 entraînements/semaine
* environ 10 000 pas/j au départ
* TDEE réel initial autour de **2 850 kcal**
* estimation initiale volontairement sous-évaluée à **2 600 kcal**
* phase de perte
* baisse progressive de l'activité/NEAT
* remontée des pas
* passage en maintenance
* puis début de prise de poids.

Le but est de voir comment le système peut apprendre que :

[
2600 \neq TDEE_{\text{réel}}
]

et progressivement converger vers quelque chose comme :

[
2850
]

sans jamais avoir besoin de changer de formule.

---

# 2. Le cœur de la simulation

La vraie logique documentée par MacroFactor est :

[
\boxed{
Calories_{in}-Calories_{out}
============================

\Delta E_{stockée}
}
]

donc :

[
\boxed{
TDEE=Calories_{in}-\Delta E_{stockée}
}
]

MacroFactor précise que l'énergie stockée est déduite de l'évolution de la **tendance de poids**, en tenant compte du fait que la variation de poids n'est pas constituée exclusivement de graisse : la proportion de graisse/masse maigre dépend notamment de la vitesse de changement du poids. ([MacroFactor Help][1])

---

# 3. Pourquoi le Weight Trend est absolument central

Supposons :

| Jour | Poids |
| ---- | ----: |
| 1    |  80,0 |
| 2    |  80,5 |
| 3    |  79,9 |
| 4    |  80,3 |
| 5    |  79,7 |
| 6    |  80,0 |
| 7    |  79,6 |

Si on utilisait directement le poids :

[
80,0\rightarrow79,6
]

on pourrait conclure :

[
-0,4kg
]

Mais une partie de cette variation peut être :

* eau ;
* glycogène ;
* sodium ;
* contenu digestif ;
* inflammation liée à l'entraînement.

MacroFactor utilise donc le **Weight Trend**, et son Change Rate est calculé à partir de la variation de cette tendance sur **20 jours**, exprimée en rythme hebdomadaire. ([MacroFactor Help][2])

C'est précisément ce qui empêche un repas très salé ou une grosse séance jambes de provoquer immédiatement une correction absurde des calories.

---

# 4. La boucle devient donc

```text
Calories consommées
        ↓
   poids quotidien
        ↓
    Weight Trend
        ↓
   Change Rate
        ↓
variation d'énergie stockée
        ↓
       TDEE
        ↓
objectif de perte/prise
        ↓
 calories cibles
        ↓
      macros
        ↓
nouvelle semaine
        ↓
       feedback
```

Et cette boucle recommence.

---

# 5. Maintenant faisons le cas 2 600 → 2 850

Supposons :

[
TDEE_{\text{réel}}=2850
]

Mais l'estimation initiale est :

[
TDEE_0=2600
]

On donne donc à la personne environ :

[
2200-2400 kcal
]

selon l'objectif.

Supposons qu'elle mange réellement :

[
2400
]

et perde du poids au rythme correspondant approximativement à :

[
-0,4kg/semaine
]

Une approximation énergétique simplifiée donne :

[
0,4\times7700
=============

3080 kcal/semaine
]

soit :

[
3080/7
\approx440 kcal/j
]

Donc :

[
TDEE
\approx2400+440
]

[
\boxed{2840}
]

La conclusion devient progressivement :

> « Cette personne mange environ 2 400 kcal et perd du poids comme quelqu'un qui possède environ 2 840 kcal de dépense. »

Donc :

[
2600
\rightarrow
2700
\rightarrow
2800
\rightarrow
2850
]

Le modèle mathématique n'a pas changé.

**Le paramètre estimé a changé.**

---

# 6. C'est une forme d'identification de système

On peut écrire :

[
W_{t+1}=W_t+
\frac{Calories_{in}-TDEE}{\rho}
]

où (\rho) représente la conversion énergétique effective de la variation de poids.

On connaît approximativement :

[
W_t
]

et :

[
Calories_{in}
]

On cherche donc :

[
TDEE
]

Le problème est essentiellement :

[
\boxed{
\text{observer la sortie pour estimer le paramètre caché}
}
]

C'est beaucoup plus robuste que de dire :

> « Tu es un homme de 30 ans, 80 kg et 180 cm, donc ton TDEE est 2 650. »

---

# 7. Et c'est pourquoi le TDEE “observé” est plus important que le BMR

Le BMR est une **estimation physiologique**.

Le TDEE observé est une **inférence comportementale + physiologique**.

Ton TDEE réel est :

[
TDEE=BMR+TEF+NEAT+EAT
]

avec :

* BMR = métabolisme basal ;
* TEF = effet thermique des aliments ;
* NEAT = activité non sportive ;
* EAT = exercice.

MacroFactor n'a pas besoin de mesurer séparément chacun de ces éléments.

Il mesure leur résultat :

[
\boxed{TDEE_{\text{global}}}
]

à partir de l'apport et de la trajectoire pondérale. ([MacroFactor Help][1])

---

# 8. C'est aussi pour cela que le NEAT est “capturé” indirectement

Imagine :

### Semaine 1

10 000 pas/j

[
TDEE=2850
]

Puis tu commences ton régime.

Fatigue :

### Semaine 5

6 000 pas/j

Le NEAT baisse.

Ton TDEE devient par exemple :

[
2750
]

MacroFactor n'a pas besoin de dire :

> « Ah, tu as perdu 100 kcal de NEAT. »

Il observe simplement que :

[
Calories_{in}
]

produisent désormais une perte plus lente.

Donc :

[
TDEE_{\text{estimé}}\downarrow
]

C'est une des raisons pour lesquelles le système peut s'adapter aux différences individuelles.

---

# 9. Et inversement

Tu passes de :

[
6000\rightarrow12000\ pas/j
]

Ton TDEE augmente.

Avec **Step-Informed Updates**, MacroFactor peut même accélérer cette adaptation avant que toute la conséquence du changement d'activité apparaisse dans la tendance de poids. ([MacroFactor Help][3])

C'est une fonctionnalité particulièrement intéressante parce qu'elle combine :

[
\text{signal prédictif}
+
\text{feedback réel}
]

plutôt que d'attendre aveuglément la balance.

---

# 10. Le scénario de la simulation

J'ai volontairement introduit plusieurs phases :

### Phase A — Cut

Calories autour de :

[
2400
]

avec :

[
TDEE\approx2850
]

Donc déficit :

[
\approx450 kcal/j
]

---

### Phase B — Adaptation

Les pas descendent progressivement :

[
10,000
\rightarrow
7,000
]

Le TDEE réel simulé descend lui aussi.

C'est là qu'on peut observer un phénomène très important :

> **le déficit alimentaire reste identique, mais le rythme de perte ralentit.**

Cela ne signifie pas forcément que le régime “ne marche plus”.

Cela peut simplement signifier :

[
NEAT\downarrow
]

---

# 11. Puis remontée de l'activité

Les pas remontent :

[
7000
\rightarrow
13000
]

Le TDEE simulé remonte :

[
2780
\rightarrow
3040
]

L'algorithme doit progressivement reconnaître cette nouvelle réalité.

C'est précisément le genre de changement pour lequel MacroFactor propose les **Expenditure Modifiers**. MacroFactor indique que les deux modificateurs — Step-Informed Updates et Predictive Goal Adjustment — améliorent selon leurs tests l'exactitude des recommandations d'environ 6–8 % à l'échelle mensuelle et environ 20 % sur des périodes plus longues. ([MacroFactor Help][3])

---

# 12. Puis vient la maintenance

J'ai ensuite simulé :

[
TDEE\approx2800-2850
]

et un apport qui remonte progressivement vers :

[
\approx2850
]

La différence :

[
Calories_{in}-TDEE
]

se rapproche alors de :

[
0
]

Donc :

[
\Delta Weight\rightarrow0
]

C'est la définition opérationnelle de la maintenance.

---

# 13. Puis le bulk

Ensuite :

[
Calories>TDEE
]

Par exemple :

[
3000>2900
]

Donc :

[
+100 kcal/j
]

Le poids commence à augmenter.

MacroFactor peut alors déduire :

[
TDEE
====

## Calories_{in}

Surplus_{implicite}
]

Si :

[
Calories=3000
]

et que le rythme de prise implique :

[
+150 kcal/j
]

alors :

[
TDEE=3000-150
]

[
\boxed{2850}
]

Même formule.

---

# 14. Et maintenant les macros

C'est là que beaucoup d'applications font quelque chose de beaucoup plus simpliste.

MacroFactor fait conceptuellement :

[
\boxed{
Calories
\rightarrow Protein
\rightarrow Fat/Carbs
}
]

et non :

[
Calories\times30%
]

pour chacun.

MacroFactor documente explicitement que les calories sont déterminées d'abord selon l'objectif et le TDEE, puis les protéines selon les préférences et l'exercice, et enfin les calories restantes sont distribuées entre lipides et glucides. ([MacroFactor Help][4])

---

# 15. Prenons notre exemple

Supposons :

[
Calories=2400
]

et :

[
Protein=160g
]

Alors :

[
160\times4=640 kcal
]

Il reste :

[
2400-640=1760
]

### Balanced

Les calories non protéiques sont réparties approximativement moitié/moitié entre lipides et glucides. ([MacroFactor Help][4])

Donc :

[
880 kcal
]

de lipides et :

[
880 kcal
]

de glucides.

Cela donne approximativement :

[
Fat=880/9\approx98g
]

[
Carbs=880/4=220g
]

Donc :

[
\boxed{160P/220C/98F}
]

---

# 16. Et si TDEE augmente de 100 kcal ?

Supposons :

[
Target=2500
]

La protéine reste autour de :

[
160g
]

Il reste :

[
2500-640=1860
]

En Balanced :

[
930 kcal
]

pour chaque côté.

Donc :

[
Fat\approx103g
]

[
Carbs\approx233g
]

On obtient environ :

[
\boxed{160P/233C/103F}
]

Tu vois le principe :

### +100 kcal

n'entraîne pas :

> +25 g de protéines.

Il augmente principalement :

* glucides ;
* lipides.

MacroFactor confirme explicitement que les protéines changent relativement peu de semaine en semaine, tandis que les changements énergétiques sont principalement absorbés par les glucides et lipides. ([MacroFactor Help][5])

---

# 17. Pourquoi la protéine peut quand même changer

Elle dépend notamment de :

* poids ;
* composition corporelle ;
* activité ;
* objectif ;
* préférence de niveau de protéines.

MacroFactor indique par exemple que les recommandations peuvent varier de quelques grammes avec les changements de poids, tandis qu'un changement de catégorie de composition corporelle ou de type d'exercice peut entraîner une modification plus importante. ([MacroFactor Help][5])

Pour un programme manuel/collaboratif, MacroFactor donne comme plage générale :

[
1,2-2,2g/kg/j
]

avec une tendance vers le haut pour les personnes plus actives et/ou en déficit. ([MacroFactor Help][6])

---

# 18. Puis le choix du programme modifie le partage

### Balanced

[
FatCalories\approxCarbCalories
]

([MacroFactor Help][4])

### Low-Fat / High-Carb

[
CarbCalories>FatCalories
]

([MacroFactor Help][7])

### Low-Carb / High-Fat

[
FatCalories>CarbCalories
]

([MacroFactor Help][8])

### Keto

Les glucides sont maintenus très bas, avec une marge pour les fibres et la flexibilité nutritionnelle, puis les calories restantes vont principalement aux lipides. ([MacroFactor Help][9])

---

# 19. Une chose particulièrement élégante

MacroFactor ne cherche pas à imposer :

> « Le meilleur ratio de macros est X/Y/Z. »

Il considère plutôt que plusieurs distributions peuvent être parfaitement compatibles avec :

[
\text{même apport énergétique}
+
\text{même quantité de protéines}
]

et donc avec :

[
\text{même perte de graisse}
]

si l'adhérence est équivalente.

Le choix devient alors une question de :

* préférence ;
* satiété ;
* performance ;
* tolérance ;
* style alimentaire.

---

# 20. Le cas du minimum de lipides

C'est là que le système devient intéressant.

Supposons que les calories diminuent énormément.

MacroFactor ne continue pas indéfiniment à réduire les lipides.

Il impose un **minimum** dans ses programmes coachés, puis les réductions énergétiques supplémentaires passent davantage par les glucides. ([MacroFactor Help][5])

Donc la relation n'est pas toujours :

[
\Delta Fat=\Delta Carb
]

Il existe des contraintes physiologiques.

---

# 21. Pourquoi je n'ai pas mis les constantes internes exactes dans Excel

Parce que ce serait malhonnête.

Le fichier que je t'ai donné contient volontairement des paramètres marqués comme :

**“simulation pédagogique”**.

Par exemple :

* fenêtre simplifiée ;
* coefficient de convergence ;
* 7 700 kcal/kg ;
* protéine simulée à partir de la masse maigre ;
* partage Balanced 50/50 en calories.

Ces valeurs permettent de **reproduire le comportement conceptuel**, mais elles ne doivent pas être présentées comme le code source de MacroFactor.

MacroFactor dit lui-même que les mathématiques internes exactes de l'expenditure sont relativement complexes et ne publie pas tous les détails. ([MacroFactor Help][10])

---

# 22. En revanche, certaines choses sont absolument établies

### Établi

[
Calories_{in}
-------------

# \Delta E_{stored}

TDEE
]

([MacroFactor Help][1])

### Établi

Change Rate basé sur **20 jours de Weight Trend**. ([MacroFactor Help][2])

### Établi

La tendance est utilisée plutôt que le poids brut pour éviter les sur-corrections. ([MacroFactor Help][10])

### Établi

Les changements d'activité peuvent être intégrés plus rapidement via Step-Informed Updates. ([MacroFactor Help][3])

### Établi

Calories → protéines → glucides/lipides. ([MacroFactor Help][5])

### Établi

Les programmes Balanced, High-Carb/Low-Fat, Low-Carb/High-Fat et Keto ont des allocations différentes. ([MacroFactor Help][4])

---

# 23. Le point le plus intéressant de la simulation

Regarde particulièrement la colonne :

**TDEE estimé lissé**

dans le fichier Excel.

Tu verras que l'estimation ne fait pas :

[
2600\rightarrow2850
]

en une seule fois.

Elle se comporte plutôt comme :

[
2600
\rightarrow
2640
\rightarrow
2710
\rightarrow
2780
\rightarrow
2820
\rightarrow
2840
\rightarrow
2850
]

C'est exactement le type de convergence que l'on veut obtenir avec un système soumis à du bruit.

---

# 24. Pourquoi une semaine bizarre ne détruit donc pas le régime

Imaginons :

### Semaine normale

[
-0,4kg
]

### Semaine suivante

gros restaurant + sodium :

[
+0,3kg
]

Le poids brut suggérerait :

> « Tu as pris du poids ! »

Mais la tendance ne va pas nécessairement interpréter cela comme :

[
+0,7kg\ de\ graisse
]

MacroFactor cherche précisément à éviter ce genre de réaction excessive. Il explique qu'une semaine atypique provoque d'abord une correction prudente, et que des corrections plus importantes apparaissent si le phénomène persiste la semaine suivante. ([MacroFactor Help][10])

---

# 25. Le “plateau” est donc également intéressant

Supposons :

### Semaine 1

[
-0,5kg
]

### Semaine 2

[
0,0kg
]

### Semaine 3

[
0,0kg
]

Un système naïf pourrait immédiatement faire :

[
Calories-500
]

MacroFactor est beaucoup plus prudent.

Parce qu'il existe deux hypothèses :

### H1

Le TDEE a réellement diminué.

### H2

Le poids est temporairement retardé par :

* eau ;
* glycogène ;
* contenu intestinal ;
* etc.

Et statistiquement, H2 peut être très plausible.

C'est pourquoi l'algorithme augmente progressivement la correction si le phénomène persiste. ([MacroFactor Help][10])

---

# 26. C'est exactement ce qu'on veut d'un système de feedback

Il faut éviter deux erreurs :

### Sous-réaction

Ne jamais modifier les calories.

### Sur-réaction

Modifier massivement les calories à chaque fluctuation.

Le système cherche :

[
\boxed{\text{réactivité + inertie}}
]

C'est une combinaison difficile à obtenir.

---

# 27. Une autre particularité : l'algorithme n'est pas dépendant d'une adhérence parfaite

MacroFactor indique explicitement que son calcul peut être **“adherence-neutral”** : il utilise ce que tu as effectivement enregistré et la réponse du poids, plutôt que de supposer que la cible calorique a été respectée. ([MacroFactor Help][1])

Exemple :

Objectif :

[
2300
]

Mais tu manges :

[
2500
]

Si tu perds quand même du poids à un certain rythme, l'algorithme travaille à partir de :

[
2500
]

et non :

[
2300
]

C'est fondamental.

---

# 28. Donc il ne confond pas “objectif” et “réalité”

Il y a trois valeurs différentes :

[
\boxed{Calories_{target}}
]

[
\boxed{Calories_{logged}}
]

[
\boxed{TDEE_{observed}}
]

Et c'est une distinction que je trouve particulièrement importante.

---

# 29. Exemple

Tu dois manger :

[
2400
]

mais tu manges :

[
2600
]

et tu perds du poids.

L'algorithme ne conclut pas :

> « Il a mangé 2400. »

Il voit :

[
2600
]

et le changement de poids.

Donc :

[
TDEE=f(2600,\Delta Weight)
]

Cette architecture permet de conserver une certaine robustesse face à une adhérence imparfaite, à condition que les apports soient raisonnablement bien enregistrés. ([MacroFactor Help][11])

---

# 30. Mais il y a une condition cruciale

Il faut suffisamment de données de poids.

MacroFactor recommande idéalement une pesée quotidienne, ou au minimum plusieurs fois par semaine ; sans nouvelles données de poids, l'estimation de dépense peut se mettre en pause. ([MacroFactor Help][12])

Donc :

[
Calories\ uniquement
]

ne suffisent pas.

Il faut :

[
Calories+Weight
]

pour identifier la dépense.

---

# 31. Et c'est pour cela que je te conseille de regarder 5 variables ensemble

Si tu veux réellement comprendre ton propre métabolisme avec MacroFactor, ne regarde pas uniquement :

**Calories.**

Regarde :

### 1. TDEE

[
\boxed{TDEE}
]

### 2. Calories consommées

[
\boxed{CI}
]

### 3. Weight Trend

[
\boxed{WT}
]

### 4. Change Rate

[
\boxed{CR}
]

### 5. Activité

[
\boxed{Steps/Exercise}
]

C'est leur combinaison qui raconte l'histoire.

---

# 32. Et je peux aller encore plus loin avec toi

Le fichier actuel est une **simulation pédagogique**.

La prochaine étape vraiment intéressante serait de construire un **modèle personnel**, avec tes propres données.

On pourrait prendre par exemple :

```text
Date
Poids
Calories
Protéines
Glucides
Lipides
Pas
Entraînement
TDEE MacroFactor
Weight Trend MacroFactor
Change Rate
```

et reconstruire :

[
\boxed{
TDEE_{\text{observé personnel}}
}
]

sur 8–16 semaines.

On pourrait alors distinguer :

[
BMR
]

[
TDEE
]

[
NEAT
]

[
EAT
]

[
TEF
]

et surtout voir **quelle part de tes variations de TDEE vient probablement de l'activité, du poids et de l'adaptation comportementale**.

Et là, on ne serait plus seulement en train de comprendre MacroFactor : **on pourrait pratiquement faire un “jumeau mathématique” de ton propre métabolisme énergétique**, semaine après semaine.

Le fichier Excel que je t'ai préparé constitue justement la base pour ça.

[1]: https://help.macrofactorapp.com/en/articles/20-expenditure?utm_source=chatgpt.com "Expenditure | MacroFactor"
[2]: https://help.macrofactorapp.com/en/articles/19-change-rate?utm_source=chatgpt.com "Change Rate | MacroFactor"
[3]: https://help.macrofactorapp.com/en/articles/274-expenditure-modifiers?utm_source=chatgpt.com "Expenditure Modifiers | MacroFactor"
[4]: https://help.macrofactorapp.com/en/articles/93-balanced-macro-program?utm_source=chatgpt.com "Balanced Macro Program | MacroFactor"
[5]: https://help.macrofactorapp.com/en/articles/222-how-does-macrofactor-make-adjustments-for-a-weight-gain-or-weight-loss-goal?utm_source=chatgpt.com "How Does MacroFactor Make Adjustments For a Weight Gain or Weight Loss Goal? | MacroFactor"
[6]: https://help.macrofactorapp.com/en/articles/142-protein?utm_source=chatgpt.com "Protein | MacroFactor"
[7]: https://help.macrofactorapp.com/en/articles/84-high-carb-and-low-fat-macro-program?utm_source=chatgpt.com "High-Carb and Low-Fat Macro Program | MacroFactor"
[8]: https://help.macrofactorapp.com/en/articles/94-low-carb-and-high-fat-macro-program?utm_source=chatgpt.com "Low-Carb and High-Fat Macro Program | MacroFactor"
[9]: https://help.macrofactorapp.com/en/articles/86-keto-macro-program?utm_source=chatgpt.com "Keto Macro Program | MacroFactor"
[10]: https://help.macrofactorapp.com/en/articles/26-how-should-i-interpret-changes-to-my-energy-expenditure?utm_source=chatgpt.com "How Should I Interpret Changes to my Energy Expenditure? | MacroFactor"
[11]: https://help.macrofactorapp.com/en/articles/140-do-i-need-to-log-everything-i-eat-and-drink-to-have-an-accurate-expenditure-and-use-macrofactor-s-coaching-features?utm_source=chatgpt.com "Do I Need to Log Everything I Eat and Drink to Have an Accurate Expenditure and Use MacroFactor's Coaching Features? | MacroFactor"
[12]: https://help.macrofactorapp.com/en/articles/109-how-frequently-do-i-need-to-log-my-weight-for-the-expenditure-algorithm-and-weekly-coaching-updates?utm_source=chatgpt.com "How Frequently do I Need to Log my Weight For the Expenditure Algorithm and Weekly Coaching Updates? | MacroFactor"
