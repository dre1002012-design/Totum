import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_localizations.dart';
import 'l10n/l10n_ext.dart';
import 'screens/profile_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/bilan_screen.dart';
import 'screens/conseils_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/app_settings.dart';
import 'services/pending_food_ops.dart';
import 'services/premium_status.dart';
import 'services/profile.dart' show computeAndSaveTargetsFromStoredProfile;
import 'theme/totum_style.dart';


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

    // Priorité 60 (15/08/2026) : mode sombre réel. TotumColors (charte
    // graphique custom de tout le reste de l'app) est désormais adaptative
    // au thème — voir totum_style.dart. Ce widget écoute maintenant AUSSI
    // AppSettings.effectiveBrightness (pas seulement themeMode) : en mode
    // "Système", themeMode ne change jamais lui-même, seule la luminosité
    // effective de l'OS bouge — c'est elle qui doit déclencher la
    // reconstruction pour que TotumColors se réévalue partout.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) => ValueListenableBuilder<Brightness>(
        valueListenable: AppSettings.effectiveBrightness,
        builder: (context, brightness, __) => ValueListenableBuilder<double>(
          valueListenable: AppSettings.textScale,
          // Priorité 62 (15/08/2026) : traduction complète FR/EN. Écoute
          // AppSettings.language (même réglage qui pilotait déjà le nom des
          // aliments, désormais étendu à toute l'interface) pour
          // reconstruire l'app avec la bonne Locale — un seul réglage,
          // jamais de dérive entre la langue des textes et celle des noms
          // d'aliments.
          builder: (context, scale, ___) => ValueListenableBuilder<String>(
            valueListenable: AppSettings.language,
            builder: (context, lang, ____) {
              SystemChrome.setSystemUIOverlayStyle(
                brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light.copyWith(
                        statusBarColor: Colors.transparent,
                        systemNavigationBarColor: TotumColors.surface,
                        systemNavigationBarIconBrightness: Brightness.light,
                      )
                    : SystemUiOverlayStyle.dark.copyWith(
                        statusBarColor: Colors.transparent,
                        systemNavigationBarColor: TotumColors.surface,
                        systemNavigationBarIconBrightness: Brightness.dark,
                      ),
              );
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Totum',
                locale: Locale(lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
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
                // Priorité 63 : pas de `const` — un `home` const est
                // canonicalisé (même instance à chaque build de MaterialApp),
                // donc Flutter détecte `child.widget == newWidget` et saute
                // entièrement la reconstruction de AuthGate et de tout ce qui
                // suit. Résultat observé (retour d'Alex) : changer le thème
                // ou la langue dans Réglages ne se voyait qu'après avoir
                // changé d'onglet (le seul autre déclencheur de rebuild).
                // ignore: prefer_const_constructors
                home: AuthGate(),
              );
            },
          ),
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
        // Priorité 63 (mode sombre/langue instantanés) : PAS de `const` ici.
        // `home: AuthGate()` (non-const, voir plus bas) permet à AuthGate de
        // se reconstruire quand le thème/la langue changent, mais si cette
        // valeur de retour reste `const PremiumGate()`, l'expression const
        // canonicalisée reste IDENTIQUE d'un build à l'autre : Flutter
        // détecte `child.widget == newWidget` (identité) et saute la
        // reconstruction de tout le sous-arbre en dessous — exactement le
        // bug qui empêchait le thème/la langue de se propager sans changer
        // d'onglet.
        // ignore: prefer_const_constructors
        return PremiumGate();
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
    // Priorité 65 : voir services/premium_status.dart — permet à
    // AccountScreen/PaywallScreen de nous dire "réévalue le statut" (après
    // un achat, une activation) sans jamais avoir à recréer cette route.
    PremiumStatus.refreshTrigger.addListener(_loadStatus);
  }

  @override
  void dispose() {
    PremiumStatus.refreshTrigger.removeListener(_loadStatus);
    super.dispose();
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
    // Priorité 63 : pas de `const` — voir commentaire sur PremiumGate() dans
    // AuthGate.build(), même raison (thème/langue doivent pouvoir traverser).
    if (_allowed) {
      // ignore: prefer_const_constructors
      return _RootShell();
    }

    // Sinon → paywall
    // ignore: prefer_const_constructors
    return PaywallScreen();
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

  @override
  void initState() {
    super.initState();
    // Priorité 63 (retour d'Alex, mode sombre "collant") : les 4 onglets
    // restent montés en permanence (late final _pages ci-dessus, jamais
    // reconstruit), donc même une fois le sous-arbre `const` corrigé
    // au-dessus (AuthGate/PremiumGate/_RootShell), IndexedStack repasserait
    // les MÊMES instances de widgets à chaque frame — Flutter les
    // considère alors identiques et ne les reconstruit pas. On écoute donc
    // directement les réglages ici et on force, comme pour un changement
    // d'onglet, le rafraîchissement de la coque ET des 4 onglets.
    AppSettings.effectiveBrightness.addListener(_onAppearanceChanged);
    AppSettings.language.addListener(_onAppearanceChanged);

    // Priorité 64 (retour d'Alex : le Bilan 7/30/90j retombe sur l'objectif
    // du jour pour les jours passés) : l'historique des objectifs
    // (goals_snapshots_v1, voir bilan_screen.dart/_goalsRawForDay) n'était
    // écrit que depuis le Journal (au chargement/retour sur cet onglet) ou
    // une sauvegarde explicite du profil — un jour où l'utilisateur ouvre
    // seulement le Tableau de bord/Bilan/Conseils ne laissait donc AUCUNE
    // trace de l'objectif réellement en vigueur ce jour-là, et le Bilan
    // retombait alors, à raison, sur l'objectif courant (repli documenté,
    // non-régressif — pas un calcul faux, un trou dans l'historique).
    // Un seul appel ici, une fois par lancement d'app, garantit un
    // instantané du jour quel que soit l'onglet réellement visité.
    () async {
      try {
        await computeAndSaveTargetsFromStoredProfile();
      } catch (_) {}
    }();

    // Priorité 66 (fiabilité hors ligne) : retente au lancement les
    // écritures Journal qui avaient échoué lors de la session précédente
    // (voir services/pending_food_ops.dart) — l'autre déclencheur, plus
    // fréquent, est le retour sur l'onglet Journal (JournalScreenState
    // .refresh()).
    () async {
      try {
        await PendingFoodOps.instance.flush();
      } catch (_) {}
    }();
  }

  @override
  void dispose() {
    AppSettings.effectiveBrightness.removeListener(_onAppearanceChanged);
    AppSettings.language.removeListener(_onAppearanceChanged);
    super.dispose();
  }

  void _onAppearanceChanged() {
    if (!mounted) return;
    setState(() {}); // recolore la coque (Scaffold, BottomAppBar, FAB)
    _profileKey.currentState?.refresh();
    _journalKey.currentState?.refresh();
    _bilanKey.currentState?.refresh();
    _conseilsKey.currentState?.refresh();
  }

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
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCentralAdd,
        backgroundColor: TotumColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      // Priorité 60 (15/08/2026, mode sombre) : bug historique confirmé —
      // cette barre utilisait Colors.black45 en dur pour les icônes/
      // libellés non sélectionnés, alors que son fond (implicite, non fixé
      // ici) suivait déjà le thème Material. En mode sombre système, fond
      // sombre + texte noir en dur = invisible. `color` fixé explicitement
      // sur TotumColors.surface (cohérent avec le reste de la charte) et
      // les couleurs de _navItem passent par TotumColors, adaptatif.
      bottomNavigationBar: BottomAppBar(
        color: TotumColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _navItem(0, Icons.dashboard_rounded, context.l10n.navDashboard),
            _navItem(1, Icons.restaurant, context.l10n.navJournal),
            const SizedBox(width: 56), // espace pour le bouton central
            _navItem(2, Icons.bar_chart, context.l10n.navBilan),
            _navItem(3, Icons.lightbulb, context.l10n.navConseils),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final selected = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: selected ? TotumColors.accent : TotumColors.textSecondary),
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
                        color: selected ? TotumColors.accent : TotumColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}