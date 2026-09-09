// lib/services/account_guard.dart
//
// BUG CRITIQUE CORRIGÉ (21/08/2026, retour d'Alex — poids d'un compte de
// test visible sur un 2e compte de test JAMAIS utilisé, reproduit et confirmé
// via export SQL direct de `weight_log` : 15 pesées identiques dupliquées
// d'un user_id vers un autre) : la quasi-totalité des données de l'app
// (poids, journal, objectifs, pauses, score, sommeil/stress...) est mise en
// cache localement (SharedPreferences) SANS être scopée par utilisateur —
// un changement de compte sur le même appareil/navigateur (web notamment :
// pas besoin même d'un "se déconnecter" explicite, un signIn() qui remplace
// la session active suffit) laisse les données de l'ANCIEN compte dans le
// cache local. Pire : plusieurs services (`CalibrationService._readHistory`
// en tête) réconcilient ce cache local avec Supabase et RÉ-ÉCRIVENT
// silencieusement les entrées "locales non encore synchronisées" vers
// Supabase sous l'identité du compte ACTUELLEMENT connecté — c'est
// exactement ce mécanisme qui a dupliqué l'historique de poids d'un compte
// dans un autre.
//
// Correctif : à chaque changement d'utilisateur authentifié détecté (y
// compris null → quelqu'un, quelqu'un → personne, ou quelqu'un → quelqu'un
// d'autre), tout le cache local SharedPreferences est vidé AVANT que le
// reste de l'app n'accède à la moindre donnée — sauf les clés `settings_*`
// (préférences de l'APPAREIL : thème, langue, unités, taille de texte — pas
// des données de compte, doivent survivre à un changement de compte).
//
// BUG CRITIQUE CORRIGÉ (21/08/2026, retour d'Alex après publication Play
// Store — "je dois me reconnecter à chaque ouverture de l'app") : la 1re
// version de ce correctif vidait TOUTES les clés sauf `settings_*` — y
// compris la clé que `supabase_flutter` utilise LUI-MÊME pour persister la
// session (`sb-<ref-projet>-auth-token`, voir `supabase_flutter`
// `lib/src/supabase.dart` — construite comme
// `SharedPreferencesLocalStorage(persistSessionKey: "sb-$host-auth-token")`
// par défaut, jamais configurée autrement dans `main.dart`). Résultat :
// juste après une connexion réussie, ce correctif tournait (nouvel
// utilisateur détecté) et effaçait IMMÉDIATEMENT la session tout juste
// persistée — la connexion "prenait" pour la session en cours (déjà en
// mémoire), mais ne survivait plus jamais à un redémarrage de l'app.
// Exclusion étendue aux clés `sb-*` (préfixe documenté du SDK) en plus de
// `settings_*` — cette clé n'est de toute façon PAS une donnée de compte au
// sens de ce correctif (aucun risque de fuite : `supabase_flutter` la
// réécrit lui-même à chaque connexion/déconnexion réelle).
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'calibration_service.dart';
import 'pause_service.dart';
import 'profile.dart';

const _lastAuthUserIdKey = 'account_guard_last_user_id';

/// À appeler avant tout accès aux données locales — voir `AuthGate` dans
/// `main.dart` (au démarrage de l'app et à chaque changement d'état
/// d'authentification). Idempotent : ne fait rien si l'utilisateur
/// authentifié n'a pas changé depuis le dernier appel (le cas courant,
/// exécuté à chaque changement d'onglet/reconstruction — doit rester bon
/// marché).
Future<void> ensureLocalDataMatchesAuthenticatedUser() async {
  final sp = await SharedPreferences.getInstance();
  final currentId = Supabase.instance.client.auth.currentUser?.id;
  final lastId = sp.getString(_lastAuthUserIdKey);
  if (currentId == lastId) return;

  final keysToClear = sp
      .getKeys()
      .where((k) => !k.startsWith('settings_') && !k.startsWith('sb-'))
      .toList();
  for (final k in keysToClear) {
    await sp.remove(k);
  }
  if (currentId != null) {
    await sp.setString(_lastAuthUserIdKey, currentId);
  }

  // Caches MÉMOIRE (pas juste disque) — un changement de compte sans
  // redémarrage de l'app (web notamment) pouvait encore servir jusqu'à 5s
  // de données de l'ancien compte depuis ces singletons.
  CalibrationService.instance.resetInMemoryCache();
  PauseService.instance.resetInMemoryCache();
  ProfileStore.instance.resetInMemoryCache();
}
