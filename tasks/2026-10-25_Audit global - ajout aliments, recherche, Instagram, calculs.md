# Audit global du 25/10/2026 — état des lieux fonctionnel

Sauvegarde avant travaux : tag git `backup/pre-audit-2026-10-25` (retour arrière possible à tout moment : `git checkout backup/pre-audit-2026-10-25`).

Vérifications finales : `flutter analyze` 0 problème · **92/92 tests** (74 avant + 18 nouveaux) · `flutter build web --wasm` OK · build Android : voir fin du document.

---

## 1. Vérification du calcul des calories (tes données réelles, avant ta pause)

Données : export journal 01/09 → 25/10 (35 jours suivis) + `weight_log_rows.csv` (ton compte, 39 pesées). Pause visible à partir du 16/10.

**Rejeu exact de l'algorithme de l'app** (`computeCalibration` : poids lissé EMA, segments début/fin 30 %, densité énergétique variable, pondération 0,65) :

| Fin de fenêtre | Apport moyen logué | Variation poids (tendance) | TDEE empirique | Cible affichée (formule × 0,35 + empirique × 0,65) |
|---|---|---|---|---|
| 26/09 | 3 563 kcal | +0,98 kg | 3 019 | ~3 000–3 070 |
| 02/10 | 3 570 kcal | +0,24 kg | 3 401 | ~3 250–3 320 |
| 09/10 | 3 557 kcal | +0,54 kg | 3 279 | ~3 170–3 240 |
| 12/10 | 3 585 kcal | +0,36 kg | 3 370 | ~3 230–3 300 |
| 15/10 | 3 532 kcal | +0,87 kg | 3 040 | ~3 020–3 090 |
| 16/10 | 3 528 kcal | +0,67 kg | 3 142 | ~3 080–3 150 |

**Contre-contrôle indépendant** (régression linéaire simple sur toute la période, aucun code de l'app) : pente +0,045 kg/jour, apport moyen 3 496 kcal/j → **TDEE ≈ 3 120–3 150 kcal/j**.

**Verdict : le calcul est correct.** La cible de ton export (3 220 kcal, maintien) est à +2,5 % de l'estimation indépendante — dans la marge d'incertitude. Cohérence physique vérifiée : tu as mangé en moyenne ~280 kcal au-dessus de ta cible, et ton poids est monté de 72,2 à 73,9 kg, exactement ce que prédit le bilan énergétique.

Points d'attention (pas des bugs) :
- Trous du 12–14/09, 27/09, 03–05/10 : sans repas logués. Après le 03–05/10, ton poids saute de 72,7 à 74,1 kg. Si tu as mangé ces jours-là sans loguer, la prise de poids est attribuée aux autres jours et **sous-estime** légèrement ton TDEE. → Déclarer une **pause** pour ces jours (Tableau de bord) les exclut proprement du calcul.
- Ta formule de départ (sans historique) : 1 670 kcal de métabolisme × 1,78 (« Très actif ») = 2 970 kcal — vérifié aussi sur le nouveau récapitulatif de l'onboarding.

## 2. Bouton « + » : latence et ergonomie (le cœur de l'app)

### Causes mesurées de la latence
| Mesure (PC, un téléphone est 3 à 10× plus lent) | Avant | Après |
|---|---|---|
| Ouverture de la liste « Aliments » (tri ~3 500 aliments) | 309 ms | 45 ms (puis cache) |
| Chaque frappe dans la recherche (base complète 11 329 aliments) | ~1 840 ms | 6–40 ms |

Cause : le nom de chaque aliment était renormalisé (≈ 30 remplacements de caractères) **à l'intérieur des comparateurs de tri**, des centaines de milliers de fois par frappe, et les 3 listes + 3 comptages étaient recalculés à chaque rebuild (même pour les onglets invisibles).

### Ce qui a changé
- **Une seule page d'ajout** : le « + » central ET le « + » de chaque repas ouvrent la même page (avant : 2 interfaces différentes, source des questions de tes testeurs). Le repas et le jour sont présélectionnés ; un jour passé est rappelé en orange sous le titre.
- **3 onglets fixes, tous visibles** : Aliments · Favoris · Perso.
- **Marques & restaurants** sortis dans leur propre écran (onglets Marques / Restaurants), sans perdre de place : une ligne d'accès en haut de la liste (qui défile avec elle) + un raccourci « N résultats dans Marques & restaurants » quand ta recherche y trouve quelque chose. On peut maintenant y chercher un **produit** (« big mac ») sans choisir l'enseigne d'abord.
- **Ajout en un tap (⊕)** sur chaque ligne, avec la **dernière quantité utilisée** (tes 160 g d'œufs, 24 g de whey…). La fiche détaillée pré-remplit aussi cette quantité.
- La fiche **se ferme immédiatement** (l'enregistrement continue en arrière-plan) + confirmation « ✓ Banane · 120 g → Petit-déjeuner » avec **Annuler**.
- Les **donuts du Journal** se mettent à jour instantanément depuis la mémoire (avant : 2 allers-retours réseau).
- Lignes allégées : cœur + ⊕ seulement ; modifier/supprimer une création perso dans un menu ⋮ ; « copier en aliment perso » déplacé dans la fiche.
- Icône « compte » retirée de cette page (hors sujet ici).

### Bugs corrigés
- **Recette / aliment / repas perso qui n'apparaissait qu'après changement d'onglet** — même famille que le bug des favoris de septembre (page = route séparée non notifiée). Désormais un notificateur de catalogue unique.
- **Ajouts rapides simultanés** : l'identifiant serveur pouvait être rattaché à la mauvaise ligne (`list.last`) → suppression ultérieure de la mauvaise entrée. Corrigé.
- **Scan depuis un jour passé** : le produit était ajouté à aujourd'hui. Corrigé.
- Vignettes Perso tronquées (« Aliments p… », « Re… ») : corrigé.
- Repas perso ajouté depuis la recherche : présélectionnait toujours « Petit-déjeuner, aujourd'hui ». Corrigé.

## 3. Recherche par phrase

Nouveau moteur (`lib/services/food_search.dart`), testé sur la vraie base :
- l'**ordre des mots est libre**, virgules/tirets/accents/majuscules ignorés, « de/la/aux… » ignorés, pluriels ramenés au singulier ;
- **faute de frappe d'une lettre** tolérée (« bananne », « poullet ») ;
- **mode phrase** : si aucun aliment ne contient tous les mots, ceux qui en contiennent tous sauf un sont proposés ;
- classement : début de nom > premier mot > mots exacts > préfixes, aliments génériques avant variantes longues, puis tes favoris, tes aliments habituels, les aliments bruts courants.

Exemples vérifiés : « magret de canard » → Canard, magret cru/grillé/fumé · « pâtes cuites » · « poulet rôti » · « sardine huile tournesol » · « lait demi écrémé » · « pomme de terre cuite ».

## 4. Base de données d'aliments

- **145 aliments CIQUAL sans valeur d'énergie** dans la table ANSES, comptés **0 kcal** dans le journal (ex. « Brochette de bœuf, crue », « Canneberge crue », « Brocciu », « Baba au rhum »).
  - 57 avec protéines/glucides/lipides connus : énergie calculée avec les coefficients officiels du **règlement UE 1169/2011** (la méthode même de l'ANSES).
  - 88 incomplets : jamais d'invention → mention « Énergie non communiquée par l'ANSES », avertissement dans la fiche, placés après les variantes complètes en recherche.
- Emoji 🏥 (hôpital) des substituts de repas → 🥤 / 🍮.
- 8 libellés avec espaces doublés nettoyés.
- Contrôles RAS : aucun doublon de nom, aucun aliment sans pictogramme.

## 5. Nouveau : « Partager sur Instagram » (repas → contenu clé en main)

Accès : menu ⋮ d'un repas du Journal, ou icône 📷 dans la fiche détail du repas.

- **Formats** : Carrousel (5 visuels 1080×1350), Post (1 visuel 1080×1350), Story (1080×1920, zones Instagram respectées), Reel (5 images 1080×1920 à importer dans l'éditeur de Reels avec ta musique).
- **Carrousel** pensé pour les enregistrements et envois : 1) photo + accroche chiffrée + kcal/macros, 2) d'où vient l'énergie (anneau), 3) micronutriments phares en % des VNR, 4) ingrédients et quantités (« à enregistrer pour la refaire »), 5) « Ce que j'en retiens » + appel à enregistrer / envoyer.
- **Photo du plat** depuis la galerie, nom du plat modifiable, ton @compte (mémorisé), 3 ambiances (crème, sauge, nuit), mention « Calculé avec Totum » désactivable.
- **Légende prête à coller** (copiée automatiquement à l'export) : accroche, macros, micros, ingrédients, appels à l'action, **5 mots-dièse max** (limite Instagram depuis décembre 2025).
- **Rigueur** : % calculés sur les **VNR officielles UE** (pas sur tes cibles perso de 3 220 kcal), aucune allégation réglementée (« riche en », « source de »), fibres et oméga-3 comparés aux références EFSA avec mention explicite.
- Export : feuille de partage native (Instagram y apparaît directement) ; téléchargement des images sur le web.

Limite assumée : pas de génération vidéo dans l'app — les images 9:16 s'importent dans l'éditeur de Reels, qui gère musique et transitions.

## 6. Parcours d'inscription

- Champs **vides** au départ (avant : 30 ans / 175 cm / 70 kg pré-remplis → on pouvait valider sans rien saisir, exactement le profil faux que ce parcours devait éviter).
- **Valeurs plausibles exigées** (âge 16–100, taille 120–230 cm, poids 30–300 kg) avec message clair.
- Bug de saisie corrigé (champs taille/poids recréés à chaque frappe).
- Récapitulatif : explique d'où vient le chiffre (métabolisme de base, ajustement automatique ensuite).

## 7. Rafraîchissement des pages

- Tableau de bord : une seule lecture des aliments du jour au lieu de deux à chaque retour sur l'onglet.
- Journal : donuts instantanés après ajout (voir §2).
- Bilan, Conseils : gardent déjà leur dernière valeur pendant le rechargement (aucun clignotement) — RAS.

## 8. À tester par toi sur téléphone (non vérifiable ici)

1. Sélection de la photo du plat (galerie) puis partage vers Instagram (carrousel multi-images).
2. Ajout rapide ⊕ puis « Annuler » avec réseau lent.
3. Ajout depuis le « + » d'un repas affiché à une date passée.
4. iOS : première ouverture de la galerie (nouvelle autorisation déclarée).

## 9. Restant / recommandations (non faits volontairement)

- Marques & restaurants viennent de la base USDA (enseignes surtout américaines) : utile mais peu pertinent pour un public français. Piste : produits Open Food Facts France (cf. audit scanner du 15/09).
- Recettes de la bibliothèque : vitamine E et B9 toujours absentes des micros (dette connue depuis le 17/08).
- Email de confirmation lent à l'inscription : nécessite une configuration SMTP côté Supabase (hors code).

## Fichiers principaux

- `lib/services/food_search.dart` (nouveau) — moteur de recherche
- `lib/screens/journal_screen.dart` — page d'ajout, ajout rapide, partage, corrections
- `lib/services/meal_share.dart`, `lib/widgets/meal_share_slides.dart`, `lib/screens/meal_share_screen.dart`, `lib/services/widget_image_renderer.dart`, `lib/services/export/share_images_*.dart` (nouveaux) — Instagram
- `lib/services/foods_loader.dart` — énergie manquante
- `lib/screens/onboarding_screen.dart`, `lib/screens/profile_screen.dart`, `lib/services/day_totals.dart`
- Tests : `food_search_test`, `foods_energy_test`, `meal_share_screenshot_test`, `add_food_page_screenshot_test`, `onboarding_screenshot_test` (captures dans `build/screens/` et `build/share/`, régénérables)
