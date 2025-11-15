import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/profile_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/bilan_screen.dart';
import 'screens/conseils_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/paywall_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      ),
    );
  };

  await Supabase.initialize(
    url: 'https://yqcbawsszozouhlkxtsj.supabase.co',      // 🔸 tu as déjà mis tes vraies valeurs ici
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxY2Jhd3Nzem96b3VobGt4dHNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5NzEwNDUsImV4cCI6MjA3NTU0NzA0NX0.N11gEoG_SZ65GA0bRzFStgXb5YqzIB4trU9FbLbMtcU',        // 🔸 idem
  );

  runApp(const TotumApp());
}

class TotumApp extends StatelessWidget {
  const TotumApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFFF7A00); // ton orange Totum

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Totum',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: color, brightness: Brightness.light),
        useMaterial3: true,
      ),
      home: const AuthGate(), // ✅ on passe par la "porte d’auth"
    );
  }
}

// ✅ Cette widget décide : login ou app ?
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        // Pas connecté → écran de connexion
        if (session == null) {
          return const AuthScreen();
        }

        // Connecté → on passe par la porte "Premium / Essai"
        return const PremiumGate();
      },
    );
  }
}

class PremiumGate extends StatefulWidget {
  const PremiumGate({super.key});

  @override
  State<PremiumGate> createState() => _PremiumGateState();
}

class _PremiumGateState extends State<PremiumGate> {
  bool _loading = true;
  bool _allowed = true; // par défaut : on laisse entrer si jamais il y a une erreur

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  /// S'assure qu'une ligne user_status existe pour cet utilisateur.
  /// - Si elle existe déjà → on la renvoie.
  /// - Si elle n'existe pas → on la crée, puis on renvoie la nouvelle.
  Future<Map<String, dynamic>?> _ensureUserStatus(
    SupabaseClient supabase,
    String userId,
  ) async {
    // 1) On regarde si la ligne existe déjà
    final existing = await supabase
        .from('user_status')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    // 2) Sinon on la crée.
    //    trial_start et is_premium utilisent leurs valeurs par défaut dans la base.
    final inserted = await supabase
        .from('user_status')
        .upsert(
          {'id': userId},
          onConflict: 'id',
        )
        .select()
        .maybeSingle();

    return inserted;
  }

  Future<void> _loadStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _allowed = false;
          _loading = false;
        });
        return;
      }

      // 🔐 On s'assure qu'il y a une ligne user_status pour cet utilisateur
      final status = await _ensureUserStatus(supabase, user.id);

      bool allow = true;

      if (status != null) {
        final isPremium = status['is_premium'] == true;

        if (isPremium) {
          // Déjà premium → accès complet
          allow = true;
        } else {
          // Pas premium → on regarde la date de début d'essai
          final raw = status['trial_start'];
          DateTime? trialStart;

          if (raw is String) {
            trialStart = DateTime.tryParse(raw);
          } else if (raw is DateTime) {
            trialStart = raw;
          }

          if (trialStart != null) {
            final now = DateTime.now().toUtc();
            final startUtc = trialStart.toUtc();
            final diff = now.difference(startUtc);

            // Essai actif si moins de 7 jours
            final trialActive = diff.inDays < 7;
            allow = trialActive;
          } else {
            // Pas de date → par sécurité, on laisse passer (tu pourras durcir plus tard si tu veux)
            allow = true;
          }
        }
      } else {
        // Cas très rare : même après upsert on n'a rien → on ne bloque pas
        allow = true;
      }

      if (!mounted) return;
      setState(() {
        _allowed = allow;
        _loading = false;
      });
    } catch (e) {
      // En cas de problème réseau, on préfère ne PAS bloquer l'accès.
      if (!mounted) return;
      setState(() {
        _allowed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Essai encore actif OU utilisateur premium
    if (_allowed) {
      return const _RootShell();
    }

    // Essai terminé et pas premium → paywall
    return const PaywallScreen();
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;

  // === Onglets (pages) =======================================================
  final _pages = const [
    ProfileScreen(),   // 👤 profil
    JournalScreen(),   // 🍽️ journal
    BilanScreen(),     // 📊 bilan
    ConseilsScreen(),  // 💡 conseils
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Bilan'),
          NavigationDestination(icon: Icon(Icons.lightbulb), label: 'Conseils'),
        ],
      ),
    );
  }
}
