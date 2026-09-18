// lib/screens/onboarding_screen.dart
//
// Parcours d'accueil pour un compte qui n'a JAMAIS configuré son profil
// (voir nutri.needsOnboarding()) — ajouté le 18/09/2026 après audit
// concurrentiel (MyFitnessPal et Cronometer imposent tous deux un parcours
// guidé avant le tableau de bord, avec des champs quasi identiques :
// sexe/âge/taille/poids, puis niveau d'activité, puis objectif) et un bug
// réel remonté par de vrais utilisateurs de Totum : atterrir directement
// sur le Tableau de bord avec des valeurs par défaut (30 ans, 175 cm,
// 70 kg) éditables ne rendait pas évident qu'il fallait les personnaliser
// ET les enregistrer — plusieurs utilisateurs repartaient sans jamais
// toucher à leur profil réel. 4 étapes courtes, pas d'"usine à gaz" :
// réglages secondaires (régime alimentaire, répartition des macros, masse
// grasse, poids cible) volontairement absents d'ici, toujours modifiables
// ensuite depuis Profil → les fiches dédiées, désormais fiables (voir le
// correctif du même jour dans profile_screen.dart : chaque fiche sauvegarde
// réellement à sa fermeture).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n_ext.dart';
import '../services/app_settings.dart';
import '../services/calibration_service.dart';
import '../services/profile.dart' as nutri;
import '../services/units.dart';
import '../theme/totum_style.dart';
import 'profile_screen.dart' show goalOptionsFor;

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  static const _pageCount = 4;

  nutri.Sex _sex = nutri.Sex.male;
  final _ageCtrl = TextEditingController(text: '30');
  final _heightCtrl = TextEditingController(text: '175'); // toujours en cm en interne
  final _weightCtrl = TextEditingController(text: '70');  // toujours en kg en interne
  nutri.ActivityLevel? _activity;
  nutri.GoalType? _goal;
  bool _saving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;

  bool get _canContinueFromMeasures => _num(_ageCtrl) > 0 && _num(_heightCtrl) > 0 && _num(_weightCtrl) > 0;

  void _goTo(int page) {
    _pageCtrl.animateToPage(page, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  nutri.UserProfile _buildProfile() => nutri.UserProfile(
        sex: _sex,
        age: _num(_ageCtrl).round(),
        heightCm: _num(_heightCtrl),
        weightKg: _num(_weightCtrl),
        activity: _activity ?? nutri.ActivityLevel.sedentary,
        goal: _goal ?? nutri.GoalType.maintain,
      );

  // Mêmes correspondances que _activityToDb/_goalToDb dans profile_screen.dart
  // (volontairement dupliquées, pas partagées) : switch SANS cas `default`
  // — si une valeur d'enum est ajoutée un jour sans mettre aussi à jour cette
  // fonction, Dart refuse de compiler plutôt que de laisser les deux dériver
  // silencieusement l'une de l'autre.
  String _activityToDb(nutri.ActivityLevel a) => switch (a) {
        nutri.ActivityLevel.sedentary => 'sedentary',
        nutri.ActivityLevel.light => 'light',
        nutri.ActivityLevel.moderate => 'moderate',
        nutri.ActivityLevel.active => 'intense',
        nutri.ActivityLevel.veryActive => 'very_intense',
        nutri.ActivityLevel.extreme => 'extreme',
      };

  String _goalToDb(nutri.GoalType g) => switch (g) {
        nutri.GoalType.lose => 'loss',
        nutri.GoalType.maintain => 'maintain',
        nutri.GoalType.gain => 'gain',
        nutri.GoalType.loseMild => 'loss_mild',
        nutri.GoalType.gainMild => 'gain_mild',
      };

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final profile = _buildProfile();

    final sp = await SharedPreferences.getInstance();
    await sp.setString('profile_sex', profile.sex == nutri.Sex.female ? 'female' : 'male');
    await sp.setDouble('profile_age', profile.age.toDouble());
    await sp.setDouble('profile_height', profile.heightCm);
    await sp.setDouble('profile_weight', profile.weightKg);
    await sp.setInt('profile_activity', profile.activity.index);
    await sp.setInt('profile_goal', profile.goal.index);

    // Calcule ET sauvegarde goals_kcal/prot/carb/fat/fiber + tous les
    // micronutriments (saveNutritionTargets, appelée à l'intérieur) —
    // relit les clés profile_* qu'on vient d'écrire ci-dessus.
    try {
      await nutri.computeAndSaveTargetsFromStoredProfile();
    } catch (_) {}

    // Première pesée du parcours — alimente tout de suite la calibration
    // adaptative (même geste que "Tes mesures" plus tard dans l'app).
    try {
      await CalibrationService.instance.logWeighIn(profile.weightKg);
    } catch (_) {}

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_profile').upsert({
          'user_id': user.id,
          'sex': profile.sex == nutri.Sex.female ? 'female' : 'male',
          'age': profile.age,
          'height_cm': profile.heightCm,
          'weight_kg': profile.weightKg,
          'activity_level': _activityToDb(profile.activity),
          'goal': _goalToDb(profile.goal),
        }, onConflict: 'user_id');
      }
    } catch (_) {
      // Hors-ligne : rien ne bloque, les clés locales déjà écrites
      // ci-dessus suffisent à faire tourner l'app (même filet de sécurité
      // que le reste de l'app) — se synchronisera au retour du réseau via
      // les mécanismes déjà en place ailleurs.
    }

    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            TotumDots(count: _pageCount, index: _page),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(), // navigation par boutons uniquement — jamais de balayage accidentel qui saute une étape
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _measuresPage(),
                  _activityPage(),
                  _goalPage(),
                  _summaryPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageScaffold({
    required String title,
    String? subtitle,
    required Widget child,
    required Widget bottomButton,
    bool showBack = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _goTo(_page - 1),
              icon: Icon(Icons.arrow_back_rounded, color: TotumColors.textSecondary),
            ),
          if (showBack) const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 13, height: 1.4, color: TotumColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 12),
          bottomButton,
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: TotumColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  // ── Étape 1 — Mesures ────────────────────────────────────────────────

  Widget _measuresPage() {
    final l10n = context.l10n;
    return _pageScaffold(
      title: l10n.onboardingWelcomeTitle,
      subtitle: l10n.onboardingWelcomeSubtitle,
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingSex, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _sexButton(l10n.profileMale, nutri.Sex.male),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _sexButton(l10n.profileFemale, nutri.Sex.female),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _numField(label: l10n.profileAgeYears, controller: _ageCtrl, icon: Icons.cake_outlined),
          const SizedBox(height: 14),
          _unitAwareField(
            labelMetric: l10n.profileHeightCm,
            labelImperial: l10n.profileHeightIn,
            icon: Icons.height,
            isWeight: false,
            controller: _heightCtrl,
          ),
          const SizedBox(height: 14),
          _unitAwareField(
            labelMetric: l10n.profileWeightKg,
            labelImperial: l10n.profileWeightLb,
            icon: Icons.monitor_weight_outlined,
            isWeight: true,
            controller: _weightCtrl,
          ),
        ],
      ),
      bottomButton: _primaryButton(
        l10n.onboardingContinue,
        _canContinueFromMeasures ? () => _goTo(1) : null,
      ),
    );
  }

  Widget _sexButton(String label, nutri.Sex sex) {
    final selected = _sex == sex;
    return GestureDetector(
      onTap: () => setState(() => _sex = sex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? TotumColors.accent : TotumColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? TotumColors.accent : TotumColors.outline),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : TotumColors.textPrimary)),
        ),
      ),
    );
  }

  Widget _numField({required String label, required TextEditingController controller, IconData? icon}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// [controller] reste TOUJOURS en unité métrique (cm/kg) — seul l'AFFICHAGE
  /// bascule en impérial (in/lb) selon AppSettings.unitSystem, converti à la
  /// saisie et à l'initialisation. Même principe que _UnitAwareNumField dans
  /// profile_screen.dart (widget non réutilisé ici pour ne pas toucher à cet
  /// écran déjà stabilisé aujourd'hui), pour ne jamais enregistrer une valeur
  /// impériale telle quelle dans un champ métrique.
  Widget _unitAwareField({
    required String labelMetric,
    required String labelImperial,
    required IconData icon,
    required bool isWeight,
    required TextEditingController controller,
  }) {
    return ValueListenableBuilder<UnitSystem>(
      valueListenable: AppSettings.unitSystem,
      builder: (context, system, _) {
        final isImperial = system == UnitSystem.imperial;
        final metricValue = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
        final displayed = isWeight ? Units.displayWeight(metricValue, system) : Units.displayHeight(metricValue, system);
        final displayCtrl = TextEditingController(
          text: displayed == displayed.roundToDouble() ? displayed.toStringAsFixed(0) : displayed.toStringAsFixed(1),
        );
        return TextField(
          controller: displayCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            final entered = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
            final metric = isWeight ? Units.weightToKg(entered, system) : Units.heightToCm(entered, system);
            controller.text = metric.toString();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: isImperial ? labelImperial : labelMetric,
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  // ── Étape 2 — Niveau d'activité ──────────────────────────────────────

  Widget _activityPage() {
    final l10n = context.l10n;
    return _pageScaffold(
      title: l10n.onboardingStepActivityTitle,
      subtitle: l10n.profileActivitySheetDesc,
      child: Column(
        children: [
          for (final level in nutri.ActivityLevel.values)
            _choiceCard(
              title: level.titleFor(l10n),
              subtitle: level.descriptionFor(l10n),
              selected: _activity == level,
              onTap: () => setState(() => _activity = level),
            ),
        ],
      ),
      bottomButton: _primaryButton(
        l10n.onboardingContinue,
        _activity != null ? () => _goTo(2) : null,
      ),
    );
  }

  // ── Étape 3 — Objectif ───────────────────────────────────────────────

  Widget _goalPage() {
    final l10n = context.l10n;
    return _pageScaffold(
      title: l10n.onboardingStepGoalTitle,
      child: Column(
        children: [
          for (final o in goalOptionsFor(l10n))
            _choiceCard(
              icon: o.icon,
              title: o.title,
              subtitle: o.description,
              selected: _goal == o.goal,
              onTap: () => setState(() => _goal = o.goal),
            ),
        ],
      ),
      bottomButton: _primaryButton(
        l10n.onboardingContinue,
        _goal != null ? () => _goTo(3) : null,
      ),
    );
  }

  Widget _choiceCard({
    IconData? icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TotumCard(
        onTap: onTap,
        accentBorder: selected,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: selected ? TotumColors.accent : TotumColors.textSecondary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: selected ? TotumColors.accent : TotumColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12, height: 1.35, color: TotumColors.textSecondary)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: TotumColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Étape 4 — Récap ──────────────────────────────────────────────────

  Widget _summaryPage() {
    final l10n = context.l10n;
    final targets = nutri.computeNutritionTargets(_buildProfile());
    final g = targets.goals;
    return _pageScaffold(
      title: l10n.onboardingStepSummaryTitle,
      subtitle: l10n.onboardingSummaryIntro,
      child: TotumCard(
        child: Column(
          children: [
            Text('${g.kcal.round()} kcal/j',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TotumColors.accent)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroChip(l10n.profileProteinG, g.prot),
                _macroChip(l10n.profileCarbG, g.carb),
                _macroChip(l10n.profileFatG, g.fat),
              ],
            ),
          ],
        ),
      ),
      bottomButton: _primaryButton(l10n.onboardingStart, _finish, loading: _saving),
    );
  }

  Widget _macroChip(String label, double grams) {
    return Column(
      children: [
        Text('${grams.round()} g', style: TextStyle(fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: TotumColors.textSecondary)),
      ],
    );
  }
}
