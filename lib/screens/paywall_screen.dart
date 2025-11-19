import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'auth_screen.dart';
import 'account_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // ===== In-App Purchase : uniquement pour afficher le vrai prix Play Store =====
  final InAppPurchase _iap = InAppPurchase.instance;
  static const String _kPremiumProductId = 'premium_unlock';

  bool _loadingPrice = true;
  bool _storeAvailable = false;
  ProductDetails? _premiumProduct;
  String _priceError = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initStoreInfo();
    } else {
      // Sur le web, pas de Google Play Billing
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

      const ids = {_kPremiumProductId};
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
        setState(() {
          _storeAvailable = false;
          _priceError = 'Produit Premium introuvable sur le Store.';
          _loadingPrice = false;
        });
        return;
      }

      setState(() {
        _storeAvailable = true;
        _premiumProduct = response.productDetails.first;
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

  // ===== Changer de compte : déconnexion + retour propre à l’auth =====
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
        SnackBar(content: Text('Problème lors du changement de compte : $e')),
      );
    }
  }

  // ===== Aller vers l’écran Compte (où se fait l’achat réel) =====
  void _goToAccountScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccountScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = const Color(0xFFFF7A00); // ton orange TOTUM
    final String priceText = _premiumProduct?.price ?? '6,99 €';

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
                const Text(
                  'Ton essai TOTUM est terminé',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ==== Sous-titre + explication du modèle ====
                Text(
                  _loadingPrice
                      ? 'Chargement du prix en cours…'
                      : "Tu as profité de 7 jours complets de TOTUM.\n\n"
                        "Pour continuer à utiliser l’application à vie, sans aucune publicité, "
                        "tu peux débloquer l’accès TOTUM Premium avec un paiement unique de $priceText.",
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // ==== Mise en avant des bénéfices ====
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Avec TOTUM Premium, tu gardes :',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        _BenefitRow(text: 'Accès illimité à toutes les fonctions'),
                        _BenefitRow(text: 'Aucune publicité ni distraction'),
                        _BenefitRow(text: 'Un paiement unique, pas d’abonnement'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (_priceError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _priceError,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (!_storeAvailable && !_loadingPrice)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Le Store n’est pas disponible pour le moment.\n"
                      "Vérifie ta connexion internet ou essaie de relancer l’application.",
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 8),

                // ==== Bouton principal : renvoie vers AccountScreen ====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToAccountScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      _loadingPrice
                          ? 'Passer en Premium'
                          : 'Passer en Premium ($priceText à vie)',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==== Texte explicatif sur le bouton ====
                const Text(
                  "En appuyant sur ce bouton, tu seras redirigé·e vers la page Compte.\n"
                  "Le paiement est géré de manière sécurisée par Google Play.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // ==== Bouton "Changer de compte" ====
                TextButton(
                  onPressed: _changeAccount,
                  child: const Text('Changer de compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==== Ligne de bénéfice (petite puce) ====
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
