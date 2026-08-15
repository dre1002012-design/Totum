import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/profile_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/bilan_screen.dart';
import 'screens/conseils_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/app_settings.dart';


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
    url: 'https://yqcbawsszozouhlkxtsj.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxY2Jhd3Nzem96b3VobGt4dHNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5NzEwNDUsImV4cCI6MjA3NTU0NzA0NX0.N11gEoG_SZ65GA0bRzFStgXb5YqzIB4trU9FbLbMtcU',
  );

  await AppSettings.load();

  runApp(const TotumApp());
}

class TotumApp extends StatelessWidget {
  const TotumApp({super.key});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF7A00); // orange TOTUM

    // Réglages → Apparence pilote themeMode ici. Note pour la suite : le
    // thème Material par défaut (AppBars, boutons standards, etc.) répond
    // déjà correctement au mode sombre — les écrans qui utilisent encore
    // des couleurs codées en dur (Profil via TotumColors, et les futurs
    // passages Journal/Bilan/Conseils) resteront visuellement clairs tant
    // que ce système partagé n'a pas lui-même été rendu sensible au thème
    // (prévu en une seule passe une fois les 4 onglets alignés visuellement).
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) => ValueListenableBuilder<double>(
        valueListenable: AppSettings.textScale,
        builder: (context, scale, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Totum',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: color, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: color, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: mode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

// Décide : écran de connexion ou application ?
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

        // Connecté → porte « Premium / Abonnement / Essai »
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
  bool _allowed = true; // par défaut : on laisse entrer en cas d'erreur

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  /// S'assure qu'une ligne user_status existe pour cet utilisateur.
  Future<Map<String, dynamic>?> _ensureUserStatus(
    SupabaseClient supabase,
    String userId,
  ) async {
    final existing = await supabase
        .from('user_status')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

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

      final status = await _ensureUserStatus(supabase, user.id);

      bool allow = true;

      if (status != null) {
        final isPremium = status['is_premium'] == true;

        // Abonnement annuel actif ? (premium_until dans le futur)
        DateTime? premiumUntil;
        final rawUntil = status['premium_until'];
        if (rawUntil is String) {
          premiumUntil = DateTime.tryParse(rawUntil);
        } else if (rawUntil is DateTime) {
          premiumUntil = rawUntil;
        }
        final subActive = premiumUntil != null &&
            premiumUntil.toUtc().isAfter(DateTime.now().toUtc());

        if (isPremium || subActive) {
          // Accès à vie (clients historiques) OU abonnement en cours
          allow = true;
        } else {
          // Ni l'un ni l'autre → on regarde l'essai gratuit
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
            // Pas de date → par sécurité, on laisse passer
            allow = true;
          }
        }
      } else {
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

    // Essai actif OU premium à vie OU abonnement en cours
    if (_allowed) {
      return const _RootShell();
    }

    // Sinon → paywall
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

  // Clés pour piloter chaque onglet depuis l'extérieur : ouvrir la page
  // d'ajout depuis le + (Journal), et surtout forcer un rafraîchissement des
  // données au retour sur un onglet — les 4 onglets restent montés en
  // permanence (IndexedStack ci-dessous, pour éviter le flash visuel qu'on
  // avait avant au changement d'onglet), donc `initState()` ne se relance
  // plus jamais tout seul : sans ce rafraîchissement explicite, un onglet
  // ne verrait plus jamais les changements faits ailleurs (aliment logué
  // dans Journal, poids enregistré...) tant que l'app n'est pas totalement
  // relancée.
  final GlobalKey<JournalScreenState> _journalKey =
      GlobalKey<JournalScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey =
      GlobalKey<ProfileScreenState>();
  final GlobalKey<BilanScreenState> _bilanKey = GlobalKey<BilanScreenState>();
  final GlobalKey<ConseilsScreenState> _conseilsKey =
      GlobalKey<ConseilsScreenState>();

  // === Onglets (pages) =======================================================
  late final List<Widget> _pages = [
    ProfileScreen(key: _profileKey),     // 👤 tableau de bord
    JournalScreen(key: _journalKey),     // 🍽️ journal
    BilanScreen(key: _bilanKey),         // 📊 bilan
    ConseilsScreen(key: _conseilsKey),   // 💡 conseils
  ];

  void _selectTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    switch (i) {
      case 0:
        _profileKey.currentState?.refresh();
        break;
      case 1:
        _journalKey.currentState?.refresh();
        break;
      case 2:
        _bilanKey.currentState?.refresh();
        break;
      case 3:
        _conseilsKey.currentState?.refresh();
        break;
    }
  }

  void _onCentralAdd() {
    // Bascule sur l'onglet Journal puis ouvre la page d'ajout.
    _selectTab(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _journalKey.currentState?.openAddPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF7A00);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCentralAdd,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _navItem(0, Icons.dashboard_rounded, 'Tableau de bord'),
            _navItem(1, Icons.restaurant, 'Journal'),
            const SizedBox(width: 56), // espace pour le bouton central
            _navItem(2, Icons.bar_chart, 'Bilan'),
            _navItem(3, Icons.lightbulb, 'Conseils'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    const accent = Color(0xFFFF7A00);
    final selected = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: selected ? accent : Colors.black45),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? accent : Colors.black45)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}