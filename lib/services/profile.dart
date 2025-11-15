// lib/services/profile.dart

import 'package:shared_preferences/shared_preferences.dart';

/// ====== ENUMS / MODÈLES =====================================================

enum Sex { male, female }

/// Ordre gardé pour compatibilité avec les index déjà stockés:
/// 0: sédentaire, 1: léger, 2: modéré, 3: soutenu, 4: très intense
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

/// Objectif calorique global (même logique que chez toi)
enum GoalType { lose, maintain, gain }

class UserProfile {
  final Sex sex;
  final int age;           // années
  final double heightCm;   // cm
  final double weightKg;   // kg
  final ActivityLevel activity;
  final GoalType goal;

  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
  });

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    GoalType? goal,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
    );
  }
}

class Goals {
  final double kcal;
  final double prot;  // g
  final double carb;  // g
  final double fat;   // g
  final double fiber; // g

  const Goals({
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
  });
}

/// Cibles complètes (macro + essentiels + à surveiller + minéraux + vitamines)
class NutritionTargets {
  // Macro-cibles
  final Goals goals;

  // Acides gras & “à surveiller”
  final double sat;     // g - 12% E
  final double o9;      // g - Ω9 (oléique) 20% E
  final double o6;      // g - Ω6 (LA) 4% E
  final double o3;      // g - Ω3 (ALA) 1% E
  final double epa;     // g - 0.25
  final double dha;     // g - 0.25
  final double sugars;  // g - 10% E
  final double salt;    // g - 5

  // Minéraux (mg sauf µg indiqués)
  final double caMg;  // 950 mg
  final double cuMg;  // 1.9 mg H / 1.5 mg F
  final double feMg;  // 11 mg
  final double iUg;   // 150 µg
  final double mgMg;  // 380 mg H / 300 mg F
  final double mnMg;  // 8 mg
  final double pMg;   // 550 mg
  final double kMg;   // 3500 mg
  final double seUg;  // 70 µg
  final double naMg;  // 1500 mg
  final double znMg;  // 14 mg H / 11 mg F

  // Vitamines
  final double vitA_Ug;   // 750 µg H / 650 µg F
  final double vitD_Ug;   // 15 µg
  final double vitE_Mg;   // 10 mg H / 9 mg F
  final double vitK_Ug;   // 79 µg
  final double vitC_Mg;   // 110 mg
  final double b1_Mg;     // 1.6 mg
  final double b2_Mg;     // 1.6 mg
  final double b3_Mg;     // 10 mg
  final double b5_Mg;     // 6 mg H / 5 mg F
  final double b6_Mg;     // 1.7 mg H / 1.6 mg F
  final double b9_Ug;     // 330 µg
  final double b12_Ug;    // 2.5 µg

  const NutritionTargets({
    required this.goals,
    required this.sat,
    required this.o9,
    required this.o6,
    required this.o3,
    required this.epa,
    required this.dha,
    required this.sugars,
    required this.salt,
    required this.caMg,
    required this.cuMg,
    required this.feMg,
    required this.iUg,
    required this.mgMg,
    required this.mnMg,
    required this.pMg,
    required this.kMg,
    required this.seUg,
    required this.naMg,
    required this.znMg,
    required this.vitA_Ug,
    required this.vitD_Ug,
    required this.vitE_Mg,
    required this.vitK_Ug,
    required this.vitC_Mg,
    required this.b1_Mg,
    required this.b2_Mg,
    required this.b3_Mg,
    required this.b5_Mg,
    required this.b6_Mg,
    required this.b9_Ug,
    required this.b12_Ug,
  });
}

/// ====== CALCULS =============================================================

double _activityFactor(ActivityLevel a) => switch (a) {
      ActivityLevel.sedentary => 1.20,
      ActivityLevel.light => 1.375,
      ActivityLevel.moderate => 1.55,
      ActivityLevel.active => 1.725,
      ActivityLevel.veryActive => 1.90,
    };

double _proteinPerKg(ActivityLevel a) => switch (a) {
      ActivityLevel.sedentary => 1.0,
      ActivityLevel.light => 1.2,
      ActivityLevel.moderate => 1.6,
      ActivityLevel.active => 2.0,
      ActivityLevel.veryActive => 2.5,
    };

double _roundTo(double v, double step) => (v / step).round() * step;

/// Mifflin–St Jeor + activité + objectif (lose -15 %, gain +15 %) + répartitions
Goals computeGoals(UserProfile p) {
  final sexAdj = (p.sex == Sex.male) ? 5 : -161;
  final bmr = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + sexAdj;

  double kcal = bmr * _activityFactor(p.activity);
  kcal = switch (p.goal) {
    GoalType.lose => kcal * 0.85,
    GoalType.maintain => kcal,
    GoalType.gain => kcal * 1.15,
  };

  final prot = _proteinPerKg(p.activity) * p.weightKg; // g
  final fat = (0.35 * kcal) / 9.0; // g
  final carb = (0.55 * kcal) / 4.0; // g
  const fiber = 30.0; // g

  return Goals(
    kcal: _roundTo(kcal, 10),
    prot: _roundTo(prot, 1),
    carb: _roundTo(carb, 1),
    fat: _roundTo(fat, 1),
    fiber: fiber,
  );
}

/// Cibles complémentaires (Ω9/Ω6/ALA, saturés, sucres, sel, minéraux, vitamines)
NutritionTargets computeNutritionTargets(UserProfile p) {
  final g = computeGoals(p);
  final kcal = g.kcal;

  double pctToG(double pct, int kcalPerG) => (pct * kcal) / 100.0 / kcalPerG;

  final sat = _roundTo(pctToG(12, 9), 0.1); // 12 % E /9
  final o9 = _roundTo(pctToG(20, 9), 0.1); // Ω9 20 % E /9
  final o6 = _roundTo(pctToG(4, 9), 0.1); // Ω6 4 % E /9
  final o3 = _roundTo(pctToG(1, 9), 0.1); // Ω3 (ALA) 1 % E /9
  final sugars = _roundTo(pctToG(10, 4), 0.5); // Sucres 10 % E /4
  const epa = 0.25;
  const dha = 0.25;
  const salt = 5.0;

  final isF = (p.sex == Sex.female);

  // Minéraux (mg/µg)
  final caMg = 950.0;
  final cuMg = isF ? 1.5 : 1.9;
  final feMg = 11.0;
  final iUg = 150.0;
  final mgMg = isF ? 300.0 : 380.0;
  final mnMg = 8.0;
  final pMg = 550.0;
  final kMg = 3500.0;
  final seUg = 70.0;
  final naMg = 1500.0;
  final znMg = isF ? 11.0 : 14.0;

  // Vitamines
  final vitA_Ug = isF ? 650.0 : 750.0;
  const vitD_Ug = 15.0;
  final vitE_Mg = isF ? 9.0 : 10.0;
  const vitK_Ug = 79.0;
  const vitC_Mg = 110.0;
  const b1_Mg = 1.6;
  const b2_Mg = 1.6;
  const b3_Mg = 10.0;
  final b5_Mg = isF ? 5.0 : 6.0;
  final b6_Mg = isF ? 1.6 : 1.7;
  const b9_Ug = 330.0;
  const b12_Ug = 2.5;

  return NutritionTargets(
    goals: g,
    sat: sat,
    o9: o9,
    o6: o6,
    o3: o3,
    epa: epa,
    dha: dha,
    sugars: sugars,
    salt: salt,
    caMg: caMg,
    cuMg: cuMg,
    feMg: feMg,
    iUg: iUg,
    mgMg: mgMg,
    mnMg: mnMg,
    pMg: pMg,
    kMg: kMg,
    seUg: seUg,
    naMg: naMg,
    znMg: znMg,
    vitA_Ug: vitA_Ug,
    vitD_Ug: vitD_Ug,
    vitE_Mg: vitE_Mg,
    vitK_Ug: vitK_Ug,
    vitC_Mg: vitC_Mg,
    b1_Mg: b1_Mg,
    b2_Mg: b2_Mg,
    b3_Mg: b3_Mg,
    b5_Mg: b5_Mg,
    b6_Mg: b6_Mg,
    b9_Ug: b9_Ug,
    b12_Ug: b12_Ug,
  );
}

/// ====== PERSISTANCE =========================================================
/// Clés conservées pour compatibilité avec ton existant.

class ProfileStore {
  ProfileStore._();
  static final instance = ProfileStore._();

  Future<UserProfile> load() async {
    final sp = await SharedPreferences.getInstance();

    final sexStr = sp.getString('profile_sex'); // 'female' | 'male'
    final sex = (sexStr == 'female') ? Sex.female : Sex.male;

    // stockés en double chez toi → on supporte les deux
    final ageD = sp.getDouble('profile_age') ?? 30.0;
    final height = sp.getDouble('profile_height') ?? 175.0;
    final weight = sp.getDouble('profile_weight') ?? 70.0;

    // activity & goal stockés en int index (compatibles avec ActivityLevel.values / GoalType.values)
    final actIdx = sp.getInt('profile_activity') ?? 0;
    final goalIdx = sp.getInt('profile_goal') ?? 1;

    final activity = ActivityLevel.values[(actIdx.clamp(0, ActivityLevel.values.length - 1))];
    final goal = GoalType.values[(goalIdx.clamp(0, GoalType.values.length - 1))];

    return UserProfile(
      sex: sex,
      age: ageD.round(),
      heightCm: height,
      weightKg: weight,
      activity: activity,
      goal: goal,
    );
  }

  Future<void> save(UserProfile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('profile_sex', p.sex == Sex.female ? 'female' : 'male');
    await sp.setDouble('profile_age', p.age.toDouble());
    await sp.setDouble('profile_height', p.heightCm);
    await sp.setDouble('profile_weight', p.weightKg);
    await sp.setInt('profile_activity', p.activity.index);
    await sp.setInt('profile_goal', p.goal.index);
  }
}

/// Sauvegarde centralisée des objectifs (pour UI: fiche aliments, bilan, donuts…)
Future<void> saveNutritionTargets(NutritionTargets t) async {
  final sp = await SharedPreferences.getInstance();

  // Goals
  await sp.setDouble('goals_kcal', t.goals.kcal);
  await sp.setDouble('goals_prot', t.goals.prot);
  await sp.setDouble('goals_carb', t.goals.carb);
  await sp.setDouble('goals_fat', t.goals.fat);
  await sp.setDouble('goals_fiber', t.goals.fiber);

  // Fats & watch
  await sp.setDouble('goals_sat', t.sat);
  await sp.setDouble('goals_o9', t.o9);
  await sp.setDouble('goals_o6', t.o6);
  await sp.setDouble('goals_o3', t.o3);
  await sp.setDouble('goals_epa', t.epa);
  await sp.setDouble('goals_dha', t.dha);
  await sp.setDouble('goals_sugars', t.sugars);
  await sp.setDouble('goals_salt', t.salt);

  // Minerals
  await sp.setDouble('goals_ca_mg', t.caMg);
  await sp.setDouble('goals_cu_mg', t.cuMg);
  await sp.setDouble('goals_fe_mg', t.feMg);
  await sp.setDouble('goals_i_ug', t.iUg);
  await sp.setDouble('goals_mg_mg', t.mgMg);
  await sp.setDouble('goals_mn_mg', t.mnMg);
  await sp.setDouble('goals_p_mg', t.pMg);
  await sp.setDouble('goals_k_mg', t.kMg);
  await sp.setDouble('goals_se_ug', t.seUg);
  await sp.setDouble('goals_na_mg', t.naMg);
  await sp.setDouble('goals_zn_mg', t.znMg);

  // Vitamins
  await sp.setDouble('goals_vita_ug', t.vitA_Ug);
  await sp.setDouble('goals_vitd_ug', t.vitD_Ug);
  await sp.setDouble('goals_vite_mg', t.vitE_Mg);
  await sp.setDouble('goals_vitk_ug', t.vitK_Ug);
  await sp.setDouble('goals_vitc_mg', t.vitC_Mg);
  await sp.setDouble('goals_b1_mg', t.b1_Mg);
  await sp.setDouble('goals_b2_mg', t.b2_Mg);
  await sp.setDouble('goals_b3_mg', t.b3_Mg);
  await sp.setDouble('goals_b5_mg', t.b5_Mg);
  await sp.setDouble('goals_b6_mg', t.b6_Mg);
  await sp.setDouble('goals_b9_ug', t.b9_Ug);
  await sp.setDouble('goals_b12_ug', t.b12_Ug);
}

/// Utilitaire: (re)calcule depuis le profil chargé et persiste tout en une fois.
Future<NutritionTargets> computeAndSaveTargetsFromStoredProfile() async {
  final profile = await ProfileStore.instance.load();
  final targets = computeNutritionTargets(profile);
  await saveNutritionTargets(targets);
  return targets;
}
