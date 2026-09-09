import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_ext.dart';
import '../services/app_settings.dart';
import '../services/premium_status.dart';
import '../services/units.dart';
import '../services/export/journal_export.dart';
import '../theme/totum_style.dart';

/// URL du portail client Stripe (gestion/annulation d'abonnement).
/// À remplir lorsque le portail client sera activé dans Stripe
/// (Paramètres → Portail client → lien de connexion billing.stripe.com/p/login/...).
/// Tant que cette valeur est vide, le bouton « Gérer mon abonnement »
/// n'est pas affiché.
const String _kStripePortalUrl = 'https://billing.stripe.com/p/login/7sY00kd2e0NDchS4ZD1RC00';

// ═══════════════════════════════════════════════════════════════════════
//  Petits composants partagés entre l'écran racine et les sous-écrans
//  Réglages — même charte partout (TotumCard, accent unique).
// ═══════════════════════════════════════════════════════════════════════

Widget _sectionHeader(IconData icon, String title) {
  return Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: TotumColors.accent),
      ),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
    ],
  );
}

Widget _subLabel(String text, {String? hint}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
        if (hint != null) ...[
          const SizedBox(height: 3),
          Text(hint, style: TextStyle(fontSize: 11, color: TotumColors.textMuted)),
        ],
      ],
    ),
  );
}

// Priorité 63 (retour d'Alex, thème sombre encore "collant" dans Compte et
// paramètres) : ces sous-écrans sont poussés via Navigator.push et ne font
// PAS partie de l'IndexedStack des 4 onglets (voir main.dart) — le
// rafraîchissement forcé là-bas ne les atteint pas. `TotumColors` étant de
// simples getters statiques (pas un InheritedWidget), rien ne les
// reconstruit automatiquement quand la luminosité change pendant qu'ils
// sont affichés. `children` passe donc d'une liste figée à une fabrique
// (`List<Widget> Function()`), réévaluée à chaque changement via ce
// ValueListenableBuilder — chaque appelant capture déjà ses variables
// locales (l10n, etc.) dans la closure, aucun autre changement nécessaire
// aux 5 sites d'appel au-delà de `children: [...]` -> `children: () => [...]`.
Widget _settingsScaffold({required String title, required List<Widget> Function() children}) {
  return ValueListenableBuilder<Brightness>(
    valueListenable: AppSettings.effectiveBrightness,
    builder: (context, _, __) => Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: TotumColors.textPrimary,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: children(),
        ),
      ),
    ),
  );
}

/// Un seul écran, une seule icône d'entrée (Priorité 48, retour d'Alex :
/// "je ne veux pas me retrouver avec deux logos en haut à droite de
/// l'application... à partir de ce petit bonhomme-là, on a la notion de
/// compte, de thème, de réglage, etc. Tout va être centralisé dans cet
/// onglet-là"). Restructuré en menu à tiroirs façon Cronometer (Priorité 53,
/// 14/08/2026, captures d'écran fournies par Alex — "j'aimerais bien que tu
/// fasses l'équivalent, mais approprié à notre application") : abonnement/
/// facturation visible directement à la racine (contexte le plus fréquent
/// d'arrivée ici, notamment depuis les upsells Premium ailleurs dans l'app),
/// puis un menu de lignes (Compte / Apparence / Langue & unités / Mes
/// données / À propos) menant chacune à son propre écran dédié — au lieu de
/// tout empiler sur une seule page. Adapté au périmètre réel de Totum, pas
/// une copie 1:1 : pas de "Jeûne"/"Planificateur de macros"/"Connecter les
/// appareils" (fonctions qui n'existent pas dans l'app), "Profil"/
/// "Objectifs" restent dans l'onglet Profil dédié (déjà l'équivalent direct,
/// pas dupliqués ici).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _loading = true;
  DateTime? _trialStart;
  bool _isPremium = false;      // accès à vie (clients historiques)
  DateTime? _premiumUntil;      // fin d'abonnement annuel (web)

  SupabaseClient get _client => Supabase.instance.client;

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  // Ancien achat unique (clients historiques + restauration) et
  // nouvel abonnement annuel.
  static const String _kPremiumProductId = 'premium_unlock';
  static const String _kSubProductId = 'totum_premium_annual';
  bool _storeAvailable = false;
  bool _purchasePending = false;
  ProductDetails? _subProduct;     // abonnement annuel
  String _purchaseError = '';

  @override
  void initState() {
    super.initState();
    // Priorité 63 (retour d'Alex, thème sombre "collant" dans Compte et
    // paramètres) : cet écran est poussé via Navigator.push, hors de
    // l'IndexedStack des 4 onglets — TotumColors (simples getters
    // statiques) ne le fait pas se reconstruire tout seul quand la
    // luminosité change pendant qu'il est affiché. Voir aussi
    // _settingsScaffold ci-dessus pour les sous-écrans (Apparence, etc.).
    AppSettings.effectiveBrightness.addListener(_onAppearanceChanged);
    _loadStatus();
    if (!kIsWeb) {
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onError: (err) {
          setState(() {
            _purchaseError = err.toString();
            _purchasePending = false;
          });
        },
        onDone: () => _purchaseSub.cancel(),
      );
      _initStoreInfo();
      // Récupère les achats/abonnements déjà possédés (ex : abonnement
      // actif souscrit précédemment) afin de réactiver l'accès et
      // d'enregistrer le purchaseToken pour la vérification serveur.
      _iap.restorePurchases();
    }
  }

  @override
  void dispose() {
    AppSettings.effectiveBrightness.removeListener(_onAppearanceChanged);
    if (!kIsWeb) _purchaseSub.cancel();
    super.dispose();
  }

  void _onAppearanceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadStatus() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      final status = await _client
          .from('user_status')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      DateTime? trialStart;
      bool isPremium = false;
      DateTime? premiumUntil;
      if (status != null) {
        final raw = status['trial_start'];
        if (raw is String) {
          trialStart = DateTime.tryParse(raw);
        } else if (raw is DateTime) {
          trialStart = raw;
        }
        isPremium = status['is_premium'] == true;

        final rawUntil = status['premium_until'];
        if (rawUntil is String) {
          premiumUntil = DateTime.tryParse(rawUntil);
        } else if (rawUntil is DateTime) {
          premiumUntil = rawUntil;
        }
      }
      if (!mounted) return;
      setState(() {
        _trialStart = trialStart;
        _isPremium = isPremium;
        _premiumUntil = premiumUntil;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _initStoreInfo() async {
    final available = await _iap.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() => _storeAvailable = false);
      return;
    }
    const ids = {_kPremiumProductId, _kSubProductId};
    final resp = await _iap.queryProductDetails(ids);
    if (!mounted) return;
    if (resp.error != null) {
      setState(() {
        _storeAvailable = false;
        _purchaseError = resp.error!.message;
      });
      return;
    }
    if (resp.productDetails.isEmpty) {
      setState(() {
        _storeAvailable = false;
        _purchaseError = context.l10n.accountProductNotFound;
      });
      return;
    }
    // Tri des produits : abonnement (l'achat unique legacy n'est plus vendu)
    ProductDetails? sub;
    for (final pd in resp.productDetails) {
      if (pd.id == _kSubProductId) sub = pd;
    }
    setState(() {
      _storeAvailable = true;
      _subProduct = sub;
    });
  }

  Future<void> _buyPremium() async {
    // On vend désormais l'ABONNEMENT annuel (plus l'achat unique).
    if (!_storeAvailable || _subProduct == null) {
      setState(() {
        _purchaseError = context.l10n.accountSubscriptionUnavailable;
      });
      return;
    }
    setState(() {
      _purchasePending = true;
      _purchaseError = '';
    });
    final param = PurchaseParam(productDetails: _subProduct!);
    // buyNonConsumable convient aussi aux abonnements avec in_app_purchase.
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!mounted) return;
      if (p.status == PurchaseStatus.pending) {
        setState(() => _purchasePending = true);
      } else {
        // Distingue un nouvel achat (message + activation) d'une simple
        // restauration au démarrage (activation silencieuse, sans pop-up).
        final bool isNewPurchase = p.status == PurchaseStatus.purchased;
        final bool isRestore = p.status == PurchaseStatus.restored;

        if (isNewPurchase || isRestore) {
          if (p.productID == _kSubProductId) {
            await _activateSubscription(p, showMessage: isNewPurchase);
          } else if (p.productID == _kPremiumProductId) {
            // Achat unique legacy : n'active à vie QUE ce produit précis.
            await _activatePremium(showMessage: isNewPurchase);
          }
        } else if (p.status == PurchaseStatus.error) {
          final msg = p.error?.message ?? '';
          if (msg.contains('possedez deja cet article') ||
              msg.contains('possédez déjà cet article') ||
              msg.toLowerCase().contains('already own this item')) {
            await _activatePremium();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.accountAlreadyOwnedRestored),
                ),
              );
            }
          } else if (mounted) {
            setState(() => _purchaseError =
                msg.isEmpty ? context.l10n.accountUnknownError : msg);
          }
        }
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        if (!mounted) return;
        setState(() => _purchasePending = false);
      }
    }
  }

  Future<void> _activatePremium({bool showMessage = true}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      await _client
          .from('user_status')
          .update({'is_premium': true}).eq('id', user.id);
      await _loadStatus();
      // Priorité 65 (audit global) : sans ça, PremiumGate (main.dart) — qui
      // décide d'afficher l'app ou le Paywall — ne réévaluait jamais son
      // propre statut après un achat réussi ici, malgré `_loadStatus()`
      // ci-dessus qui ne met à jour que L'AFFICHAGE de CET écran. Combiné à
      // l'ancien `pushAndRemoveUntil` déjà corrigé côté Paywall, l'utilisateur
      // restait bloqué sur Compte même après avoir payé.
      PremiumStatus.requestRefresh();
      if (!mounted) return;
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountPremiumActivated)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountActivationError(e.toString()))),
      );
    }
  }

  /// Abonnement annuel Google Play. On enregistre le purchaseToken (lien
  /// achat ↔ utilisateur, utilisé par la fonction serveur play-webhook pour
  /// les renouvellements/annulations) ET on pose premium_until à +1 an pour
  /// un accès immédiat sans attendre la première notification serveur.
  Future<void> _activateSubscription(PurchaseDetails? purchase,
      {bool showMessage = true}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Enregistre le lien purchaseToken → user pour la vérif serveur
      final token = purchase
          ?.verificationData.serverVerificationData;
      if (token != null && token.isNotEmpty) {
        await _client.from('play_purchases').upsert({
          'purchase_token': token,
          'user_id': user.id,
          'subscription_id': _kSubProductId,
        }, onConflict: 'purchase_token');
      }

      // Accès immédiat (la fonction serveur affinera la date au besoin)
      final until = DateTime.now().toUtc().add(const Duration(days: 365));
      await _client.from('user_status').update({
        'premium_until': until.toIso8601String(),
      }).eq('id', user.id);

      await _loadStatus();
      PremiumStatus.requestRefresh(); // voir _activatePremium ci-dessus
      if (!mounted) return;
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSubscriptionActivated)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountActivationError(e.toString()))),
      );
    }
  }

  Future<void> _openStripe() async {
    // Abonnement annuel 14,99 €/an — l'identifiant et l'email du compte
    // sont transmis à Stripe pour un déblocage automatique fiable
    // via le webhook.
    final user = _client.auth.currentUser;
    final uid = user?.id ?? '';
    final email = user?.email ?? '';
    final uri = Uri.parse(
      'https://buy.stripe.com/8x24gAd2e67Xfu43Vz1RC01'
      '?client_reference_id=$uid'
      '&prefilled_email=${Uri.encodeComponent(email)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openManageSubscription() async {
    // Android : la gestion/résiliation se fait dans le Play Store.
    // Web : portail client Stripe.
    final Uri uri;
    if (!kIsWeb) {
      uri = Uri.parse(
          'https://play.google.com/store/account/subscriptions'
          '?sku=$_kSubProductId&package=com.totumapp.totum');
    } else {
      if (_kStripePortalUrl.isEmpty) return;
      uri = Uri.parse(_kStripePortalUrl);
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _frDate(DateTime d) {
    final l = d.toLocal();
    final dd = l.day.toString().padLeft(2, '0');
    final mm = l.month.toString().padLeft(2, '0');
    return '$dd/$mm/${l.year}';
  }

  // Abonnement annuel encore actif ?
  bool get _subActive =>
      _premiumUntil != null && _premiumUntil!.toUtc().isAfter(DateTime.now().toUtc());

  DateTime? get _trialEnd => _trialStart?.toUtc().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: TotumColors.textPrimary,
        title: Text(l10n.accountScreenTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _profileHeader(user),
                  const SizedBox(height: 22),
                  // BUG CORRIGÉ (19/08/2026, retour d'Alex — audit ergonomie
                  // "Compte et paramètres") : la carte d'abonnement n'avait
                  // aucun libellé de section, contrairement à "Réglages"
                  // juste en dessous — ajoutée pour la même clarté/parité
                  // visuelle, et pour bien distinguer "Abonnement" de
                  // "Compte" (identité) comme demandé.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.accountSubscriptionSectionLabel,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
                  ),
                  const SizedBox(height: 12),
                  _subscriptionCard(),
                  const SizedBox(height: 26),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.accountSettingsSectionLabel,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
                  ),
                  const SizedBox(height: 12),
                  TotumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _menuRow(
                          icon: Icons.person_outline,
                          label: l10n.accountMenuAccount,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AccountDetailsScreen(client: _client))),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.palette_outlined,
                          label: l10n.accountMenuAppearance,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen())),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.translate,
                          label: l10n.accountMenuLanguageUnits,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const LanguageUnitsSettingsScreen())),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.download_outlined,
                          label: l10n.accountMenuMyData,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const DataExportScreen())),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.info_outline,
                          label: l10n.accountMenuAbout,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // BUG CORRIGÉ (19/08/2026, retour d'Alex — "je veux que le
                  // bouton déconnexion soit directement visible depuis la
                  // partie Compte et paramètres, pas dans Compte") :
                  // déplacé depuis AccountDetailsScreen (où il était bundlé
                  // avec "Supprimer mon compte", 2 actions de nature très
                  // différente) vers cet écran racine, en ligne autonome.
                  // Pas de style "danger" (rouge) — se déconnecter n'est ni
                  // destructif ni irréversible, contrairement à la
                  // suppression de compte qui, elle, reste dans Compte.
                  TotumCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TotumRadius.card),
                      onTap: () => _confirmSignOut(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 20, color: TotumColors.textPrimary),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(l10n.accountSignOut,
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountSignOutConfirmTitle),
        content: Text(l10n.accountSignOutConfirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.accountSignOut)),
        ],
      ),
    );
    if (confirmed == true) {
      await _client.auth.signOut();
      // BUG CORRIGÉ (21/08/2026, retour d'Alex — "on reste sur la page,
      // seulement en revenant en arrière on voit l'écran de connexion") :
      // `signOut()` fait bien basculer `AuthGate` (main.dart) sur
      // `AuthScreen`, mais ce changement a lieu SOUS la pile de navigation
      // — cet écran (`AccountScreen`) reste poussé PAR-DESSUS tant qu'il
      // n'est pas explicitement dépilé, masquant le nouvel écran en
      // dessous. Même correctif déjà appliqué à la suppression de compte
      // juste en dessous (`_confirmDelete`) — généralisé ici avec
      // `popUntil(isFirst)` plutôt qu'un nombre de `pop()` fixe, pour
      // rester correct quel que soit le nombre d'écrans empilés au-dessus
      // du tableau de bord au moment de la déconnexion.
      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  En-tête profil + abonnement — même charte que le reste de l'app
  //  (TotumCard, accent unique, pas de bannière géante).
  // ═══════════════════════════════════════════════════════════════════════

  Widget _profileHeader(User? user) {
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return TotumCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TotumColors.accentSoft,
              border: Border.all(color: TotumColors.accentBorder, width: 1.6),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: TotumColors.accent)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email.isNotEmpty ? email : context.l10n.accountDefaultName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                const SizedBox(height: 5),
                _statusChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    final l10n = context.l10n;
    IconData icon;
    String label;
    if (_isPremium) {
      icon = Icons.workspace_premium_outlined;
      label = l10n.accountStatusLifetimePremium;
    } else if (_subActive) {
      icon = Icons.workspace_premium_outlined;
      label = l10n.accountStatusAnnualSubscriber;
    } else {
      final end = _trialEnd;
      final remaining = end != null ? end.difference(DateTime.now().toUtc()).inDays + 1 : null;
      icon = Icons.hourglass_top_rounded;
      label = (remaining != null && remaining >= 0)
          ? l10n.accountStatusTrialRemaining(remaining)
          : l10n.accountStatusTrialEnded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: TotumColors.accent),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: TotumColors.accent)),
        ],
      ),
    );
  }

  Widget _subscriptionCard() {
    final l10n = context.l10n;
    final String storePriceText = kIsWeb ? '14,99 €/an' : (_subProduct?.price ?? '14,99 €/an');

    if (_isPremium) {
      // BUG CORRIGÉ (19/08/2026, retour d'Alex — "on ne peut pas cliquer sur
      // la vignette abonnement") : la carte n'avait aucune action au tap.
      // Rien à "gérer" pour un accès à vie (pas de facturation récurrente),
      // mais un tap doit malgré tout donner une confirmation explicite
      // plutôt que de rester une vignette morte.
      return TotumCard(
        accentBorder: true,
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.accountStatusLifetimePremium),
            content: Text(l10n.accountLifetimeDialogContent),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonConfirm))],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Icon(Icons.workspace_premium_outlined, size: 20, color: TotumColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.accountStatusLifetimePremium, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(l10n.accountSubLifetimeSubtitle,
                      style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: TotumColors.textMuted),
          ],
        ),
      );
    }

    if (_subActive) {
      // BUG CORRIGÉ (19/08/2026) : toute la carte est désormais cliquable
      // (avant : seul le petit bouton texte "Gérer mon abonnement" en bas
      // l'était) — mène directement à la gestion (Play Store/Stripe), où se
      // trouvent le renouvellement/l'annulation.
      return TotumCard(
        accentBorder: true,
        onTap: _openManageSubscription,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.workspace_premium_outlined, size: 20, color: TotumColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.accountSubActiveTitle,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(l10n.accountSubActiveSubtitle(_frDate(_premiumUntil!)),
                          style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (!kIsWeb || _kStripePortalUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: TotumColors.outline),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _openManageSubscription,
                  style: TextButton.styleFrom(foregroundColor: TotumColors.accent, padding: const EdgeInsets.symmetric(vertical: 8)),
                  icon: const Icon(Icons.settings_outlined, size: 17),
                  label: Text(l10n.accountManageSubscription, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                l10n.accountManageViaStripeReceipt,
                style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted),
              ),
            ],
          ],
        ),
      );
    }

    // Essai en cours ou terminé — carte avec appel à l'action.
    final end = _trialEnd;
    final now = DateTime.now().toUtc();
    final remaining = end != null ? end.difference(now).inDays + 1 : null;
    final inTrial = remaining != null && remaining >= 0;
    final subtitle = end == null
        ? l10n.accountTrialUnknown
        : inTrial
            ? l10n.accountTrialRemainingDays(remaining)
            : l10n.accountTrialEndedSubtitle;

    // BUG CORRIGÉ (19/08/2026) : toute la carte cliquable, même action que
    // le bouton principal en dessous (achat natif si disponible, sinon
    // Stripe sur web) — cohérent avec les 2 autres états ci-dessus.
    VoidCallback? cardTap;
    if (!kIsWeb && _storeAvailable && _subProduct != null) {
      cardTap = _purchasePending ? null : _buyPremium;
    } else if (kIsWeb) {
      cardTap = _openStripe;
    }

    return TotumCard(
      onTap: cardTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: TotumColors.page, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(Icons.hourglass_top_rounded, size: 19, color: TotumColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inTrial ? l10n.accountTrialInProgressTitle : l10n.accountTrialEndedTitle,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: TotumColors.textSecondary, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!kIsWeb && _storeAvailable && _subProduct != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _purchasePending ? null : _buyPremium,
                style: FilledButton.styleFrom(
                  backgroundColor: TotumColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_purchasePending ? l10n.accountProcessing : l10n.accountSubscribeWithPrice(storePriceText),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            )
          else if (kIsWeb)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _openStripe,
                style: FilledButton.styleFrom(
                  backgroundColor: TotumColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.accountSubscribeAnnualWeb, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            )
          else if (!_storeAvailable)
            Text(l10n.accountInAppUnavailable,
                style: TextStyle(fontSize: 12, color: TotumColors.textMuted)),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.accountStripeSecurePayment,
                style: TextStyle(fontSize: 11, color: TotumColors.textMuted),
              ),
            ),
          if (_purchaseError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_purchaseError, style: TextStyle(fontSize: 12, color: TotumColors.negative)),
            ),
        ],
      ),
    );
  }

  Widget _menuRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: TotumColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
            ),
            Icon(Icons.chevron_right, size: 18, color: TotumColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Sous-écran "Compte" — email, gestion de session, suppression de compte.
// ═══════════════════════════════════════════════════════════════════════

class AccountDetailsScreen extends StatefulWidget {
  final SupabaseClient client;
  const AccountDetailsScreen({super.key, required this.client});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  bool _deleting = false;

  /// BUG CORRIGÉ (19/08/2026, retour d'Alex — audit ergonomie "Compte et
  /// paramètres") : avant ce correctif, cet écran n'affichait QUE l'email en
  /// lecture seule — aucun moyen de modifier nom/téléphone/mot de passe/
  /// email une fois connecté (le seul flux mot de passe existant était le
  /// "mot de passe oublié" pré-connexion). Nom/téléphone stockés dans
  /// `user_metadata` (fusion défensive avec l'existant, jamais un
  /// remplacement complet — voir `_saveMetadata`) : aucun autre endroit du
  /// code n'utilise `user_metadata` à ce jour, mais fusionner reste la
  /// pratique sûre par défaut plutôt que de supposer que ça restera vrai.
  Future<void> _editTextField({
    required String fieldLabel,
    required String currentValue,
    required Future<void> Function(String newValue) onSave,
    bool obscure = false,
    TextInputType? keyboardType,
  }) async {
    final ctrl = TextEditingController(text: currentValue);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.accountEditFieldTitle(fieldLabel)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: obscure,
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.commonSave)),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      await onSave(ctrl.text.trim());
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.accountFieldSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.accountFieldSaveError(e.toString()))));
      }
    }
  }

  Future<void> _saveMetadata(String key, String value) async {
    final current = Map<String, dynamic>.from(widget.client.auth.currentUser?.userMetadata ?? {});
    current[key] = value;
    await widget.client.auth.updateUser(UserAttributes(data: current));
  }

  Future<void> _editEmail() async {
    final ctrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.accountEditFieldTitle(context.l10n.accountEmailLabel)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: context.l10n.accountNewEmailLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.commonSave)),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final newEmail = ctrl.text.trim();
    if (newEmail.isEmpty) return;
    try {
      // Supabase envoie un e-mail de confirmation avant que le changement ne
      // prenne réellement effet — `currentUser.email` ne change donc pas
      // immédiatement ici, volontairement (sécurité : évite qu'une simple
      // faute de frappe verrouille le compte hors d'une adresse valide).
      await widget.client.auth.updateUser(UserAttributes(email: newEmail));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.accountEmailChangeSentMessage(newEmail))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.accountFieldSaveError(e.toString()))));
      }
    }
  }

  Future<void> _editPassword() async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.accountEditFieldTitle(context.l10n.accountPasswordLabel)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newCtrl,
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(labelText: context.l10n.accountNewPasswordLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: context.l10n.accountConfirmPasswordLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.commonSave)),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    if (newCtrl.text.length < 8) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.accountPasswordTooShort)));
      return;
    }
    if (newCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.accountPasswordMismatch)));
      return;
    }
    try {
      await widget.client.auth.updateUser(UserAttributes(password: newCtrl.text));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.accountFieldSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.accountFieldSaveError(e.toString()))));
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.accountDeleteDialogTitle),
        content: Text(context.l10n.accountDeleteDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TotumColors.negative),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.accountDeletePermanently),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final user = widget.client.auth.currentUser;
    try {
      if (user != null) {
        await widget.client.from('account_deletion_requests').insert({'user_id': user.id});
      }
    } catch (e) {
      // La table peut ne pas encore être migrée côté Supabase (voir
      // supabase/migrations) — ne bloque jamais la déconnexion/le nettoyage
      // local ci-dessous, la demande sera à traiter manuellement le temps
      // que la migration soit appliquée.
      debugPrint('Erreur enregistrement demande de suppression de compte: $e');
    }

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.clear();
    } catch (_) {}

    try {
      await widget.client.auth.signOut();
    } catch (_) {}

    if (mounted) {
      setState(() => _deleting = false);
      // 2 popups à fermer : cet écran ET l'écran racine Compte & Paramètres
      // (sinon on atterrit sur une page Compte vide d'utilisateur connecté).
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool danger = false,
    bool loading = false,
  }) {
    final color = danger ? TotumColors.negative : TotumColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            loading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(loading ? context.l10n.accountDeletingInProgress : label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ),
            if (!danger) Icon(Icons.chevron_right, size: 18, color: TotumColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: TotumColors.textSecondary)),
            ),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: TotumColors.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.client.auth.currentUser;
    final email = user?.email ?? '';
    final fullName = (user?.userMetadata?['full_name'] as String?) ?? '';
    final phone = (user?.userMetadata?['phone_number'] as String?) ?? '';
    final l10n = context.l10n;
    // BUG CORRIGÉ (19/08/2026, retour d'Alex — audit ergonomie) : email,
    // nom, téléphone et mot de passe regroupés dans UNE carte "Identité",
    // tous modifiables (avant : email seul, en lecture seule) — "Se
    // déconnecter" déplacé sur l'écran racine (Compte et paramètres), ne
    // reste ici que "Supprimer mon compte" (action sur l'identité elle-même).
    return _settingsScaffold(title: l10n.accountDetailsScreenTitle, children: () => [
      TotumCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _infoRow(label: l10n.accountEmailLabel, value: email, onTap: _editEmail),
            Divider(height: 1, color: TotumColors.outline),
            _infoRow(
              label: l10n.accountFullNameLabel,
              value: fullName.isEmpty ? l10n.accountFullNameEmpty : fullName,
              onTap: () => _editTextField(
                fieldLabel: l10n.accountFullNameLabel,
                currentValue: fullName,
                onSave: (v) => _saveMetadata('full_name', v),
              ),
            ),
            Divider(height: 1, color: TotumColors.outline),
            _infoRow(
              label: l10n.accountPhoneLabel,
              value: phone.isEmpty ? l10n.accountPhoneEmpty : phone,
              onTap: () => _editTextField(
                fieldLabel: l10n.accountPhoneLabel,
                currentValue: phone,
                keyboardType: TextInputType.phone,
                onSave: (v) => _saveMetadata('phone_number', v),
              ),
            ),
            Divider(height: 1, color: TotumColors.outline),
            _infoRow(label: l10n.accountPasswordLabel, value: l10n.accountPasswordMasked, onTap: _editPassword),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TotumCard(
        padding: EdgeInsets.zero,
        child: _actionRow(
          icon: Icons.delete_outline,
          label: l10n.accountDeleteDialogTitle,
          danger: true,
          loading: _deleting,
          onTap: _deleting ? null : _confirmDeleteAccount,
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Sous-écran "Apparence" — thème (verrouillé), taille de texte.
// ═══════════════════════════════════════════════════════════════════════

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _settingsScaffold(title: l10n.appearanceScreenTitle, children: () => [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.palette_outlined, l10n.appearanceThemeSectionTitle),
            const SizedBox(height: 16),
            // Priorité 60 (15/08/2026) : mode sombre réel — TotumColors est
            // désormais adaptative (voir totum_style.dart), donc ce choix
            // n'est plus verrouillé sur Clair.
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppSettings.themeMode,
              builder: (context, mode, _) {
                Widget option(ThemeMode value, IconData icon, String label) {
                  final selected = mode == value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => AppSettings.themeMode.value = value,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected ? TotumColors.accentSoft : null,
                          side: BorderSide(
                              color: selected ? TotumColors.accentBorder : TotumColors.outline,
                              width: selected ? 1.6 : 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 20, color: selected ? TotumColors.accent : TotumColors.textSecondary),
                            const SizedBox(height: 6),
                            Text(label,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: selected ? TotumColors.accent : TotumColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Row(
                  children: [
                    option(ThemeMode.light, Icons.light_mode_outlined, l10n.appearanceThemeLight),
                    option(ThemeMode.dark, Icons.dark_mode_outlined, l10n.appearanceThemeDark),
                    option(ThemeMode.system, Icons.brightness_auto_outlined, l10n.appearanceThemeSystem),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.format_size, l10n.appearanceTextSizeSectionTitle),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: AppSettings.textScale,
              builder: (context, scale, _) {
                final options = <(double, String)>[(0.88, 'A-'), (1.0, 'A'), (1.15, 'A+'), (1.3, 'A++')];
                return Row(
                  children: [
                    for (int i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _TextScaleButton(
                          label: options[i].$2,
                          selected: (scale - options[i].$1).abs() < 0.01,
                          onTap: () => AppSettings.textScale.value = options[i].$1,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ]);
  }
}

class _TextScaleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TextScaleButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? TotumColors.accentSoft : null,
        side: BorderSide(color: selected ? TotumColors.accentBorder : TotumColors.outline, width: selected ? 1.6 : 1),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label,
          style: TextStyle(fontWeight: FontWeight.w800, color: selected ? TotumColors.accent : TotumColors.textPrimary)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Sous-écran "Langue & unités".
// ═══════════════════════════════════════════════════════════════════════

class LanguageUnitsSettingsScreen extends StatelessWidget {
  const LanguageUnitsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _settingsScaffold(title: l10n.languageUnitsScreenTitle, children: () => [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.translate, l10n.languageSectionTitle),
            const SizedBox(height: 16),
            _subLabel(l10n.languageSubLabel, hint: l10n.languageSubLabelHint),
            ValueListenableBuilder<String>(
              valueListenable: AppSettings.language,
              builder: (context, lang, _) => SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'fr', label: Text(l10n.languageFrench)),
                  ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ],
                selected: {lang},
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: TotumColors.accent,
                  selectedForegroundColor: Colors.white,
                ),
                onSelectionChanged: (s) => AppSettings.language.value = s.first,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.straighten, l10n.unitsSectionTitle),
            const SizedBox(height: 16),
            _subLabel(l10n.unitsSubLabel, hint: l10n.unitsSubLabelHint),
            ValueListenableBuilder<UnitSystem>(
              valueListenable: AppSettings.unitSystem,
              builder: (context, units, _) => SegmentedButton<UnitSystem>(
                segments: const [
                  ButtonSegment(value: UnitSystem.metric, label: Text('kg / cm')),
                  ButtonSegment(value: UnitSystem.imperial, label: Text('lb / in')),
                ],
                selected: {units},
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: TotumColors.accent,
                  selectedForegroundColor: Colors.white,
                ),
                onSelectionChanged: (s) => AppSettings.unitSystem.value = s.first,
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Sous-écran "Mes données" — export.
// ═══════════════════════════════════════════════════════════════════════

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _exporting = false;

  Future<void> _exportData() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 89)), end: now),
      helpText: l10n.dataExportPeriodHelpText,
      saveText: l10n.dataExportSaveText,
    );
    if (range == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      await JournalExporter.exportHtml(from: range.start, to: range.end);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dataExportSuccessSnackbar)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dataExportErrorSnackbar(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _settingsScaffold(title: l10n.dataExportScreenTitle, children: () => [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.download_outlined, l10n.dataExportSectionTitle),
            const SizedBox(height: 14),
            Text(
              l10n.dataExportDescription,
              style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _exporting ? null : _exportData,
                icon: _exporting
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: TotumColors.accent))
                    : const Icon(Icons.ios_share, size: 18),
                label: Text(_exporting ? l10n.dataExportGenerating : l10n.dataExportButton),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: TotumColors.accentBorder, width: 1.4),
                  foregroundColor: TotumColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Sous-écran "À propos".
// ═══════════════════════════════════════════════════════════════════════

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // BUG CORRIGÉ (19/08/2026, retour d'Alex — "apporter un niveau de détail
  // supérieur") : n'affichait QUE le numéro de version. Ajouté : identifiant
  // du package (utile pour un rapport de bug précis) et un bouton d'info
  // synthétisant la valeur ajoutée de l'app et sa rigueur scientifique —
  // SANS mention nominative (demande explicite d'Alex, deuxième passe :
  // retirer le crédit personnel affiché en dur). Volontairement pas de lien
  // vers des CGU/politique de confidentialité qui n'existent pas encore
  // ailleurs dans l'app — n'invente jamais un lien vers une page absente.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _settingsScaffold(title: l10n.aboutScreenTitle, children: () => [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BUG CORRIGÉ (19/08/2026, retour d'Alex) : la mention nominative
            // ("conçue et développée par Alex, naturopathe...") est retirée
            // — remplacée par une info accessible au tap sur le pictogramme
            // "i" DÉJÀ présent à côté du titre (`_sectionHeader`), dont le
            // contenu ne mentionne ni nom ni qualification, seulement la
            // valeur ajoutée de l'app et sa rigueur scientifique (voir
            // `aboutInfoContent`). Un SEUL pictogramme cliquable pour toute
            // la vignette — retour d'Alex (2e passe) : un 2e bouton "i"
            // séparé ajouté à droite faisait doublon avec celui déjà présent
            // à gauche du titre.
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('TOTUM'),
                  content: Text(l10n.aboutInfoContent, style: const TextStyle(height: 1.4)),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonConfirm))],
                ),
              ),
              child: _sectionHeader(Icons.info_outline, 'TOTUM'),
            ),
            const SizedBox(height: 16),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) {
                final info = snap.data;
                Widget row(String label, String value) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: TextStyle(fontSize: 13, color: TotumColors.textSecondary)),
                          Flexible(
                            child: Text(value,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
                          ),
                        ],
                      ),
                    );
                return Column(
                  children: [
                    row(l10n.aboutVersionLabel,
                        info == null ? '…' : '${info.version} (${info.buildNumber})'),
                    row(l10n.aboutPackageIdLabel, info?.packageName ?? '…'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ]);
  }
}
