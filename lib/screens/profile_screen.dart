import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile.dart' as nutri;
import '../services/calibration_service.dart';
import '../services/day_totals.dart';
import '../services/priority_nutrients.dart';
import '../services/app_settings.dart';
import '../services/units.dart';
import '../theme/totum_style.dart';
import 'package:fl_chart/fl_chart.dart';
import 'weight_trend_screen.dart';
import 'expenditure_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

/// Régime alimentaire — n'existe pas dans le moteur de calcul (n'affecte ni
/// les calories ni les macros) : purement local à l'écran, oriente juste la
/// source de certains nutriments ailleurs dans l'app (onglet Bilan).
enum Diet { omnivore, vegetarien, vegetalien }

String _dietLabel(Diet d) => switch (d) {
      Diet.omnivore => 'Omnivore',
      Diet.vegetarien => 'Végétarien',
      Diet.vegetalien => 'Végétalien',
    };

/// 5 objectifs — la vignette/liste reste compacte (emoji/titre/indication
/// chiffrée), mais chaque option garde son descriptif complet + conseils,
/// accessibles via "En savoir plus" — une vraie valeur ajoutée, au même
/// titre que les fiches nutriments de l'onglet Bilan, donc conservée
/// spécifiquement ici (contrairement aux autres fiches, restées épurées).
class _GoalOption {
  final nutri.GoalType goal;
  final IconData icon;
  final String title;
  final String description;
  final List<String> tips;
  final String coach;
  const _GoalOption({
    required this.goal,
    required this.icon,
    required this.title,
    required this.description,
    required this.tips,
    required this.coach,
  });
}

const List<_GoalOption> _kGoalOptions = [
  _GoalOption(
    goal: nutri.GoalType.lose,
    icon: Icons.local_fire_department,
    title: 'Perte de gras',
    description: 'Perdre de la masse grasse à un bon rythme, tout en préservant tes muscles et ton énergie.',
    tips: [
      'Garde un bon apport en protéines pour protéger tes muscles',
      'Bouge régulièrement — même une marche quotidienne compte',
      'Dors suffisamment : la récupération fait partie du résultat',
      'Après 8 à 10 semaines, prévois une pause en Maintien',
    ],
    coach: 'La priorité est de préserver ta masse musculaire pendant que tu perds du gras. '
        'TOTUM relève automatiquement ta cible en protéines. Un rythme modéré est plus '
        'efficace et bien plus durable qu\'un régime extrême.',
  ),
  _GoalOption(
    goal: nutri.GoalType.loseMild,
    icon: Icons.trending_down,
    title: 'Perte en douceur',
    description: 'Perdre du poids progressivement, sans frustration ni coup de fatigue. Idéal pour tenir dans le temps.',
    tips: [
      'Un déficit léger, plus facile à tenir au quotidien',
      'Prends soin de ta récupération et de ton sommeil',
      'Garde de l\'énergie pour tes activités et ta forme',
      'La régularité compte plus que la vitesse',
    ],
    coach: 'Cette approche tout en douceur est parfaite pour perdre du poids sans y penser '
        'en permanence. La progression est plus lente, mais c\'est justement ce qui la rend '
        'durable : patience et constance sont tes meilleures alliées.',
  ),
  _GoalOption(
    goal: nutri.GoalType.maintain,
    icon: Icons.balance,
    title: 'Maintien',
    description: 'Stabiliser ton poids et te sentir bien, sur la durée.',
    tips: [
      'Mange à hauteur de tes besoins, ni plus ni moins',
      'Garde une activité physique régulière',
      'Conserve un bon apport en protéines',
      'Observe ton poids moyen sur la semaine, pas au jour le jour',
    ],
    coach: 'Ton objectif n\'est plus de perdre ou de prendre, mais de conserver tes résultats '
        'et de te sentir bien. C\'est la régularité qui ancre les bonnes habitudes sur le '
        'long terme — tu es dans la zone de la sérénité.',
  ),
  _GoalOption(
    goal: nutri.GoalType.gainMild,
    icon: Icons.fitness_center,
    title: 'Prise de muscle',
    description: 'Développer tes muscles progressivement, avec une prise de gras maîtrisée.',
    tips: [
      'Un léger surplus, juste ce qu\'il faut pour construire',
      'Associe à une activité de renforcement si tu le peux',
      'Un bon apport en protéines soutient tes muscles',
      'Un sommeil de qualité accélère les progrès',
    ],
    coach: 'Une progression lente et maîtrisée donne un bien meilleur ratio muscle/graisse '
        'qu\'une prise rapide. Inutile de forcer : la qualité prime sur la quantité, et ton '
        'corps te remerciera.',
  ),
  _GoalOption(
    goal: nutri.GoalType.gain,
    icon: Icons.rocket_launch,
    title: 'Prise de masse',
    description: 'Maximiser ta prise de muscle et de force, pour les objectifs les plus ambitieux.',
    tips: [
      'Un surplus plus marqué pour soutenir la construction',
      'Idéal si tu t\'entraînes intensément et régulièrement',
      'Une bonne récupération est essentielle',
      'Surveille ton évolution pour rester sur la bonne voie',
    ],
    coach: 'Ce mode est fait pour les objectifs ambitieux. Contrôle régulièrement ton évolution '
        'pour éviter une prise de graisse superflue : un surplus maîtrisé donne toujours de '
        'meilleurs résultats qu\'un excès non suivi.',
  ),
];

_GoalOption _goalOption(nutri.GoalType g) => _kGoalOptions.firstWhere((o) => o.goal == g);

class ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  SupabaseClient get _client => Supabase.instance.client;

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

  String _dietStyleToDb(nutri.DietStyle d) => switch (d) {
        nutri.DietStyle.balanced => 'balanced',
        nutri.DietStyle.highCarb => 'high_carb',
        nutri.DietStyle.highFat => 'high_fat',
        nutri.DietStyle.keto => 'keto',
      };

  nutri.Sex _sex = nutri.Sex.male;
  Diet _diet = Diet.omnivore;
  nutri.GoalType _goal = nutri.GoalType.maintain;
  bool _goalChosen = false; // false tant que l'utilisateur n'a pas choisi

  // Niveau d'activité — UN SEUL choix qualitatif (quotidien + sport
  // confondus), plutôt que deux réglages séparés à recouper soi-même.
  // Choix délibéré après audit (06/08/2026, voir docs/TODO.md) : un
  // compteur de pas ne capture pas l'intensité (course ≠ marche à pas
  // égal), et demander à l'utilisateur d'estimer ses pas "hors
  // entraînement" s'est révélé source d'erreur réelle en usage — la
  // même approche que celle vérifiée chez MacroFactor (un seul niveau
  // qualitatif comme point de départ, la calibration adaptative fait le
  // reste). null tant que l'utilisateur n'a pas encore choisi.
  nutri.ActivityLevel? _activityLevel;

  // Masse grasse — plages (façon MacroFactor) plutôt qu'une saisie libre en
  // %, plus fiable pour qui n'a qu'une estimation visuelle.
  bool _bodyFatEnabled = false;
  nutri.BodyFatRange? _bodyFatRange;
  final _ageCtrl = TextEditingController(text: '30');
  final _heightCtrl = TextEditingController(text: '175');
  final _weightCtrl = TextEditingController(text: '70');
  // Poids cible — optionnel, active le "Maintien dynamique" (façon
  // MacroFactor, audit du 09/08/2026) : sans lui, Maintien reste kcal=TDEE
  // comme avant.
  final _targetWeightCtrl = TextEditingController();
  nutri.DietStyle _dietStyle = nutri.DietStyle.balanced;

  double _kcal = 0, _prot = 0, _carb = 0, _fat = 0, _fib = 30;

  // Aperçu réactif : _dirty est vrai dès que les objectifs affichés
  // diffèrent des dernières valeurs réellement sauvegardées.
  bool _dirty = false;
  double _savedKcal = 0, _savedProt = 0, _savedCarb = 0, _savedFat = 0, _savedFib = 30;

  bool _manualMode = false;
  final _manualKcalCtrl = TextEditingController();
  final _manualProtCtrl = TextEditingController();
  final _manualCarbCtrl = TextEditingController();
  final _manualFatCtrl = TextEditingController();
  final _manualFibCtrl = TextEditingController();

  CalibrationResult _calibration = CalibrationResult.none;

  late Future<List<WeighIn>> _weightHistoryFuture;
  late Future<DayTotals> _dayTotalsFuture;
  late Future<nutri.NutritionTargets> _targetsFuture;
  late Future<List<ExpenditurePoint>> _expenditureHistoryFuture;

  final _kpiPageCtrl = PageController();
  int _kpiPage = 0;

  void _refreshCharts() {
    _weightHistoryFuture = CalibrationService.instance.recentHistory(60);
    _dayTotalsFuture = computeTodayTotals();
    _targetsFuture = _computeAutoTargets();
    _expenditureHistoryFuture = CalibrationService.instance.expenditureHistory(days: 60);
  }

  /// Recharge les données pouvant avoir changé depuis un autre onglet
  /// (aliment logué dans Journal, poids enregistré...). Appelé par
  /// main.dart à chaque retour sur cet onglet : les 4 onglets restent
  /// montés en permanence (IndexedStack, pour éviter le flash visuel au
  /// changement d'onglet), donc plus rien ne recharge automatiquement au
  /// retour comme le faisait — par accident — l'ancien remontage complet.
  void refresh() {
    if (!mounted) return;
    setState(_refreshCharts);
  }

  /// Cibles complètes (macros + micronutriments) pour la carte
  /// "Micronutriments en vedette" — même profil que [_computeAutoGoals],
  /// mais renvoie l'objet complet plutôt que juste kcal/macros.
  Future<nutri.NutritionTargets> _computeAutoTargets() async {
    final kg = _num(_weightCtrl);
    final cm = _num(_heightCtrl);
    final age = _num(_ageCtrl).round();
    final profile = _buildCurrentProfile(kg, cm, age);
    return nutri.computeCalibratedTargets(profile);
  }

  /// Résumé affiché sur la vignette "Niveau d'activité" — null tant que
  /// l'utilisateur n'a pas encore choisi.
  String? get _activitySummary => _activityLevel?.title;

  String get _measuresSummary {
    final age = _num(_ageCtrl).round();
    final h = _num(_heightCtrl);
    final w = _num(_weightCtrl);
    final system = AppSettings.unitSystem.value;
    return '$age ans · ${Units.formatHeight(h, system)} · ${Units.formatWeight(w, system)}';
  }

  /// Construit le profil courant à partir des champs du formulaire — le
  /// niveau d'activité choisi par l'utilisateur EST directement le PAL
  /// (via _activityFactor dans le moteur), plus besoin de le reconstruire
  /// depuis des pas et une liste d'entraînements séparés.
  nutri.UserProfile _buildCurrentProfile(double kg, double cm, int age) {
    return nutri.UserProfile(
      sex: _sex,
      age: age,
      heightCm: cm,
      weightKg: kg,
      activity: _activityLevel ?? nutri.ActivityLevel.sedentary,
      goal: _goal,
      bodyFatPercent: _currentBodyFat(),
      targetWeightKg: _targetWeightKg,
      dietStyle: _dietStyle,
    );
  }

  double? get _targetWeightKg {
    final v = _num(_targetWeightCtrl);
    return v > 0 ? v : null;
  }

  /// Recalcule IMMÉDIATEMENT l'aperçu des objectifs (formule pure, sans la
  /// pondération de calibration adaptative qui n'a de sens qu'à la
  /// sauvegarde). Appelé depuis TOUS les réglages, pour que l'effet soit
  /// visible tout de suite — c'était le bug racine du round précédent
  /// ("les valeurs ne bougent pas").
  void _recomputePreview() {
    final kg = _num(_weightCtrl);
    final cm = _num(_heightCtrl);
    final age = _num(_ageCtrl).round();
    if (kg <= 0 || cm <= 0 || age <= 0) return;

    final profile = _buildCurrentProfile(kg, cm, age);
    final g = nutri.computeGoals(profile);
    setState(() {
      _kcal = g.kcal;
      _prot = g.prot;
      _carb = g.carb;
      _fat = g.fat;
      _fib = g.fiber;
      _dirty = g.kcal != _savedKcal ||
          g.prot != _savedProt ||
          g.carb != _savedCarb ||
          g.fat != _savedFat ||
          g.fiber != _savedFib;
    });
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _manualKcalCtrl.dispose();
    _manualProtCtrl.dispose();
    _manualCarbCtrl.dispose();
    _manualFatCtrl.dispose();
    _manualFibCtrl.dispose();
    _kpiPageCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;

  /// Affiche un nombre sans zéros décimaux inutiles.
  String _trimNumber(double v) {
    String s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  double? _currentBodyFat() {
    if (!_bodyFatEnabled || _bodyFatRange == null) return null;
    return _bodyFatRange!.midpointFor(_sex);
  }

  /// Libellé "Rythme visé : −X %/sem" recalculé pour le profil courant (âge,
  /// sexe, % de masse grasse si connu) — reflète la vraie vitesse cible
  /// appliquée, y compris la variante conservatrice pour les profils déjà
  /// secs ou seniors (voir [nutri.goalRateBwPerWeekFor]). Objectif exprimé en
  /// %poids/semaine plutôt qu'en %TDEE figé — façon MacroFactor (audit du
  /// 09/08/2026) : le même objectif correspond à un déficit/surplus qui
  /// s'adapte automatiquement à mesure que le poids change.
  String _technicalLabelFor(nutri.GoalType goal) {
    if (goal == nutri.GoalType.maintain) {
      return _targetWeightCtrl.text.trim().isNotEmpty ? 'Maintien dynamique' : 'Équilibre';
    }
    final age = _num(_ageCtrl).round();
    final rate = nutri.goalRateBwPerWeekFor(goal, age, sex: _sex, bodyFatPercent: _currentBodyFat());
    final pct = (rate.abs() * 100);
    final pctStr = pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toStringAsFixed(2);
    return rate < 0 ? 'Rythme visé : −$pctStr %/sem' : 'Rythme visé : +$pctStr %/sem';
  }

  /// Écart entre les calories saisies et la somme réelle des macros (mode
  /// manuel) — directionnel et chiffré.
  ({String text, double diff, bool tooHigh})? _checkManualCoherence() {
    final kcal = _num(_manualKcalCtrl);
    final prot = _num(_manualProtCtrl);
    final carb = _num(_manualCarbCtrl);
    final fat = _num(_manualFatCtrl);
    if (kcal <= 0) return null;
    final computedKcal = (prot * 4) + (carb * 4) + (fat * 9);
    if (computedKcal <= 0) return null;
    final diff = computedKcal - kcal;
    final pct = diff.abs() / kcal;
    if (pct > 0.05) {
      final tooHigh = diff > 0;
      final pctTxt = (pct * 100).toStringAsFixed(0);
      final text = tooHigh
          ? 'Tes macros représentent ${computedKcal.toStringAsFixed(0)} kcal — '
              '${diff.toStringAsFixed(0)} kcal ($pctTxt %) DE PLUS que les '
              '${kcal.toStringAsFixed(0)} kcal indiquées.'
          : 'Tes macros représentent ${computedKcal.toStringAsFixed(0)} kcal — '
              '${diff.abs().toStringAsFixed(0)} kcal ($pctTxt %) DE MOINS que les '
              '${kcal.toStringAsFixed(0)} kcal indiquées.';
      return (text: text, diff: diff, tooHigh: tooHigh);
    }
    return null;
  }

  /// Objectifs auto (formule + calibration adaptative si assez de données)
  /// — délègue à [nutri.computeCalibratedGoals], EXACTEMENT la même
  /// fonction que celle appliquée à la sauvegarde
  /// (computeAndSaveTargetsFromStoredProfile) : l'aperçu affiché ici et la
  /// valeur réellement enregistrée ne peuvent donc plus jamais diverger.
  Future<nutri.Goals> _computeAutoGoals() async {
    final kg = _num(_weightCtrl);
    final cm = _num(_heightCtrl);
    final age = _num(_ageCtrl).round();
    final profile = _buildCurrentProfile(kg, cm, age);

    final calib = await CalibrationService.instance.computeCalibration();
    if (mounted) setState(() => _calibration = calib);

    return nutri.computeCalibratedGoals(profile);
  }

  Future<void> _computeAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    final kg = _num(_weightCtrl);
    final cm = _num(_heightCtrl);
    final age = _num(_ageCtrl).round();

    final goalsAuto = await _computeAutoGoals();
    final kcalAuto = goalsAuto.kcal;
    final protAuto = goalsAuto.prot;
    final carbAuto = goalsAuto.carb;
    final fatAuto = goalsAuto.fat;
    final fibAuto = goalsAuto.fiber;

    double finalKcal, finalProt, finalCarb, finalFat, finalFib;
    if (_manualMode) {
      finalKcal = _num(_manualKcalCtrl) > 0 ? _num(_manualKcalCtrl) : kcalAuto;
      finalProt = _num(_manualProtCtrl) > 0 ? _num(_manualProtCtrl) : protAuto;
      finalCarb = _num(_manualCarbCtrl) > 0 ? _num(_manualCarbCtrl) : carbAuto;
      finalFat = _num(_manualFatCtrl) > 0 ? _num(_manualFatCtrl) : fatAuto;
      finalFib = _num(_manualFibCtrl) > 0 ? _num(_manualFibCtrl) : fibAuto;
    } else {
      finalKcal = kcalAuto;
      finalProt = protAuto;
      finalCarb = carbAuto;
      finalFat = fatAuto;
      finalFib = fibAuto;
    }

    final sp = await SharedPreferences.getInstance();
    await sp.setString('profile_sex', _sex == nutri.Sex.female ? 'female' : 'male');

    final declarativeActivity = _activityLevel ?? nutri.ActivityLevel.sedentary;
    await sp.setInt('profile_activity', declarativeActivity.index);

    await sp.setInt('profile_diet', _diet.index);
    await sp.setInt('profile_goal', _goal.index);
    await sp.setDouble('profile_age', age.toDouble());
    await sp.setDouble('profile_height', cm.toDouble());
    await sp.setDouble('profile_weight', kg);
    await sp.setInt('profile_diet_style', _dietStyle.index);

    final bodyFat = _currentBodyFat();
    if (bodyFat != null && _bodyFatRange != null) {
      await sp.setDouble('profile_body_fat_pct', bodyFat);
      await sp.setInt('profile_body_fat_range', _bodyFatRange!.index);
    } else {
      await sp.remove('profile_body_fat_pct');
      await sp.remove('profile_body_fat_range');
    }

    final targetWeight = _targetWeightKg;
    if (targetWeight != null) {
      await sp.setDouble('profile_target_weight', targetWeight);
    } else {
      await sp.remove('profile_target_weight');
    }

    await sp.setDouble('goals_kcal', finalKcal);
    await sp.setDouble('goals_prot', finalProt);
    await sp.setDouble('goals_carb', finalCarb);
    await sp.setDouble('goals_fat', finalFat);
    await sp.setDouble('goals_fiber', finalFib);
    await sp.setBool('goals_manual', _manualMode);

    await nutri.computeAndSaveTargetsFromStoredProfile();
    await CalibrationService.instance.logWeighIn(kg);

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('user_profile').upsert({
          'user_id': user.id,
          'sex': _sex == nutri.Sex.female ? 'female' : 'male',
          'age': age,
          'height_cm': cm,
          'weight_kg': kg,
          'activity_level': _activityToDb(declarativeActivity),
          'goal': _goalToDb(_goal),
          'body_fat_pct': bodyFat,
        }, onConflict: 'user_id');
      }
    } catch (e) {
      debugPrint('Erreur Supabase user_profile: $e');
    }

    // Poids cible + style de répartition macros : upsert SÉPARÉ, avec son
    // propre try/catch, pour ces 2 champs récents. Tant que les colonnes
    // target_weight_kg/diet_style n'existent pas côté Supabase (migration à
    // faire), cet appel échoue silencieusement SANS jamais faire échouer
    // l'upsert principal ci-dessus (sexe/âge/poids/objectif...), qui reste
    // dans son propre bloc protégé.
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('user_profile').upsert({
          'user_id': user.id,
          'target_weight_kg': targetWeight,
          'diet_style': _dietStyleToDb(_dietStyle),
        }, onConflict: 'user_id');
      }
    } catch (e) {
      debugPrint('Erreur Supabase user_profile (poids cible/répartition macros) — colonnes pas encore migrées ? $e');
    }

    if (!mounted) return;
    setState(() {
      _kcal = finalKcal;
      _prot = finalProt;
      _carb = finalCarb;
      _fat = finalFat;
      _fib = finalFib;
      _savedKcal = finalKcal;
      _savedProt = finalProt;
      _savedCarb = finalCarb;
      _savedFat = finalFat;
      _savedFib = finalFib;
      _dirty = false;
    });
    _refreshCharts();
    // Le nouvel objectif change les cibles micronutriments affichées dans
    // le carrousel (carte "Micronutriments en vedette") : redéclenche un
    // rebuild pour que la FutureBuilder concernée reflète _targetsFuture.
    if (mounted) setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Objectifs mis à jour · ${finalKcal.round()} kcal par jour'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshCharts();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final sp = await SharedPreferences.getInstance();

    var sexStr = sp.getString('profile_sex');
    var goalIndex = sp.getInt('profile_goal');
    var activityIndex = sp.getInt('profile_activity');
    var age = sp.getDouble('profile_age');
    var height = sp.getDouble('profile_height');
    var weight = sp.getDouble('profile_weight');
    var goalsKcal = sp.getDouble('goals_kcal');
    var goalsProt = sp.getDouble('goals_prot');
    var goalsCarb = sp.getDouble('goals_carb');
    var goalsFat = sp.getDouble('goals_fat');
    var goalsFiber = sp.getDouble('goals_fiber');
    final manualMode = sp.getBool('goals_manual') ?? false;
    var bodyFat = sp.getDouble('profile_body_fat_pct');
    var targetWeight = sp.getDouble('profile_target_weight');
    var dietStyleIndex = sp.getInt('profile_diet_style');

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final remote =
            await _client.from('user_profile').select().eq('user_id', user.id).maybeSingle();
        if (remote != null) {
          final remoteSex = remote['sex'] as String?;
          final remoteGoal = remote['goal'] as String?;
          final remoteAge = (remote['age'] as num?)?.toDouble();
          final remoteHeight = (remote['height_cm'] as num?)?.toDouble();
          final remoteWeight = (remote['weight_kg'] as num?)?.toDouble();
          final remoteBodyFat = (remote['body_fat_pct'] as num?)?.toDouble();
          if (remoteBodyFat != null && remoteBodyFat > 0) {
            bodyFat = remoteBodyFat;
            await sp.setDouble('profile_body_fat_pct', remoteBodyFat);
          }
          if (remoteSex != null) sexStr = remoteSex;
          if (remoteAge != null) age = remoteAge;
          if (remoteHeight != null) height = remoteHeight;
          if (remoteWeight != null) weight = remoteWeight;
          if (remoteGoal != null) {
            const mapGoal = <String, int>{'loss': 0, 'maintain': 1, 'gain': 2, 'loss_mild': 3, 'gain_mild': 4};
            goalIndex = mapGoal[remoteGoal] ?? goalIndex;
          }
          // activity_level distant re-hydraté ici : depuis la simplification
          // à un seul choix qualitatif (06/08/2026), c'est de nouveau une
          // valeur directe et fiable (avant : combinaison aplatie de
          // "quotidien"+"entraînements" non décomposable) — la synchroniser
          // entre appareils a donc du sens.
          final remoteActivity = remote['activity_level'] as String?;
          if (remoteActivity != null) {
            const mapActivity = <String, int>{
              'sedentary': 0, 'light': 1, 'moderate': 2,
              'intense': 3, 'very_intense': 4, 'extreme': 5,
            };
            activityIndex = mapActivity[remoteActivity] ?? activityIndex;
          }
          // Poids cible / style de répartition macros : colonnes récentes,
          // absentes tant que la migration Supabase n'a pas été faite —
          // `remote[...]` renvoie alors simplement null, sans erreur (accès
          // à une clé absente d'un Map), donc pas de repli particulier requis.
          final remoteTargetWeight = (remote['target_weight_kg'] as num?)?.toDouble();
          if (remoteTargetWeight != null && remoteTargetWeight > 0) {
            targetWeight = remoteTargetWeight;
          }
          final remoteDietStyle = remote['diet_style'] as String?;
          if (remoteDietStyle != null) {
            const mapDietStyle = <String, int>{
              'balanced': 0, 'high_carb': 1, 'high_fat': 2, 'keto': 3,
            };
            dietStyleIndex = mapDietStyle[remoteDietStyle] ?? dietStyleIndex;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement profil Supabase: $e');
    }

    if (goalsKcal == null && age != null && height != null && weight != null && sexStr != null && goalIndex != null) {
      final sexEnum = (sexStr == 'female') ? nutri.Sex.female : nutri.Sex.male;
      final goalEnum = nutri.GoalType.values[goalIndex.clamp(0, nutri.GoalType.values.length - 1)];

      // Profil tout juste créé : aucune donnée de pas/entraînement encore
      // renseignée -> repli sédentaire (PAL 1.20), cohérent avec la valeur
      // par défaut de _dailyPal.
      final profile = nutri.UserProfile(
        sex: sexEnum,
        age: age.round(),
        heightCm: height,
        weightKg: weight,
        activity: nutri.ActivityLevel.sedentary,
        goal: goalEnum,
        bodyFatPercent: (bodyFat != null && bodyFat > 0) ? bodyFat : null,
      );
      final goalsAuto = nutri.computeGoals(profile);
      goalsKcal = goalsAuto.kcal;
      goalsProt = goalsAuto.prot;
      goalsCarb = goalsAuto.carb;
      goalsFat = goalsAuto.fat;
      goalsFiber = goalsAuto.fiber;

      await sp.setDouble('goals_kcal', goalsKcal);
      await sp.setDouble('goals_prot', goalsProt);
      await sp.setDouble('goals_carb', goalsCarb);
      await sp.setDouble('goals_fat', goalsFat);
      await sp.setDouble('goals_fiber', goalsFiber);
    }

    final bodyFatRangeIdx = sp.getInt('profile_body_fat_range');

    if (!mounted) return;
    setState(() {
      _sex = (sexStr == 'female') ? nutri.Sex.female : nutri.Sex.male;

      if (activityIndex != null) {
        _activityLevel = nutri.ActivityLevel.values[activityIndex.clamp(0, nutri.ActivityLevel.values.length - 1)];
      }

      final dietIndex = sp.getInt('profile_diet');
      if (dietIndex != null) _diet = Diet.values[dietIndex.clamp(0, Diet.values.length - 1)];
      if (dietStyleIndex != null) {
        _dietStyle = nutri.DietStyle.values[dietStyleIndex.clamp(0, nutri.DietStyle.values.length - 1)];
      }
      if (targetWeight != null && targetWeight > 0) {
        _targetWeightCtrl.text =
            targetWeight == targetWeight.roundToDouble() ? targetWeight.toStringAsFixed(0) : _trimNumber(targetWeight);
      }
      if (goalIndex != null) {
        _goal = nutri.GoalType.values[goalIndex.clamp(0, nutri.GoalType.values.length - 1)];
        _goalChosen = true;
      }
      if (age != null) _ageCtrl.text = age.toStringAsFixed(0);
      if (height != null) _heightCtrl.text = height.toStringAsFixed(0);
      if (weight != null) {
        _weightCtrl.text = weight == weight.roundToDouble() ? weight.toStringAsFixed(0) : _trimNumber(weight);
      }
      if (goalsKcal != null) _kcal = goalsKcal;
      if (goalsProt != null) _prot = goalsProt;
      if (goalsCarb != null) _carb = goalsCarb;
      if (goalsFat != null) _fat = goalsFat;
      if (goalsFiber != null) _fib = goalsFiber;
      _savedKcal = _kcal;
      _savedProt = _prot;
      _savedCarb = _carb;
      _savedFat = _fat;
      _savedFib = _fib;
      _dirty = false;
      _manualMode = manualMode;

      if (bodyFat != null && bodyFat > 0 && bodyFatRangeIdx != null) {
        _bodyFatEnabled = true;
        _bodyFatRange = nutri.BodyFatRange.values[bodyFatRangeIdx.clamp(0, nutri.BodyFatRange.values.length - 1)];
      } else if (bodyFat != null && bodyFat > 0) {
        // L'index de tranche (profile_body_fat_range) n'est jamais envoyé à
        // Supabase, contrairement au % lui-même (body_fat_pct) — après une
        // réinstallation, le % revient bien du cloud mais l'index local a
        // disparu, et sans lui la tranche restait désactivée (retour d'Alex,
        // 11/08/2026 : "ma masse grasse optionnelle... disparaît"). On
        // reconstruit ici la tranche la plus proche depuis le % restauré.
        _bodyFatEnabled = true;
        _bodyFatRange = nutri.BodyFatRange.values.reduce((a, b) =>
            (a.midpointFor(_sex) - bodyFat!).abs() <= (b.midpointFor(_sex) - bodyFat).abs() ? a : b);
      }
      if (manualMode) {
        _manualKcalCtrl.text = _kcal.toStringAsFixed(0);
        _manualProtCtrl.text = _prot.toStringAsFixed(0);
        _manualCarbCtrl.text = _carb.toStringAsFixed(0);
        _manualFatCtrl.text = _fat.toStringAsFixed(0);
        _manualFibCtrl.text = _fib.toStringAsFixed(0);
      }
    });

    if (bodyFatRangeIdx == null && _bodyFatRange != null) {
      await sp.setInt('profile_body_fat_range', _bodyFatRange!.index);
    }

    _refreshCharts();
    // Déclenche un rebuild pour que les FutureBuilder (poids, totaux du
    // jour, cibles) affichent les futures fraîchement réassignées ci-dessus.
    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  UI — une seule page scrollable : carrousel de synthèse, vignettes
  //  d'entrée, évolution, sauvegarde.
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TotumColors.textPrimary,
        centerTitle: true,
        title: Image.asset('assets/logo_wordmark.png', height: 46),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Compte & Paramètres',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _kpiCarousel(),
            const SizedBox(height: 10),
            TotumDots(count: 4, index: _kpiPage),
            const SizedBox(height: 22),
            _tileGrid(context),
            const SizedBox(height: 22),
            _evolutionCarousel(),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: TotumColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _computeAndSave(),
                icon: const Icon(Icons.check_rounded),
                label: Text(_dirty ? 'Confirmer mes objectifs' : 'Objectifs enregistrés',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                icon: Icon(_manualMode ? Icons.auto_fix_high : Icons.edit_note, size: 18),
                style: TextButton.styleFrom(foregroundColor: TotumColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _manualMode = !_manualMode;
                    if (_manualMode) {
                      _manualKcalCtrl.text = _kcal.toStringAsFixed(0);
                      _manualProtCtrl.text = _prot.toStringAsFixed(0);
                      _manualCarbCtrl.text = _carb.toStringAsFixed(0);
                      _manualFatCtrl.text = _fat.toStringAsFixed(0);
                      _manualFibCtrl.text = _fib.toStringAsFixed(0);
                    }
                  });
                },
                label: Text(_manualMode ? 'Revenir au calcul automatique' : 'Personnaliser mes objectifs'),
              ),
            ),
            if (_manualMode) ...[
              const SizedBox(height: 12),
              _manualGoalsCard(),
            ],
            const SizedBox(height: 20),
            const Text(
              'Le détail complet (vitamines, minéraux, acides gras) se calcule automatiquement dans l\'onglet Bilan.',
              style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Carrousel KPI ────────────────────────────────────────────────────

  Widget _kpiCarousel() {
    return FutureBuilder<DayTotals>(
      future: _dayTotalsFuture,
      builder: (context, snap) {
        final today = snap.data ?? DayTotals.empty;
        return SizedBox(
          height: 220,
          child: PageView(
            controller: _kpiPageCtrl,
            onPageChanged: (i) => setState(() => _kpiPage = i),
            children: [
              _kpiRemainingCard(today),
              _kpiMacroRingsCard(today),
              _kpiMacroPlateCard(today),
              _kpiMicronutrientsCard(today),
            ],
          ),
        );
      },
    );
  }

  /// Petit en-tête centré "AUJOURD'HUI" — utilisé en haut des cartes 1 et 2
  /// du carrousel (les seules à ne pas déjà porter l'info dans leur propre
  /// titre, contrairement aux cartes 3/4 : "Ton assiette aujourd'hui",
  /// "Micronutriments en vedette").
  Widget _todayEyebrow() {
    return const Text('AUJOURD\'HUI',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: TotumColors.textMuted));
  }

  Widget _legendIconRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: TotumColors.accent),
          const SizedBox(width: 7),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: TotumColors.textSecondary))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
        ],
      ),
    );
  }

  /// Carte 1 — la première chose vue en ouvrant l'app : façon MyFitnessPal,
  /// Reste = Objectif − Aliments (pas de ligne Exercice, décision Alex : le
  /// niveau d'activité choisi inclut déjà le sport dans le calcul de
  /// l'objectif, cf. Priorité 12/13 — une ligne Exercice ici recréerait
  /// exactement le double comptage qu'on a corrigé). Traitement visuel un
  /// cran au-dessus des autres cartes (contour accentué, ring plus grand,
  /// pictogrammes) puisque c'est la vignette la plus vue de tout l'onglet.
  Widget _kpiRemainingCard(DayTotals today) {
    final remaining = _kcal - today.kcal;
    final isOver = _kcal > 0 && today.kcal > _kcal;
    final fraction = _kcal > 0 ? (today.kcal / _kcal).clamp(0.0, 1.0) : 0.0;
    final ringColor = isOver ? TotumColors.negative : TotumColors.accent;
    return TotumCard(
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _todayEyebrow(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 116,
                height: 116,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 38,
                        sections: [
                          PieChartSectionData(
                            value: fraction > 0 ? fraction : 0.0001,
                            color: ringColor,
                            title: '',
                            radius: 15,
                          ),
                          PieChartSectionData(
                            value: (1 - fraction) > 0 ? (1 - fraction) : 0.0001,
                            color: TotumColors.outlineStrong,
                            title: '',
                            radius: 15,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isOver ? '+${(-remaining).round()}' : remaining.round().toString(),
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isOver ? TotumColors.negative : TotumColors.textPrimary)),
                        Text(isOver ? 'kcal dépassé' : 'kcal restant', textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9.5, color: TotumColors.textSecondary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendIconRow(Icons.flag_rounded, 'Objectif de base', '${_kcal.round()}'),
                    _legendIconRow(Icons.restaurant_rounded, 'Aliments', '${today.kcal.round()}'),
                    if (_calibration.hasEnoughData) ...[
                      const SizedBox(height: 6),
                      const Text('Affiné selon tes résultats réels',
                          style: TextStyle(fontSize: 10, color: TotumColors.accent, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroRing(String label, IconData icon, double consumed, double target) {
    final fraction = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final diff = target - consumed;
    final isOver = target > 0 && diff < 0;
    final ringColor = isOver ? TotumColors.negative : TotumColors.accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 23,
                  sections: [
                    PieChartSectionData(
                        value: fraction > 0 ? fraction : 0.0001, color: ringColor, title: '', radius: 11),
                    PieChartSectionData(
                        value: (1 - fraction) > 0 ? (1 - fraction) : 0.0001,
                        color: TotumColors.outlineStrong,
                        title: '',
                        radius: 11),
                  ],
                ),
              ),
              Text(consumed.round().toString(),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isOver ? TotumColors.negative : TotumColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: TotumColors.textSecondary),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
          ],
        ),
        Text(
          isOver ? '+${(-diff).round()} g dépassé' : '${diff.clamp(0.0, double.infinity).round()} g restants',
          style: TextStyle(
              fontSize: 10,
              color: isOver ? TotumColors.negative : TotumColors.textMuted,
              fontWeight: isOver ? FontWeight.w700 : FontWeight.normal),
        ),
      ],
    );
  }

  /// Carte 2 — façon Cronometer : 3 rings glucides/lipides/protéines,
  /// consommé aujourd'hui vs objectif. Même traitement visuel que la carte 1
  /// (contour accentué) — les deux premières cartes du carrousel sont les
  /// plus consultées, elles doivent avoir la même cohérence graphique.
  Widget _kpiMacroRingsCard(DayTotals today) {
    return TotumCard(
      accentBorder: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _todayEyebrow(),
          const SizedBox(height: 4),
          const Text('Macronutriments', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroRing('Glucides', Icons.grain, today.carb, _carb),
              _macroRing('Lipides', Icons.opacity, today.fat, _fat),
              _macroRing('Protéines', Icons.fitness_center, today.prot, _prot),
            ],
          ),
        ],
      ),
    );
  }

  /// Carte 3 — répartition des macros "en assiette" (camembert des kcal).
  /// Montre la répartition réellement consommée aujourd'hui si l'utilisateur
  /// a déjà loggé un aliment, sinon la répartition cible (libellé explicite
  /// pour ne jamais laisser d'ambiguïté sur ce qui est affiché).
  Widget _kpiMacroPlateCard(DayTotals today) {
    final useToday = today.hasData;
    final carbKcal = (useToday ? today.carb : _carb) * 4.0;
    final fatKcal = (useToday ? today.fat : _fat) * 9.0;
    final protKcal = (useToday ? today.prot : _prot) * 4.0;
    final total = carbKcal + fatKcal + protKcal;
    final rows = [
      ('Glucides', carbKcal, TotumProgress.stop100),
      ('Lipides', fatKcal, TotumProgress.stop75),
      ('Protéines', protKcal, TotumProgress.stop50),
    ];
    return TotumCard(
      accentBorder: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: total > 0
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                      sections: [
                        for (final r in rows)
                          if (r.$2 > 0)
                            PieChartSectionData(
                              value: r.$2,
                              color: r.$3,
                              radius: 48,
                              title: '${(r.$2 / total * 100).round()}%',
                              titleStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                      ],
                    ),
                  )
                : const Center(
                    child: Icon(Icons.pie_chart_outline, color: TotumColors.textMuted, size: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(useToday ? 'Ton assiette aujourd\'hui' : 'Ton assiette (objectif)',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                const SizedBox(height: 10),
                for (final r in rows) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(width: 9, height: 9, decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 11.5, color: TotumColors.textSecondary))),
                        Text(total > 0 ? '${(r.$2 / total * 100).round()}%' : '—',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte 4 — micronutriments "en vedette" : les 10 nutriments jugés
  /// prioritaires (mêmes que "Priorité du jour" dans Conseils), statut du
  /// jour uniquement — le détail complet reste dans Bilan/Conseils.
  Widget _kpiMicronutrientsCard(DayTotals today) {
    return TotumCard(
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Micronutriments en vedette',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
          const SizedBox(height: 12),
          FutureBuilder<nutri.NutritionTargets>(
            future: _targetsFuture,
            builder: (context, snap) {
              final targets = snap.data;
              if (targets == null) {
                return const SizedBox(
                    height: 130, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              return GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 4,
                childAspectRatio: 0.72,
                children: [
                  for (final key in kPriorityNutrientKeys)
                    _microChip(key, today, targets),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _microChip(String key, DayTotals today, nutri.NutritionTargets targets) {
    final target = priorityNutrientTarget(key, targets) ?? 0;
    final consumed = priorityNutrientConsumed(key, today.micros);
    final fraction = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final label = kPriorityNutrientLabel[key] ?? key;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 1,
                  centerSpaceRadius: 11,
                  sections: [
                    PieChartSectionData(
                        value: fraction > 0 ? fraction : 0.0001,
                        color: TotumProgress.forFraction(fraction),
                        title: '',
                        radius: 6),
                    PieChartSectionData(
                        value: (1 - fraction) > 0 ? (1 - fraction) : 0.0001,
                        color: TotumColors.outline,
                        title: '',
                        radius: 6),
                  ],
                ),
              ),
              Text('${(fraction * 100).round()}',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8.5, color: TotumColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── Grille de vignettes « + » ────────────────────────────────────────

  Widget _tileGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TotumInputTile(
                icon: Icons.flag_rounded,
                label: 'Objectif',
                value: _goalChosen ? _goalOption(_goal).title : null,
                onTap: () => _openGoalSheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ValueListenableBuilder<UnitSystem>(
                valueListenable: AppSettings.unitSystem,
                builder: (context, _, __) => TotumInputTile(
                  icon: Icons.straighten,
                  label: 'Mesures',
                  value: _measuresSummary,
                  onTap: () => _openMeasuresSheet(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TotumInputTile(
                icon: Icons.directions_run,
                label: 'Niveau d\'activité',
                value: _activitySummary,
                onTap: () => _openActivitySheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TotumInputTile(
                icon: Icons.restaurant,
                label: 'Régime alimentaire',
                value: _dietLabel(_diet),
                onTap: () => _openDietSheet(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TotumInputTile(
                icon: Icons.pie_chart_outline,
                label: 'Répartition des macros',
                value: _dietStyle.title,
                onTap: () => _openDietStyleSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Feuilles d'entrée — minimalistes, un seul geste pour choisir ─────

  /// [pinned] — contenu qui reste TOUJOURS visible en haut de la fiche,
  /// même en scrollant (le bandeau d'impact) : sur "Mesures" et
  /// "Entraînements", le contenu dépasse la hauteur visible, et un bandeau
  /// simplement placé en tête du contenu scrollable disparaissait dès qu'on
  /// descendait — corrigé en le sortant de la zone scrollable.
  Future<void> _openSheet(
    BuildContext context, {
    required String title,
    Widget Function(BuildContext, StateSetter)? pinned,
    required Widget Function(BuildContext, StateSetter) builder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TotumColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.86),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: TotumColors.outlineStrong, borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
                      const SizedBox(height: 12),
                      if (pinned != null) pinned(ctx, setSheetState),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: builder(ctx, setSheetState),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetDoneButton(BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: TotumColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text('Terminé', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  /// [icon] (Material, monochrome accent) prime sur [emoji] quand fourni —
  /// aligné sur le style pictogramme épuré des grandes apps de référence.
  Widget _pickRow({
    String? emoji,
    IconData? icon,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TotumCard(
        onTap: onTap,
        accentBorder: selected,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? TotumColors.accentSoft : TotumColors.page,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: selected ? TotumColors.accent : TotumColors.textSecondary),
              )
            else
              Text(emoji ?? '', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: TotumColors.accent),
          ],
        ),
      ),
    );
  }

  /// Bandeau d'impact — visible en direct DANS la fiche pendant qu'on
  /// ajuste un réglage (objectif, mesures, quotidien, entraînements) :
  /// pas besoin de fermer pour voir l'effet sur l'objectif calorique.
  /// [beforeKcal] est capturé à l'ouverture de la fiche, avant tout réglage.
  /// [afterKcal] permet un aperçu HYPOTHÉTIQUE (ex. "et si j'ajoutais cette
  /// activité ?") sans attendre qu'elle soit réellement commise — sinon
  /// _kcal (déjà appliqué) est utilisé par défaut.
  Widget _impactBanner(double beforeKcal, {double? afterKcal}) {
    final after = afterKcal ?? _kcal;
    final diff = after - beforeKcal;
    final changed = diff.abs() >= 1;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: changed ? TotumColors.accentSoft : TotumColors.page,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: changed ? TotumColors.accentBorder : TotumColors.outline),
      ),
      child: Row(
        children: [
          Icon(changed ? Icons.bolt : Icons.check_circle_outline,
              size: 18, color: changed ? TotumColors.accent : TotumColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              changed
                  ? 'Impact sur ton objectif : ${beforeKcal.round()} → ${after.round()} kcal '
                      '(${diff >= 0 ? '+' : ''}${diff.round()})'
                  : 'Objectif actuel : ${after.round()} kcal',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: changed ? TotumColors.accent : TotumColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGoalSheet(BuildContext context) {
    final kcalAtOpen = _kcal;
    _openSheet(
      context,
      title: 'Ton objectif',
      pinned: (ctx, setSheetState) => _impactBanner(kcalAtOpen),
      builder: (ctx, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final o in _kGoalOptions) _goalPickRow(ctx, o, setSheetState),
            const SizedBox(height: 4),
            _sheetDoneButton(ctx),
          ],
        );
      },
    );
  }

  /// Ligne de sélection d'un objectif — 2 zones cliquables, comme la banque
  /// d'exercices : le corps de la ligne choisit l'objectif, le bouton
  /// "En savoir plus" ouvre le descriptif complet (conseils du coach).
  Widget _goalPickRow(BuildContext sheetCtx, _GoalOption o, StateSetter setSheetState) {
    final selected = _goalChosen && _goal == o.goal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TotumCard(
        accentBorder: selected,
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _goal = o.goal;
                    _goalChosen = true;
                  });
                  setSheetState(() {});
                  _recomputePreview();
                },
                child: Row(
                  children: [
                    Icon(o.icon, size: 24, color: TotumColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                          Text(_technicalLabelFor(o.goal), style: const TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.check_circle, color: TotumColors.accent, size: 20),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => _openGoalDetailSheet(sheetCtx, o),
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.info_outline, size: 20, color: TotumColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Descriptif complet d'un objectif (conseils du coach) — une vraie
  /// valeur ajoutée conservée spécifiquement ici, au même titre que les
  /// fiches nutriments de l'onglet Bilan.
  void _openGoalDetailSheet(BuildContext context, _GoalOption o) {
    _openSheet(context, title: o.title, builder: (ctx, _) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(_technicalLabelFor(o.goal), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.accent)),
          ),
          const SizedBox(height: 12),
          Text(o.description, style: const TextStyle(fontSize: 14.5, color: TotumColors.textPrimary, height: 1.4)),
          const SizedBox(height: 18),
          const Text('À retenir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
          const SizedBox(height: 8),
          ...o.tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: TotumColors.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, color: TotumColors.textPrimary, height: 1.35))),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          TotumCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 18, color: TotumColors.accent),
                    SizedBox(width: 8),
                    Text('Conseil du coach', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(o.coach, style: const TextStyle(fontSize: 13, color: TotumColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _openDietSheet(BuildContext context) {
    // Icônes Material (charte graphique) — même langage visuel que la
    // banque d'exercices, plus d'emoji multicolore.
    const options = [
      (Diet.omnivore, Icons.set_meal_outlined, 'Omnivore'),
      (Diet.vegetarien, Icons.eco_outlined, 'Végétarien'),
      (Diet.vegetalien, Icons.grass_outlined, 'Végétalien'),
    ];
    _openSheet(context, title: 'Régime alimentaire', builder: (ctx, setSheetState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            _pickRow(
              icon: o.$2,
              title: o.$3,
              selected: _diet == o.$1,
              onTap: () {
                setState(() => _diet = o.$1);
                setSheetState(() {});
              },
            ),
          const SizedBox(height: 4),
          _sheetDoneButton(ctx),
        ],
      );
    });
  }

  void _openMeasuresSheet(BuildContext context) {
    final kcalAtOpen = _kcal;
    _openSheet(
      context,
      title: 'Tes mesures',
      pinned: (ctx, setSheetState) => _impactBanner(kcalAtOpen),
      builder: (ctx, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wc, size: 18, color: TotumColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<nutri.Sex>(
                    segments: const [
                      ButtonSegment(value: nutri.Sex.male, label: Text('Homme')),
                      ButtonSegment(value: nutri.Sex.female, label: Text('Femme')),
                    ],
                    selected: {_sex},
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: TotumColors.accent,
                      selectedForegroundColor: Colors.white,
                    ),
                    onSelectionChanged: (s) {
                      setState(() => _sex = s.first);
                      setSheetState(() {});
                      _recomputePreview();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _numField(
                      label: 'Âge (ans)',
                      icon: Icons.cake_outlined,
                      controller: _ageCtrl,
                      onChanged: (_) { setSheetState((){}); _recomputePreview(); })),
              const SizedBox(width: 12),
              Expanded(
                  child: _UnitAwareNumField(
                      labelMetric: 'Taille (cm)',
                      labelImperial: 'Taille (in)',
                      icon: Icons.height,
                      isWeight: false,
                      metricController: _heightCtrl,
                      onChanged: (_) { setSheetState((){}); _recomputePreview(); })),
            ]),
            const SizedBox(height: 12),
            _UnitAwareNumField(
                labelMetric: 'Poids (kg)',
                labelImperial: 'Poids (lb)',
                icon: Icons.monitor_weight_outlined,
                isWeight: true,
                metricController: _weightCtrl,
                onChanged: (_) { setSheetState((){}); _recomputePreview(); }),
            const SizedBox(height: 8),
            // Préconisation de pesée — mêmes conditions que celles
            // documentées par MacroFactor (audit du 09/08/2026) : la
            // fiabilité de la tendance de poids (et donc de la calibration
            // adaptative) dépend directement de la régularité des conditions
            // de pesée.
            const Text(
              'Pèse-toi si possible tous les jours, dans les mêmes conditions à chaque fois — idéalement le matin à jeun, au lever.',
              style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),
            _UnitAwareNumField(
                labelMetric: 'Poids cible (kg) — optionnel',
                labelImperial: 'Poids cible (lb) — optionnel',
                icon: Icons.flag_outlined,
                isWeight: true,
                metricController: _targetWeightCtrl,
                onChanged: (_) { setSheetState((){}); _recomputePreview(); }),
            const SizedBox(height: 4),
            const Text(
              'Utilisé uniquement pour l\'objectif Maintien : une fois proche de ta cible, tes calories suivent ta dépense réelle ; si tu t\'en éloignes, un léger ajustement automatique t\'y ramène doucement.',
              style: TextStyle(fontSize: 11, color: TotumColors.textMuted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.pie_chart_outline, size: 18, color: TotumColors.textSecondary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Masse grasse — optionnel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
                ),
                Switch(
                  value: _bodyFatEnabled,
                  activeThumbColor: TotumColors.accent,
                  onChanged: (v) {
                    setState(() => _bodyFatEnabled = v);
                    setSheetState(() {});
                    _recomputePreview();
                  },
                ),
              ],
            ),
            if (_bodyFatEnabled) ...[
              const SizedBox(height: 10),
              const Text('Choisis la plage la plus proche de ta silhouette actuelle.',
                  style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
              const SizedBox(height: 8),
              // Retour d'Alex (11/08/2026) : une tranche déjà choisie reste
              // sélectionnée — on ne peut plus la désélectionner en retapant
              // dessus. Pour ne plus renseigner de masse grasse, il faut
              // désactiver le bouton ci-dessus (seul point de sortie).
              for (final r in nutri.BodyFatRange.values)
                _pickRow(
                  icon: Icons.pie_chart_outline,
                  title: r.labelFor(_sex),
                  subtitle: r.tierFor(_sex),
                  selected: _bodyFatRange == r,
                  onTap: () {
                    setState(() => _bodyFatRange = r);
                    setSheetState(() {});
                    _recomputePreview();
                  },
                ),
            ],
            const SizedBox(height: 8),
            _sheetDoneButton(ctx),
          ],
        );
      },
    );
  }

  /// Fiche "Niveau d'activité" — UN SEUL choix qualitatif (quotidien + sport
  /// confondus), qui remplace les deux anciens réglages "Ton quotidien"
  /// (pas) et "Tes entraînements" (banque MET). Décision prise après audit
  /// (06/08/2026, sources et raisonnement complets dans docs/TODO.md) :
  /// un compteur de pas ne capture pas l'intensité d'une séance, et
  /// demander à l'utilisateur de estimer ses pas "hors entraînement" pour
  /// éviter un double comptage s'est révélé une vraie source de confusion
  /// en usage. Cette approche à choix unique est celle vérifiée chez
  /// MacroFactor : un point de départ qualitatif suffit, la calibration
  /// adaptative (déjà branchée, voir computeCalibratedGoals) corrige le
  /// reste vers la réalité de l'utilisateur en 2-3 semaines.
  void _openActivitySheet(BuildContext context) {
    final kcalAtOpen = _kcal;
    _openSheet(
      context,
      title: 'Ton niveau d\'activité',
      pinned: (ctx, setSheetState) => _impactBanner(kcalAtOpen),
      builder: (ctx, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisis la description la plus proche de TA semaine type — quotidien '
              'ET sport confondus, l\'un ou l\'autre suffit à te situer dans un palier.',
              style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final level in nutri.ActivityLevel.values)
              _pickRow(
                icon: Icons.directions_run,
                title: level.title,
                subtitle: level.description,
                selected: _activityLevel == level,
                onTap: () {
                  // Retour d'Alex (11/08/2026) : un niveau déjà choisi reste
                  // sélectionné — on ne peut plus le désélectionner en
                  // retapant dessus, on ne fait que basculer vers un autre.
                  setState(() => _activityLevel = level);
                  setSheetState(() {});
                  _recomputePreview();
                },
              ),
            const SizedBox(height: 4),
            _sheetDoneButton(ctx),
          ],
        );
      },
    );
  }

  /// Répartition des calories non-protéiques entre lipides/glucides — façon
  /// MacroFactor (Balanced/High-Carb/High-Fat/Keto, audit du 09/08/2026). À
  /// ne pas confondre avec "Régime alimentaire" (omnivore/pescatarien/
  /// végane, orthogonal, n'affecte que la source d'oméga-3 et le rappel
  /// B12) : ici, seule la répartition lipides/glucides change — calories et
  /// protéines restent identiques.
  void _openDietStyleSheet(BuildContext context) {
    final kcalAtOpen = _kcal;
    _openSheet(
      context,
      title: 'Répartition des macros',
      pinned: (ctx, setSheetState) => _impactBanner(kcalAtOpen),
      builder: (ctx, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ne change ni tes calories ni tes protéines — seulement comment le reste '
              'se répartit entre lipides et glucides.',
              style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final style in nutri.DietStyle.values)
              _pickRow(
                icon: Icons.pie_chart_outline,
                title: style.title,
                subtitle: style.description,
                selected: _dietStyle == style,
                onTap: () {
                  setState(() => _dietStyle = style);
                  setSheetState(() {});
                  _recomputePreview();
                },
              ),
            const SizedBox(height: 4),
            _sheetDoneButton(ctx),
          ],
        );
      },
    );
  }

  Widget _numField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: kIsWeb ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 19, color: TotumColors.textSecondary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      onChanged: onChanged,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Nombre invalide' : null,
    );
  }

  // ─── Ton évolution — carrousel horizontal avec points ─────────────────

  Widget _evolutionCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ton évolution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
        const SizedBox(height: 10),
        _evolutionTapCard(
          title: 'Poids',
          subtitle: '60 derniers jours',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeightTrendScreen())),
          chart: FutureBuilder<List<WeighIn>>(
            future: _weightHistoryFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              return WeightTrendChart(data: snap.data ?? const <WeighIn>[]);
            },
          ),
        ),
        const SizedBox(height: 14),
        _evolutionTapCard(
          title: 'Dépense énergétique',
          subtitle: 'estimation adaptative',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpenditureScreen())),
          chart: FutureBuilder<List<ExpenditurePoint>>(
            future: _expenditureHistoryFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              return ExpenditureChart(data: snap.data ?? const <ExpenditurePoint>[]);
            },
          ),
        ),
      ],
    );
  }

  Widget _evolutionTapCard({
    required String title,
    required String subtitle,
    required Widget chart,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(TotumRadius.card),
      onTap: onTap,
      child: TotumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                      const SizedBox(width: 6),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: TotumColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: TotumColors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            chart,
          ],
        ),
      ),
    );
  }

  // ─── Mode manuel ────────────────────────────────────────────────────

  Widget _manualGoalsCard() {
    return TotumCard(
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mes objectifs personnalisés',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: TotumColors.accent)),
          const SizedBox(height: 4),
          const Text('Ces valeurs remplacent le calcul automatique.', style: TextStyle(fontSize: 12, color: TotumColors.textSecondary)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(label: 'Énergie (kcal)', controller: _manualKcalCtrl, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: _numField(label: 'Protéines (g)', controller: _manualProtCtrl, onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _numField(label: 'Glucides (g)', controller: _manualCarbCtrl, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: _numField(label: 'Lipides (g)', controller: _manualFatCtrl, onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 10),
          _numField(label: 'Fibres (g)', controller: _manualFibCtrl, onChanged: (_) => setState(() {})),
          Builder(builder: (context) {
            final warning = _checkManualCoherence();
            if (warning == null) return const SizedBox.shrink();
            final color = warning.tooHigh ? const Color(0xFFEF6C00) : const Color(0xFF1E88E5);
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.4))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(warning.tooHigh ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(warning.text, style: TextStyle(fontSize: 12, color: color, height: 1.4))),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: TotumColors.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Appliquer mes objectifs'),
              onPressed: () => _computeAndSave(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ poids/taille sensible au système d'unités (Priorité 48, Réglages →
/// Unités) : `metricController` reste TOUJOURS la source de vérité en
/// kg/cm (lue par _num()/_buildCurrentProfile/_computeAndSave, inchangée),
/// ce widget ne fait que projeter un affichage/une saisie dans l'unité
/// choisie et reconvertit vers le kg/cm de stockage à chaque frappe — aucun
/// risque sur les calculs, la sauvegarde ou la synchronisation Supabase.
class _UnitAwareNumField extends StatefulWidget {
  final String labelMetric;
  final String labelImperial;
  final TextEditingController metricController;
  final bool isWeight; // true = poids (kg/lb), false = taille (cm/in)
  final IconData? icon;
  final void Function(String)? onChanged; // reçoit la valeur métrique (texte)
  const _UnitAwareNumField({
    required this.labelMetric,
    required this.labelImperial,
    required this.metricController,
    required this.isWeight,
    this.icon,
    this.onChanged,
  });

  @override
  State<_UnitAwareNumField> createState() => _UnitAwareNumFieldState();
}

class _UnitAwareNumFieldState extends State<_UnitAwareNumField> {
  final _displayCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromMetric();
    AppSettings.unitSystem.addListener(_onUnitSystemChanged);
  }

  void _onUnitSystemChanged() {
    if (mounted) setState(_syncFromMetric);
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;

  void _syncFromMetric() {
    final metricValue = _parse(widget.metricController);
    if (metricValue <= 0) {
      _displayCtrl.text = '';
      return;
    }
    final system = AppSettings.unitSystem.value;
    final displayed =
        widget.isWeight ? Units.displayWeight(metricValue, system) : Units.displayHeight(metricValue, system);
    _displayCtrl.text =
        displayed == displayed.roundToDouble() ? displayed.toStringAsFixed(0) : displayed.toStringAsFixed(1);
  }

  void _onDisplayChanged(String v) {
    final system = AppSettings.unitSystem.value;
    final displayed = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    final metric = widget.isWeight ? Units.weightToKg(displayed, system) : Units.heightToCm(displayed, system);
    widget.metricController.text = metric == metric.roundToDouble() ? metric.toStringAsFixed(0) : metric.toStringAsFixed(2);
    widget.onChanged?.call(widget.metricController.text);
  }

  @override
  void dispose() {
    AppSettings.unitSystem.removeListener(_onUnitSystemChanged);
    _displayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = AppSettings.unitSystem.value;
    return TextFormField(
      controller: _displayCtrl,
      keyboardType: kIsWeb ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: system == UnitSystem.imperial ? widget.labelImperial : widget.labelMetric,
        prefixIcon: widget.icon != null ? Icon(widget.icon, size: 19, color: TotumColors.textSecondary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      onChanged: _onDisplayChanged,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Nombre invalide' : null,
    );
  }
}
