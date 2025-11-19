import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ====== État général (essai / premium) ======
  bool _loading = true;
  DateTime? _trialStart;
  bool _isPremium = false;

  SupabaseClient get _client => Supabase.instance.client;

  // ====== In-App Purchase (Google Play Billing) ======
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  static const String _kPremiumProductId = 'premium_unlock';
  bool _storeAvailable = false;
  bool _purchasePending = false;
  ProductDetails? _premiumProduct;
  String _purchaseError = '';

  @override
  void initState() {
    super.initState();
    _loadStatus(); // charge essai/premium depuis Supabase

    if (!kIsWeb) {
      // Écoute des mises à jour d’achats
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

      _initStoreInfo(); // charge infos produit (prix) depuis Google Play
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _purchaseSub.cancel();
    }
    super.dispose();
  }

  // ===== Lecture du statut essai/premium côté Supabase =====
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

      if (status != null) {
        final raw = status['trial_start'];
        if (raw is String) {
          trialStart = DateTime.tryParse(raw);
        } else if (raw is DateTime) {
          trialStart = raw;
        }
        isPremium = status['is_premium'] == true;
      }

      if (!mounted) return;
      setState(() {
        _trialStart = trialStart;
        _isPremium = isPremium;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ===== Initialisation du Store & chargement du produit =====
  Future<void> _initStoreInfo() async {
    final available = await _iap.isAvailable();
    if (!available) {
      setState(() => _storeAvailable = false);
      return;
    }

    const ids = {_kPremiumProductId};
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
        _purchaseError = 'Produit premium introuvable sur le Store.';
      });
      return;
    }

    setState(() {
      _storeAvailable = true;
      _premiumProduct = resp.productDetails.first;
    });
  }

  // ===== Lancer l’achat =====
  Future<void> _buyPremium() async {
    if (!_storeAvailable || _premiumProduct == null) {
      setState(() {
        _purchaseError =
            'Achat non disponible pour le moment. Réessaie dans quelques instants.';
      });
      return;
    }

    setState(() {
      _purchasePending = true;
      _purchaseError = '';
    });

    final param = PurchaseParam(productDetails: _premiumProduct!);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  // ===== Écoute des mises à jour d’achats =====
  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.pending) {
        setState(() => _purchasePending = true);
      } else {
        if (p.status == PurchaseStatus.purchased) {
          // ✅ Google confirme l’achat → on active le Premium côté Supabase
          await _activatePremium();
        } else if (p.status == PurchaseStatus.error) {
          final msg = p.error?.message ?? '';

          // Cas particulier : Google dit que l’article est déjà possédé
          if (msg.contains('possédez déjà cet article') ||
              msg.toLowerCase().contains('already own this item')) {
            // On considère que l’utilisateur a déjà payé dans le passé.
            // On restaure son Premium en base.
            await _activatePremium();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Tu possédais déjà TOTUM Premium sur ce compte Google, ton accès a été restauré ✅',
                  ),
                ),
              );
            }
          } else {
            setState(() => _purchaseError = msg.isEmpty ? 'Erreur inconnue.' : msg);
          }
        }

        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
        setState(() => _purchasePending = false);
      }
    }
  }

  // ===== Activation Premium côté Supabase =====
  Future<void> _activatePremium() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('user_status')
          .update({'is_premium': true})
          .eq('id', user.id);

      await _loadStatus(); // recharge l’état local

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci ! TOTUM Premium est activé 🥳')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’activation : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    final color = const Color(0xFFFF7A00); // orange Totum

    // Prix officiel Play Store ou fallback provisoire
    final storePriceText = _premiumProduct?.price ?? '6,99 €';

    // Texte de statut (essai / premium)
    String statusTitle = 'Statut du compte';
    String statusSubtitle = '';

    DateTime? trialEnd;
    if (_trialStart != null) {
      trialEnd = _trialStart!.toUtc().add(const Duration(days: 7));
    }

    if (_isPremium) {
      statusSubtitle =
          'Premium à vie actif. Merci pour ta confiance 💛\nTu profites de TOTUM sans pub, avec toutes les fonctions.';
    } else if (trialEnd != null) {
      final now = DateTime.now().toUtc();
      final diff = trialEnd.difference(now);
      if (diff.inDays >= 0) {
        final remainingDays = diff.inDays + 1;
        statusSubtitle =
            'Essai gratuit en cours.\nIl te reste environ $remainingDays jour(s) d’accès complet '
            'avant le passage à la version à vie à $storePriceText sans pub.';
      } else {
        statusSubtitle =
            'Essai gratuit terminé.\nPour continuer à utiliser TOTUM sans aucune limitation, '
            'débloque l’accès Premium à vie pour $storePriceText sans pub.';
      }
    } else {
      statusSubtitle =
          'Nous n’avons pas encore pu déterminer ton essai. Si besoin, essaie de te déconnecter puis de te reconnecter.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Compte TOTUM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (user != null)
                      Text(
                        user.email ?? '',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 24),

                    // 🧾 Carte de statut essai / premium
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              statusSubtitle,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (!_isPremium && trialEnd != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Fin de l’essai (théorique) : ${trialEnd.toLocal()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔸 Bouton "Passer en Premium" (réellement branché sur Google Play)
                    if (!_isPremium && !kIsWeb && _storeAvailable && _premiumProduct != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _purchasePending ? null : _buyPremium,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: color,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(
                            _purchasePending
                                ? 'Traitement en cours…'
                                : 'Passer en Premium ($storePriceText à vie)',
                          ),
                        ),
                      ),

                    if (!_isPremium && (! _storeAvailable || kIsWeb))
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Le paiement in-app n’est pas disponible sur cet appareil.',
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (_purchaseError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _purchaseError,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 🔻 Bouton "Se déconnecter"
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await _client.auth.signOut();

                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Se déconnecter'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
