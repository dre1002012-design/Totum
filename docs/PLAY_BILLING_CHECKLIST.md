# Google Play Billing — checklist avant le 31/08/2026

Guide clé en main, écrit le 17/08/2026 après vérification des sources officielles Google (liens en bas de page — pas de supposition, tout est sourcé). Objectif : que vous ne découvriez rien à la dernière minute sur ce sujet précis.

## 1. Où en est réellement l'app aujourd'hui — bonne nouvelle

Vérifié dans `pubspec.lock` : `in_app_purchase_android` est résolu en version **0.5.2**, qui embarque la **Billing Library native 8.0.0**. C'est exactement la version minimale exigée par Google à partir du 31/08/2026. `flutter pub outdated` confirme qu'aucune version plus récente n'est disponible pour ce paquet en l'état des contraintes actuelles.

**Conclusion : aucune mise à jour de dépendance n'est nécessaire pour être conforme aujourd'hui.** Le seul risque serait de downgrader accidentellement ce paquet plus tard — ne touchez pas `in_app_purchase`/`in_app_purchase_android` dans `pubspec.yaml` sans revérifier ce point.

## 2. Ce que l'échéance du 31/08/2026 change concrètement

Ce n'est **pas** un interrupteur qui coupe l'app ou les abonnements existants à cette date :
- **Ce qui est bloqué après le 31/08** : Google Play **refuse les nouveaux envois/mises à jour** (upload d'un nouvel APK/AAB) construits avec une Billing Library antérieure à 8.0.0. Un simple message de refus dans Play Console.
- **Ce qui continue de fonctionner sans rien faire** : l'app déjà publiée, les installations existantes, les abonnements déjà souscrits — rien ne casse côté utilisateur du jour au lendemain.
- Une **prolongation jusqu'au 01/11/2026** existe, mais elle n'est **pas automatique** — il faut la demander explicitement dans Play Console si besoin de plus de temps. Comme vous êtes déjà en 8.0.0, vous n'avez normalement pas besoin de cette prolongation.
- Petite note technique sans lien avec vous : le lien que docs/KNOWN_ISSUES.md citait (`.../billing/compliance`) renvoie une 404 côté Google — l'URL correcte aujourd'hui est `developer.android.com/google/play/billing/deprecation-faq`.

**Donc : ce point précis n'est plus un blocage pour vous.** Ce qui reste réellement à faire, c'est de tester le parcours d'achat avant de publier — ce que vous n'avez encore jamais fait en conditions réelles.

## 3. Tester un achat SANS payer réellement — étapes exactes

Deux réglages Play Console sont nécessaires **ensemble** (l'un sans l'autre ne suffit pas) :

### Étape A — Publier sur une piste de test interne
1. Play Console → votre app → **Test et publication → Tests → Test interne**.
2. Créez une release de test interne, uploadez votre AAB (`flutter build appbundle --release` — déjà généré et vérifié fonctionnel cette session).
3. Ajoutez votre propre adresse e-mail (ou celle d'un testeur de confiance) à la liste des testeurs de cette piste.
4. Récupérez le lien d'installation fourni par Play Console (lien "opt-in" du test interne) et installez l'app via ce lien sur un vrai appareil Android connecté avec ce compte Google.

### Étape B — Activer les testeurs de licence (le vrai interrupteur "pas de vraie charge")
1. Play Console → **Configuration → Test de licence** (`License testing`, dans les paramètres du compte développeur, pas de l'app).
2. Ajoutez la même adresse e-mail (ou un groupe Google contenant cette adresse) à la liste des testeurs de licence.
3. **Sans cette étape, un testeur installé via la piste interne serait quand même facturé réellement.** Les deux réglages sont indépendants et tous les deux obligatoires.

### Étape C — Dérouler le parcours complet
Avec les deux réglages en place, sur l'appareil de test :
1. Ouvrez l'app, allez sur l'écran Compte → achat de l'abonnement annuel (produit `totum_premium_annual`).
2. Lancez l'achat — Google affiche l'écran de paiement standard, mais **aucune carte n'est débitée** (mention "test card, never charged" visible sur l'écran de paiement Google).
3. Vérifiez dans l'app : le message de confirmation apparaît, l'accès premium se débloque immédiatement (`_activateSubscription` dans `account_screen.dart` écrit `premium_until` à +365 jours et enregistre le `purchase_token`).
4. Vérifiez côté Supabase : une ligne apparaît dans la table `play_purchases` (`purchase_token`, `user_id`, `subscription_id`), et `user_status.premium_until` est bien mis à jour pour ce compte.
5. **Testez aussi la restauration** : désinstallez l'app (ou installez-la sur un 2e appareil avec le même compte Google), reconnectez-vous, utilisez le bouton "Restaurer mes achats" (`_iap.restorePurchases()`, déjà appelé automatiquement à l'ouverture de l'écran Compte) — l'accès premium doit revenir sans nouvel achat.
6. **Annulez l'abonnement de test** ensuite (Play Store → Abonnements → annuler) pour ne pas laisser un abonnement de test actif indéfiniment — ça reste un vrai abonnement Google côté plateforme, juste non facturé.

### Point à vérifier en plus, spécifique à votre architecture
Le code (`account_screen.dart`) fait référence à une fonction serveur `play-webhook` censée recevoir les notifications Google (RTDN — Real-Time Developer Notifications) pour les renouvellements/annulations/remboursements, en complément de l'activation immédiate côté client. **Vérifiez que ce webhook est bien configuré dans Play Console** (Configuration → Notifications en temps réel des développeurs → URL de votre endpoint Supabase) — sans ça, l'activation initiale fonctionnera (testée ci-dessus), mais les renouvellements/annulations ne se répercuteront pas automatiquement dans `user_status`, un point qui ne se verra que des semaines plus tard sans test dédié possible avant la date réelle.

## 4. Calendrier concret pour vous, à partir d'aujourd'hui (17/08/2026)

- **Cette semaine** : Étapes A + B ci-dessus (30-45 min, une fois les accès Play Console en main).
- **Avant le 31/08/2026** : dérouler l'étape C au moins une fois de bout en bout, vérifier le point RTDN.
- Vous n'avez **aucune action de mise à jour de dépendance** à faire pour la date du 31/08 — c'est déjà en ordre.

## Sources (vérifiées le 17/08/2026)
- https://developer.android.com/google/play/billing/deprecation-faq
- https://developer.android.com/google/play/billing/migrate-gpblv8
- https://developer.android.com/google/play/billing/release-notes
- https://pub.dev/packages/in_app_purchase_android/changelog
- https://support.google.com/googleplay/android-developer/answer/6062777 (test de licence)
- https://support.google.com/googleplay/android-developer/answer/9845334 (pistes de test interne/fermé/ouvert)
