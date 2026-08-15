import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_settings.dart';
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

Widget _settingsScaffold({required String title, required List<Widget> children}) {
  return Scaffold(
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
        children: children,
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
    if (!kIsWeb) _purchaseSub.cancel();
    super.dispose();
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
    if (!available) {
      setState(() => _storeAvailable = false);
      return;
    }
    const ids = {_kPremiumProductId, _kSubProductId};
    final resp = await _iap.queryProductDetails(ids);
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
        _purchaseError = 'Produit Premium introuvable sur le Store.';
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
        _purchaseError =
            'Abonnement non disponible pour le moment. Réessaie dans quelques instants.';
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
                const SnackBar(
                  content: Text(
                    'Tu possédais déjà TOTUM Premium sur ce compte Google, ton accès a été restauré.',
                  ),
                ),
              );
            }
          } else {
            setState(() =>
                _purchaseError = msg.isEmpty ? 'Erreur inconnue.' : msg);
          }
        }
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
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
      if (!mounted) return;
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Merci ! TOTUM Premium est activé !')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'activation : $e')),
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
      if (!mounted) return;
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Merci ! Ton abonnement TOTUM Premium est actif !')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'activation : $e')),
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

    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: TotumColors.textPrimary,
        title: const Text('Compte & Paramètres', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _profileHeader(user),
                  const SizedBox(height: 14),
                  _subscriptionCard(),
                  const SizedBox(height: 26),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Réglages',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
                  ),
                  const SizedBox(height: 12),
                  TotumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _menuRow(
                          icon: Icons.person_outline,
                          label: 'Compte',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AccountDetailsScreen(client: _client))),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.palette_outlined,
                          label: 'Apparence',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen())),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.translate,
                          label: 'Langue & unités',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const LanguageUnitsSettingsScreen())),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.download_outlined,
                          label: 'Mes données',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const DataExportScreen())),
                        ),
                        Divider(height: 1, color: TotumColors.outline),
                        _menuRow(
                          icon: Icons.info_outline,
                          label: 'À propos',
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
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
                Text(email.isNotEmpty ? email : 'Compte TOTUM',
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
    IconData icon;
    String label;
    if (_isPremium) {
      icon = Icons.workspace_premium_outlined;
      label = 'Premium à vie';
    } else if (_subActive) {
      icon = Icons.workspace_premium_outlined;
      label = 'Abonné·e annuel';
    } else {
      final end = _trialEnd;
      final remaining = end != null ? end.difference(DateTime.now().toUtc()).inDays + 1 : null;
      icon = Icons.hourglass_top_rounded;
      label = (remaining != null && remaining >= 0) ? 'Essai — $remaining j restants' : 'Essai terminé';
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
    final String storePriceText = kIsWeb ? '14,99 €/an' : (_subProduct?.price ?? '14,99 €/an');

    if (_isPremium) {
      return TotumCard(
        accentBorder: true,
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
                  Text('Premium à vie', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Accès complet, sans publicité — merci pour ta confiance.',
                      style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_subActive) {
      return TotumCard(
        accentBorder: true,
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
                      Text('Abonnement annuel actif',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Jusqu\'au ${_frDate(_premiumUntil!)} · 14,99 €/an',
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
                  label: const Text('Gérer mon abonnement', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                'Pour gérer ou annuler ton abonnement, utilise le lien « Gérer votre abonnement » présent dans tes reçus Stripe.',
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
        ? 'Nous n\'avons pas encore pu déterminer ton essai. Si besoin, déconnecte-toi puis reconnecte-toi.'
        : inTrial
            ? 'Il te reste $remaining jour${remaining > 1 ? 's' : ''} d\'accès complet à TOTUM.'
            : 'Ton essai gratuit est terminé — abonne-toi pour retrouver un accès complet.';

    return TotumCard(
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
                    Text(inTrial ? 'Essai gratuit en cours' : 'Essai gratuit terminé',
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
                child: Text(_purchasePending ? 'Traitement en cours…' : 'S\'abonner ($storePriceText)',
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
                child: const Text('S\'abonner — 14,99 €/an', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            )
          else if (!_storeAvailable)
            Text('Le paiement in-app n\'est pas disponible sur cet appareil.',
                style: TextStyle(fontSize: 12, color: TotumColors.textMuted)),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Paiement 100 % sécurisé via Stripe · renouvelé automatiquement chaque année, annulable à tout moment.',
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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action est irréversible : ta demande de suppression sera enregistrée, ton compte et toutes tes données '
          '(journal, objectifs, historique de poids) seront supprimés définitivement. Tu seras déconnecté immédiatement.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TotumColors.negative),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer définitivement'),
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
              child: Text(loading ? 'Suppression…' : label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ),
            if (!danger) Icon(Icons.chevron_right, size: 18, color: TotumColors.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.client.auth.currentUser?.email ?? '';
    return _settingsScaffold(title: 'Compte', children: [
      TotumCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Adresse courriel', style: TextStyle(fontSize: 13, color: TotumColors.textSecondary)),
            Flexible(
              child: Text(email,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TotumCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _actionRow(
              icon: Icons.logout_rounded,
              label: 'Se déconnecter',
              onTap: () async {
                await widget.client.auth.signOut();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            Divider(height: 1, color: TotumColors.outline),
            _actionRow(
              icon: Icons.delete_outline,
              label: 'Supprimer mon compte',
              danger: true,
              loading: _deleting,
              onTap: _deleting ? null : _confirmDeleteAccount,
            ),
          ],
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
    return _settingsScaffold(title: 'Apparence', children: [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.palette_outlined, 'Thème'),
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
                    option(ThemeMode.light, Icons.light_mode_outlined, 'Clair'),
                    option(ThemeMode.dark, Icons.dark_mode_outlined, 'Sombre'),
                    option(ThemeMode.system, Icons.brightness_auto_outlined, 'Système'),
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
            _sectionHeader(Icons.format_size, 'Taille du texte'),
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
    return _settingsScaffold(title: 'Langue & unités', children: [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.restaurant_menu, 'Langue des aliments'),
            const SizedBox(height: 16),
            _subLabel('Nom des aliments',
                hint: 'Dans la recherche et le journal — le reste de l\'app reste en français.'),
            ValueListenableBuilder<String>(
              valueListenable: AppSettings.language,
              builder: (context, lang, _) => SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fr', label: Text('Français')),
                  ButtonSegment(value: 'en', label: Text('Anglais')),
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
            _sectionHeader(Icons.straighten, 'Unités de mesure'),
            const SizedBox(height: 16),
            _subLabel('Poids et taille', hint: 'Les calculs internes restent toujours en métrique.'),
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
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 89)), end: now),
      helpText: 'Période à exporter',
      saveText: 'EXPORTER',
    );
    if (range == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      await JournalExporter.exportHtml(from: range.start, to: range.end);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapport exporté')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export : $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _settingsScaffold(title: 'Mes données', children: [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.download_outlined, 'Exporter mon journal'),
            const SizedBox(height: 14),
            Text(
              'Exporte ton journal alimentaire, tes objectifs et tes micronutriments sur une période, au format HTML (convertible en PDF, ex. pour un professionnel de santé).',
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
                label: Text(_exporting ? 'Génération…' : 'Exporter mes données'),
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

  // Priorité 61 (15/08/2026) : version lue directement depuis le build
  // (package_info_plus) plutôt qu'une constante dupliquée à resynchroniser
  // à la main à chaque bump de pubspec.yaml — source d'incohérence
  // éliminée pour de bon, plutôt que juste corrigée une fois de plus.
  Future<String> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    return _settingsScaffold(title: 'À propos', children: [
      TotumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.info_outline, 'TOTUM'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Version', style: TextStyle(fontSize: 13, color: TotumColors.textSecondary)),
                FutureBuilder<String>(
                  future: _loadVersion(),
                  builder: (context, snap) => Text(snap.data ?? '…',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }
}
