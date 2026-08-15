import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n_ext.dart';

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
    final l10n = context.l10n;
    if (s.contains('invalid login credentials')) {
      return l10n.authWrongCredentials;
    }
    if (s.contains('email not confirmed')) {
      return l10n.authEmailNotConfirmed;
    }
    if (s.contains('user already registered') ||
        s.contains('already been registered')) {
      return l10n.authUserAlreadyRegistered;
    }
    if (s.contains('password should be at least')) {
      return l10n.authPasswordTooShort;
    }
    if (s.contains('unable to validate email') ||
        s.contains('invalid email')) {
      return l10n.authInvalidEmail;
    }
    if (s.contains('network') || s.contains('socket') ||
        s.contains('failed host')) {
      return l10n.authNetworkError;
    }
    if (s.contains('rate limit') || s.contains('too many')) {
      return l10n.authRateLimit;
    }
    return l10n.authGenericError;
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
        context.l10n.authSignUpWelcome,
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
        _showMessage(context.l10n.authSignInSuccess);
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
        context.l10n.authEnterEmailFirst,
        color: const Color(0xFFEF6C00),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showMessage(
        context.l10n.authResetPasswordSent,
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
      if (!mounted) return;
      _showMessage(
        context.l10n.authGoogleSignInFailed,
        color: const Color(0xFFC62828),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF7A00);
    final l10n = context.l10n;
    final String pricingText = l10n.authPricingText;

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

                  Text(
                    l10n.authWelcomeTitle,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    l10n.authTagline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Message prix adapté selon la plateforme
                  Text(
                    pricingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.authEmailLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.authEmailRequired;
                      }
                      if (!value.contains('@')) return l10n.authEmailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: l10n.authPasswordLabel,
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
                        return l10n.authPasswordRequired;
                      }
                      if (value.length < 6) return l10n.authPasswordMinLength;
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text(l10n.authForgotPassword),
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
                            child: Text(l10n.authSignInButton),
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
                            child: Text(l10n.authSignUpButton),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.authOr,
                            style: const TextStyle(fontSize: 13)),
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
                                Text(l10n.authContinueWithGoogle,
                                    style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  Text(
                    l10n.authTermsNotice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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