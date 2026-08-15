# Règles de collaboration — Claude / agent IA sur ce projet

Ces règles s'appliquent à toute session de travail sur TOTUM (Claude Code, agent VS Code, ou toute IA assistante).

## Langue
Toujours communiquer et documenter en français. C'est aussi la langue de l'application.

## Format obligatoire pour toute modification de code
Donner systématiquement un bloc **"cherche ceci" / "remplace par cela"** exploitable directement au Ctrl+F dans l'éditeur.
- ❌ Ne jamais donner d'instruction du type "insère telle méthode dans la classe X, après la méthode Y".
- ✅ Toujours donner le texte exact à chercher (contexte suffisant pour être unique dans le fichier) et le texte exact de remplacement.
- Si l'agent a un accès direct au fichier (outil d'édition), il peut appliquer directement — mais doit d'abord avoir lu le fichier réel pour vérifier que le texte cherché existe bien tel quel.

## Toujours vérifier le vrai fichier avant d'éditer
Ne jamais halluciner le contenu d'un fichier existant. Avant toute modification :
1. Lire le fichier réel concerné.
2. Vérifier que les noms de classes, méthodes, variables, clés utilisés correspondent exactement à l'existant.
3. Ne proposer un bloc cherche/remplace qu'une fois cette vérification faite.

Ce pattern a été validé sur toute une session de développement et a évité plusieurs erreurs (fichiers parfois périmés ou dupliqués par relance de script ; découverte que `CoachContext.ratios` accepte en réalité 30 micronutriments et non les 8 initialement supposés). À conserver systématiquement.

## Modifications ciblées, pas de réécritures complètes
Privilégier des modifications chirurgicales avec spécification explicite du fichier et de l'emplacement avant toute intégration, plutôt que de réécrire des fichiers entiers.

## Garde-fou d'architecture
Ne jamais proposer ou entamer une migration d'architecture lourde (ex. migration Supabase complète pour Recettes/Ingrédients) sans validation explicite d'Alex, même si un document externe la recommande. Voir `PROJECT_CONTEXT.md` pour la décision actée sur ce sujet précis.

## Vis-à-vis des spécifications ou cahiers des charges externes
Si Alex transmet un document généré par un autre outil/IA (cahier des charges, audit, spec) :
1. Ne jamais l'appliquer tel quel sans vérification contre le code réel.
2. Distinguer une architecture proposée (à valider avant tout changement structurant) d'une idée ponctuelle réutilisable (à évaluer au cas par cas).
3. Vérifier les affirmations factuelles du document contre le code et/ou une recherche externe si pertinent (exemple : la remise en cause du filtre "Perte de poids" a été vérifiée par recherche sur les apps de référence avant d'être actée).

## Philosophie produit à respecter dans les choix UX/texte
- Ne jamais formuler une fonctionnalité comme une promesse de résultat corporel (ex. "Perte de poids" comme filtre de recette). Toujours décrire une propriété factuelle du contenu (calories, protéines, temps de préparation...).
- S'appuyer sur des seuils scientifiques reconnus quand ils existent (ex. seuils de sommeil NSF Hirshkowitz 2015) plutôt que des seuils arbitraires.
- Rappel vision produit : app éducative et holistique, fiabilité et profondeur avant tout — voir `PROJECT_CONTEXT.md`.

## Gestion du TODO
Dérouler les tâches de `TODO.md` dans l'ordre indiqué, sans sauter d'étapes, sauf demande explicite d'Alex. Mettre à jour `TODO.md` et `CURRENT_STATE.md` au fur et à mesure (cocher les tâches terminées, déplacer les nouvelles découvertes vers la section pertinente).

## Repères techniques à ne jamais casser sans vérification
- Clé de trigger `micro` dans `coach_advices.json` = exactement les clés de `decision.microRatios` dans `_decideTheme()` de `conseils_screen.dart` (30 clés valides confirmées).
- `CoachContext.goalKey` : `'loss'` (goalIndex ≤ 0), `'maintain'` (1 ou 2), `'gain'` (≥ 3).
- `CoachContext.activityKey` : `'low'` (activityIdx ≤ 0) ou `'normal'`.
- `_kRatioToFicheKey` dans `conseils_screen.dart` : mapping ratio → clé de fiche nutriment (30 entrées).