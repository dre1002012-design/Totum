// lib/services/profile.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import 'calibration_service.dart';

/// ====== ENUMS / MODÈLES =====================================================

enum Sex { male, female }

/// Ordre gardé pour compatibilité avec les index déjà stockés:
/// 0: sédentaire, 1: léger, 2: modéré, 3: soutenu, 4: très intense,
/// 5: extrême (NOUVEAU — ajouté en fin de liste, ne casse aucun index existant)
///
/// Un SEUL palier auto-évalué de façon holistique (quotidien + sport
/// confondus), plutôt que deux réglages séparés (pas d'un côté, liste
/// d'entraînements MET de l'autre) sommés entre eux. Choix délibéré après
/// audit (06/08/2026) : la dépense d'une séance de sport dépend de son
/// INTENSITÉ (course ≠ marche ≠ musculation à nombre de pas égal), ce qu'un
/// compteur de pas ne peut pas capturer, quelle que soit sa granularité ;
/// et demander à l'utilisateur d'estimer ses pas "hors entraînement" pour
/// éviter un double comptage s'est révélé une source d'erreur/confusion
/// bien réelle en usage (retour direct d'Alex, cas concret : séance de
/// course faisant grimper le compteur de pas du jour, en plus de la
/// contribution de la séance elle-même déclarée séparément).
///
/// Cette approche — un seul niveau d'activité qualitatif comme point de
/// départ, RIEN d'autre — est aussi celle vérifiée (recherche web, sources
/// dans docs/TODO.md) chez MacroFactor : leurs propres données confirment
/// explicitement que le comptage de pas "ne s'additionne jamais aux
/// calories jour par jour". Le point de départ n'a pas besoin d'être
/// parfait : c'est la calibration adaptative (CalibrationService, poids
/// réel vs calories réelles) qui corrige vers la réalité de l'utilisateur
/// en 2-3 semaines — un point de départ qualitatif raisonnable suffit,
/// une granularité artificielle en amont n'apporte aucune précision
/// supplémentaire, seulement un risque d'erreur de saisie.
enum ActivityLevel { sedentary, light, moderate, active, veryActive, extreme }

extension ActivityLevelX on ActivityLevel {
  String titleFor(AppLocalizations l10n) => switch (this) {
        ActivityLevel.sedentary => l10n.activityLevelSedentaryTitle,
        ActivityLevel.light => l10n.activityLevelLightTitle,
        ActivityLevel.moderate => l10n.activityLevelModerateTitle,
        ActivityLevel.active => l10n.activityLevelActiveTitle,
        ActivityLevel.veryActive => l10n.activityLevelVeryActiveTitle,
        ActivityLevel.extreme => l10n.activityLevelExtremeTitle,
      };

  /// Décrit TOUJOURS quotidien et sport ensemble (jamais l'un sans l'autre)
  /// — l'un OU l'autre peut suffire à se situer dans ce palier.
  String descriptionFor(AppLocalizations l10n) => switch (this) {
        ActivityLevel.sedentary => l10n.activityLevelSedentaryDesc,
        ActivityLevel.light => l10n.activityLevelLightDesc,
        ActivityLevel.moderate => l10n.activityLevelModerateDesc,
        ActivityLevel.active => l10n.activityLevelActiveDesc,
        ActivityLevel.veryActive => l10n.activityLevelVeryActiveDesc,
        ActivityLevel.extreme => l10n.activityLevelExtremeDesc,
      };
}

enum GoalType {
  lose,       // Perte agressive   — Déficit ~20%
  maintain,   // Maintien          — TDEE × 1.00
  gain,       // Prise de masse    — Surplus ~10%
  loseMild,   // Perte modérée     — Déficit ~12%
  gainMild,   // Prise modérée     — Surplus ~5%
}

/// Plages de masse grasse (façon MacroFactor) — remplace la saisie libre en
/// %, plus fiable pour la plupart des gens qui n'ont qu'une estimation
/// visuelle. 8 tranches, calées sur les catégories de référence de l'ACE
/// (American Council on Exercise) — la classification la plus largement
/// citée pour situer un % de masse grasse (essentiel / athlète / fitness /
/// moyen / élevé) — puis subdivisées pour garder assez de précision sur le
/// calcul (Cunningham utilise directement ce %). Hommes et femmes ont des
/// plages différentes : à % égal, la signification physiologique n'est pas
/// la même (repères ACE ~10 points plus hauts chez la femme).
enum BodyFatRange { r1, r2, r3, r4, r5, r6, r7, r8 }

extension BodyFatRangeX on BodyFatRange {
  /// Valeur représentative (centre de la tranche) injectée dans le calcul.
  double midpointFor(Sex sex) {
    if (sex == Sex.male) {
      return switch (this) {
        BodyFatRange.r1 => 4.0,   // 2-5 %   — essentiel
        BodyFatRange.r2 => 8.0,   // 6-9 %   — athlète (très sec)
        BodyFatRange.r3 => 12.0,  // 10-13 % — athlète
        BodyFatRange.r4 => 16.0,  // 14-17 % — fitness
        BodyFatRange.r5 => 20.0,  // 18-21 % — moyen
        BodyFatRange.r6 => 23.0,  // 22-24 % — moyen
        BodyFatRange.r7 => 27.0,  // 25-29 % — élevé
        BodyFatRange.r8 => 33.0,  // 30 %+   — élevé
      };
    }
    return switch (this) {
      BodyFatRange.r1 => 12.0,  // 10-13 % — essentiel
      BodyFatRange.r2 => 16.0,  // 14-17 % — athlète (très sec)
      BodyFatRange.r3 => 19.0,  // 18-20 % — athlète
      BodyFatRange.r4 => 23.0,  // 21-24 % — fitness
      BodyFatRange.r5 => 27.0,  // 25-28 % — moyen
      BodyFatRange.r6 => 30.0,  // 29-31 % — moyen
      BodyFatRange.r7 => 34.0,  // 32-36 % — élevé
      BodyFatRange.r8 => 40.0,  // 37 %+   — élevé
    };
  }

  String labelFor(Sex sex) {
    if (sex == Sex.male) {
      return switch (this) {
        BodyFatRange.r1 => '2 – 5 %',
        BodyFatRange.r2 => '6 – 9 %',
        BodyFatRange.r3 => '10 – 13 %',
        BodyFatRange.r4 => '14 – 17 %',
        BodyFatRange.r5 => '18 – 21 %',
        BodyFatRange.r6 => '22 – 24 %',
        BodyFatRange.r7 => '25 – 29 %',
        BodyFatRange.r8 => '30 % et plus',
      };
    }
    return switch (this) {
      BodyFatRange.r1 => '10 – 13 %',
      BodyFatRange.r2 => '14 – 17 %',
      BodyFatRange.r3 => '18 – 20 %',
      BodyFatRange.r4 => '21 – 24 %',
      BodyFatRange.r5 => '25 – 28 %',
      BodyFatRange.r6 => '29 – 31 %',
      BodyFatRange.r7 => '32 – 36 %',
      BodyFatRange.r8 => '37 % et plus',
    };
  }

  /// Repère qualitatif ACE affiché à côté de la plage — aide à se situer
  /// sans avoir à connaître son % exact.
  String tierFor(Sex sex, AppLocalizations l10n) => switch (this) {
        BodyFatRange.r1 => l10n.bodyFatTierEssential,
        BodyFatRange.r2 || BodyFatRange.r3 => l10n.bodyFatTierAthlete,
        BodyFatRange.r4 => l10n.bodyFatTierFitness,
        BodyFatRange.r5 || BodyFatRange.r6 => l10n.bodyFatTierAverage,
        BodyFatRange.r7 || BodyFatRange.r8 => l10n.bodyFatTierHigh,
      };
}

/// Reconstruit le palier ActivityLevel le plus proche d'un PAL continu —
/// utilisé uniquement pour retrouver un palier cohérent (protéines,
/// ajustements) à partir du PAL calibré (continu) que produit la
/// calibration adaptative. Le choix direct de l'utilisateur (palier
/// ActivityLevel) reste la source de vérité tant qu'aucune calibration
/// n'est encore disponible.
ActivityLevel nearestActivityLevel(double pal) {
  if (pal < 1.275) return ActivityLevel.sedentary;
  if (pal < 1.415) return ActivityLevel.light;
  if (pal < 1.55) return ActivityLevel.moderate;
  if (pal < 1.70) return ActivityLevel.active;
  if (pal < 1.84) return ActivityLevel.veryActive;
  return ActivityLevel.extreme;
}

/// Style de répartition des calories non-protéiques entre lipides et
/// glucides — même ordre de calcul que MacroFactor (Calories → Protéines →
/// répartition du solde), mais des proportions recalibrées sur l'AMDR
/// (Institute of Medicine, plancher/plafond lipides 20-35% des calories
/// totales) et la zone associée à la mortalité la plus basse dans la cohorte
/// PURE (Dehghan et al. 2017, The Lancet, 18 pays/>135 000 participants),
/// PAS une copie du ratio ~50/50 de MacroFactor (celui-ci pousse
/// régulièrement les lipides au-delà du plafond AMDR — constaté et signalé
/// par Alex). N'affecte JAMAIS les calories totales ni les protéines (fixées
/// avant, sur la masse maigre) — uniquement comment le solde se répartit.
/// Priorité 19 (10/08/2026).
enum DietStyle { balanced, highCarb, highFat, keto }

extension DietStyleX on DietStyle {
  String titleFor(AppLocalizations l10n) => switch (this) {
        DietStyle.balanced => l10n.dietStyleBalancedTitle,
        DietStyle.highCarb => l10n.dietStyleHighCarbTitle,
        DietStyle.highFat => l10n.dietStyleHighFatTitle,
        DietStyle.keto => l10n.dietStyleKetoTitle,
      };

  String descriptionFor(AppLocalizations l10n) => switch (this) {
        DietStyle.balanced => l10n.dietStyleBalancedDesc,
        DietStyle.highCarb => l10n.dietStyleHighCarbDesc,
        DietStyle.highFat => l10n.dietStyleHighFatDesc,
        DietStyle.keto => l10n.dietStyleKetoDesc,
      };
}

class UserProfile {
  final Sex sex;
  final int age;           // années
  final double heightCm;   // cm
  final double weightKg;   // kg
  final ActivityLevel activity; // choix direct de l'utilisateur, source de vérité
  final GoalType goal;
  final double? bodyFatPercent; // optionnel — % masse grasse si connu
  final double? targetWeightKg; // optionnel — active le Maintien dynamique
  final DietStyle dietStyle;

  // PAL continu produit UNIQUEMENT par la calibration adaptative
  // (computeCalibratedTargets) une fois assez de données réelles
  // disponibles (poids + calories loguées) — null tant qu'aucune
  // calibration n'existe, auquel cas le calcul retombe sur le palier fixe
  // _activityFactor(activity) choisi par l'utilisateur.
  final double? activityPalOverride;

  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    this.bodyFatPercent,
    this.targetWeightKg,
    this.dietStyle = DietStyle.balanced,
    this.activityPalOverride,
  });

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    GoalType? goal,
    double? bodyFatPercent,
    bool clearBodyFat = false,
    double? targetWeightKg,
    bool clearTargetWeight = false,
    DietStyle? dietStyle,
    double? activityPalOverride,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      bodyFatPercent:
          clearBodyFat ? null : (bodyFatPercent ?? this.bodyFatPercent),
      targetWeightKg: clearTargetWeight ? null : (targetWeightKg ?? this.targetWeightKg),
      dietStyle: dietStyle ?? this.dietStyle,
      activityPalOverride: activityPalOverride ?? this.activityPalOverride,
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

class NutritionTargets {
  final Goals goals;

  // Acides gras & "à surveiller"
  final double sat;
  final double o9;
  final double o6;
  final double o3;
  final double epa;
  final double dha;
  final double sugars;
  final double salt;

  // Minéraux
  final double caMg;
  final double cuMg;
  final double feMg;
  final double iUg;
  final double mgMg;
  final double mnMg;
  final double pMg;
  final double kMg;
  final double seUg;
  final double naMg;
  final double znMg;

  // Vitamines
  final double vitAUg;
  final double vitBetacarUg;
  final double vitDUg;
  final double vitEMg;
  final double vitKUg;
  final double vitCMg;
  final double b1Mg;
  final double b2Mg;
  final double b3Mg;
  final double b5Mg;
  final double b6Mg;
  final double b9Ug;
  final double b12Ug;

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
    required this.vitAUg,
    required this.vitBetacarUg,
    required this.vitDUg,
    required this.vitEMg,
    required this.vitKUg,
    required this.vitCMg,
    required this.b1Mg,
    required this.b2Mg,
    required this.b3Mg,
    required this.b5Mg,
    required this.b6Mg,
    required this.b9Ug,
    required this.b12Ug,
  });
}

/// ====== CALCULS SCIENTIFIQUES RECALIBRÉS ====================================

/// COEFFICIENTS PAL RÉALISTES (Ajustés sur les mesures par Eau Doublement Marquée)
/// Évite la surestimation massive des besoins vs Garmin / Montres sport.
double _activityFactor(ActivityLevel a) => switch (a) {
      ActivityLevel.sedentary => 1.20, // Bureau, pas de sport, < 4000 pas/j
      ActivityLevel.light => 1.35, // Entraînement 1-3x/semaine ou 5-7k pas/j
      ActivityLevel.moderate => 1.48, // Entraînement 3-5x/semaine ou 8-10k pas/j
      ActivityLevel.active => 1.62, // Entraînement quotidien / travail debout
      ActivityLevel.veryActive => 1.78, // Double séance / travail physique lourd
      ActivityLevel.extreme => 1.90, // Métier physique lourd + 5-6 séances/sem combinés
    };

bool _isHighActivity(ActivityLevel a) =>
    a == ActivityLevel.active || a == ActivityLevel.veryActive || a == ActivityLevel.extreme;

/// PAL réellement utilisé pour le calcul : le PAL continu (Profil 3.0,
/// pas + entraînements) quand il est fourni par l'appelant, sinon le palier
/// fixe déclaratif. `p.activity` doit déjà être le palier le plus proche du
/// PAL continu (via nearestActivityLevel) — les 2 restent donc toujours
/// cohérents pour les ajustements par palier (protéines, micronutriments).
double _effectivePal(UserProfile p) => p.activityPalOverride ?? _activityFactor(p.activity);

double _roundTo(double v, double step) => (v / step).round() * step;

/// BMR — Mifflin-St Jeor
double _bmrMifflin(UserProfile p) {
  final sexAdj = (p.sex == Sex.male) ? 5 : -161;
  return 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + sexAdj;
}

/// BMR — Cunningham (référence métabolique sur masse maigre, formule
/// utilisée par MacroFactor comme point de départ initial — audit
/// scientifique du 09/08/2026, tasks/026-08-09_Audit scientifique de Macro
/// factor.md). Constantes exactes : BMR = 500 + 22×FFM(kg). Historiquement
/// remplacée ici par Katch-McArdle (370 + 21.6×FFM, formule proche mais aux
/// constantes différentes) — basculée sur Cunningham pour une parité
/// littérale avec MacroFactor, comme demandé par Alex.
double _bmrCunningham(double leanMassKg) {
  return 500 + (22 * leanMassKg);
}

/// Calcul de la Masse Maigre (LBM) estimée ou réelle
double _getLeanMassKg(UserProfile p) {
  final bf = p.bodyFatPercent;
  // >= 2 (et non > 4) : le plancher physiologique réel (ACE) est ~2% chez
  // l'homme, et le point milieu de la plage "Essentiel" homme vaut
  // EXACTEMENT 4.0 — avec l'ancien seuil ">4" strict, cette plage précise
  // repassait silencieusement sur Mifflin au lieu de Cunningham (bug
  // confirmé : deux plages adjacentes utilisaient 2 formules différentes,
  // donnant un saut incohérent entre elles).
  if (bf != null && bf >= 2 && bf < 60) {
    return p.weightKg * (1 - (bf / 100.0));
  }
  // Estimation Boer si le % masse grasse n'est pas fourni
  if (p.sex == Sex.male) {
    return (0.407 * p.weightKg) + (0.267 * p.heightCm) - 19.2;
  } else {
    return (0.252 * p.weightKg) + (0.473 * p.heightCm) - 48.3;
  }
}

/// Sélectionne le BMR le plus exact selon les données disponibles
double _computeBmr(UserProfile p) {
  final bf = p.bodyFatPercent;
  // >= 2 (et non > 4) : le plancher physiologique réel (ACE) est ~2% chez
  // l'homme, et le point milieu de la plage "Essentiel" homme vaut
  // EXACTEMENT 4.0 — avec l'ancien seuil ">4" strict, cette plage précise
  // repassait silencieusement sur Mifflin au lieu de Cunningham (bug
  // confirmé : deux plages adjacentes utilisaient 2 formules différentes,
  // donnant un saut incohérent entre elles).
  if (bf != null && bf >= 2 && bf < 60) {
    final lbm = p.weightKg * (1 - bf / 100.0);
    return _bmrCunningham(lbm);
  }
  return _bmrMifflin(p);
}

/// Version publique de [_computeBmr] — le BMR ne dépend jamais de l'activité
/// (sexe/âge/taille/poids/%masse grasse uniquement). Utilisé côté écran pour
/// le partage repos/mouvement du donut, et par [computeCalibratedTargets]
/// pour convertir un TDEE calibré en PAL équivalent.
double computeBmr(UserProfile p) {
  return _computeBmr(p);
}

/// Composition corporelle déjà "lean" (tiers ACE Essentiel/Athlète — mêmes
/// seuils que [BodyFatRange], sexes différenciés). Utilisé pour moduler le
/// déficit : la littérature sur la perte de gras chez les sportifs entraînés
/// est explicite là-dessus — "the lower the % body fat of the athlete, the
/// more conservative should the energy deficit be" (Iraki et al. 2021,
/// Nutrients — revue sur la phase de perte de gras chez les athlètes
/// entraînés en résistance). Un déficit agressif chez une personne déjà
/// sèche expose davantage à la perte de masse musculaire.
bool _isLeanBodyFat(Sex sex, double bodyFatPercent) =>
    sex == Sex.male ? bodyFatPercent < 14.0 : bodyFatPercent < 21.0;

/// Vitesse cible en fraction du poids corporel par semaine (négatif = perte)
/// — remplace l'ancien multiplicateur %TDEE fixe. MacroFactor exprime ses
/// objectifs en %poids/semaine plutôt qu'en %TDEE figé : ainsi, le même
/// objectif "Perte de gras" correspond à un déficit qui diminue
/// automatiquement à mesure que le poids baisse, plutôt qu'un pourcentage
/// toujours identique (audit du 09/08/2026). Les valeurs elles-mêmes restent
/// dans les fourchettes déjà validées cette session : 0,5-1,0 %/semaine pour
/// la perte (Iraki et al. 2021, Nutrients — bas de fourchette préféré),
/// 0,25-0,5 %/semaine pour la prise (littérature bulking, Iraki, Aragon &
/// Schoenfeld 2019) — reformulées en %/semaine, aucune nouvelle valeur
/// inventée. `maintain` est géré à part par [_goalEnergyAdjustmentKcal]
/// (Maintien dynamique).
double _goalRateBwPerWeek(GoalType goal, {bool conservative = false}) {
  return switch (goal) {
    GoalType.lose => conservative ? -0.007 : -0.010, // -0,7 %/-1,0 %/sem
    GoalType.loseMild => conservative ? -0.0035 : -0.005, // -0,35 %/-0,5 %/sem
    GoalType.maintain => 0.0,
    GoalType.gainMild => 0.0025, // +0,25 %/sem
    GoalType.gain => 0.004, // +0,4 %/sem
  };
}

bool _isConservativeGoal(int age, {Sex? sex, double? bodyFatPercent}) {
  final isSenior = age >= 60;
  final isLean = sex != null && bodyFatPercent != null && _isLeanBodyFat(sex, bodyFatPercent);
  return isSenior || isLean;
}

/// Version publique de [_goalRateBwPerWeek] (avec la logique senior/lean déjà
/// appliquée) — pour l'affichage du "rythme visé" côté écran.
double goalRateBwPerWeekFor(GoalType goal, int age, {Sex? sex, double? bodyFatPercent}) =>
    _goalRateBwPerWeek(goal, conservative: _isConservativeGoal(age, sex: sex, bodyFatPercent: bodyFatPercent));

/// Densité énergétique effective (kcal/kg) utilisée pour convertir une
/// vitesse cible (%poids/semaine) en écart calorique quotidien — JAMAIS une
/// constante fixe de 7700 kcal/kg. Principe documenté par MacroFactor : la
/// composition d'une variation de poids (graisse vs eau/glycogène/masse
/// maigre) dépend de la VITESSE du changement — plus le rythme est rapide,
/// plus une part importante est probablement de l'eau/glycogène (densité
/// énergétique plus faible) ; plus il est lent, plus la variation est
/// probablement majoritairement de la graisse (densité plus proche de
/// ~9440 kcal/kg de tissu adipeux pur). Implémentation propre à TOTUM — les
/// constantes internes exactes de MacroFactor ne sont pas publiques (l'audit
/// du 09/08/2026 le confirme explicitement) — interpolation linéaire entre
/// deux ancrages plausibles au vu de la littérature, pas une reproduction de
/// leur algorithme propriétaire.
double _effectiveEnergyDensity(double absRateBwPerWeek) {
  const slowDensity = 8400.0; // rythme lent (≤0,25 %/sem) : proche graisse pure
  const fastDensity = 7000.0; // rythme rapide (≥1,2 %/sem) : mélange eau/glycogène/masse maigre
  const slowThreshold = 0.0025;
  const fastThreshold = 0.012;
  if (absRateBwPerWeek <= slowThreshold) return slowDensity;
  if (absRateBwPerWeek >= fastThreshold) return fastDensity;
  final t = (absRateBwPerWeek - slowThreshold) / (fastThreshold - slowThreshold);
  return slowDensity + (fastDensity - slowDensity) * t;
}

/// Écart calorique quotidien (positif = surplus, négatif = déficit) à
/// ajouter au TDEE pour viser la vitesse cible de l'objectif — remplace
/// l'ancien `_goalMultiplier` multiplicatif. Pour `maintain`, implémente le
/// "Maintien dynamique" façon MacroFactor : sans poids cible renseigné,
/// comportement inchangé (0, donc kcal = TDEE) ; avec un poids cible, une
/// zone morte de ±0,7 kg autour de la cible (dans la zone → 0), au-delà →
/// petit déficit/surplus de 0,15 %/semaine pour ramener doucement vers la
/// cible.
double _goalEnergyAdjustmentKcal(
  GoalType goal,
  double weightKg,
  int age, {
  Sex? sex,
  double? bodyFatPercent,
  double? targetWeightKg,
}) {
  if (goal == GoalType.maintain) {
    if (targetWeightKg == null) return 0.0;
    final diff = weightKg - targetWeightKg; // > 0 = au-dessus de la cible
    if (diff.abs() <= 0.7) return 0.0;
    final rate = diff > 0 ? -0.0015 : 0.0015; // ±0,15 %/semaine
    final density = _effectiveEnergyDensity(rate.abs());
    return (rate * weightKg * density) / 7.0;
  }

  final conservative = _isConservativeGoal(age, sex: sex, bodyFatPercent: bodyFatPercent);
  final rate = _goalRateBwPerWeek(goal, conservative: conservative);
  if (rate == 0.0) return 0.0;
  final density = _effectiveEnergyDensity(rate.abs());
  return (rate * weightKg * density) / 7.0;
}

/// Plancher calorique absolu de sécurité — jusqu'ici ABSENT du calcul (audit
/// du 17/08/2026) : un profil de petit gabarit + objectif "lose" pouvait
/// atterrir sous les 1000 kcal/jour sans aucun garde-fou, un territoire
/// associé au RED-S (Mountjoy et al., consensus CIO 2014/2018 : dérèglement
/// menstruel, ralentissement thyroïdien, perte de densité osseuse) —
/// exactement le risque d'effet yoyo/dérèglement endocrinien qu'Alex a
/// demandé à éliminer. Double plancher, on garde le plus élevé des deux :
/// - un minimum absolu par sexe, valeurs cliniques usuelles (Academy of
///   Nutrition and Dietetics / NIH Body Weight Planner) : 1200 kcal femme,
///   1500 kcal homme ;
/// - 90% du BMR, pour ne jamais descendre sous le métabolisme de repos même
///   chez un profil déjà atypique par rapport à ces seuils génériques.
/// Exposée publiquement pour que l'écran Profil affiche le même seuil en
/// mode manuel (avertissement, pas un blocage — voir profile_screen.dart).
double minSafeKcalFor(Sex sex, double bmr) {
  final sexFloor = sex == Sex.female ? 1200.0 : 1500.0;
  final bmrFloor = bmr * 0.9;
  return sexFloor > bmrFloor ? sexFloor : bmrFloor;
}

/// CALCUL CENTRAL DES MACRONUTRIMENTS (100% PHYSIOLOGIQUE)
Goals computeGoals(UserProfile p) {
  // Palier le plus proche (persistance/ajustements par palier) — voir
  // _effectivePal pour le PAL réellement utilisé dans le calcul.
  final effActivity = p.activity;

  // 1. Calcul du BMR et TDEE
  final bmr = _computeBmr(p);
  final tdee = bmr * _effectivePal(p);

  // 2. Calories Cibles — écart additif (%poids/semaine → kcal), pas un
  // multiplicateur du TDEE (voir _goalEnergyAdjustmentKcal).
  final rawKcal = tdee +
      _goalEnergyAdjustmentKcal(p.goal, p.weightKg, p.age,
          sex: p.sex, bodyFatPercent: p.bodyFatPercent, targetWeightKg: p.targetWeightKg);

  final kcalFloor = minSafeKcalFor(p.sex, bmr);
  final kcal = rawKcal < kcalFloor ? kcalFloor : rawKcal;

  // 3. Masse Maigre (LBM) pour calcul précis des besoins structurels
  final lbmKg = _getLeanMassKg(p);

  // 4. Protéines (Basé sur la Masse Maigre pour préserver la masse musculaire)
  // Recommandation scientifique : 1.8g à 2.7g / kg de LBM selon l'intensité et le déficit
  double protPerKgLbm = switch (effActivity) {
    ActivityLevel.sedentary => 1.6,
    ActivityLevel.light => 1.8,
    ActivityLevel.moderate => 2.1,
    ActivityLevel.active => 2.4,
    ActivityLevel.veryActive => 2.6,
    ActivityLevel.extreme => 2.8,
  };

  // Ajustement protéines selon l'objectif (Déficit = besoin protéique accru)
  if (p.goal == GoalType.lose) protPerKgLbm += 0.3;
  if (p.goal == GoalType.loseMild) protPerKgLbm += 0.15;
  if (p.age >= 50) protPerKgLbm += 0.2; // Compensation de la résistance anabolique

  final prot = (protPerKgLbm * lbmKg).clamp(p.weightKg * 1.0, p.weightKg * 2.5);
  final protKcal = prot * 4.0;

  // 5-6. Lipides/Glucides — MacroFactor documente explicitement l'ordre
  // Calories → Protéines → répartition du SOLDE entre lipides et glucides
  // selon le style choisi (Balanced/High-Carb/High-Fat/Keto), pas des % fixes
  // des calories totales (audit du 09/08/2026). MAIS le style de MacroFactor
  // (Balanced = ~50/50 kcal non-protéiques) n'est pas repris tel quel : pour
  // un profil-type, cela pousse les lipides à ~37% des calories totales,
  // au-dessus du plafond AMDR (Institute of Medicine — révision 2024
  // toujours en vigueur : lipides 20-35%, glucides 45-65%, protéines
  // 10-35% de l'énergie totale) — constaté concrètement par Alex (jusqu'à
  // 130g+ de lipides/jour). Recalibré (Priorité 19) sur l'AMDR ET sur la
  // zone associée à la mortalité totale la plus basse dans l'étude de
  // cohorte PURE (18 pays, >135 000 participants, Dehghan et al. 2017,
  // The Lancet : ~30-35% lipides / ~50% glucides / ~15-20% protéines) —
  // ni un excès de lipides, ni le dogme "low-fat" que cette même étude
  // invalide. Plancher ET plafond lipidiques désormais tous deux appliqués
  // (20% et 35% des calories totales — rôles hormonaux/vitamines
  // liposolubles pour le plancher ; AMDR pour le plafond) sur tous les
  // styles SAUF Keto, qui vise par construction des lipides élevés — voir
  // sa mise en garde dédiée dans DietStyleX.description.
  final remainingKcal = (kcal - protKcal).clamp(0.0, double.infinity);
  final minFatGrams = (kcal * 0.20) / 9.0;
  final maxFatGrams = (kcal * 0.35) / 9.0;

  double fat, carb;
  if (p.dietStyle == DietStyle.keto) {
    // Glucides fixés bas (marge fibres/flexibilité nutritionnelle), le reste
    // va aux lipides — logique documentée par MacroFactor, pas un simple ratio.
    const ketoCarbGrams = 30.0;
    carb = ketoCarbGrams;
    const carbKcalKeto = ketoCarbGrams * 4.0;
    fat = ((remainingKcal - carbKcalKeto) / 9.0).clamp(minFatGrams, double.infinity);
  } else {
    // Fractions recalibrées pour viser, sur un profil-type, des totaux
    // proches de : Équilibré ≈ 30F/45C, Riche en glucides ≈ 21F/54C
    // (plancher AMDR côté lipides, avantage performance/endurance des
    // apports glucidiques élevés), Riche en lipides ≈ 35F/40C (plafond AMDR,
    // jamais au-delà — le clamp ci-dessous le garantit quel que soit le %
    // de protéines individuel).
    final fatFraction = switch (p.dietStyle) {
      DietStyle.balanced => 0.40,
      DietStyle.highCarb => 0.28,
      DietStyle.highFat => 0.48,
      DietStyle.keto => 0.0, // traité ci-dessus
    };
    fat = ((remainingKcal * fatFraction) / 9.0).clamp(minFatGrams, maxFatGrams);
    final fatKcalActual = fat * 9.0;
    final carbKcal = (remainingKcal - fatKcalActual).clamp(0.0, double.infinity);
    carb = (carbKcal / 4.0).clamp(30.0, double.infinity);
  }

  // 7. Fibres (ANSES : 14g / 1000 kcal, minimum 25g, max 45g)
  final fiber = ((kcal / 1000.0) * 14.0).clamp(25.0, 45.0);

  return Goals(
    kcal: _roundTo(kcal, 10),
    prot: _roundTo(prot, 1),
    carb: _roundTo(carb, 1),
    fat: _roundTo(fat, 1),
    fiber: _roundTo(fiber, 1),
  );
}

/// Cibles complémentaires (Invariable, optimisé ANSES)
NutritionTargets computeNutritionTargets(UserProfile p) {
  final g = computeGoals(p);
  final kcal = g.kcal;

  double pctToG(double pct, int kcalPerG) => (pct * kcal) / 100.0 / kcalPerG;

  // AG essentiels vs total lipides — architecture v3, corrigée après un
  // test réel (15g graines de chia + 80g huile d'olive) qui a révélé que
  // la v2 ("oméga-9 = tout le reste du budget") donnait une cible d'environ
  // 76% du budget lipides total — MATHÉMATIQUEMENT cohérente (la somme
  // tombait juste), mais PRATIQUEMENT irréalisable : l'huile d'olive n'est
  // qu'à ~73% d'acide oléique pur, jamais 100%. Pour atteindre une cible
  // aussi haute, il fallait ~80g d'huile — qui à elle seule dépasse déjà le
  // budget lipides total, avant même tout autre aliment de la journée.
  //
  // v3 : l'oméga-9 vise 35% du budget lipides total — proche des repères
  // usuels (les oméga-9 représentent naturellement environ la moitié des
  // lipides d'une alimentation type ; on reste volontairement en dessous
  // pour garantir une cible atteignable via une quantité réaliste d'huile
  // d'olive/avocat/oléagineux, sans écraser le reste du budget).
  // - ALA (oméga-3) et LA (oméga-6) restent des planchers ANSES ABSOLUS
  //   (1% et 4% des calories) — non négociables, vraiment essentiels.
  // - Les AG saturés restent un PLAFOND séparé à surveiller, pas une part
  //   du budget à "remplir".
  final fatTotal = g.fat;
  final o6 = _roundTo(pctToG(4, 9), 0.1);  // LA — plancher ANSES fixe
  final o3 = _roundTo(pctToG(1, 9), 0.1);  // ALA — plancher ANSES fixe
  final o9 = _roundTo(fatTotal * 0.35, 0.1); // oméga-9 — cible réaliste, atteignable
  final sat = _roundTo(pctToG(10, 9), 0.1); // plafond indépendant, à surveiller
  final sugars = _roundTo(pctToG(10, 4), 0.5);
  const salt = 5.0;

  // Palier le plus proche du PAL continu — cohérent avec computeGoals.
  final effActivity = p.activity;

  final isActive = effActivity == ActivityLevel.moderate ||
      effActivity == ActivityLevel.active ||
      effActivity == ActivityLevel.veryActive ||
      effActivity == ActivityLevel.extreme;
  final epa = isActive ? 0.50 : 0.25;
  final dha = isActive ? 0.50 : 0.25;

  final isF = (p.sex == Sex.female);
  final isYoungWoman = isF && p.age < 50;
  final isOlderWoman = isF && p.age >= 50;
  final isHighActivity = _isHighActivity(effActivity);
  final isSeniorPlus = p.age >= 65;

  // Priorité 71 (audit micronutriments du 17/08/2026) : ne relevait le
  // plancher calcique qu'aux femmes 50+ (post-ménopause), alors que
  // `isSeniorPlus` (65+, déjà calculé ci-dessous pour vitamine E/sélénium)
  // s'applique tout autant aux hommes — la perte de densité osseuse liée à
  // l'âge touche aussi les hommes, plus tardivement. Un homme senior
  // recevait jusqu'ici 950mg au lieu des 1200mg recommandés.
  final caMg = (isOlderWoman || isSeniorPlus) ? 1200.0 : 950.0;
  final cuMg = isF ? 1.5 : 1.9;
  final feMg = isYoungWoman ? 16.0 : 11.0;
  const iUg = 150.0;

  var mgMg = isF ? 300.0 : 380.0;
  if (isHighActivity) mgMg *= 1.10;

  const mnMg = 3.0; // Cible EFSA (Adequate Intake) — 8,0 était la LIMITE DE SÉCURITÉ, pas la cible
  const pMg = 550.0;

  var kMg = 3500.0;
  if (isHighActivity) kMg *= 1.10;

  var seUg = 70.0;
  if (isSeniorPlus) seUg *= 1.10;

  const naMg = 1500.0;

  var znMg = isF ? 11.0 : 14.0;
  if (isHighActivity) znMg *= 1.15;

  final vitaUg = isF ? 650.0 : 750.0;
  final vitbetacarUg = isF ? 2600.0 : 3000.0;
  final vitdUg = p.age >= 50 ? 20.0 : 15.0;

  var viteMg = isF ? 9.0 : 10.0;
  if (isSeniorPlus) viteMg *= 1.10;

  // Priorité 71 (audit micronutriments) : ANSES exprime la vitamine K en
  // ~1µg/kg de poids corporel/jour, pas en valeur fixe — l'ancienne
  // constante (79µg) était de fait ce calcul figé pour un adulte de
  // référence ~79kg, appliqué tel quel à tout le monde.
  final vitkUg = _roundTo(p.weightKg * 1.0, 1.0);
  const vitcMg = 110.0;
  // B1, B2 et B3 : l'ANSES les exprime en mg PAR MÉGAJOULE d'énergie
  // consommée (0,1 mg/MJ pour B1 ; ~0,14 mg/MJ pour B2 ; 1,6 mg EN/MJ pour
  // B3, non genré), pas en valeur fixe. 1 kcal = 0,004184 MJ. B2 restait
  // figée à 1,6mg (le plancher, conservé comme borne basse) alors que B1 et
  // B3 appliquaient déjà correctement ce même principe — écart corrigé.
  final energyMJ = kcal * 0.004184;
  final b1Mg = _roundTo((0.1 * energyMJ).clamp(1.0, double.infinity), 0.1);
  final b2Mg = _roundTo((0.14 * energyMJ).clamp(1.6, double.infinity), 0.1);
  final b3Mg = _roundTo((1.6 * energyMJ).clamp(11.0, double.infinity), 0.5);
  final b5Mg = isF ? 5.0 : 6.0;
  final b6Mg = isF ? 1.6 : 1.7;
  const b9Ug = 330.0;
  const b12Ug = 4.0;

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
    mgMg: _roundTo(mgMg, 1),
    mnMg: mnMg,
    pMg: pMg,
    kMg: _roundTo(kMg, 1),
    seUg: _roundTo(seUg, 1),
    naMg: naMg,
    znMg: _roundTo(znMg, 1),
    vitAUg: vitaUg,
    vitBetacarUg: vitbetacarUg,
    vitDUg: vitdUg,
    vitEMg: _roundTo(viteMg, 0.1),
    vitKUg: vitkUg,
    vitCMg: vitcMg,
    b1Mg: b1Mg,
    b2Mg: b2Mg,
    b3Mg: b3Mg,
    b5Mg: b5Mg,
    b6Mg: b6Mg,
    b9Ug: b9Ug,
    b12Ug: b12Ug,
  );
}

/// ====== PERSISTANCE =========================================================

class ProfileStore {
  ProfileStore._();
  static final instance = ProfileStore._();

  Future<UserProfile> load() async {
    final sp = await SharedPreferences.getInstance();

    final sexStr = sp.getString('profile_sex');
    final sex = (sexStr == 'female') ? Sex.female : Sex.male;

    final ageD = sp.getDouble('profile_age') ?? 30.0;
    final height = sp.getDouble('profile_height') ?? 175.0;
    final weight = sp.getDouble('profile_weight') ?? 70.0;

    final actIdx = sp.getInt('profile_activity') ?? 0;
    final goalIdx = sp.getInt('profile_goal') ?? 1;

    final activity =
        ActivityLevel.values[actIdx.clamp(0, ActivityLevel.values.length - 1)];
    final goal = GoalType.values[goalIdx.clamp(0, GoalType.values.length - 1)];

    final bodyFat = sp.getDouble('profile_body_fat_pct');
    final targetWeight = sp.getDouble('profile_target_weight');
    final dietStyleIdx = sp.getInt('profile_diet_style') ?? 0;

    // Niveau d'activité : choix unique direct de l'utilisateur (voir
    // ActivityLevel — plus de reconstruction depuis pas + entraînements
    // séparés). `activityPalOverride` reste null ici : il n'est renseigné
    // que par la calibration adaptative (computeCalibratedTargets), jamais
    // au chargement simple du profil.
    return UserProfile(
      sex: sex,
      age: ageD.round(),
      heightCm: height,
      weightKg: weight,
      activity: activity,
      goal: goal,
      bodyFatPercent: (bodyFat != null && bodyFat > 0) ? bodyFat : null,
      targetWeightKg: (targetWeight != null && targetWeight > 0) ? targetWeight : null,
      dietStyle: DietStyle.values[dietStyleIdx.clamp(0, DietStyle.values.length - 1)],
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
    await sp.setInt('profile_diet_style', p.dietStyle.index);

    if (p.bodyFatPercent != null && p.bodyFatPercent! > 0) {
      await sp.setDouble('profile_body_fat_pct', p.bodyFatPercent!);
    } else {
      await sp.remove('profile_body_fat_pct');
    }
    if (p.targetWeightKg != null && p.targetWeightKg! > 0) {
      await sp.setDouble('profile_target_weight', p.targetWeightKg!);
    } else {
      await sp.remove('profile_target_weight');
    }
  }
}

/// Détail du TDEE (repos vs mouvement), pour l'affichage visuel (Profil 2.0).
class EnergyBreakdown {
  final double bmr;   // dépense au repos
  final double tdee;  // dépense totale (avant ajustement objectif)
  final double kcal;  // cible finale (après ajustement objectif)
  const EnergyBreakdown({required this.bmr, required this.tdee, required this.kcal});
  double get movementKcal => (tdee - bmr).clamp(0, double.infinity);
}

/// Calcule le détail BMR / mouvement / cible, pour le donut chart du profil.
EnergyBreakdown computeEnergyBreakdown(UserProfile p) {
  final bmr = _computeBmr(p);
  final tdee = bmr * _effectivePal(p);
  final rawKcal = tdee +
      _goalEnergyAdjustmentKcal(p.goal, p.weightKg, p.age,
          sex: p.sex, bodyFatPercent: p.bodyFatPercent, targetWeightKg: p.targetWeightKg);
  // Même plancher de sécurité que [computeGoals] — sinon ce détail
  // BMR/mouvement/ajustement afficherait un total qui ne correspond plus
  // aux calories/macros réellement calculées et sauvegardées.
  final kcalFloor = minSafeKcalFor(p.sex, bmr);
  final kcal = rawKcal < kcalFloor ? kcalFloor : rawKcal;
  return EnergyBreakdown(bmr: bmr, tdee: tdee, kcal: kcal);
}

Future<void> saveNutritionTargets(NutritionTargets t) async {
  final sp = await SharedPreferences.getInstance();

  await sp.setDouble('goals_kcal', t.goals.kcal);
  await sp.setDouble('goals_prot', t.goals.prot);
  await sp.setDouble('goals_carb', t.goals.carb);
  await sp.setDouble('goals_fat', t.goals.fat);
  await sp.setDouble('goals_fiber', t.goals.fiber);

  await sp.setDouble('goals_sat', t.sat);
  await sp.setDouble('goals_o9', t.o9);
  await sp.setDouble('goals_o6', t.o6);
  await sp.setDouble('goals_o3', t.o3);
  await sp.setDouble('goals_epa', t.epa);
  await sp.setDouble('goals_dha', t.dha);
  await sp.setDouble('goals_sugars', t.sugars);
  await sp.setDouble('goals_salt', t.salt);

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

  await sp.setDouble('goals_vita_ug', t.vitAUg);
  await sp.setDouble('goals_vitbetacar_ug', t.vitBetacarUg);
  await sp.setDouble('goals_vitd_ug', t.vitDUg);
  await sp.setDouble('goals_vite_mg', t.vitEMg);
  await sp.setDouble('goals_vitk_ug', t.vitKUg);
  await sp.setDouble('goals_vitc_mg', t.vitCMg);
  await sp.setDouble('goals_b1_mg', t.b1Mg);
  await sp.setDouble('goals_b2_mg', t.b2Mg);
  await sp.setDouble('goals_b3_mg', t.b3Mg);
  await sp.setDouble('goals_b5_mg', t.b5Mg);
  await sp.setDouble('goals_b6_mg', t.b6Mg);
  await sp.setDouble('goals_b9_ug', t.b9Ug);
  await sp.setDouble('goals_b12_ug', t.b12Ug);

  // Historise l'INTÉGRALITÉ des objectifs du jour (macros + AG essentiels +
  // à surveiller + minéraux + vitamines) — corrige le Bilan 30/60/90j qui
  // comparait sinon les jours passés aux objectifs ACTUELS au lieu de ceux
  // réellement en vigueur ce jour-là.
  await _appendGoalsSnapshot(sp, t);
}

/// Ajoute (ou remplace si déjà fait aujourd'hui) un instantané daté de
/// TOUS les objectifs (macros, AG essentiels, à surveiller, minéraux,
/// vitamines) — un seul par jour, la sauvegarde la plus récente du jour
/// fait foi.
Future<void> _appendGoalsSnapshot(SharedPreferences sp, NutritionTargets t) async {
  const key = 'goals_snapshots_v1';
  final today = DateTime.now();
  final todayKey = '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  List<dynamic> list = [];
  final raw = sp.getString(key);
  if (raw != null && raw.isNotEmpty) {
    try {
      list = jsonDecode(raw) as List;
    } catch (_) {
      list = [];
    }
  }

  list.removeWhere((e) => (e as Map)['date'] == todayKey);
  list.add({
    'date': todayKey,
    // Macros
    'kcal': t.goals.kcal, 'prot': t.goals.prot, 'carb': t.goals.carb,
    'fat': t.goals.fat, 'fiber': t.goals.fiber,
    // AG essentiels & à surveiller
    'sat': t.sat, 'o9': t.o9, 'o6': t.o6, 'o3': t.o3,
    'epa': t.epa, 'dha': t.dha, 'sugars': t.sugars, 'salt': t.salt,
    // Minéraux
    'caMg': t.caMg, 'cuMg': t.cuMg, 'feMg': t.feMg, 'iUg': t.iUg,
    'mgMg': t.mgMg, 'mnMg': t.mnMg, 'pMg': t.pMg, 'kMg': t.kMg,
    'seUg': t.seUg, 'naMg': t.naMg, 'znMg': t.znMg,
    // Vitamines
    'vitAUg': t.vitAUg, 'vitBetacarUg': t.vitBetacarUg, 'vitDUg': t.vitDUg,
    'vitEMg': t.vitEMg, 'vitKUg': t.vitKUg, 'vitCMg': t.vitCMg,
    'b1Mg': t.b1Mg, 'b2Mg': t.b2Mg, 'b3Mg': t.b3Mg, 'b5Mg': t.b5Mg,
    'b6Mg': t.b6Mg, 'b9Ug': t.b9Ug, 'b12Ug': t.b12Ug,
  });

  // Garde-fou : ne conserve que les 200 derniers instantanés (~6-7 mois
  // d'usage quotidien), pour ne pas grossir indéfiniment.
  list.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  if (list.length > 200) {
    list = list.sublist(list.length - 200);
  }

  await sp.setString(key, jsonEncode(list));

  // Priorité 67 (retour répété d'Alex : le Bilan 7/30/90j retombe toujours
  // sur l'objectif du jour) — cause racine trouvée : cet historique
  // n'existait qu'en local (SharedPreferences), donc disparaissait à
  // chaque réinstallation de l'app, EXACTEMENT le même bug déjà identifié
  // et corrigé pour weight_log (voir calibration_service.dart). Synchronisé
  // ici avec Supabase (table goal_snapshots, migration
  // 20260817_goal_snapshots.sql) pour survivre à une réinstallation ou un
  // changement d'appareil. Échec silencieux tant que la migration n'a pas
  // encore été appliquée côté Supabase — comportement local inchangé.
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('goal_snapshots').upsert({
        'user_id': user.id,
        'date': todayKey,
        'kcal': t.goals.kcal, 'prot': t.goals.prot, 'carb': t.goals.carb,
        'fat': t.goals.fat, 'fiber': t.goals.fiber,
        'sat': t.sat, 'o9': t.o9, 'o6': t.o6, 'o3': t.o3,
        'epa': t.epa, 'dha': t.dha, 'sugars': t.sugars, 'salt': t.salt,
        'ca_mg': t.caMg, 'cu_mg': t.cuMg, 'fe_mg': t.feMg, 'i_ug': t.iUg,
        'mg_mg': t.mgMg, 'mn_mg': t.mnMg, 'p_mg': t.pMg, 'k_mg': t.kMg,
        'se_ug': t.seUg, 'na_mg': t.naMg, 'zn_mg': t.znMg,
        'vit_a_ug': t.vitAUg, 'vit_betacar_ug': t.vitBetacarUg,
        'vit_d_ug': t.vitDUg, 'vit_e_mg': t.vitEMg, 'vit_k_ug': t.vitKUg,
        'vit_c_mg': t.vitCMg,
        'b1_mg': t.b1Mg, 'b2_mg': t.b2Mg, 'b3_mg': t.b3Mg, 'b5_mg': t.b5Mg,
        'b6_mg': t.b6Mg, 'b9_ug': t.b9Ug, 'b12_ug': t.b12Ug,
      }, onConflict: 'user_id,date');
    }
  } catch (_) {
    // Table pas encore migrée / hors ligne : l'historique local suffit en
    // attendant, aucune régression.
  }
}

/// Calibration adaptative (façon MacroFactor) : si assez de données de poids
/// réel + calories loguées sont disponibles, déduit un PAL "calibré" tel
/// que, une fois repassé dans LE MÊME moteur de calcul
/// (computeNutritionTargets), il redonne un jeu COMPLET et cohérent de
/// cibles — kcal, macros ET micronutriments recalculés ensemble sur la même
/// base. Volontairement PAS un simple correctif ponctuel des seules
/// calories : ça romprait la cohérence interne (ex. les AG essentiels ou les
/// sucres, exprimés en % des calories, resteraient calés sur l'ancien
/// total). Ici, tout redécoule de la même formule, donc reste garanti
/// cohérent entre lui — exactement le niveau de rigueur MacroFactor.
///
/// Si aucune calibration n'est encore disponible (moins de 10 jours de
/// pesées ou moins de 8 jours de journal alimentaire dans la fenêtre), les
/// cibles formule pure sont retournées telles quelles, inchangées.
Future<NutritionTargets> computeCalibratedTargets(UserProfile profile) async {
  final formulaTargets = computeNutritionTargets(profile);

  final calib = await CalibrationService.instance.computeCalibration();
  if (!calib.hasEnoughData || calib.empiricalTdee == null) return formulaTargets;

  final bmr = _computeBmr(profile);
  if (bmr <= 0) return formulaTargets;

  // L'écart objectif (%poids/semaine → kcal) ne dépend plus du TDEE (modèle
  // additif, pas multiplicatif) : il se soustrait donc directement, que le
  // TDEE utilisé soit la formule ou l'empirique.
  final adjustmentKcal = _goalEnergyAdjustmentKcal(profile.goal, profile.weightKg, profile.age,
      sex: profile.sex, bodyFatPercent: profile.bodyFatPercent, targetWeightKg: profile.targetWeightKg);
  final empiricalGoalAdjusted = calib.empiricalTdee! + adjustmentKcal;
  final blendedKcal = (formulaTargets.goals.kcal * (1 - calib.blendWeight)) +
      (empiricalGoalAdjusted * calib.blendWeight);

  // PAL "calibré" équivalent : en le repassant dans UserProfile, tout le
  // reste (protéines par masse maigre, plancher/plafond lipides, glucides en
  // solde, AG essentiels/sucres en % des calories) se recalcule cohérent
  // avec ces nouvelles calories, sans aucun correctif à la main. On retire
  // d'abord l'écart objectif (constant, indépendant du TDEE) avant de
  // diviser par le BMR pour obtenir le PAL implicite.
  final calibratedPal = ((blendedKcal - adjustmentKcal) / bmr).clamp(1.10, 2.20);
  final calibratedProfile = profile.copyWith(
    activityPalOverride: calibratedPal,
    activity: nearestActivityLevel(calibratedPal),
  );
  return computeNutritionTargets(calibratedProfile);
}

/// Version publique ne retournant que les macros — pour l'aperçu écran
/// (Profil), avant sauvegarde. Utilise EXACTEMENT la même logique que
/// [computeCalibratedTargets] (utilisée à la sauvegarde) : aperçu et valeur
/// réellement enregistrée ne peuvent donc plus diverger.
Future<Goals> computeCalibratedGoals(UserProfile profile) async {
  final targets = await computeCalibratedTargets(profile);
  return targets.goals;
}

Future<NutritionTargets> computeAndSaveTargetsFromStoredProfile() async {
  final profile = await ProfileStore.instance.load();
  var targets = computeNutritionTargets(profile);

  final sp = await SharedPreferences.getInstance();
  final isManual = sp.getBool('goals_manual') ?? false;

  if (isManual) {
    final manualKcal = sp.getDouble('goals_kcal');
    final manualProt = sp.getDouble('goals_prot');
    final manualCarb = sp.getDouble('goals_carb');
    final manualFat = sp.getDouble('goals_fat');
    final manualFiber = sp.getDouble('goals_fiber');

    if (manualKcal != null &&
        manualProt != null &&
        manualCarb != null &&
        manualFat != null &&
        manualFiber != null) {
      // Sous-cibles lipidiques et B1/B3/sucres RECALCULÉES sur les valeurs
      // MANUELLES (pas laissées sur l'ancien calcul automatique) — sinon
      // elles restent figées sur des calories qui ne sont plus les tiennes.
      // Même architecture v3 que le calcul auto : ALA/LA = planchers ANSES
      // fixes, oméga-9 = 35% du budget lipides (cible réaliste, atteignable
      // via une quantité normale d'huile d'olive/oléagineux).
      final manualEnergyMJ = manualKcal * 0.004184;
      final manualO6 = _roundTo(manualKcal * 0.04 / 9.0, 0.1);
      final manualO3 = _roundTo(manualKcal * 0.01 / 9.0, 0.1);
      final manualO9 = _roundTo(manualFat * 0.35, 0.1);
      targets = NutritionTargets(
        goals: Goals(
          kcal: manualKcal,
          prot: manualProt,
          carb: manualCarb,
          fat: manualFat,
          fiber: manualFiber,
        ),
        sat: _roundTo(manualKcal * 0.10 / 9.0, 0.1),
        o9: manualO9,
        o6: manualO6,
        o3: manualO3,
        epa: targets.epa,
        dha: targets.dha,
        sugars: _roundTo(manualKcal * 0.10 / 4.0, 0.5),
        salt: targets.salt,
        caMg: targets.caMg,
        cuMg: targets.cuMg,
        feMg: targets.feMg,
        iUg: targets.iUg,
        mgMg: targets.mgMg,
        mnMg: targets.mnMg,
        pMg: targets.pMg,
        kMg: targets.kMg,
        seUg: targets.seUg,
        naMg: targets.naMg,
        znMg: targets.znMg,
        vitAUg: targets.vitAUg,
        vitBetacarUg: targets.vitBetacarUg,
        vitDUg: targets.vitDUg,
        vitEMg: targets.vitEMg,
        vitKUg: targets.vitKUg,
        vitCMg: targets.vitCMg,
        b1Mg: _roundTo((0.1 * manualEnergyMJ).clamp(1.0, double.infinity), 0.1),
        b2Mg: targets.b2Mg,
        b3Mg: _roundTo((1.6 * manualEnergyMJ).clamp(11.0, double.infinity), 0.5),
        b5Mg: targets.b5Mg,
        b6Mg: targets.b6Mg,
        b9Ug: targets.b9Ug,
        b12Ug: targets.b12Ug,
      );
    }
  } else {
    // Mode auto (l'immense majorité des utilisateurs) : applique la
    // calibration adaptative si assez de données réelles sont disponibles.
    // AVANT ce correctif, cette étape manquait entièrement ici — la valeur
    // calibrée calculée côté écran (Profil) était donc systématiquement
    // écrasée par la formule pure au moment de la sauvegarde, rendant le
    // mécanisme d'auto-ajustement inopérant en pratique malgré le badge
    // "Affiné selon tes résultats réels" affiché à l'utilisateur.
    targets = await computeCalibratedTargets(profile);
  }

  await saveNutritionTargets(targets);
  return targets;
}