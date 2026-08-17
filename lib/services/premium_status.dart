// lib/services/premium_status.dart
//
// Priorité 65 (audit global) : signal partagé pour forcer PremiumGate
// (main.dart) à réévaluer l'accès premium/essai après un achat ou une
// activation, sans jamais toucher à la pile de navigation. Avant, l'écran
// Compte et le Paywall utilisaient `Navigator.pushAndRemoveUntil(...,
// (route) => false)` pour "revenir à l'app" après un abonnement ou un
// changement de compte — ça supprimait AUSSI la route racine (AuthGate/
// PremiumGate), laissant l'utilisateur bloqué sur l'écran poussé, sans
// aucun moyen d'atteindre les 4 onglets principaux (bug confirmé : after
// paying, or after switching account, dead end). Le correctif : ne plus
// jamais supprimer la route racine ; PremiumGate reste monté en permanence
// et se réévalue lui-même dès que ce signal est déclenché.
import 'package:flutter/foundation.dart';

class PremiumStatus {
  PremiumStatus._();

  /// Incrémenté à chaque fois qu'un écran veut forcer PremiumGate à
  /// relire le statut premium/essai côté Supabase. La valeur elle-même
  /// n'a pas de sens, seul le changement compte (ValueListenableBuilder /
  /// addListener réagissent à toute notification).
  static final ValueNotifier<int> refreshTrigger = ValueNotifier(0);

  static void requestRefresh() => refreshTrigger.value++;
}
