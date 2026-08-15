import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_ext.dart';
import 'auth_screen.dart';
import 'account_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // ===== In-App Purchase : uniquement pour Android =====
  final InAppPurchase _iap = InAppPurchase.instance;
  static const String _kSubProductId = 'totum_premium_annual';

  bool _loadingPrice = true;
  bool _storeAvailable = false;
  ProductDetails? _subProduct;
  String _priceError = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initStoreInfo();
    } else {
      _loadingPrice = false;
      _storeAvailable = false;
    }
  }

  Future<void> _initStoreInfo() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        setState(() {
          _storeAvailable = false;
          _loadingPrice = false;
        });
        return;
      }

      const ids = {_kSubProductId};
      final response = await _iap.queryProductDetails(ids);

      if (response.error != null) {
        setState(() {
          _storeAvailable = false;
          _priceError = response.error!.message;
          _loadingPrice = false;
        });
        return;
      }

      if (response.productDetails.isEmpty) {
        if (!mounted) return;
        setState(() {
          _storeAvailable = false;
          _priceError = context.l10n.paywallSubscriptionNotFound;
          _loadingPrice = false;
        });
        return;
      }

      setState(() {
        _storeAvailable = true;
        _subProduct = response.productDetails.first;
        _loadingPrice = false;
      });
    } catch (e) {
      setState(() {
        _storeAvailable = false;
        _priceError = e.toString();
        _loadingPrice = false;
      });
    }
  }

  // ===== Changer de compte =====
  Future<void> _changeAccount() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.paywallChangeAccountError(e.toString()))),
      );
    }
  }

  // ===== Bouton principal =====
  Future<void> _handlePremiumButton() async {
    if (kIsWeb) {
      // Abonnement annuel 14,99 €/an — l'identifiant et l'email du compte
      // sont transmis à Stripe pour un déblocage automatique fiable
      // via le webhook.
      final user = Supabase.instance.client.auth.currentUser;
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
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccountScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    const Color primaryColor = Color(0xFFFF7A00);

    final String priceText = kIsWeb
        ? '14,99 €/an'
        : (_subProduct?.price ?? '14,99 €/an');

    final String buttonText = kIsWeb
        ? l10n.paywallButtonSubscribeWithPrice(priceText)
        : (_loadingPrice
            ? l10n.paywallButtonSubscribe
            : l10n.paywallButtonSubscribeWithPrice(priceText));

    final String subtitleText = kIsWeb
        ? l10n.paywallSubtitleWeb
        : (_loadingPrice
            ? l10n.paywallSubtitleLoading
            : l10n.paywallSubtitleNative(priceText));

    final String footerText =
        kIsWeb ? l10n.paywallFooterWeb : l10n.paywallFooterNative;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==== Logo ====
                Image.asset(
                  'assets/logo.png',
                  height: 110,
                ),
                const SizedBox(height: 24),

                // ==== Titre ====
                Text(
                  l10n.paywallTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ==== Sous-titre ====
                Text(
                  subtitleText,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // ==== Bénéfices ====
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.paywallBenefitsTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _BenefitRow(text: l10n.paywallBenefit1),
                        _BenefitRow(text: l10n.paywallBenefit2),
                        _BenefitRow(text: l10n.paywallBenefit3),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==== Erreurs Android uniquement ====
                if (!kIsWeb && _priceError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _priceError,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (!kIsWeb && !_storeAvailable && !_loadingPrice)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      l10n.paywallStoreUnavailable,
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 8),

                // ==== Bouton principal ====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handlePremiumButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(buttonText),
                  ),
                ),

                const SizedBox(height: 12),

                // ==== Texte explicatif ====
                Text(
                  footerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // ==== Changer de compte ====
                TextButton(
                  onPressed: _changeAccount,
                  child: Text(l10n.paywallChangeAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==== Ligne de bénéfice ====
class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Color(0xFFFF7A00),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}