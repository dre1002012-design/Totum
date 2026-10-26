# 26/10/2026 — Corrections du « + », pauses dans le calcul, visuels Instagram v2

Suite des retours d'Alex sur la version du 25/10 (captures du 26/10 13h56).
Vérifications : `flutter analyze` 0 problème · **97/97 tests** · build web `--wasm` · déployé sur https://totum-app-2026.web.app (empreinte du fichier en ligne = build local).

## 1. Bouton « + » (page d'ajout)

| Problème signalé | Cause | Correction |
|---|---|---|
| Le message « ✓ … ajouté » restait figé à l'écran | Depuis Flutter 3.32, un message **avec bouton** (« Annuler ») reste affiché tant qu'on ne le ferme pas (`persist` vaut vrai par défaut) | `persist: false` → disparaît après 4 s. Même défaut corrigé sur le message « Renvoyer l'email » de la connexion. Un test vérifie désormais que le message disparaît seul. |
| ⊕ ajoutait 100 g d'office, sans régler le poids | Choix d'« ajout rapide » trop direct | ⊕ ouvre une **fiche quantité express** : quantité habituelle pré-sélectionnée (taper un chiffre la remplace, Entrée valide), portions en un geste (habituel, 50/100/150/200 g, portions USDA), kcal + macros en direct, repas modifiable, lien vers le détail complet. Le tap sur la ligne ouvre toujours la fiche complète. |
| Marques & restaurants affichés en permanence | Mauvaise interprétation : accès toujours visible | **Masqués par défaut**, interrupteur « Marques & restaurants » dans les options (⚙). Les onglets Aliments/Favoris/Perso restent masquables aussi. Textes des options mis à jour (ils citaient encore « Commun/…/Restaurant »). |

## 2. Pauses dans le calcul de la dépense (« je m'étais bien mis en pause »)

**Constat** : les pesées *pendant* la pause étaient bien exclues, mais le lissage reliait encore le **dernier poids avant la pause au premier poids après**. Tout l'écart de part et d'autre (repas non notés, rétention d'eau du retour) était donc attribué aux jours suivis, comme si ces kilos venaient des calories notées.

**Sur tes données réelles** (pauses supposées aux jours sans repas notés, faute d'export `pause_periods`) : le saut du 03-06/10 (72,7 → 74,1 kg, puis redescente = eau) faisait attribuer jusqu'à **+1,07 kg** aux jours suivis au lieu de **~+0,3 kg**, et **sous-estimait ta dépense de 100 à 150 kcal/j**.

**Correction, alignée sur MacroFactor** (« l'estimation est gelée pendant la période non suivie puis reprend là où elle s'était arrêtée » ; « attendre 3-4 jours que le poids se stabilise au retour ») :
1. la fenêtre d'analyse est découpée en **segments continus entre les pauses** ; chaque segment a son propre lissage, et seules les variations *à l'intérieur* des segments entrent dans l'équation. La pesée du retour n'est plus jamais comparée à celle d'avant la pause ;
2. **3 jours de stabilisation** après chaque pause : ces pesées sont mises de côté (eau, sel, glycogène).

Un **seul et même calcul** (`estimateEnergyBalance`) alimente désormais la cible calorique, le graphique de dépense et le compteur de jours : ils ne peuvent plus diverger. Tests : régression sans pause, retour de pause avec +3 kg d'eau (dépense exacte retrouvée), et rejeu de tes données comparé à un calcul indépendant (écart ≤ 2 kcal). Le bandeau « Pause » explique maintenant ce comportement.

## 3. Visuels Instagram v2

**Deux comptes** : *Mon compte naturo & coach* (appel à te suivre, @agenaturo) ou *Compte Totum* (appel à télécharger l'app sur Google Play). **4 ambiances** : Totum crème, Totum nuit (charte de l'app), Naturo sauge, Naturo lin (tons naturels). Je n'ai pas pu voir ton compte Instagram (connexion obligatoire) : envoie-moi une capture de ton profil et j'aligne précisément couleurs et typographie.

**Carrousel de 8 visuels**, une idée par visuel (structure des carrousels les plus enregistrés) :
1. **Couverture** : photo pleine largeur, titre chiffré (« 686 % de la référence en vitamine B12 dans une seule assiette »), 3 chiffres clés.
2. **D'où vient l'énergie ?** : kcal, protéines/glucides/lipides en % de l'énergie, fibres.
3. **Micronutriments en vedette** : 6 jauges + la **source n°1 dans l'assiette** (« 🐟 Sardine »).
4. **Acides gras essentiels** : EPA+DHA, ALA, oméga-6, **rapport ω6/ω3** vs cible ANSES (< 5), avec le conseil pour le corriger.
5. **Ce qu'ils font pour toi** : rôle de chaque nutriment, formulé avec les **allégations de santé autorisées par l'UE** (règlement 432/2012).
6. **La recette** : ingrédients, grammes, kcal.
7. **L'équilibre** : « ✓ déjà bien couverts » + nutriments **à compléter** avec les aliments qui en apportent (preuve que l'alimentation suffit).
8. **Ce que j'en retiens** + récapitulatif chiffré + appel à l'action (enregistrer, envoyer, suivre/télécharger).

**Choix de fond** :
- Micronutriments en vedette = **uniquement les essentiels santé/longévité** (oméga-3, magnésium, vitamines D, K, B9, B12, C, potassium, zinc, sélénium, iode, calcium, fer, E, A, B1, B6). **Exclus** : phosphore, sodium, cuivre, manganèse (déjà abondants).
- Pourcentages sur les **valeurs de référence officielles UE** ; acides gras sur les **références ANSES** ; jamais de « riche en ».
- **Nouveaux formats** : Paysage 1200×630 (site, Facebook, LinkedIn) et **Bannière Play Store** 1024×500.
- **« Partager ma journée »** (menu ⋮ d'un repas) : toute la journée en un carrousel (« 17 micronutriments essentiels au-dessus de 30 % — sans complément »).
- Légende prête à coller : accroche, macros, essentiels avec leur rôle, acides gras, ingrédients, appels à l'action, **5 mots-dièse max**.

Captures de contrôle : `build/share/` (régénérables via `flutter test test/screens/meal_share_screenshot_test.dart`).

## À tester sur téléphone
1. ⊕ → fiche quantité → Ajouter : le message disparaît seul après 4 s, « Annuler » fonctionne.
2. Options (⚙) → activer « Marques & restaurants ».
3. Menu ⋮ d'un repas → Partager sur Instagram / Partager ma journée → choisir le compte, la photo, exporter.
4. Après ta prochaine pause : la dépense ne doit plus chuter au retour.

## Restant
- Captures de ton profil Instagram pour caler l'ambiance « Naturo » sur ton identité exacte.
- Captures d'écran de l'app pour la fiche Play Store (différentes de la bannière) : chantier séparé si tu le souhaites.
- Export `pause_periods` (SQL ci-dessous) pour confirmer tes dates de pause réelles :
  `select start_date, end_date from pause_periods where user_id = '73037693-0249-44f9-b339-44dcdb005bf5' order by start_date;`
