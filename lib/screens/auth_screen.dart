import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;

  final _formKey = GlobalKey<FormState>();

  SupabaseClient get _client => Supabase.instance.client;

  /// Affiche un message stylé (couleur selon le type) avec une durée adaptée.
  void _showMessage(String text,
      {Color color = const Color(0xFF2E7D32), int seconds = 4}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontSize: 14)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: seconds),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Traduit une erreur technique Supabase en message clair en français.
  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect. Vérifie et réessaie.';
    }
    if (s.contains('email not confirmed')) {
      return '📧 Ton email n\'est pas encore confirmé. Ouvre le lien reçu par mail, puis reconnecte-toi.';
    }
    if (s.contains('user already registered') ||
        s.contains('already been registered')) {
      return 'Un compte existe déjà avec cet email. Essaie de te connecter.';
    }
    if (s.contains('password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (s.contains('unable to validate email') ||
        s.contains('invalid email')) {
      return 'Cette adresse email ne semble pas valide.';
    }
    if (s.contains('network') || s.contains('socket') ||
        s.contains('failed host')) {
      return 'Connexion internet indisponible. Vérifie ta connexion et réessaie.';
    }
    if (s.contains('rate limit') || s.contains('too many')) {
      return 'Trop de tentatives. Patiente une minute avant de réessayer.';
    }
    return 'Une erreur est survenue. Réessaie dans un instant.';
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      await _client.auth.signUp(email: email, password: password);
      if (!mounted) return;
      _showMessage(
        '🎉 Bienvenue ! Ton compte est créé.\n'
        '📧 Ouvre ta boîte mail et clique sur le lien de confirmation, '
        'puis reviens te connecter ici.',
        color: const Color(0xFFEF6C00), // orange : action requise
        seconds: 8,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e), color: const Color(0xFFC62828));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        // Crée la ligne user_status au premier login si absente
        await _client.from('user_status').upsert(
          {'id': user.id},
          onConflict: 'id',
        );
        if (!mounted) return;
        _showMessage('Connexion réussie ✅ Bon retour parmi nous !');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e), color: const Color(0xFFC62828));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage(
        'Entre d\'abord ton email ci-dessus, puis appuie sur « Mot de passe oublié ».',
        color: const Color(0xFFEF6C00),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showMessage(
        '📧 Si un compte existe pour cet email, tu vas recevoir un lien '
        'pour réinitialiser ton mot de passe. Pense à vérifier tes spams.',
        color: const Color(0xFFEF6C00),
        seconds: 7,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e), color: const Color(0xFFC62828));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            kIsWeb ? null : 'com.totumapp.totum://login-callback/',
      );
    } catch (error) {
      debugPrint('Erreur Google sign-in: $error');
      _showMessage(
        'La connexion avec Google n\'a pas abouti. Réessaie ou utilise ton email.',
        color: const Color(0xFFC62828),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF7A00);

    // Message de prix selon la plateforme
    const String pricingText = kIsWeb
        ? 'Essai gratuit 7 jours, puis abonnement 14,99 €/an renouvelé automatiquement. Annulable à tout moment.'
        : 'Essai gratuit 7 jours, puis abonnement 14,99 €/an renouvelé automatiquement. Annulable à tout moment.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', height: 120),
                  const SizedBox(height: 24),

                  const Text(
                    'Bienvenue sur TOTUM',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Ton compagnon de suivi complet, pour une vitalité totale.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Message prix adapté selon la plateforme
                  const Text(
                    pricingText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Entre un email';
                      }
                      if (!value.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Entre un mot de passe';
                      }
                      if (value.length < 6) return 'Au moins 6 caractères';
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              backgroundColor: color,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Se connecter'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _signUp,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            child: const Text('Créer un compte'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('ou',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/icons/google.png',
                                    height: 20, width: 20),
                                const SizedBox(width: 8),
                                const Text('Continuer avec Google',
                                    style: TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  const Text(
                    'En continuant, tu acceptes les conditions d\'utilisation et la politique de confidentialité de TOTUM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}