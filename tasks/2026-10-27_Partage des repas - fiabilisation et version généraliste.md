# 27/10/2026 — Partage des repas : fiabilisation, contenu et version généraliste

Vérifications : `flutter analyze` 0 problème · **99/99 tests** · build web `--wasm` · build Android · déployé sur https://totum-app-2026.web.app.

## 1. Le partage ne fonctionnait pas — causes et correction

| Cause | Effet | Correction |
|---|---|---|
| Sur le web, l'ancienne version ne partageait jamais : elle lançait des **téléchargements automatiques** | Bloqués par les navigateurs (plusieurs fichiers sans geste), ignorés par Safari iOS | Partage via l'API du navigateur (menu de partage natif sur mobile) avec repli en téléchargement |
| Le navigateur n'autorise le partage que **juste après un toucher** ; on créait 8 images *puis* on partageait | Autorisation expirée → échec silencieux | **Parcours en 2 temps** : « Créer les visuels », puis fiche « Tes visuels sont prêts » avec **Partager…** (nouveau geste), **Enregistrer sur l'appareil** (galerie photos sur mobile, téléchargement sur le web), **Copier la légende** ; toucher une miniature partage ce visuel seul (story) |
| La fiche de résultat n'était pas défilable | Bouton « Partager… » hors écran sur un petit téléphone | Fiche défilable |
| Copie automatique de la légende refusée par certains navigateurs | Interrompait tout le parcours | Copie « au mieux », jamais bloquante |
| Police système différente selon l'appareil (iOS, Samsung, web) | Risque de texte qui déborde sur certains téléphones | **Police des visuels embarquée** dans l'app (Roboto, licence Apache 2.0) : rendu identique partout |

**Connexion directe à un compte Instagram : non retenue.** L'API de publication de Meta exige un compte professionnel et une validation de l'app par Meta, ce qui est inadapté à une app grand public. Le menu de partage natif donne déjà accès au fil, aux stories et aux messages Instagram, ainsi qu'à Facebook, WhatsApp, l'e-mail, etc., sans aucune connexion.

Test automatisé du parcours complet : écran réel → « Créer 8 visuels » → fiche → « Partager… » → le menu de partage reçoit bien les **8 fichiers PNG**, et la légende est copiée.

## 2. Emojis : supprimés pour les nutriments

Aucun emoji ne représentait correctement un nutriment : un poisson à la fois pour la B12 et les oméga-3, une châtaigne pour le sélénium, une viande pour les protéines même dans un plat végétal… Ils sont remplacés par des **badges à symbole explicite**, comme dans les infographies nutritionnelles professionnelles :
- minéraux : symbole chimique (Mg, Zn, Se, K, Ca, Fe, I) ;
- vitamines : « VIT » + lettre (D, C, B12, K…), d'où « VIT K » (vitamine) ≠ « K » (potassium) ;
- acides gras : ω3 / ω6, avec « EPA DHA », « ALA », « LA ».

Les emojis restent **uniquement pour les aliments** (pictogrammes de la base Ciqual). La légende n'en contient que deux, universels : 💾 (enregistrer) et ✈️ (envoyer, l'icône d'Instagram). Des tests vérifient qu'aucun emoji ne s'est glissé dans les données des nutriments ni dans la légende.

## 3. Fiabilité du contenu

- **Erreur corrigée** : le « rapport ω6/ω3 » ne comptait que l'oméga-3 végétal (ALA). Il affichait 10,3 et conseillait « ajoute du lin » pour un plat de sardines apportant 1,9 g d'oméga-3 marins. Il compte désormais tous les oméga-3 : **0,7 ✓** ici.
- **Deux référentiels seulement**, cités de façon courte et homogène :
  - vitamines et minéraux : % des **valeurs nutritionnelles de référence de l'UE** (adulte), les mêmes que sur les emballages ;
  - fibres (**30 g/j**) et acides gras essentiels : **repères ANSES** (adulte).
- **Rôles** : formulations des allégations de santé **autorisées dans l'UE**, portant sur le nutriment et jamais présentées comme une promesse du plat.
- **Micronutriments en vedette** : essentiels santé/longévité uniquement. Jamais phosphore, sodium, cuivre ni manganèse.
- Si un ingrédient n'a **pas de données de micronutriments** (aliment perso, produit scanné incomplet), le visuel l'indique (« valeurs sous-estimées »).
- Nombres au format français (1 030, 0,7), vérification visuelle de chaque visuel.

## 4. Version généraliste (app en production)

- Plus de choix « compte naturo / compte Totum ». Il reste un **@compte optionnel** (affiché en pied de visuel et dans l'appel à l'action), et une mention discrète **« Analysé avec Totum »**, activée par défaut et désactivable.
- **6 ambiances**, **Totum** par défaut : Totum, Totum nuit, Nature, Lin, Océan, Épuré.
- **6 formats** :
  - **Carrousel** 8 visuels 1080×1350 (Instagram, Facebook, LinkedIn) ;
  - **Post** 1080×1350 ;
  - **Story** 1080×1920 ;
  - **Reel** : 8 images 1080×1920 pour Reels, TikTok ou Shorts ;
  - **Paysage** 1200×630 (site, blog, Facebook, LinkedIn) ;
  - **Bannière** 1024×500 (en-tête de site ou de profil).
- Textes neutres (« À retenir », « L'essentiel ») ; mots-dièse généralistes (5 maximum) ; conseils de publication génériques.

## À tester sur téléphone
1. Menu ⋮ d'un repas → **Partager ce repas** → Créer → **Partager…** → Instagram, puis publication ou story.
2. **Enregistrer sur l'appareil** → les images apparaissent dans la galerie. iOS demandera l'autorisation d'ajout aux photos.
3. Sur le web (mobile) : Partager… ouvre le menu de partage du téléphone ; sur ordinateur, les images se téléchargent.
