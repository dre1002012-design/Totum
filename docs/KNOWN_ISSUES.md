# TOTUM — Known Issues

Ce fichier recense les bugs connus, les limitations acceptées (comportement volontaire ou compromis assumé) et les points de vigilance à garder en tête avant de toucher à certaines parties du code. Objectif : ne jamais redécouvrir un sujet déjà tranché, et savoir pourquoi il est resté en l'état.

À la différence de `TODO.md` (liste d'actions ordonnées) et `CURRENT_STATE.md` (description de ce qui est fait), ce fichier explique le *pourquoi* d'un statu quo.

## Légende
- 🐞 **Bug actif** — comportement incorrect confirmé, pas encore corrigé
- ⚖️ **Limitation acceptée** — compromis assumé, pas un bug
- 👁️ **Point de vigilance** — piège potentiel à connaître avant de modifier ce code
- ⏰ **Risque / échéance externe** — à surveiller, pas encore bloquant
- ✅ **Résolu** — conservé pour historique/contexte

---

## 🐞 Bugs actifs

### Icône PWA absente sur l'écran d'accueil iPhone/Safari
- **Où** : configuration PWA (manifest / meta tags iOS)
- **Quoi** : lorsqu'un utilisateur ajoute TOTUM à l'écran d'accueil depuis Safari iOS, l'icône ne s'affiche pas correctement.
- **Impact** : faible — cosmétique, n'empêche pas l'usage de l'app.
- **Pourquoi ce n'est pas corrigé** : jamais investigué en profondeur, considéré non urgent face aux chantiers Recettes/Conseils.
- **Statut** : non planifié activement — voir `TODO.md`, section "Autres chantiers ouverts".

---

## ⚖️ Limitations acceptées

### Historisation partielle des objectifs (sex/poids/niveau d'activité non historisés)
- **Où** : `_appendGoalsSnapshot` (`profile.dart`), `_goalsRawForDay` (`bilan_screen.dart`)
- **Quoi** : les 37 champs historisés couvrent les macros, acides gras, minéraux et vitamines — mais `sex`, `weightKg` et `activityIdx` sont **toujours pris depuis les valeurs actuelles** de l'utilisateur, jamais historisés.
- **Conséquence** : si un utilisateur change de sexe déclaré, de poids de référence ou de niveau d'activité, les bilans passés recalculés utiliseront ces nouvelles valeurs, pas celles qui étaient vraies au moment concerné.
- **Pourquoi c'est accepté** : compromis délibéré pour limiter la complexité de l'historisation (poids en particulier change en continu, l'historiser à ce niveau de granularité aurait un coût disproportionné par rapport au bénéfice).

### Compatibilité ascendante par repli sur les objectifs actuels (anciens instantanés partiels)
- **Où** : `_readGoalsSnapshots` (`bilan_screen.dart`)
- **Quoi** : les instantanés créés avant la mise en place de l'historisation 37 champs ne contenaient que les 5 macros. Le code fait un repli champ-par-champ sur les objectifs *actuels* pour les 32 champs manquants sur ces anciens instantanés.
- **Conséquence** : les tendances de micronutriments affichées pour les périodes **antérieures** à la mise en place de cette fonctionnalité sont approximatives (basées sur les objectifs actuels, pas les objectifs réels de l'époque).
- **Pourquoi c'est accepté** : impossible de reconstruire une donnée qui n'a jamais été enregistrée ; le repli est le compromis le moins mauvais pour éviter des trous ou des erreurs de calcul.

### Smart Match Score : valeur neutre par défaut (50/100)
- **Où** : `smartMatchScore()` (`conseils_screen.dart`)
- **Quoi** : si `RemainingToday.hasTargets == false` (impossible de calculer le reste-à-consommer du jour), la fonction retourne un score neutre de 50/100 plutôt que de planter ou de masquer le badge.
- **Pourquoi c'est un choix assumé** : évite un état d'erreur visible pour l'utilisateur ; à ne pas "corriger" en pensant que c'est un bug.

### Malus fixe de -35 points en cas de dépassement calorique
- **Où** : `smartMatchScore()` (`conseils_screen.dart`)
- **Quoi** : le malus appliqué quand `Recipe_kcal > RC_kcal + 100` est une constante fixe (-35), pas un paramètre ajustable ni proportionnel au dépassement.
- **Pourquoi c'est accepté pour l'instant** : simplicité de la V1 du Smart Match Score. Point à revisiter si des retours utilisateurs montrent que le classement des recettes est mal calibré.

---

## 👁️ Points de vigilance

### Indentation Stack/ListView dans l'anti-flash de `conseils_screen.dart`
- **Où** : `_ConseilsScreenState`, `FutureBuilder` principal
- **Quoi** : l'ajout de la couche `Stack` (pour afficher `_lastData` + `LinearProgressIndicator` pendant le rafraîchissement) a nécessité un ajustement d'indentation d'un niveau sur les enfants de la `ListView`.
- **Piège** : toute future modification de cette zone doit vérifier que l'imbrication `Stack > ListView` est respectée, sinon retour possible du flash de page blanche ou erreur de compilation.

### Renommage `perte_poids` → `léger` (filtres recettes)
- **Où** : `_quickFilters` (`AllRecipesScreen`), `goalTags` des recettes
- **Piège** : si la clé `perte_poids` est référencée ailleurs que dans l'affichage (état sauvegardé côté utilisateur type "dernier filtre utilisé", analytics, deep links...), vérifier qu'il n'y a pas de migration de données à prévoir avant de renommer la clé.
- **Statut** : à vérifier au moment d'implémenter `TODO.md` Priorité 2.

### État d'application non confirmé des 10 blocs Smart Match Score / badges
- **Où** : `conseils_screen.dart` (Smart Match Score, badges, filtres)
- **Quoi** : ces blocs ont été livrés en fin de session précédente sous forme de texte (cherche/remplace), sans confirmation qu'ils ont bien été appliqués dans le fichier réel avant la bascule vers l'audit du CDC V2 externe.
- **Risque** : travailler sur du code supposé existant mais partiellement absent, notamment pour les priorités 1 et 2 du TODO qui en dépendent.
- **Statut** : à vérifier en premier — voir `TODO.md`, Priorité 3.

---

## ⏰ Risques / échéances externes à surveiller

### Google Play Billing 8.0.0+
- **Échéance** : 31/08/2026, extension possible jusqu'au 01/11/2026.
- **Statut actuel** : dépendances mises à jour le 22/07/2026 (`in_app_purchase` 3.3.0 / `in_app_purchase_android` 0.5.0), mais **parcours d'achat non testé** et **publication non faite**.
- **Pourquoi ce n'est pas encore bloquant** : la deadline n'est pas dépassée, mais devient urgente si elle n'est pas traitée avant fin été 2026.
- **Statut** : voir `TODO.md`, section "Autres chantiers ouverts".

---

## ✅ Résolu (conservé pour contexte)

### Bilan 30/60/90 jours comparant aux objectifs actuels au lieu des objectifs historiques du jour
- **Résolu par** : mise en place de l'historisation par snapshot journalier (37 champs) — voir `CURRENT_STATE.md` § Bilan.
- **Pourquoi c'est noté ici** : pour comprendre a posteriori pourquoi le système d'historisation snapshot a été conçu ainsi (c'est la réponse directe à ce bug), et éviter de le simplifier par erreur en pensant que c'est une sur-ingénierie.

### Incohérences cru/cuit dans les recettes existantes
- **Résolu** (vérifié le 17/08/2026, audit pré-Play-Store) : plus aucune entrée "Riz ... cru", "Poulet ... crue" ou "Saumon ... cru" dans les 168 recettes actuelles (`totum_recipes.json`) — corrigé dans une session intermédiaire, non documenté ici jusqu'à cette vérification.
- Seuls restants avec un mot-clé "cru" : "Épinard, cru" (3 recettes — smoothie et bowls, où le cru est le bon choix culinaire) et "Oeuf cru" (2 recettes d'omelette, avec l'huile de cuisson listée séparément le cas échéant) — vérifiés non problématiques : l'écart cru/cuit sur l'œuf entier est ~4% (140 vs 134 kcal/100g), sans commune mesure avec l'écart ~3x du riz qui motivait cette entrée.