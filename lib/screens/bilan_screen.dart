import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'sun_vitamin_d_screen.dart' show SunVitaminDScreen;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/totum_score.dart';

import '../services/foods_loader.dart' as foods_loader;
import '../services/calibration_service.dart' show CalibrationService;
import '../services/export/journal_export.dart';
import '../services/nutrient_labels.dart';
import 'account_screen.dart'; // ✅
import '../theme/totum_style.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../services/app_settings.dart';

// Supabase client global (comme dans les autres écrans)
SupabaseClient get _client => Supabase.instance.client;


/// ───────────────────────────── Couleurs / helpers ─────────────────────────────

const Color kTotumOrange = TotumColors.accent;

Color _barColor(double pct) {
  if (!pct.isFinite) return TotumProgress.stop100;
  return TotumProgress.forFraction(pct.clamp(0.0, 1.0));
}

/// Couleur inversée pour la section "À surveiller" — ici c'est rester SOUS
/// le seuil qui est positif, donc sémantique de delta directionnel
/// (règle 5 de la charte), pas la rampe de progression.
Color _watchColor(double pct) {
  if (!pct.isFinite) return TotumColors.negative;
  if (pct <= 1.0) return TotumColors.positive; // ≤100 % = sous le seuil
  if (pct <= 1.2) return TotumColors.accent;   // 100–120 % = à surveiller
  return TotumColors.negative;                 // >120 % = dépassement net
}

/// Traduit un titre de groupe (MetricGroup.title) pour l'affichage — ce
/// titre n'est jamais comparé/utilisé comme clé ailleurs dans le code
/// (contrairement à Metric.label, voir nutrient_labels.dart), donc aucun
/// risque à le traduire directement ici.
String _groupTitle(String title, AppLocalizations l10n) => switch (title) {
      'Macro-cibles' => l10n.bilanGroupMacroTargets,
      'Acides gras essentiels' => l10n.bilanPillarFattyAcidsFull,
      'À surveiller' => l10n.scorePillarWatch,
      'Vitamines' => l10n.scorePillarVitamins,
      'Minéraux' => l10n.scorePillarMinerals,
      'Apports indicatifs' => l10n.bilanGroupIndicative,
      _ => title,
    };

/// ───────────────────────────── Périodes ─────────────────────────────

enum ReportSpan { day, d7, d30, d90 }

class _SpanInfo {
  final DateTime from;
  final DateTime to;
  final bool isAverage;
  const _SpanInfo(this.from, this.to, this.isAverage);
}

_SpanInfo _spanInfo(ReportSpan span) {
  final now = DateTime.now();
  switch (span) {
    case ReportSpan.day:
      final d = DateTime(now.year, now.month, now.day);
      return _SpanInfo(d, d, false);
    case ReportSpan.d7:
      return _SpanInfo(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
        DateTime(now.year, now.month, now.day),
        true,
      );
    case ReportSpan.d30:
      return _SpanInfo(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)),
        DateTime(now.year, now.month, now.day),
        true,
      );
    case ReportSpan.d90:
      return _SpanInfo(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 89)),
        DateTime(now.year, now.month, now.day),
        true,
      );
  }
}

/// ───────────────────────────── Modèles internes ─────────────────────────────

class _GoalsRaw {
  final double kcal;
  final double prot;
  final double carb;
  final double fat;
  final double fiber;
  final String sex; // 'male' | 'female'
  final double weightKg;
  final int activityIdx; // 0..4

  // Acides gras / à surveiller
  final double sat, o9, o6, o3, epa, dha, sugars, salt;

  // Minéraux
  final double caMg, cuMg, feMg, iUg, mgMg, mnMg, pMg, kMg, seUg, naMg, znMg;

  // Vitamines
  final double vitAUg, vitBetacarUg, vitDUg, vitEMg, vitKUg, vitCMg,
      b1Mg, b2Mg, b3Mg, b5Mg, b6Mg, b9Ug, b12Ug;

  const _GoalsRaw({
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.sex,
    required this.weightKg,
    required this.activityIdx,
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

class _DayTotals {
  final double kcal;
  final double prot;
  final double carb;
  final double fat;
  final double fiber;
  final Map<String, double> micros;
  final double waterMlFromJournal;
  final List<String> waterSources;
  final bool hasData;
  _DayTotals({
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.micros,
    required this.waterMlFromJournal,
    required this.waterSources,
    required this.hasData,
  });

  factory _DayTotals.empty() => _DayTotals(
        kcal: 0,
        prot: 0,
        carb: 0,
        fat: 0,
        fiber: 0,
        micros: <String, double>{},
        waterMlFromJournal: 0,
        waterSources: const [],
        hasData: false,
      );
}
/// Limites supérieures de sécurité journalières (UL) — EFSA, adultes.
const double _kUlRetinolUg  = 3000.0; // Vitamine A préformée (rétinol)
const double _kUlFerMg      = 40.0;   // Fer (EFSA 2024)
const double _kUlZincMg     = 25.0;   // Zinc
const double _kUlSeleniumUg = 255.0;
const double _kUlVitDUg     = 100.0;  // Vitamine D (4 000 UI)
const double _kUlVitEMg     = 300.0;  // Vitamine E (alpha-tocophérol)
const double _kUlB6Mg       = 12.0;   // Vitamine B6
const double _kUlIodeUg     = 600.0;  // Iode
const double _kUlCalciumMg  = 2500.0; // Calcium
const double _kUlCuivreMg   = 4.9;    // Cuivre (0,07 mg/kg — adulte 70 kg)

class Metric {
  final String label;
  final double value;
  final double? target;
  final String unit;
  final int decimals;
  final double? ul; // limite haute de sécurité (optionnelle)
  final String? ficheKey; // clé de la fiche explicative (optionnelle)
  const Metric(this.label, this.value, this.target, this.unit, this.decimals,
      {this.ul, this.ficheKey});
}

class MetricGroup {
  final String title;
  final IconData icon;
  final List<Metric> metrics;
  final bool isWatch;
  const MetricGroup({
    required this.title,
    required this.icon,
    required this.metrics,
    this.isWatch = false,
  });
}

class HydrationData {
  final double journalMl;
  final double manualMl;
  final double targetMl;
  final List<String> sources;
  const HydrationData({
    required this.journalMl,
    required this.manualMl,
    required this.targetMl,
    required this.sources,
  });

  double get totalMl => journalMl + manualMl;
  double get ratio => targetMl > 0 ? (totalMl / targetMl) : 0.0;
}

class DailyEnergyPoint {
  final DateTime date;
  final double kcal;
  final double goalKcal; // objectif RÉELLEMENT en vigueur ce jour-là
  // Dépense énergétique estimée ce jour-là par le moteur adaptatif
  // (CalibrationService.expenditureHistory) — null tant que la calibration
  // n'a pas assez de données (mêmes seuils que partout ailleurs dans l'app).
  final double? expenditureKcal;

  const DailyEnergyPoint({
    required this.date,
    required this.kcal,
    required this.goalKcal,
    this.expenditureKcal,
  });
}

class BilanData {
  final DateTime from;
  final DateTime to;
  final bool isAverage;

  // Totaux / moyennes
  final double kcal;
  final double prot;
  final double carb;
  final double fat;
  final double fiber;

  // Micros
  final Map<String, double> micros;

  // Nouveau : points journaliers d’énergie (pour le graphique)
  final List<DailyEnergyPoint> dailyEnergy;

  // Groupes pour l’affichage
  final MetricGroup macrosGroup;
  final MetricGroup efasGroup;
  final MetricGroup watchGroup;
  final MetricGroup vitaminsGroup;
  final MetricGroup mineralsGroup;
  final MetricGroup indicGroup;

  // Hydratation
  final HydrationData hydration;

  // Vitamine D synthétisée au soleil sur la période (déjà incluse dans la
  // valeur "Vit D" de vitaminsGroup — exposée à part pour le détail de la
  // fiche/l'icône soleil, voir showSunVitDSheet).
  final double sunVitDUg;

  const BilanData({
    required this.from,
    required this.to,
    required this.isAverage,
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
    required this.micros,
    required this.dailyEnergy,
    required this.macrosGroup,
    required this.efasGroup,
    required this.watchGroup,
    required this.vitaminsGroup,
    required this.mineralsGroup,
    required this.indicGroup,
    required this.hydration,
    this.sunVitDUg = 0.0,
  });
}


/// ───────────────────────────── Helpers profil / objectifs ─────────────────────────────

Future<_GoalsRaw> _readGoalsRaw() async {
  final sp = await SharedPreferences.getInstance();
  final kcal = sp.getDouble('goals_kcal') ?? 2000.0;
  final prot = sp.getDouble('goals_prot') ?? 120.0;
  final carb = sp.getDouble('goals_carb') ?? (kcal * 0.55) / 4.0;
  final fat = sp.getDouble('goals_fat') ?? (kcal * 0.35) / 9.0;
  final fiber = sp.getDouble('goals_fiber') ?? 30.0;
  final sexStr = sp.getString('profile_sex') ?? 'male';
  final sex = (sexStr == 'female') ? 'female' : 'male';
  final weight = sp.getDouble('profile_weight') ?? 70.0;
  final act = sp.getInt('profile_activity') ?? 0;
  final isF = sex == 'female';

  // Lecture des cibles sauvegardées par profile.dart (avec ajustements
  // âge/activité/composition corporelle déjà appliqués)
  return _GoalsRaw(
    kcal: kcal,
    prot: prot,
    carb: carb,
    fat: fat,
    fiber: fiber,
    sex: sex,
    weightKg: weight,
    activityIdx: act,
     // Le sel : cible de base 5 g pour tous (garde-fou — les sédentaires en
     // consomment déjà trop via l'ultra-transformé). Seuls les profils très
     // actifs voient leur cible relevée pour compenser les pertes sudorales
     // en sodium (repères sportifs : +0,3 à 1 g sodium/h d'effort intense).
     // intense (3) → +1 g de sel ; très intense (4) → +2 g de sel.
     sat: sp.getDouble('goals_sat') ?? (kcal * 0.10) / 9.0,
    o9: sp.getDouble('goals_o9') ?? (kcal * 0.20) / 9.0,
    o6: sp.getDouble('goals_o6') ?? (kcal * 0.04) / 9.0,
    o3: sp.getDouble('goals_o3') ?? (kcal * 0.01) / 9.0,
    epa: sp.getDouble('goals_epa') ?? 0.25,
    dha: sp.getDouble('goals_dha') ?? 0.25,
    sugars: sp.getDouble('goals_sugars') ?? (kcal * 0.10) / 4.0,
    salt: (sp.getDouble('goals_salt') ?? 5.0) +
        (act >= 4 ? 2.0 : (act == 3 ? 1.0 : 0.0)),
    caMg: sp.getDouble('goals_ca_mg') ?? 950.0,
    cuMg: sp.getDouble('goals_cu_mg') ?? (isF ? 1.5 : 1.9),
    feMg: sp.getDouble('goals_fe_mg') ?? 11.0,
    iUg: sp.getDouble('goals_i_ug') ?? 150.0,
    mgMg: sp.getDouble('goals_mg_mg') ?? (isF ? 300.0 : 380.0),
    // Cible EFSA (Adequate Intake) = 3.0 ; 8.0 était l'ancienne LIMITE DE
    // SÉCURITÉ réutilisée par erreur comme repli (voir profile.dart:377,
    // seule source de vérité pour cette valeur).
    mnMg: sp.getDouble('goals_mn_mg') ?? 3.0,
    pMg: sp.getDouble('goals_p_mg') ?? 550.0,
    kMg: sp.getDouble('goals_k_mg') ?? 3500.0,
    seUg: sp.getDouble('goals_se_ug') ?? 70.0,
    naMg: sp.getDouble('goals_na_mg') ?? 1500.0,
    znMg: sp.getDouble('goals_zn_mg') ?? (isF ? 11.0 : 14.0),
    vitAUg: sp.getDouble('goals_vita_ug') ?? (isF ? 650.0 : 750.0),
    vitBetacarUg: sp.getDouble('goals_vitbetacar_ug') ?? (isF ? 2600.0 : 3000.0),
    vitDUg: sp.getDouble('goals_vitd_ug') ?? 15.0,
    vitEMg: sp.getDouble('goals_vite_mg') ?? (isF ? 9.0 : 10.0),
    vitKUg: sp.getDouble('goals_vitk_ug') ?? 79.0,
    vitCMg: sp.getDouble('goals_vitc_mg') ?? 110.0,
    b1Mg: sp.getDouble('goals_b1_mg') ?? 1.6,
    b2Mg: sp.getDouble('goals_b2_mg') ?? 1.6,
    b3Mg: sp.getDouble('goals_b3_mg') ?? 10.0,
    b5Mg: sp.getDouble('goals_b5_mg') ?? (isF ? 5.0 : 6.0),
    b6Mg: sp.getDouble('goals_b6_mg') ?? (isF ? 1.6 : 1.7),
    b9Ug: sp.getDouble('goals_b9_ug') ?? 330.0,
    b12Ug: sp.getDouble('goals_b12_ug') ?? 2.5,
  );
}

/// Un instantané COMPLET des objectifs, daté — macros, AG essentiels,
/// à surveiller, minéraux, vitamines (37 valeurs).
class _GoalsSnapshot {
  final String date; // 'YYYY-MM-DD'
  final double kcal, prot, carb, fat, fiber;
  final double sat, o9, o6, o3, epa, dha, sugars, salt;
  final double caMg, cuMg, feMg, iUg, mgMg, mnMg, pMg, kMg, seUg, naMg, znMg;
  final double vitAUg, vitBetacarUg, vitDUg, vitEMg, vitKUg, vitCMg,
      b1Mg, b2Mg, b3Mg, b5Mg, b6Mg, b9Ug, b12Ug;
  const _GoalsSnapshot({
    required this.date,
    required this.kcal,
    required this.prot,
    required this.carb,
    required this.fat,
    required this.fiber,
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

/// Lit l'historique des objectifs macro enregistré par profile.dart à
/// chaque sauvegarde de profil. Triés du plus ancien au plus récent.
Future<List<_GoalsSnapshot>> _readGoalsSnapshots() async {
  final sp = await SharedPreferences.getInstance();
  final raw = sp.getString('goals_snapshots_v1');
  if (raw == null || raw.isEmpty) return const [];
  // Repli sur les objectifs actuels pour les instantanés plus anciens qui
  // n'auraient que les 5 macros (créés avant l'extension aux micros) —
  // aucune casse sur l'historique déjà constitué.
  final fallback = await _readGoalsRaw();
  double d(Map<String, dynamic> m, String key, double fb) {
    final v = m[key];
    return v is num ? v.toDouble() : fb;
  }
  try {
    final list = jsonDecode(raw) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return _GoalsSnapshot(
        date: m['date'] as String,
        kcal: d(m, 'kcal', fallback.kcal),
        prot: d(m, 'prot', fallback.prot),
        carb: d(m, 'carb', fallback.carb),
        fat: d(m, 'fat', fallback.fat),
        fiber: d(m, 'fiber', fallback.fiber),
        sat: d(m, 'sat', fallback.sat),
        o9: d(m, 'o9', fallback.o9),
        o6: d(m, 'o6', fallback.o6),
        o3: d(m, 'o3', fallback.o3),
        epa: d(m, 'epa', fallback.epa),
        dha: d(m, 'dha', fallback.dha),
        sugars: d(m, 'sugars', fallback.sugars),
        salt: d(m, 'salt', fallback.salt),
        caMg: d(m, 'caMg', fallback.caMg),
        cuMg: d(m, 'cuMg', fallback.cuMg),
        feMg: d(m, 'feMg', fallback.feMg),
        iUg: d(m, 'iUg', fallback.iUg),
        mgMg: d(m, 'mgMg', fallback.mgMg),
        mnMg: d(m, 'mnMg', fallback.mnMg),
        pMg: d(m, 'pMg', fallback.pMg),
        kMg: d(m, 'kMg', fallback.kMg),
        seUg: d(m, 'seUg', fallback.seUg),
        naMg: d(m, 'naMg', fallback.naMg),
        znMg: d(m, 'znMg', fallback.znMg),
        vitAUg: d(m, 'vitAUg', fallback.vitAUg),
        vitBetacarUg: d(m, 'vitBetacarUg', fallback.vitBetacarUg),
        vitDUg: d(m, 'vitDUg', fallback.vitDUg),
        vitEMg: d(m, 'vitEMg', fallback.vitEMg),
        vitKUg: d(m, 'vitKUg', fallback.vitKUg),
        vitCMg: d(m, 'vitCMg', fallback.vitCMg),
        b1Mg: d(m, 'b1Mg', fallback.b1Mg),
        b2Mg: d(m, 'b2Mg', fallback.b2Mg),
        b3Mg: d(m, 'b3Mg', fallback.b3Mg),
        b5Mg: d(m, 'b5Mg', fallback.b5Mg),
        b6Mg: d(m, 'b6Mg', fallback.b6Mg),
        b9Ug: d(m, 'b9Ug', fallback.b9Ug),
        b12Ug: d(m, 'b12Ug', fallback.b12Ug),
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  } catch (_) {
    return const [];
  }
}

/// Objectifs macro RÉELLEMENT en vigueur un jour donné : le dernier
/// instantané enregistré à cette date ou avant. S'il n'y a aucun
/// instantané antérieur (données d'avant cette fonctionnalité, ou compte
/// tout neuf), on retombe sur les objectifs actuels — comportement
/// identique à avant, non-régressif.
_GoalsRaw _goalsRawForDay(
  DateTime day,
  List<_GoalsSnapshot> snapshots,
  _GoalsRaw current,
) {
  final dayKey = _dateKey(day);
  _GoalsSnapshot? applicable;
  for (final s in snapshots) {
    if (s.date.compareTo(dayKey) <= 0) {
      applicable = s; // la liste est triée croissant, on garde le dernier "<="
    } else {
      break;
    }
  }
  if (applicable == null) return current;
  final a = applicable;
  return _GoalsRaw(
    kcal: a.kcal, prot: a.prot, carb: a.carb, fat: a.fat, fiber: a.fiber,
    sex: current.sex,           // pas historisé : ne varie pas avec l'objectif
    weightKg: current.weightKg, // idem
    activityIdx: current.activityIdx,
    sat: a.sat, o9: a.o9, o6: a.o6, o3: a.o3, epa: a.epa, dha: a.dha,
    sugars: a.sugars, salt: a.salt,
    caMg: a.caMg, cuMg: a.cuMg, feMg: a.feMg, iUg: a.iUg,
    mgMg: a.mgMg, mnMg: a.mnMg, pMg: a.pMg, kMg: a.kMg,
    seUg: a.seUg, naMg: a.naMg, znMg: a.znMg,
    vitAUg: a.vitAUg, vitBetacarUg: a.vitBetacarUg, vitDUg: a.vitDUg,
    vitEMg: a.vitEMg, vitKUg: a.vitKUg, vitCMg: a.vitCMg,
    b1Mg: a.b1Mg, b2Mg: a.b2Mg, b3Mg: a.b3Mg, b5Mg: a.b5Mg, b6Mg: a.b6Mg,
    b9Ug: a.b9Ug, b12Ug: a.b12Ug,
  );
}

/// Moyenne des objectifs macro RÉELLEMENT en vigueur sur une période — pour
/// les vues 7/30/90j, quand l'objectif a pu changer en cours de route.
/// Pondère uniquement les jours où il y a eu des données consommées, pour
/// coller à la moyenne de consommation calculée par ailleurs (même base
/// de jours des deux côtés de la comparaison).
_GoalsRaw _averageGoalsRawForRange(
  List<DateTime> daysWithData,
  List<_GoalsSnapshot> snapshots,
  _GoalsRaw current,
) {
  if (daysWithData.isEmpty) return current;
  double sK=0,sP=0,sC=0,sF=0,sFib=0;
  double sSat=0,sO9=0,sO6=0,sO3=0,sEpa=0,sDha=0,sSug=0,sSalt=0;
  double sCa=0,sCu=0,sFe=0,sI=0,sMg=0,sMn=0,sP2=0,sK2=0,sSe=0,sNa=0,sZn=0;
  double sVitA=0,sVitBc=0,sVitD=0,sVitE=0,sVitK=0,sVitC=0;
  double sB1=0,sB2=0,sB3=0,sB5=0,sB6=0,sB9=0,sB12=0;
  for (final d in daysWithData) {
    final g = _goalsRawForDay(d, snapshots, current);
    sK+=g.kcal; sP+=g.prot; sC+=g.carb; sF+=g.fat; sFib+=g.fiber;
    sSat+=g.sat; sO9+=g.o9; sO6+=g.o6; sO3+=g.o3; sEpa+=g.epa; sDha+=g.dha;
    sSug+=g.sugars; sSalt+=g.salt;
    sCa+=g.caMg; sCu+=g.cuMg; sFe+=g.feMg; sI+=g.iUg; sMg+=g.mgMg;
    sMn+=g.mnMg; sP2+=g.pMg; sK2+=g.kMg; sSe+=g.seUg; sNa+=g.naMg; sZn+=g.znMg;
    sVitA+=g.vitAUg; sVitBc+=g.vitBetacarUg; sVitD+=g.vitDUg;
    sVitE+=g.vitEMg; sVitK+=g.vitKUg; sVitC+=g.vitCMg;
    sB1+=g.b1Mg; sB2+=g.b2Mg; sB3+=g.b3Mg; sB5+=g.b5Mg; sB6+=g.b6Mg;
    sB9+=g.b9Ug; sB12+=g.b12Ug;
  }
  final n = daysWithData.length;
  return _GoalsRaw(
    kcal: sK/n, prot: sP/n, carb: sC/n, fat: sF/n, fiber: sFib/n,
    sex: current.sex, weightKg: current.weightKg, activityIdx: current.activityIdx,
    sat: sSat/n, o9: sO9/n, o6: sO6/n, o3: sO3/n, epa: sEpa/n, dha: sDha/n,
    sugars: sSug/n, salt: sSalt/n,
    caMg: sCa/n, cuMg: sCu/n, feMg: sFe/n, iUg: sI/n, mgMg: sMg/n,
    mnMg: sMn/n, pMg: sP2/n, kMg: sK2/n, seUg: sSe/n, naMg: sNa/n, znMg: sZn/n,
    vitAUg: sVitA/n, vitBetacarUg: sVitBc/n, vitDUg: sVitD/n,
    vitEMg: sVitE/n, vitKUg: sVitK/n, vitCMg: sVitC/n,
    b1Mg: sB1/n, b2Mg: sB2/n, b3Mg: sB3/n, b5Mg: sB5/n, b6Mg: sB6/n,
    b9Ug: sB9/n, b12Ug: sB12/n,
  );
}

/// Objectif hydratation basé sur poids & activité
double _hydrationTarget(double weightKg, int activityIdx) {
  int bonus = switch (activityIdx.clamp(0, 4)) {
    1 => 300,
    2 => 600,
    3 || 4 => 900,
    _ => 0,
  };
  return (weightKg * 30.0 + bonus).clamp(1000, 6000).toDouble();
}

/// ───────────────────────────── Helpers FoodsRepository / Journal ─────────────────────────────

Future<void> _ensureFoodsLoaded() async {
  final repo = foods_loader.FoodsRepository.instance;
  try {
    final items = (repo.items as List);
    if (items.isEmpty) {
      try {
        await repo.loadFromAsset('assets/foods.csv');
      } catch (_) {}
    }
  } catch (_) {}
  // Toujours recharger les customs (jamais de early return ici) pour être
  // certain d'avoir les derniers aliments scannés, même si le CSV est
  // déjà chargé en mémoire depuis une session précédente.
  try {
    await repo.loadCustomFoods();
  } catch (_) {}
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _hydrationManualKeyForDate(DateTime d) =>
    'hydration_manual_ml_${_dateKey(d)}';

String _journalKeyForDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return 'journal_$y-$m-$dd';
}

/// Détecte si le nom d'aliment correspond à de l'eau en bouteille / eau du robinet
/// Eau réellement apportée par un aliment, d'après la colonne CIQUAL `Eau_g_100g`.
/// Repli sur l'ancienne détection par le nom si la donnée manque
/// (aliment personnel, ou entrée créée avant l'ajout de la colonne).
double _foodWaterMl(foods_loader.FoodItem? food, String name, double grams) {
  if (food != null) {
    final w = food.microsFor(grams)['Eau_g_100g'] ?? 0.0;
    if (w > 0) return w;
  }
  return _looksLikeWater(name) ? grams : 0.0;
}

bool _looksLikeWater(String name) {
  final lower = name.toLowerCase();
  if (lower.startsWith('eau ')) return true;
  const brands = [
    'evian',
    'badoit',
    'vittel',
    'volvic',
    'contrex',
    'perrier',
    'hépar',
    'hepar',
    'st yorre',
    'saint-yorre',
    'saint yorre',
    'st-yorre',
    'quézac',
    'quezac',
    'wattwiller',
  ];
  for (final b in brands) {
    if (lower.contains(b)) return true;
  }
  return false;
}

/// Totaux (macros + micros + eau) pour une journée donnée
Future<_DayTotals> _computeDayTotalsForDate(
  DateTime day,
  foods_loader.FoodsRepository repo,
  SharedPreferences sp,
) async {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final dd = day.day.toString().padLeft(2, '0');
  final ymd = '$y-$m-$dd';

  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
  final microTotals = <String, double>{};
  double waterMl = 0;
  final waterNames = <String>{};

  // Lookup indexé O(1) (Priorité 31) : évite de reconstruire et scanner
  // linéairement une liste fusionnée de ~3500 aliments par entrée — coût
  // multiplié par le nombre de jours pour un bilan 7/30/90j.
  foods_loader.FoodItem? findFood(String id) => repo.findById(id);

  // 1) 🔹 Tentative via Supabase (multi-appareils)
  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> rows = await _client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .eq('entry_date', ymd);

      if (rows.isNotEmpty) {
        for (final r in rows) {
          final id = (r['food_id'] ?? '').toString();
          final name = (r['food_name'] ?? '').toString();
          final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0.0;

          // Macros depuis Supabase
          kcal += (r['energy_kcal'] as num?)?.toDouble() ?? 0.0;
          prot += (r['protein_g'] as num?)?.toDouble() ?? 0.0;
          carb += (r['carbs_g'] as num?)?.toDouble() ?? 0.0;
          fat  += (r['fat_g'] as num?)?.toDouble() ?? 0.0;
          fiber += (r['fiber_g'] as num?)?.toDouble() ?? 0.0;

          // Micros : snapshot figé dans la ligne si présent, sinon recalcul
          final snap = r['micros'];
          if (snap is Map && snap.isNotEmpty) {
            snap.forEach((k, v) {
              final d = (v is num) ? v.toDouble() : 0.0;
              microTotals[k.toString()] =
                  (microTotals[k.toString()] ?? 0.0) + d;
            });
          } else if (id.isNotEmpty) {
            final food = findFood(id);
            if (food != null) {
              final mic = food.microsFor(grams);
              mic.forEach((k, v) {
                microTotals[k] = (microTotals[k] ?? 0.0) + v;
              });
            }
          }

          // Eau réellement contenue dans l'aliment (colonne CIQUAL)
          final wMl = _foodWaterMl(findFood(id), name, grams);
          if (wMl > 0) {
            waterMl += wMl;
            if (wMl >= 50) waterNames.add(name);
          }
        }

        if ((kcal + prot + carb + fat + fiber) > 0 ||
            microTotals.isNotEmpty ||
            waterMl > 0) {
          return _DayTotals(
            kcal: kcal,
            prot: prot,
            carb: carb,
            fat: fat,
            fiber: fiber,
            micros: microTotals,
            waterMlFromJournal: waterMl,
            waterSources: waterNames.toList(),
            hasData: true,
          );
        }
      }
    }
  } catch (_) {
    // En cas de souci réseau / Supabase → on tombera sur le fallback local
  }

  // 2) 🔹 Fallback : lecture locale du journal_YYYY-MM-DD (comportement historique)
  final key = _journalKeyForDate(day);
  final raw = sp.getString(key);
  if (raw == null || raw.isEmpty) {
    return _DayTotals.empty();
  }

  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return _DayTotals.empty();
  }

  // Réinitialise les compteurs pour la partie locale
  kcal = 0;
  prot = 0;
  carb = 0;
  fat = 0;
  fiber = 0;
  microTotals.clear();
  waterMl = 0;
  waterNames.clear();

  for (final mealList in decoded.values) {
    if (mealList is! List) continue;
    for (final entry in mealList) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final id = (m['id'] ?? '').toString();
      final name = (m['name'] ?? '').toString();
      final grams = (m['grams'] as num?)?.toDouble() ?? 0.0;

      // Macros depuis le journal (pour coller au journal)
      kcal += (m['kcal'] as num?)?.toDouble() ?? 0.0;
      prot += (m['prot'] as num?)?.toDouble() ?? 0.0;
      carb += (m['carb'] as num?)?.toDouble() ?? 0.0;
      fat  += (m['fat'] as num?)?.toDouble() ?? 0.0;
      fiber += (m['fiber'] as num?)?.toDouble() ?? 0.0;

      // Micros depuis la base CSV
      final food = findFood(id);
      if (food != null) {
        final mic = food.microsFor(grams);
        mic.forEach((k, v) {
          microTotals[k] = (microTotals[k] ?? 0.0) + v;
        });
      }

      // Eau réellement contenue dans l'aliment (colonne CIQUAL)
      final wMl = _foodWaterMl(food, name, grams);
      if (wMl > 0) {
        waterMl += wMl;
        if (wMl >= 50) waterNames.add(name);
      }
    }
  }

  return _DayTotals(
    kcal: kcal,
    prot: prot,
    carb: carb,
    fat: fat,
    fiber: fiber,
    micros: microTotals,
    waterMlFromJournal: waterMl,
    waterSources: waterNames.toList(),
    hasData: (kcal + prot + carb + fat + fiber) > 0 ||
        microTotals.isNotEmpty ||
        waterMl > 0,
  );
}


/// ───────────────────────────── Hydratation ─────────────────────────────

Future<HydrationData> _computeHydrationForToday(_GoalsRaw goals) async {
  final sp = await SharedPreferences.getInstance();
  final repo = foods_loader.FoodsRepository.instance;
  await _ensureFoodsLoaded();

  final now = DateTime.now();
  final dayTotals = await _computeDayTotalsForDate(now, repo, sp);

  final ymd = '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  // Eau bue via les verres du Journal (table Supabase water_intake).
  double glassesMl = 0.0;
  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final row = await _client
          .from('water_intake')
          .select('total_ml')
          .eq('user_id', user.id)
          .eq('intake_date', ymd)
          .maybeSingle();
      glassesMl = ((row?['total_ml'] as num?) ?? 0).toDouble();
    }
  } catch (_) {}

  // Repli local historique (si jamais un ancien apport manuel existe).
  final manualKey = 'hydration_manual_ml_$ymd';
  final legacyManual = sp.getDouble(manualKey) ?? 0.0;

  final target = sp.getDouble('goals_water_ml') ??
      _hydrationTarget(goals.weightKg, goals.activityIdx);

  return HydrationData(
    journalMl: dayTotals.waterMlFromJournal,
    manualMl: glassesMl + legacyManual, // verres du Journal + ancien manuel
    targetMl: target,
    sources: dayTotals.waterSources,
  );
}

/// Calcule les totaux d'un jour à partir de lignes déjà récupérées en bulk.
/// Évite N requêtes Supabase — appelée depuis _computeBilanForSpan.
_DayTotals _computeDayTotalsFromPrefetchedRows(
  List<Map<String, dynamic>> rows,
  foods_loader.FoodsRepository repo,
) {
  double kcal = 0, prot = 0, carb = 0, fat = 0, fiber = 0;
  final microTotals = <String, double>{};
  double waterMl = 0;
  final waterNames = <String>{};

  foods_loader.FoodItem? findFood(String id) => repo.findById(id);

  for (final r in rows) {
    final id    = (r['food_id']        ?? '').toString();
    final name  = (r['food_name']      ?? '').toString();
    final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0.0;

    kcal  += (r['energy_kcal'] as num?)?.toDouble() ?? 0.0;
    prot  += (r['protein_g']   as num?)?.toDouble() ?? 0.0;
    carb  += (r['carbs_g']     as num?)?.toDouble() ?? 0.0;
    fat   += (r['fat_g']       as num?)?.toDouble() ?? 0.0;
    fiber += (r['fiber_g']     as num?)?.toDouble() ?? 0.0;

    // Micros : snapshot figé dans la ligne si présent, sinon recalcul
    final snap = r['micros'];
    if (snap is Map && snap.isNotEmpty) {
      snap.forEach((k, v) {
        final d = (v is num) ? v.toDouble() : 0.0;
        microTotals[k.toString()] = (microTotals[k.toString()] ?? 0.0) + d;
      });
    } else if (id.isNotEmpty) {
      final food = findFood(id);
      if (food != null) {
        food.microsFor(grams).forEach((k, v) {
          microTotals[k] = (microTotals[k] ?? 0.0) + v;
        });
      }
    }
    final wMl = _foodWaterMl(findFood(id), name, grams);
    if (wMl > 0) {
      waterMl += wMl;
      if (wMl >= 50) waterNames.add(name);
    }
  }

  return _DayTotals(
    kcal: kcal, prot: prot, carb: carb, fat: fat, fiber: fiber,
    micros: microTotals,
    waterMlFromJournal: waterMl,
    waterSources: waterNames.toList(),
    hasData: (kcal + prot + carb + fat + fiber) > 0 ||
             microTotals.isNotEmpty || waterMl > 0,
  );
}

/// ───────────────────────────── Calcul Bilan pour une période ─────────────────────────────

Future<BilanData> _computeBilanForSpan(ReportSpan span,
    {DateTime? specificDay}) async {
  final currentGoals = await _readGoalsRaw();
  final goalsSnapshots = await _readGoalsSnapshots();
  final sp    = await SharedPreferences.getInstance();
  final repo  = foods_loader.FoodsRepository.instance;
  await _ensureFoodsLoaded();

  // Dépense énergétique estimée par jour (moteur adaptatif) — permet à la
  // vignette "Équilibre énergétique" de comparer l'apport à la dépense
  // réelle estimée, pas seulement à l'objectif (même logique que la vue
  // "Expenditure" de MacroFactor). Vide/silencieux tant que la calibration
  // n'a pas assez de données — aucune régression, juste un enrichissement.
  final Map<String, double> expenditureByDate = {};
  try {
    final expPoints = await CalibrationService.instance.expenditureHistory(days: 95);
    for (final p in expPoints) {
      expenditureByDate[_dateKey(p.date)] = p.estimateKcal;
    }
  } catch (_) {}

  // Si une date précise est fournie (tap sur une barre), on calcule ce jour.
  final _SpanInfo info;
  if (specificDay != null) {
    final d = DateTime(specificDay.year, specificDay.month, specificDay.day);
    info = _SpanInfo(d, d, false);
  } else {
    info = _spanInfo(span);
  }
  final from = info.from;
  final to   = info.to;
  final isAvg = info.isAverage;

  // ── Bulk fetch : 1 seule requête Supabase pour toute la période ───────
  final Map<String, List<Map<String, dynamic>>> rowsByDate = {};
  bool supabaseSuccess = false;

  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> allRows = await _client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .gte('entry_date', _dateKey(from))
          .lte('entry_date', _dateKey(to));

      for (final row in allRows) {
        final date = (row['entry_date'] as String?) ?? '';
        if (date.isNotEmpty) {
          rowsByDate.putIfAbsent(date, () => []).add(row);
        }
      }
      supabaseSuccess = true;
    }
  } catch (e) {
    debugPrint('Erreur bulk fetch bilan: $e');
  }

  // ── Bulk fetch "Boissons" (verres d'eau, table water_intake) ──────────
  // Bug confirmé par Alex : les moyennes 7/30/90j ne comptaient que l'eau
  // détectée dans les aliments du journal ("Aliments") et un ancien apport
  // manuel local désormais legacy — jamais les verres réellement loggés via
  // le compteur "Boissons" (stockés côté Supabase, table water_intake, un
  // total par jour), pourtant seule source utilisée pour le calcul du jour
  // même (_computeHydrationForToday). D'où des moyennes historiques bien en
  // dessous de la réalité (ex. 34 % au lieu de 100 %+).
  final Map<String, double> waterByDate = {};
  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> waterRows = await _client
          .from('water_intake')
          .select('intake_date, total_ml')
          .eq('user_id', user.id)
          .gte('intake_date', _dateKey(from))
          .lte('intake_date', _dateKey(to));
      for (final row in waterRows) {
        final date = (row['intake_date'] as String?) ?? '';
        if (date.isEmpty) continue;
        waterByDate[date] = ((row['total_ml'] as num?) ?? 0).toDouble();
      }
    }
  } catch (e) {
    debugPrint('Erreur bulk fetch boissons bilan: $e');
  }

  // ── Bulk fetch vitamine D solaire (table sun_vitamin_d) ────────────────
  // Avant (Priorité 23) : uniquement lue pour "aujourd'hui" quel que soit le
  // jour/la période réellement affichée (bug — un Bilan sur un jour passé,
  // ou une moyenne 7/30/90j, ignorait silencieusement l'apport solaire réel
  // de cette période, pourtant historisé côté Supabase depuis la Priorité 17).
  final Map<String, double> sunVitDByDate = {};
  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> sunRows = await _client
          .from('sun_vitamin_d')
          .select('date, vit_d_ug')
          .eq('user_id', user.id)
          .gte('date', _dateKey(from))
          .lte('date', _dateKey(to));
      for (final row in sunRows) {
        final date = (row['date'] as String?) ?? '';
        if (date.isEmpty) continue;
        sunVitDByDate[date] = ((row['vit_d_ug'] as num?) ?? 0).toDouble();
      }
    }
  } catch (e) {
    debugPrint('Erreur bulk fetch vitamine D solaire bilan: $e');
  }

  double sumKcal = 0, sumProt = 0, sumCarb = 0, sumFat = 0, sumFib = 0;
  double sumSunVitD = 0;
  final microTotals = <String, double>{};
  int daysWithData = 0;
  final List<DateTime> datesWithData = []; // pour moyenner les BONS objectifs
  final List<DailyEnergyPoint> energyPoints = [];

  // Hydratation (accumulateurs pour le mode moyenne)
  double sumJournalWater = 0, sumManualWater = 0;
  int hydrationDays = 0;

  for (DateTime d = from;
      !d.isAfter(to);
      d = d.add(const Duration(days: 1))) {

    final dateKey = _dateKey(d);
    _DayTotals dt;

    if (supabaseSuccess) {
      final rows = rowsByDate[dateKey] ?? [];
      dt = _computeDayTotalsFromPrefetchedRows(rows, repo);
    } else {
      // Fallback offline : requête per-jour (ancien comportement)
      dt = await _computeDayTotalsForDate(d, repo, sp);
    }

    // Hydratation : accumulée indépendamment du reste (kcal/macros). Avant,
    // ce bloc était sous le `if (!dt.hasData) continue;` ci-dessous, donc une
    // journée où seule l'eau était renseignée (sans aucun aliment loggé)
    // disparaissait silencieusement de la moyenne — bug confirmé signalé par
    // Alex. La valeur "Boissons" vient désormais de `waterByDate` (verres
    // réellement loggés, table Supabase water_intake — même source que le
    // calcul du jour même), plus l'ancien apport manuel local en repli pour
    // ne pas perdre un historique antérieur à ce mécanisme.
    if (isAvg) {
      final manualWater = (waterByDate[dateKey] ?? 0.0) +
          (sp.getDouble(_hydrationManualKeyForDate(d)) ?? 0.0);
      if (dt.waterMlFromJournal > 0 || manualWater > 0) {
        hydrationDays++;
        sumJournalWater += dt.waterMlFromJournal;
        sumManualWater += manualWater;
      }
    }

    if (!dt.hasData) continue;
    daysWithData++;
    datesWithData.add(d);

    sumKcal += dt.kcal;
    sumProt += dt.prot;
    sumCarb += dt.carb;
    sumFat  += dt.fat;
    sumFib  += dt.fiber;
    sumSunVitD += sunVitDByDate[dateKey] ?? 0.0;
    energyPoints.add(DailyEnergyPoint(
      date: d,
      kcal: dt.kcal,
      goalKcal: _goalsRawForDay(d, goalsSnapshots, currentGoals).kcal,
      expenditureKcal: expenditureByDate[dateKey],
    ));
    dt.micros.forEach((k, v) {
      microTotals[k] = (microTotals[k] ?? 0.0) + v;
    });
  }

  if (isAvg && daysWithData > 0) {
    final div = daysWithData.toDouble();
    sumKcal /= div; sumProt /= div; sumCarb /= div;
    sumFat  /= div; sumFib  /= div;
    sumSunVitD /= div;
    microTotals.updateAll((_, v) => v / div);
  }

  // ── Objectifs RÉELLEMENT en vigueur pour cette période (corrige le bug :
  // avant, on comparait toujours à l'objectif ACTUEL, jamais à celui d'alors) ──
  final _GoalsRaw goals = isAvg
      ? _averageGoalsRawForRange(datesWithData, goalsSnapshots, currentGoals)
      : _goalsRawForDay(from, goalsSnapshots, currentGoals);

  // ── Hydratation ───────────────────────────────────────────────────────
  HydrationData hydration;
  final waterTarget = sp.getDouble('goals_water_ml') ??
      _hydrationTarget(currentGoals.weightKg, currentGoals.activityIdx);

  if (!isAvg) {
    hydration = await _computeHydrationForToday(currentGoals);
  } else {
    hydration = HydrationData(
      journalMl: hydrationDays > 0 ? sumJournalWater / hydrationDays : 0,
      manualMl:  hydrationDays > 0 ? sumManualWater  / hydrationDays : 0,
      targetMl:  waterTarget,
      sources:   const [],
    );
  }

  // Vitamine D synthétisée au soleil — désormais la vraie valeur de la
  // période affichée (jour précis ou moyenne sur la fenêtre), via le bulk
  // fetch ci-dessus. Avant (bug) : toujours "aujourd'hui", quelle que soit
  // la période réellement consultée.
  final sunVitD = sumSunVitD;

  return _buildMetricGroups(
    from: from, to: to, isAverage: isAvg,
    kcal: sumKcal, prot: sumProt, carb: sumCarb, fat: sumFat, fiber: sumFib,
    micros: microTotals,
    goals: goals,
    hydration: hydration,
    dailyEnergy: energyPoints,
    sunVitD: sunVitD,
  );
}

/// Création des groupes de métriques en respectant ton cahier des charges
BilanData _buildMetricGroups({
  required DateTime from,
  required DateTime to,
  required bool isAverage,
  required double kcal,
  required double prot,
  required double carb,
  required double fat,
  required double fiber,
  required Map<String, double> micros,
  required _GoalsRaw goals,
  required HydrationData hydration,
  required List<DailyEnergyPoint> dailyEnergy,
  double sunVitD = 0.0,
}) {
  double m(String key) => micros[key] ?? 0.0;

  // Objectifs macros
  final goalKcal = goals.kcal <= 0 ? 2000.0 : goals.kcal;
  final goalProt = goals.prot <= 0 ? 120.0 : goals.prot;
  final goalCarb = goals.carb > 0 ? goals.carb : (goalKcal * 0.55) / 4.0;
  final goalFat  = goals.fat > 0 ? goals.fat : (goalKcal * 0.35) / 9.0;
  final goalFiber = goals.fiber > 0 ? goals.fiber : 30.0;

  // EFA — lus directement depuis les cibles sauvegardées (profile.dart)
  final goalO9  = goals.o9;
  final goalLA  = goals.o6;
  final goalALA = goals.o3;
  final goalEPA = goals.epa;
  final goalDHA = goals.dha;

  // À surveiller
  final goalSat    = goals.sat;
  final goalSugars = goals.sugars;
  final goalSalt   = goals.salt;

  // Objectifs vitamines — ajustés âge/sexe (déjà calculés dans profile.dart)
  final vitTargets = <String, double>{
    'Rétinol': goals.vitAUg,
    'Bêta-car.': goals.vitBetacarUg,
    'Vit D': goals.vitDUg,
    'Vit E': goals.vitEMg,
    'Vit K': goals.vitKUg,
    'Vit C': goals.vitCMg,
    'B1': goals.b1Mg,
    'B2': goals.b2Mg,
    'B3': goals.b3Mg,
    'B5': goals.b5Mg,
    'B6': goals.b6Mg,
    'B9': goals.b9Ug,
    'B12': goals.b12Ug,
  };

  // Objectifs minéraux — ajustés âge/sexe/activité (déjà calculés dans profile.dart)
  final minTargets = <String, double>{
    'Calcium': goals.caMg,
    'Cuivre': goals.cuMg,
    'Fer': goals.feMg,
    'Iode': goals.iUg,
    'Magnésium': goals.mgMg,
    'Manganèse': goals.mnMg,
    'Phosphore': goals.pMg,
    'Potassium': goals.kMg,
    'Sélénium': goals.seUg,
    'Sodium': goals.naMg,
    'Zinc': goals.znMg,
  };

  // Groupes

  final macrosGroup = MetricGroup(
    title: 'Macro-cibles',
    icon: Icons.bolt,
    metrics: [
      Metric('Énergie',   kcal,      goalKcal, 'kcal', 0),
      Metric('Protéines', prot,      goalProt, 'g',    1, ficheKey: 'proteines'),
      Metric('Glucides',  carb,      goalCarb, 'g',    1, ficheKey: 'glucides'),
      Metric('Lipides',   fat,       goalFat,  'g',    1, ficheKey: 'lipides'),
      Metric('Fibres',    fiber,     goalFiber,'g',    1, ficheKey: 'fibres'),
    ],
  );

  final efasGroup = MetricGroup(
    title: 'Acides gras essentiels',
    icon: Icons.opacity,
    metrics: [
      Metric('Oméga 9 (Oléique)', m('Acide_oléique_W9_g_100g'),           goalO9,  'g', 2, ficheKey: 'omega9'),
      Metric('Oméga 6 (LA)',      m('Acide_linoléique_W6_LA_g_100g'),     goalLA,  'g', 2, ficheKey: 'omega6'),
      Metric('Oméga 3 (ALA)',     m('Acide_alpha-linolénique_W3_ALA_g_100g'), goalALA, 'g', 2, ficheKey: 'omega3'),
      Metric('EPA',               m('EPA_g_100g'),                         goalEPA,'g', 2, ficheKey: 'epa'),
      Metric('DHA',               m('DHA_g_100g'),                         goalDHA,'g', 2, ficheKey: 'dha'),
    ],
  );

  final watchGroup = MetricGroup(
    title: 'À surveiller',
    icon: Icons.visibility_outlined,
    isWatch: true,
    metrics: [
      Metric('AG saturés', m('AG_saturés_g_100g'), goalSat,    'g', 2, ficheKey: 'agsatures'),
      Metric('Sucres',     m('Sucres_g_100g'),     goalSugars, 'g', 1, ficheKey: 'sucres'),
      Metric('Sel',        m('Sel_g_100g'),        goalSalt,   'g', 1, ficheKey: 'sel'),
      // Lignes conditionnelles : n'apparaissent que si consommées
      if (m('Polyols_g_100g') > 0.05)
        Metric('Polyols', m('Polyols_g_100g'), null, 'g', 1, ficheKey: 'polyols'),
      if (m('Alcool_g_100g') > 0.05)
        Metric('Alcool', m('Alcool_g_100g'), null, 'g', 1, ficheKey: 'alcool'),
    ],
  );

  final vitaminsGroup = MetricGroup(
    title: 'Vitamines',
    icon: Icons.wb_sunny_outlined,
    metrics: [
      Metric('Rétinol',   m('Rétinol_µg_100g'),        vitTargets['Rétinol'],   'µg', 0, ul: _kUlRetinolUg, ficheKey: 'retinol'),
      Metric('Bêta-car.', m('Beta-Carotène_µg_100g'),  vitTargets['Bêta-car.'], 'µg', 0, ficheKey: 'betacarotene'),
      Metric('Vit D', m('Vitamine_D_µg_100g') + sunVitD, vitTargets['Vit D'], 'µg', 0, ul: _kUlVitDUg, ficheKey: 'vitd'),
      Metric('Vit E', m('Vitamine_E_mg_100g'),        vitTargets['Vit E'], 'mg', 1, ul: _kUlVitEMg, ficheKey: 'vite'),
      Metric('Vit K', m('Vitamine_K1_µg_100g') + m('Vitamine_K2_µg_100g'), vitTargets['Vit K'], 'µg', 0, ficheKey: 'vitk'),
      Metric('Vit C', m('Vitamine_C_mg_100g'),        vitTargets['Vit C'], 'mg', 0, ficheKey: 'vitc'),
      Metric('B1',    m('Vitamine_B1_mg_100g'),       vitTargets['B1'],    'mg', 1, ficheKey: 'b1'),
      Metric('B2',    m('Vitamine_B2_mg_100g'),       vitTargets['B2'],    'mg', 1, ficheKey: 'b2'),
      Metric('B3',    m('Vitamine_B3_mg_100g'),       vitTargets['B3'],    'mg', 1, ficheKey: 'b3'),
      Metric('B5',    m('Vitamine_B5_mg_100g'),       vitTargets['B5'],    'mg', 1, ficheKey: 'b5'),
      Metric('B6',    m('Vitamine_B6_mg_100g'),       vitTargets['B6'],    'mg', 1, ul: _kUlB6Mg, ficheKey: 'b6'),
      Metric('B9',    m('Vitamine_B9_µg_100g'),       vitTargets['B9'],    'µg', 0, ficheKey: 'b9'),
      Metric('B12',   m('Vitamine_B12_µg_100g'),      vitTargets['B12'],   'µg', 0, ficheKey: 'b12'),
    ],
  );

  final mineralsGroup = MetricGroup(
    title: 'Minéraux',
    icon: Icons.diamond_outlined,
    metrics: [
      Metric('Calcium',   m('Calcium_mg_100g'),   minTargets['Calcium'],   'mg', 0, ul: _kUlCalciumMg, ficheKey: 'calcium'),
      Metric('Cuivre',    m('Cuivre_mg_100g'),    minTargets['Cuivre'],    'mg', 1, ul: _kUlCuivreMg, ficheKey: 'cuivre'),
      Metric('Fer',       m('Fer_mg_100g'),       minTargets['Fer'],       'mg', 1, ul: _kUlFerMg, ficheKey: 'fer'),
      Metric('Iode',      m('Iode_µg_100g'),      minTargets['Iode'],      'µg', 0, ul: _kUlIodeUg, ficheKey: 'iode'),
      Metric('Magnésium', m('Magnésium_mg_100g'), minTargets['Magnésium'],'mg', 0, ficheKey: 'magnesium'),
      Metric('Manganèse', m('Manganèse_mg_100g'), minTargets['Manganèse'],'mg', 1, ficheKey: 'manganese'),
      Metric('Phosphore', m('Phosphore_mg_100g'), minTargets['Phosphore'],'mg', 0, ficheKey: 'phosphore'),
      Metric('Potassium', m('Potassium_mg_100g'), minTargets['Potassium'],'mg', 0, ficheKey: 'potassium'),
      Metric('Sélénium',  m('Sélénium_µg_100g'),  minTargets['Sélénium'], 'µg', 0, ul: _kUlSeleniumUg, ficheKey: 'selenium'),
      Metric('Sodium',    m('Sodium_mg_100g'),    minTargets['Sodium'],   'mg', 0, ficheKey: 'sodium'),
      Metric('Zinc',      m('Zinc_mg_100g'),      minTargets['Zinc'],     'mg', 1, ul: _kUlZincMg, ficheKey: 'zinc'),
    ],
  );

  final indicGroup = MetricGroup(
    title: 'Apports indicatifs',
    icon: Icons.info_outline,
    metrics: [
      Metric('Cholestérol', m('Cholestérol_mg_100g'), 1000.0, 'mg', 0, ficheKey: 'cholesterol'),
    ],
  );

    return BilanData(
    from: from,
    to: to,
    isAverage: isAverage,
    kcal: kcal,
    prot: prot,
    carb: carb,
    fat: fat,
    fiber: fiber,
    micros: micros,
    dailyEnergy: dailyEnergy,
    macrosGroup: macrosGroup,
    efasGroup: efasGroup,
    watchGroup: watchGroup,
    vitaminsGroup: vitaminsGroup,
    mineralsGroup: mineralsGroup,
    indicGroup: indicGroup,
    hydration: hydration,
    sunVitDUg: sunVitD,
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  SCORE TOTUM — calcul 0-100 + notes par sous-chapitre
// ═══════════════════════════════════════════════════════════════════════

/// Couverture d'une métrique : min(valeur/cible, 1.0), en %.
/// Part de la journée déjà renseignée, estimée par l'énergie consommée.
/// Plancher à 20 % pour éviter qu'un seul aliment donne un score parfait.
double _dayFractionFor(BilanData d) {
  final macros = d.macrosGroup.metrics;
  if (macros.isEmpty) return 1.0;
  final energy = macros.first; // 'Énergie'
  final target = energy.target ?? 0;
  if (target <= 0) return 1.0;
  return (energy.value / target).clamp(0.20, 1.0);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Couverture d'une métrique, proratisée par la part de journée renseignée.
double _coverage(Metric m, [double dayFraction = 1.0]) {
  final t = (m.target ?? 0) * dayFraction;
  if (t <= 0) return 1.0; // pas de cible → neutre
  return (m.value / t).clamp(0.0, 1.0);
}

/// Score moyen d'un groupe "couverture" (vitamines, minéraux, AGE).
double _groupCoverageScore(MetricGroup g, [double dayFraction = 1.0]) {
  final withTarget = g.metrics.where((m) => (m.target ?? 0) > 0).toList();
  if (withTarget.isEmpty) return 100.0;
  final sum =
      withTarget.fold<double>(0, (s, m) => s + _coverage(m, dayFraction));
  return (sum / withTarget.length) * 100.0;
}

/// Score "à surveiller" : rester SOUS la cible du jour (PLEINE cible, jamais
/// proratisée) = bon. Correction (Priorité 23, 10/08/2026) : la version
/// précédente proratisait la cible par `dayFraction` — pertinent pour les
/// scores de COUVERTURE (vitamines/minéraux : plus tôt dans la journée, plus
/// la barre à atteindre est basse, pour ne pas donner un score parfait
/// après un seul aliment chanceux), mais l'effet s'inverse pour "à
/// surveiller" (moins = mieux) : réduire la cible revenait à punir une
/// consommation encore faible tôt dans la journée — constaté par Alex (à
/// peine 30 % de la cible réelle au petit-déjeuner, mais note défavorable).
/// Rester sous la cible pleine à n'importe quel moment de la journée est
/// TOUJOURS un bon signal (on ne peut pas "dépasser" ce qu'on n'a pas encore
/// mangé) ; le score n'a donc besoin d'aucun ajustement au temps écoulé — il
/// évolue naturellement, à la baisse seulement si on consomme davantage.
double _watchScore(MetricGroup g) {
  final items = g.metrics.where((m) => (m.target ?? 0) > 0).toList();
  if (items.isEmpty) return 100.0;
  double sum = 0;
  for (final m in items) {
    final t = m.target ?? 1;
    final ratio = t > 0 ? m.value / t : 0.0;
    // sous la cible → 100 ; à 150% de la cible → 0 (dégradé linéaire)
    final s = (1.0 - ((ratio - 1.0) / 0.5)).clamp(0.0, 1.0);
    sum += s;
  }
  return (sum / items.length) * 100.0;
}

TotumScore _computeTotumScore(BilanData d, AppLocalizations l10n, {bool prorate = false}) {
  final f = prorate ? _dayFractionFor(d) : 1.0;

  final vit = _groupCoverageScore(d.vitaminsGroup, f);
  final min = _groupCoverageScore(d.mineralsGroup, f);
  final age = _groupCoverageScore(d.efasGroup, f);
  final watch = _watchScore(d.watchGroup);
  final hydra = ((d.hydration.ratio / f).clamp(0.0, 1.0)) * 100.0;

  // Avertissements limites de sécurité (jamais proratisés : la sécurité est absolue)
  final warnings = <String>[];
  for (final g in [d.vitaminsGroup, d.mineralsGroup]) {
    for (final m in g.metrics) {
      if (m.ul != null && m.value > m.ul!) {
        warnings.add(m.label);
      }
    }
  }

  // Pire ratio (valeur/cible du jour, jamais proratisé) parmi les éléments
  // "à surveiller" — pilote le plafond de sécurité (voir totum_score.dart,
  // _kWatchSeverityCaps). Le plafond ne dépend jamais de l'heure de la
  // journée : un dépassement réel l'est déjà, quel que soit le temps restant.
  double watchWorstRatio = 0.0;
  String? watchWorstLabel;
  for (final m in d.watchGroup.metrics) {
    final t = m.target ?? 0;
    if (t <= 0) continue;
    final ratio = m.value / t;
    if (ratio > watchWorstRatio) {
      watchWorstRatio = ratio;
      watchWorstLabel = m.label;
    }
  }

  return computeTotumScoreFromValues(
    vitamines: vit,
    mineraux: min,
    acidesGras: age,
    hydratation: hydra,
    surveiller: watch,
    warnings: warnings,
    l10n: l10n,
    dayFraction: f,
    watchWorstRatio: watchWorstRatio,
    watchWorstLabel: watchWorstLabel,
  );
}

/// Score TOTUM du jour — point d'entrée public partagé avec l'onglet Conseils.
/// Garantit que les deux onglets affichent strictement le même chiffre.
Future<TotumScore> computeTodayTotumScore(AppLocalizations l10n) async {
  final data = await _computeBilanForSpan(ReportSpan.day);
  return _computeTotumScore(data, l10n, prorate: true);
}

/// Carte premium du Score TOTUM (note + lettre + sous-scores).
class _TotumScoreCard extends StatelessWidget {
  final TotumScore score;
  final bool isDayMode;
  final DateTime day;
  final int spanDays; // 1 = jour, sinon 7 / 30 / 90
  final List<Metric> allMicros; // pour retrouver l'unité/clé d'un warning
  const _TotumScoreCard({
    required this.score,
    required this.isDayMode,
    required this.day,
    this.spanDays = 1,
    required this.allMicros,
  });

  @override
  Widget build(BuildContext context) {
    final s = score;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [s.color.withValues(alpha: 0.12), s.color.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cercle score + lettre
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.color.withValues(alpha: 0.15),
                  border: Border.all(color: s.color, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.global.round().toString(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: s.color,
                        height: 1,
                      ),
                    ),
                    Text('/ 100',
                        style: TextStyle(
                            fontSize: 10,
                            color: s.color.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.bilanScoreTitle,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TotumColors.textSecondary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.letter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.moodFor(l10n),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: s.color,
                      ),
                    ),
                    if (s.isProvisional) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TotumColors.outline,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.autorenew, size: 12, color: TotumColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.bilanScoreUpdatesLive,
                              style: TextStyle(fontSize: 11, color: TotumColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showTotumScoreExplainerSheet(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
                foregroundColor: TotumColors.textSecondary,
              ),
              icon: const Icon(Icons.help_outline, size: 15),
              label: Text(l10n.bilanScoreHowCalculated,
                  style: const TextStyle(fontSize: 11.5)),
            ),
          ),
          const SizedBox(height: 8),
          // Alerte plafond de sécurité (Priorité 24) : un dépassement sévère
          // d'un élément "à surveiller" plafonne la note globale — affiché
          // en priorité, avant même le détail par pilier, pour que ce soit
          // la première chose comprise.
          if (s.capReason != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TotumColors.negative.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TotumColors.negative.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.report_problem_rounded, size: 20, color: TotumColors.negative),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.capReason!,
                      style: TextStyle(
                          fontSize: 12.5, color: TotumColors.negative, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Sous-scores en barres, avec la note par pilier à côté — Alex a
          // clarifié (Priorité 24) que seul le badge "% de la journée
          // renseignée" le gênait, pas ces notes-là : remises en place.
          ...s.parts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(p.label,
                          style: const TextStyle(fontSize: 12.5)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (p.score / 100).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: TotumColors.outline,
                          valueColor: AlwaysStoppedAnimation(
                            p.score >= 70
                                ? TotumColors.positive
                                : p.score >= 40
                                    ? TotumColors.accent
                                    : TotumColors.negative,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text('${p.score.round()}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )),
          // Avertissements limites de sécurité
          if (s.warnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TotumColors.negative.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: TotumColors.negative.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 20, color: TotumColors.negative),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.bilanSafetyLimitExceeded(
                          s.warnings.map((w) => nutrientDisplayLabel(w, l10n)).join(", ")),
                      style: TextStyle(
                          fontSize: 12.5,
                          color: TotumColors.negative,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Détail de chaque limite dépassée — toutes périodes
            const SizedBox(height: 8),
            for (final w in s.warnings)
                Builder(builder: (context) {
                  final metric = allMicros.firstWhere(
                    (m) => m.label == w,
                    orElse: () => const Metric('', 0, null, '', 0),
                  );
                  final microKey = _kMicroKeyForLabel[w];
                  if (microKey == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TotumColors.negative,
                          side: BorderSide(color: TotumColors.negative),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () {
                          final to = DateTime(day.year, day.month, day.day);
                          final from =
                              to.subtract(Duration(days: spanDays - 1));
                          showLimiteSheet(
                            context,
                            label: w,
                            ficheKey: metric.ficheKey,
                            microKey: microKey,
                            unit: metric.unit,
                            from: from,
                            to: to,
                            periodeLabel: spanDays <= 1
                                ? context.l10n.bilanPeriodThatDay
                                : context.l10n.bilanPeriodLastNDays(spanDays),
                          );
                        },
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: Text(context.l10n.bilanUnderstandLabel(nutrientDisplayLabel(w, context.l10n))),
                      ),
                    ),
                  );
                }),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  FICHES NUTRIMENTS — contenu éducatif (chargé depuis JSON externe)
// ═══════════════════════════════════════════════════════════════════════

class NutrientFiche {
  final String titre;
  final String emoji;
  final String sousTitre;
  final String benefices;
  final String apports;
  final String limite;
  final String sources;
  final String savaisTu;
  const NutrientFiche({
    required this.titre,
    required this.emoji,
    required this.sousTitre,
    required this.benefices,
    required this.apports,
    required this.limite,
    required this.sources,
    required this.savaisTu,
  });

  factory NutrientFiche.fromJson(Map<String, dynamic> j) => NutrientFiche(
        titre: j['titre']?.toString() ?? '',
        emoji: j['emoji']?.toString() ?? '📋',
        sousTitre: j['sousTitre']?.toString() ?? '',
        benefices: j['benefices']?.toString() ?? '',
        apports: j['apports']?.toString() ?? '',
        limite: j['limite']?.toString() ?? '',
        sources: j['sources']?.toString() ?? '',
        savaisTu: j['savaisTu']?.toString() ?? '',
      );
}

class NutrientFicheRepo {
  NutrientFicheRepo._();
  static final NutrientFicheRepo instance = NutrientFicheRepo._();

  final Map<String, NutrientFiche> _fiches = {};
  String? _loadedLang;
  bool get isLoaded =>
      _fiches.isNotEmpty && _loadedLang == AppSettings.language.value;

  Future<void> load() async {
    final lang = AppSettings.language.value;
    if (isLoaded) return;
    try {
      final asset = lang == 'en'
          ? 'assets/nutrient_fiches_en.json'
          : 'assets/nutrient_fiches.json';
      final raw = await rootBundle.loadString(asset);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final f = (map['fiches'] as Map?) ?? const {};
      _fiches.clear();
      f.forEach((k, v) {
        _fiches[k.toString()] =
            NutrientFiche.fromJson(v as Map<String, dynamic>);
      });
      _loadedLang = lang;
    } catch (e) {
      debugPrint('Erreur chargement fiches: $e');
    }
  }

  NutrientFiche? get(String? key) => key == null ? null : _fiches[key];
}

// ═══════════════════════════════════════════════════════════════════════
//  LIMITES DE SÉCURITÉ — explications éducatives (JSON externe)
// ═══════════════════════════════════════════════════════════════════════

class LimiteSecurite {
  final String nutriment, limite, reference;
  final String pourquoi, consequences, sourcesRisque, queFaire, rassurance;
  const LimiteSecurite({
    required this.nutriment,
    required this.limite,
    required this.reference,
    required this.pourquoi,
    required this.consequences,
    required this.sourcesRisque,
    required this.queFaire,
    required this.rassurance,
  });

  static LimiteSecurite fromJson(Map<String, dynamic> j) => LimiteSecurite(
        nutriment: (j['nutriment'] ?? '').toString(),
        limite: (j['limite'] ?? '').toString(),
        reference: (j['reference'] ?? '').toString(),
        pourquoi: (j['pourquoi'] ?? '').toString(),
        consequences: (j['consequences'] ?? '').toString(),
        sourcesRisque: (j['sources_risque'] ?? '').toString(),
        queFaire: (j['que_faire'] ?? '').toString(),
        rassurance: (j['rassurance'] ?? '').toString(),
      );
}

class LimitesRepo {
  LimitesRepo._();
  static final LimitesRepo instance = LimitesRepo._();

  final Map<String, LimiteSecurite> _lim = {};
  String? _loadedLang;
  bool get isLoaded =>
      _lim.isNotEmpty && _loadedLang == AppSettings.language.value;

  Future<void> load() async {
    final lang = AppSettings.language.value;
    if (isLoaded) return;
    try {
      final asset = lang == 'en'
          ? 'assets/limites_securite_en.json'
          : 'assets/limites_securite.json';
      final raw = await rootBundle.loadString(asset);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final l = (map['limites'] as Map?) ?? const {};
      _lim.clear();
      l.forEach((k, v) {
        _lim[k.toString()] =
            LimiteSecurite.fromJson(Map<String, dynamic>.from(v as Map));
      });
      _loadedLang = lang;
    } catch (e) {
      debugPrint('Erreur chargement limites: $e');
    }
  }

  LimiteSecurite? get(String? key) => key == null ? null : _lim[key];
}

/// Contributions agrégées sur une PÉRIODE (1 à 90 jours).
/// Une seule requête Supabase pour toute la plage, puis fusion par aliment.
Future<List<_FoodContribution>> _contributorsForRange(
  DateTime from,
  DateTime to,
  String microKey,
  AppLocalizations l10n,
) async {
  // Vitamine K : K1 et K2 sont deux colonnes CIQUAL distinctes mais une
  // seule "vitamine K" côté utilisateur (comme partout ailleurs dans
  // l'app) — on additionne la contribution K2 quand on nous demande K1.
  final extraKey =
      microKey == 'Vitamine_K1_µg_100g' ? 'Vitamine_K2_µg_100g' : null;
  await _ensureFoodsLoaded();
  final repo = foods_loader.FoodsRepository.instance;
  final sp = await SharedPreferences.getInstance();

  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  foods_loader.FoodItem? findFood(String id) => repo.findById(id);

  final agg = <String, double>{};
  void add(String name, double amount) {
    if (amount <= 0) return;
    agg[name] = (agg[name] ?? 0) + amount;
  }

  bool fromSupabase = false;
  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> rows = await _client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .gte('entry_date', ymd(from))
          .lte('entry_date', ymd(to));
      for (final r in rows) {
        final id = (r['food_id'] ?? '').toString();
        final name = (r['food_name'] ?? l10n.bilanUnnamedFood).toString();
        final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0.0;
        double amount = 0.0;
        // Les macros sont stockées en colonnes dédiées (déjà en grammes consommés),
        // pas dans le snapshot micros.
        const macroCols = {
          'Protéines_g_100g': 'protein_g',
          'Glucides_g_100g': 'carbs_g',
          'Lipides_g_100g': 'fat_g',
          'Fibres_g_100g': 'fiber_g',
        };
        double amountForKey(String key) {
          if (macroCols.containsKey(key)) {
            final v = r[macroCols[key]];
            return (v is num) ? v.toDouble() : 0.0;
          }
          final snap = r['micros'];
          if (snap is Map && snap[key] != null) {
            return (snap[key] is num) ? (snap[key] as num).toDouble() : 0.0;
          } else if (id.isNotEmpty) {
            final food = findFood(id);
            if (food != null) return food.microsFor(grams)[key] ?? 0.0;
          }
          return 0.0;
        }
        amount = amountForKey(microKey);
        if (extraKey != null) amount += amountForKey(extraKey);
        add(name, amount);
      }
      if (rows.isNotEmpty) fromSupabase = true;
    }
  } catch (_) {}

  // Repli local uniquement si Supabase n'a rien renvoyé.
  if (!fromSupabase) {
    try {
      var d = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day);
      while (!d.isAfter(end)) {
        final raw = sp.getString(_journalKeyForDate(d));
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          for (final meal in decoded.keys) {
            final list = (decoded[meal] as List?) ?? [];
            for (final e in list) {
              final entry = Map<String, dynamic>.from(e as Map);
              final id = (entry['id'] ?? '').toString();
              final name = (entry['name'] ?? l10n.bilanUnnamedFood).toString();
              final grams = (entry['grams'] as num?)?.toDouble() ?? 0.0;
              const macroLocal = {
                'Protéines_g_100g': 'prot',
                'Glucides_g_100g': 'carb',
                'Lipides_g_100g': 'fat',
                'Fibres_g_100g': 'fiber',
              };
              double amountForKey(String key) {
                if (macroLocal.containsKey(key)) {
                  final v = entry[macroLocal[key]];
                  return (v is num) ? v.toDouble() : 0.0;
                }
                final food = findFood(id);
                if (food != null) return food.microsFor(grams)[key] ?? 0.0;
                return 0.0;
              }
              var amount = amountForKey(microKey);
              if (extraKey != null) amount += amountForKey(extraKey);
              add(name, amount);
            }
          }
        }
        d = d.add(const Duration(days: 1));
      }
    } catch (_) {}
  }

  final out = agg.entries.map((e) => _FoodContribution(e.key, e.value)).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return out;
}

Widget _limBloc(String titre, String corps, Color couleur) {
  if (corps.trim().isEmpty) return const SizedBox.shrink();
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: couleur, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: couleur)),
        const SizedBox(height: 6),
        Text(corps,
            style: TextStyle(
                fontSize: 13.5, height: 1.5, color: TotumColors.textPrimary)),
      ],
    ),
  );
}

/// Feuille détaillée d'une limite dépassée : explication + top 10 des aliments.
void showLimiteSheet(
  BuildContext context, {
  required String label,
  required String? ficheKey,
  required String microKey,
  required String unit,
  required DateTime from,
  required DateTime to,
  required String periodeLabel,
}) {
  final lim = LimitesRepo.instance.get(ficheKey);
  final l10n = context.l10n;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TotumColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TotumColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: TotumColors.negative, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lim?.nutriment ?? nutrientDisplayLabel(label, l10n),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900, height: 1.2),
                ),
              ),
            ],
          ),
          if (lim != null) ...[
            const SizedBox(height: 4),
            Text(l10n.bilanSafetyLimitDetail(lim.limite, lim.reference),
                style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary)),
            const SizedBox(height: 16),
            _limBloc(l10n.bilanWhyLimitExists, lim.pourquoi,
                TotumColors.accent),
            _limBloc(l10n.bilanExcessConsequences,
                lim.consequences, TotumColors.accent),
            _limBloc(l10n.bilanExcessSource, lim.sourcesRisque,
                TotumColors.accent),
            _limBloc(l10n.bilanWhatToDo, lim.queFaire,
                TotumColors.accent),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TotumColors.positive.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite_outline,
                      size: 18, color: TotumColors.positive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(lim.rassurance,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: TotumColors.textPrimary)),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 16),
          Divider(height: 1, color: TotumColors.outline),
          const SizedBox(height: 16),
          Text(l10n.bilanConcernedFoods(periodeLabel),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          FutureBuilder<List<_FoodContribution>>(
            future: _contributorsForRange(from, to, microKey, l10n),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data ?? const <_FoodContribution>[];
              if (list.isEmpty) {
                return Text(
                  l10n.bilanNoFoodIdentifiedPeriod,
                  style: TextStyle(fontSize: 13, color: TotumColors.textSecondary),
                );
              }
              final top = list.take(10).toList();
              final maxAmount = top.first.amount;
              return Column(
                children: [
                  for (int i = 0; i < top.length; i++)
                    _contributorRow(i + 1, top[i], unit, maxAmount),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Panneau détaillé de la répartition des glucides (amidon vs sucres simples).
void showGlucidesBreakdown(BuildContext context, Map<String, double> micros,
    {String portionLabel = ''}) {
  final l10n = context.l10n;
  double v(String k) => micros[k] ?? 0.0;
  final amidon = v('Amidon_g_100g');
  final fructose = v('Fructose_g_100g');
  final glucose = v('Glucose_g_100g');
  final saccharose = v('Saccharose_g_100g');
  final lactose = v('Lactose_g_100g');
  final maltose = v('Maltose_g_100g');
  final galactose = v('Galactose_g_100g');
  final sucresTotal =
      fructose + glucose + saccharose + lactose + maltose + galactose;
  final polyols = v('Polyols_g_100g');
  final total = amidon + sucresTotal + polyols;

  Widget bar(String label, double val, Color color, {String? hint}) {
    final pct = total > 0 ? (val / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
              Text('${val.toStringAsFixed(1)} g',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint,
                style: TextStyle(fontSize: 11, color: TotumColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TotumColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TotumColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.bilanCarbBreakdownTitle,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          if (portionLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(portionLabel,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: TotumColors.accent)),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.bilanCarbBreakdownIntro,
            style: TextStyle(fontSize: 13, color: TotumColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (total <= 0)
            Text(
              l10n.bilanNoCarbDataPeriod,
              style: TextStyle(fontSize: 13, color: TotumColors.textSecondary),
            )
          else ...[
            bar(l10n.bilanStarchLabel, amidon,
                TotumColors.accent,
                hint: l10n.bilanStarchHint),
            bar(l10n.bilanSimpleSugarsLabel, sucresTotal,
                TotumColors.accent,
                hint: l10n.bilanSimpleSugarsHint),
            if (polyols > 0.05)
              bar(nutrientDisplayLabel('Polyols', l10n), polyols, TotumColors.accent,
                  hint: l10n.bilanPolyolsHint),
            const SizedBox(height: 8),
            Divider(color: TotumColors.outline),
            const SizedBox(height: 12),
            Text(l10n.bilanSimpleSugarsDetailTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (fructose > 0.05)
              bar('Fructose', fructose, TotumColors.accent,
                  hint: l10n.bilanFructoseHint),
            if (glucose > 0.05)
              bar('Glucose', glucose, TotumColors.accent),
            if (saccharose > 0.05)
              bar(l10n.bilanSaccharoseLabel, saccharose, TotumColors.accent,
                  hint: l10n.bilanSaccharoseHint),
            if (lactose > 0.05)
              bar('Lactose', lactose, TotumColors.accent,
                  hint: l10n.bilanLactoseHint),
            if (maltose > 0.05)
              bar('Maltose', maltose, TotumColors.accent),
            if (galactose > 0.05)
              bar('Galactose', galactose, TotumColors.accent),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TotumColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.bilanFruitVsSodaNote,
                style: TextStyle(fontSize: 12.5, height: 1.5, color: TotumColors.textPrimary),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Note adaptée au régime, affichée dans la fiche nutriment concernée.
/// diet : 0 = omnivore (aucune note), 1 = végétarien, 2 = végétalien.
String? _dietFicheNote(String ficheKey, int diet, AppLocalizations l10n) {
  if (diet == 0) return null;
  switch (ficheKey) {
    case 'omega3_marins':
    case 'epa':
    case 'dha':
      return l10n.dietNoteOmega3NoFish;
    case 'b12':
      if (diet == 2) {
        return l10n.dietNoteB12Vegan;
      }
      return l10n.dietNoteB12Vegetarian;
    case 'fer':
      return l10n.dietNoteIronVegetal;
    case 'zinc':
      return l10n.dietNoteZincVegetal;
    case 'calcium':
      if (diet == 2) {
        return l10n.dietNoteCalciumVegan;
      }
      return null;
    case 'iode':
      if (diet == 2) {
        return l10n.dietNoteIodineVegan;
      }
      return null;
    case 'vitd':
      if (diet == 2) {
        return l10n.dietNoteVitDVegan;
      }
      return null;
    case 'proteines':
      if (diet == 2) {
        return l10n.dietNoteProteinVegan;
      }
      return null;
    default:
      return null;
  }
}

/// Ouvre la fiche explicative d'un nutriment en bottom sheet.
Future<void> showNutrientFiche(BuildContext context, String ficheKey) async {
  final fiche = NutrientFicheRepo.instance.get(ficheKey);
  if (fiche == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.bilanFicheUnavailable)),
    );
    return;
  }
  final int diet =
      (await SharedPreferences.getInstance()).getInt('profile_diet') ?? 0;
  if (!context.mounted) return;
  final l10n = context.l10n;
  final String? dietNote = _dietFicheNote(ficheKey, diet, l10n);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TotumColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      const accent = TotumColors.accent;
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TotumColors.outlineStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(fiche.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fiche.titre,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        if (fiche.sousTitre.isNotEmpty)
                          Text(fiche.sousTitre,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: TotumColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ficheBloc(l10n.bilanFicheBenefits, fiche.benefices,
                  TotumColors.accent),
              _ficheBloc(l10n.bilanFicheIntakes, fiche.apports,
                  TotumColors.accent),
              if (fiche.limite.trim().isNotEmpty)
                _ficheBloc(l10n.bilanFicheSafetyLimit, fiche.limite,
                    TotumColors.accent),
              _ficheBloc(l10n.bilanFicheWhereToFind, fiche.sources,
                  TotumColors.accent),
              if (dietNote != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TotumColors.positive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: TotumColors.positive.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(diet == 2 ? Icons.eco : Icons.restaurant,
                              size: 16, color: TotumColors.positive),
                          const SizedBox(width: 6),
                          Text(
                            diet == 2
                                ? l10n.bilanDietAdaptedVegan
                                : l10n.bilanDietAdaptedVegetarian,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: TotumColors.positive),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(dietNote,
                          style: const TextStyle(fontSize: 13.5, height: 1.45)),
                    ],
                  ),
                ),
              if (fiche.savaisTu.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      TotumColors.accent.withValues(alpha: 0.10),
                      TotumColors.accent.withValues(alpha: 0.03),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: TotumColors.accentBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 17, color: TotumColors.accent),
                          const SizedBox(width: 6),
                          Text(l10n.bilanDidYouKnow,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: TotumColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(fiche.savaisTu,
                          style: const TextStyle(
                              fontSize: 13.5, height: 1.45)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l10n.bilanEducationalDisclaimer,
                style: TextStyle(fontSize: 11, color: TotumColors.textMuted),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _ficheBloc(String titre, String corps, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre,
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: 5),
        Text(corps,
            style: TextStyle(
                fontSize: 13.5, height: 1.45, color: TotumColors.textPrimary)),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  TRAÇABILITÉ — aliments responsables d'un dépassement de limite
// ═══════════════════════════════════════════════════════════════════════

class _FoodContribution {
  final String name;
  final double amount; // contribution au micro (dans son unité)
  const _FoodContribution(this.name, this.amount);
}

/// Map label affiché (ex "Fer") → clé micro CSV (ex "Fer_mg_100g").
const Map<String, String> _kMicroKeyForLabel = {
  'Fer': 'Fer_mg_100g',
  'Zinc': 'Zinc_mg_100g',
  'Sélénium': 'Sélénium_µg_100g',
  'Rétinol': 'Rétinol_µg_100g',
  'Vit D': 'Vitamine_D_µg_100g',
  'Vit E': 'Vitamine_E_mg_100g',
  'B6': 'Vitamine_B6_mg_100g',
  'Calcium': 'Calcium_mg_100g',
  'Cuivre': 'Cuivre_mg_100g',
  'Iode': 'Iode_µg_100g',
};

/// Correspondance complète label du Bilan → clé de colonne CSV, pour retrouver
/// les aliments consommés qui contiennent chaque nutriment.
/// Les emojis des macros sont retirés à la lecture (voir _microKeyForAnyLabel).
const Map<String, String> _kAllLabelToKey = {
  'Protéines': 'Protéines_g_100g',
  'Glucides': 'Glucides_g_100g',
  'Lipides': 'Lipides_g_100g',
  'Fibres': 'Fibres_g_100g',
  'Oméga 9 (Oléique)': 'Acide_oléique_W9_g_100g',
  'Oméga 6 (LA)': 'Acide_linoléique_W6_LA_g_100g',
  'Oméga 3 (ALA)': 'Acide_alpha-linolénique_W3_ALA_g_100g',
  'EPA': 'EPA_g_100g',
  'DHA': 'DHA_g_100g',
  'AG saturés': 'AG_saturés_g_100g',
  'Sucres': 'Sucres_g_100g',
  'Sel': 'Sel_g_100g',
  'Polyols': 'Polyols_g_100g',
  'Alcool': 'Alcool_g_100g',
  'Rétinol': 'Rétinol_µg_100g',
  'Bêta-car.': 'Beta-Carotène_µg_100g',
  'Vit D': 'Vitamine_D_µg_100g',
  'Vit E': 'Vitamine_E_mg_100g',
  'Vit K': 'Vitamine_K1_µg_100g',
  'Vit C': 'Vitamine_C_mg_100g',
  'B1': 'Vitamine_B1_mg_100g',
  'B2': 'Vitamine_B2_mg_100g',
  'B3': 'Vitamine_B3_mg_100g',
  'B5': 'Vitamine_B5_mg_100g',
  'B6': 'Vitamine_B6_mg_100g',
  'B9': 'Vitamine_B9_µg_100g',
  'B12': 'Vitamine_B12_µg_100g',
  'Calcium': 'Calcium_mg_100g',
  'Cuivre': 'Cuivre_mg_100g',
  'Fer': 'Fer_mg_100g',
  'Iode': 'Iode_µg_100g',
  'Magnésium': 'Magnésium_mg_100g',
  'Manganèse': 'Manganèse_mg_100g',
  'Phosphore': 'Phosphore_mg_100g',
  'Potassium': 'Potassium_mg_100g',
  'Sélénium': 'Sélénium_µg_100g',
  'Sodium': 'Sodium_mg_100g',
  'Zinc': 'Zinc_mg_100g',
  'Cholestérol': 'Cholestérol_mg_100g',
};

/// Retrouve la clé CSV d'un label, en ignorant l'emoji et les espaces de tête.
String? _microKeyForAnyLabel(String label) {
  final clean = label.replaceAll(RegExp(r'^[^\p{L}]+', unicode: true), '').trim();
  return _kAllLabelToKey[clean];
}

/// Feuille générique : les aliments CONSOMMÉS qui contiennent un nutriment,
/// classés par quantité apportée (décroissant). C'est le miroir de ce que
/// l'utilisateur a réellement mangé, pas une liste de suggestions.
/// Détail de l'apport en vitamine D par le SOLEIL sur la période affichée —
/// distinct de `showConsumedFoodsSheet` (aliments) : le soleil n'est pas un
/// aliment, mais sa contribution est bien additionnée dans la valeur "Vit D"
/// affichée (voir `_buildMetricGroups`). Demandé par Alex : avoir un visuel
/// explicite confirmant que la vitamine D solaire est bien prise en compte,
/// séparément de l'alimentaire.
/// Explique en langage simple comment la note globale est calculée —
/// demandé par Alex : synthétique, immédiatement compréhensible, justifié
/// (Priorité 24). Contenu statique, ne dépend d'aucune donnée du jour.
void showTotumScoreExplainerSheet(BuildContext context) {
  final l10n = context.l10n;
  Widget pillarRow(String label, String pct, String detail) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: TotumColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(pct,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TotumColors.accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Text(detail, style: TextStyle(fontSize: 12, color: TotumColors.textSecondary, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TotumColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: TotumColors.outline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.insights, color: TotumColors.accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.bilanScoreExplainerTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.bilanScoreExplainerIntro,
            style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          pillarRow(l10n.scorePillarVitamins, '22%', l10n.bilanPillarVitaminsDetail),
          pillarRow(l10n.scorePillarMinerals, '22%', l10n.bilanPillarMineralsDetail),
          pillarRow(l10n.bilanPillarFattyAcidsFull, '18%', l10n.bilanPillarFattyAcidsDetail),
          pillarRow(l10n.scorePillarHydration, '13%', l10n.bilanPillarHydrationDetail),
          pillarRow(l10n.scorePillarWatch, '25%', l10n.bilanPillarWatchDetail),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TotumColors.negative.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TotumColors.negative.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.report_problem_rounded, size: 17, color: TotumColors.negative),
                    const SizedBox(width: 6),
                    Text(l10n.bilanSafetyCapTitle,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.negative)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.bilanSafetyCapExplainer,
                  style: TextStyle(fontSize: 12, color: TotumColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.autorenew, size: 16, color: TotumColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.bilanScoreLiveNote,
                  style: TextStyle(fontSize: 12, color: TotumColors.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.bilanScoreSourcesNote,
            style: TextStyle(fontSize: 10.5, color: TotumColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
  );
}

void showSunVitDSheet(
  BuildContext context, {
  required double sunVitDUg,
  required DateTime from,
  required DateTime to,
  required bool isAverage,
  required String periodeLabel,
}) {
  const sunColor = Color(0xFFF9A825);
  final l10n = context.l10n;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TotumColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TotumColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: sunColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.bilanSunVitDTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAverage
                ? l10n.bilanSunVitDAverageDesc(periodeLabel)
                : l10n.bilanSunVitDSingleDesc(periodeLabel),
            style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sunColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sunColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(
                  '${sunVitDUg.toStringAsFixed(1)} µg',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: sunColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sunVitDUg > 0
                        ? l10n.bilanSunVitDAlreadyCounted
                        : l10n.bilanSunVitDNoSession,
                    style: TextStyle(fontSize: 12.5, color: TotumColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: sunColor,
                side: const BorderSide(color: sunColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SunVitaminDScreen()),
                );
              },
              icon: const Icon(Icons.wb_sunny_outlined),
              label: Text(l10n.bilanLogSunExposure),
            ),
          ),
        ],
      ),
    ),
  );
}

void showConsumedFoodsSheet(
  BuildContext context, {
  required String label,
  required String microKey,
  required String unit,
  required DateTime from,
  required DateTime to,
  required String periodeLabel,
}) {
  final l10n = context.l10n;
  final displayLabel = nutrientDisplayLabel(label, l10n);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TotumColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TotumColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.restaurant_menu,
                  color: TotumColors.accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayLabel.replaceAll(RegExp(r'^[^\p{L}]+', unicode: true), '').trim(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.bilanConsumedPeriod(periodeLabel),
              style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary)),
          const SizedBox(height: 16),
          FutureBuilder<List<_FoodContribution>>(
            future: _contributorsForRange(from, to, microKey, l10n),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data ?? const <_FoodContribution>[];
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TotumColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.bilanNoFoodContainedNutrient,
                    style: TextStyle(
                        fontSize: 13, height: 1.5, color: TotumColors.textPrimary),
                  ),
                );
              }
              final top = list.take(12).toList();
              final maxAmount = top.first.amount;
              return Column(
                children: [
                  for (int i = 0; i < top.length; i++)
                    _contributorRow(i + 1, top[i], unit, maxAmount,
                        accent: TotumColors.accent),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Recalcule, pour un jour donné, la contribution de chaque aliment à un
/// micronutriment précis. Renvoie la liste triée (plus gros contributeur d'abord).
Future<List<_FoodContribution>> _contributorsForMicro(
  DateTime day,
  String microKey,
  AppLocalizations l10n,
) async {
  await _ensureFoodsLoaded();
  final repo = foods_loader.FoodsRepository.instance;
  final sp = await SharedPreferences.getInstance();

  final y = day.year.toString().padLeft(4, '0');
  final mo = day.month.toString().padLeft(2, '0');
  final dd = day.day.toString().padLeft(2, '0');
  final ymd = '$y-$mo-$dd';

  foods_loader.FoodItem? findFood(String id) => repo.findById(id);

  final contributions = <_FoodContribution>[];

  // 1) Supabase
  try {
    final user = _client.auth.currentUser;
    if (user != null) {
      final List<Map<String, dynamic>> rows = await _client
          .from('food_entries')
          .select()
          .eq('user_id', user.id)
          .eq('entry_date', ymd);
      for (final r in rows) {
        final id = (r['food_id'] ?? '').toString();
        final name = (r['food_name'] ?? l10n.bilanUnnamedFood).toString();
        final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0.0;
        double amount = 0.0;
        final snap = r['micros'];
        if (snap is Map && snap[microKey] != null) {
          amount = (snap[microKey] is num)
              ? (snap[microKey] as num).toDouble()
              : 0.0;
        } else if (id.isNotEmpty) {
          final food = findFood(id);
          if (food != null) {
            amount = food.microsFor(grams)[microKey] ?? 0.0;
          }
        }
        if (amount > 0) contributions.add(_FoodContribution(name, amount));
      }
      if (contributions.isNotEmpty) {
        contributions.sort((a, b) => b.amount.compareTo(a.amount));
        return contributions;
      }
    }
  } catch (_) {}

  // 2) Fallback local
  try {
    final raw = sp.getString(_journalKeyForDate(day));
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final meal in decoded.keys) {
        final list = (decoded[meal] as List?) ?? [];
        for (final e in list) {
          final entry = Map<String, dynamic>.from(e as Map);
          final id = (entry['id'] ?? '').toString();
          final name = (entry['name'] ?? l10n.bilanUnnamedFood).toString();
          final grams = (entry['grams'] as num?)?.toDouble() ?? 0.0;
          final food = findFood(id);
          if (food != null) {
            final amount = food.microsFor(grams)[microKey] ?? 0.0;
            if (amount > 0) {
              contributions.add(_FoodContribution(name, amount));
            }
          }
        }
      }
    }
  } catch (_) {}

  contributions.sort((a, b) => b.amount.compareTo(a.amount));
  return contributions;
}

/// Ouvre la liste des aliments responsables d'un dépassement, en bottom sheet.
void showContributorsSheet(
  BuildContext context,
  String label,     // "Fer"
  String microKey,  // "Fer_mg_100g"
  String unit,      // "mg"
  DateTime day,
) {
  final l10n = context.l10n;
  final displayLabel = nutrientDisplayLabel(label, l10n);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TotumColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final accent = TotumColors.negative;
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => FutureBuilder<List<_FoodContribution>>(
          future: _contributorsForMicro(day, microKey, l10n),
          builder: (ctx, snap) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: TotumColors.outlineStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: accent, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.bilanIntakeMainFoods(displayLabel),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.bilanTopContributorsIntro(displayLabel),
                    style: TextStyle(fontSize: 13, color: TotumColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (snap.connectionState != ConnectionState.done)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ))
                  else if ((snap.data ?? []).isEmpty)
                    Text(l10n.bilanNoFoodIdentifiedNutrient,
                        style: TextStyle(color: TotumColors.textSecondary))
                  else ...[
                    for (int i = 0; i < snap.data!.length && i < 10; i++)
                      _contributorRow(
                        i + 1,
                        snap.data![i],
                        unit,
                        snap.data!.first.amount,
                      ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.bilanOccasionalExcessNote,
                      style: TextStyle(fontSize: 12.5, color: TotumColors.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _contributorRow(
    int rank, _FoodContribution c, String unit, double maxAmount,
    {Color? accent}) {
  final ratio = maxAmount > 0 ? (c.amount / maxAmount).clamp(0.0, 1.0) : 0.0;
  accent ??= TotumColors.negative;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(
              '${c.amount.toStringAsFixed(c.amount >= 10 ? 0 : 1)} $unit',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: accent),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.toDouble(),
            minHeight: 5,
            backgroundColor: accent.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ],
    ),
  );
}

/// Écran affichant le bilan complet d'un jour passé (ouvert au tap sur une barre).
class DayBilanScreen extends StatelessWidget {
  final DateTime day;
  const DayBilanScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final fmt = MaterialLocalizations.of(context);
    final l10n = context.l10n;
    final onDateLabel = l10n.bilanPeriodOnDate(fmt.formatMediumDate(day));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bilanDayTitle(fmt.formatMediumDate(day))),
      ),
      body: FutureBuilder<BilanData>(
        future: _computeBilanForSpan(ReportSpan.day, specificDay: day),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return Center(child: Text(l10n.bilanNoDataForDay));
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _CollapsibleCard(
                title: l10n.bilanScoreTitle,
                icon: Icons.insights,
                child: _TotumScoreCard(
                  score: _computeTotumScore(data, context.l10n,
                      prorate: _isSameDay(day, DateTime.now())),
                  isDayMode: true,
                  day: day,
                  allMicros: [
                    ...data.vitaminsGroup.metrics,
                    ...data.mineralsGroup.metrics,
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CollapsibleCard(
                title: l10n.bilanMacrosCardTitle,
                icon: Icons.bolt,
                child: _MacroOverview(
                    group: data.macrosGroup, micros: data.micros),
              ),
              const SizedBox(height: 12),
              _Section(
                title: data.efasGroup.title,
                icon: data.efasGroup.icon,
                metrics: data.efasGroup.metrics,
                isWatch: false,
                spanFrom: day,
                spanTo: day,
                periodeLabel: onDateLabel,
              ),
              _Section(
                title: data.watchGroup.title,
                icon: data.watchGroup.icon,
                metrics: data.watchGroup.metrics,
                isWatch: true,
                spanFrom: day,
                spanTo: day,
                periodeLabel: onDateLabel,
              ),
              _Section(
                title: data.vitaminsGroup.title,
                icon: data.vitaminsGroup.icon,
                metrics: data.vitaminsGroup.metrics,
                isWatch: false,
                spanFrom: day,
                spanTo: day,
                periodeLabel: onDateLabel,
                sunVitDUg: data.sunVitDUg,
              ),
              _Section(
                title: data.mineralsGroup.title,
                icon: data.mineralsGroup.icon,
                metrics: data.mineralsGroup.metrics,
                isWatch: false,
                spanFrom: day,
                spanTo: day,
                periodeLabel: onDateLabel,
              ),
              _Section(
                title: data.indicGroup.title,
                icon: data.indicGroup.icon,
                metrics: data.indicGroup.metrics,
                isWatch: false,
                spanFrom: day,
                spanTo: day,
                periodeLabel: onDateLabel,
              ),
              const SizedBox(height: 12),
              _HydrationSection(data: data.hydration),
            ],
          );
        },
      ),
    );
  }
}


/// ───────────────────────────── UI : Écran principal ─────────────────────────────

class BilanScreen extends StatefulWidget {
  const BilanScreen({super.key});

  @override
  State<BilanScreen> createState() => BilanScreenState();
}

class BilanScreenState extends State<BilanScreen> {
  static const _kSpanKey = 'bilan_last_span_idx';

  ReportSpan _span = ReportSpan.day;
  late Future<BilanData> _future;
  bool _showEnergyChart = true;
  // Dernier rapport affiché avec succès : évite de blanchir toute la page
  // vers un spinner à chaque retour sur l'onglet (main.dart appelle
  // refresh() -> nouveau `_future` à chaque switch, cf. IndexedStack) alors
  // que les anciennes données restent valables le temps du recalcul —
  // retour d'Alex (11/08/2026) : latence perçue sur Bilan/Conseils, absente
  // de Journal/Tableau de bord.
  BilanData? _lastData;

  @override
  void initState() {
    super.initState();
    NutrientFicheRepo.instance.load();      // charge les fiches explicatives
    LimitesRepo.instance.load();            // charge les explications des limites
    _future = _computeBilanForSpan(_span); // valeur par défaut immédiate
    _loadSavedSpan();                       // puis on corrige si besoin
  }

  Future<void> _loadSavedSpan() async {
    final sp = await SharedPreferences.getInstance();
    final idx = sp.getInt(_kSpanKey) ?? 0;
    final saved = ReportSpan.values[idx.clamp(0, ReportSpan.values.length - 1)];
    if (saved != _span && mounted) {
      setState(() {
        _span   = saved;
        _future = _computeBilanForSpan(saved);
      });
    }
  }

  /// Recharge le rapport affiché — appelé par main.dart à chaque retour sur
  /// cet onglet (les 4 onglets restent montés en permanence via
  /// IndexedStack pour éviter le flash au changement d'onglet, donc plus
  /// rien ne recharge automatiquement au retour comme avant).
  void refresh() {
    if (!mounted) return;
    setState(() => _future = _computeBilanForSpan(_span));
  }

  void _onSpanChanged(ReportSpan span) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSpanKey, span.index);
    setState(() {
      _span   = span;
      _future = _computeBilanForSpan(span);
    });
  }

  Future<void> _openExportDialog() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
      helpText: l10n.dataExportPeriodHelpText,
      saveText: l10n.dataExportSaveText,
    );
    if (range == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: kTotumOrange),
                const SizedBox(height: 14),
                Text(l10n.bilanGeneratingReport),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await JournalExporter.exportHtml(from: range.start, to: range.end);
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.dataExportSuccessSnackbar),
        ));
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.dataExportErrorSnackbar(e.toString())),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final segmented = <ReportSpan, Widget>{
      ReportSpan.day:
          Padding(padding: const EdgeInsets.all(8), child: Text(l10n.bilanSpanDay)),
      ReportSpan.d7:
          Padding(padding: const EdgeInsets.all(8), child: Text(l10n.bilanSpan7d)),
      ReportSpan.d30:
          Padding(padding: const EdgeInsets.all(8), child: Text(l10n.bilanSpan30d)),
      ReportSpan.d90:
          Padding(padding: const EdgeInsets.all(8), child: Text(l10n.bilanSpan90d)),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navBilan),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.dataExportSectionTitle,
            onPressed: _openExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: l10n.accountScreenTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountScreen(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CupertinoSegmentedControl<ReportSpan>(
              groupValue: _span,
              onValueChanged: _onSpanChanged,
              selectedColor: TotumColors.accent,
              borderColor: TotumColors.accent,
              pressedColor: TotumColors.accentSoft,
              unselectedColor: TotumColors.surface,
              children: segmented,
            ),
          ),
        ],
      ),
      body: FutureBuilder<BilanData>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasData) _lastData = snap.data;
          final data = _lastData;
          if (data == null) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(child: Text(l10n.bilanNoDataToDisplay));
          }

          final fmt = MaterialLocalizations.of(context);
          final range =
              '${fmt.formatShortDate(data.from)} → ${fmt.formatShortDate(data.to)}${data.isAverage ? l10n.bilanAverageSuffix : ""}';
          final periodeLabel = switch (_span) {
            ReportSpan.day => l10n.bilanPeriodToday,
            ReportSpan.d7 => l10n.bilanPeriodOver7d,
            ReportSpan.d30 => l10n.bilanPeriodOver30d,
            ReportSpan.d90 => l10n.bilanPeriodOver90d,
          };

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _computeBilanForSpan(_span);
              });
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(range,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                // 🏆 Score TOTUM du jour
                _CollapsibleCard(
                  title: l10n.bilanScoreTitle,
                  icon: Icons.insights,
                  child: _TotumScoreCard(
                    score: _computeTotumScore(data, context.l10n,
                        prorate: _span == ReportSpan.day),
                    isDayMode: _span == ReportSpan.day,
                    day: DateTime.now(),
                    spanDays: switch (_span) {
                      ReportSpan.day => 1,
                      ReportSpan.d7 => 7,
                      ReportSpan.d30 => 30,
                      ReportSpan.d90 => 90,
                    },
                    allMicros: [
                      ...data.vitaminsGroup.metrics,
                      ...data.mineralsGroup.metrics,
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 👇 Carte "Résumé graphique (kcal)" pour 7/30/90 jours
                if (_span != ReportSpan.day && data.dailyEnergy.isNotEmpty) ...[
                  _EnergyChartCard(
                    span: _span,
                    points: data.dailyEnergy,
                    goalKcal: data.macrosGroup.metrics.first.target ?? 0.0,
                    show: _showEnergyChart,
                    onToggleShow: (v) {
                      setState(() {
                        _showEnergyChart = v;
                      });
                    },
                    onDayTap: (date) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DayBilanScreen(day: date),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Bloc macro premium : donut + 4 curseurs
                _CollapsibleCard(
                  title: l10n.bilanMacrosCardTitle,
                  icon: Icons.bolt,
                  child: _MacroOverview(
                    group: data.macrosGroup,
                    micros: data.micros,
                    spanFrom: data.from,
                    spanTo: data.to,
                    periodeLabel: periodeLabel,
                  ),
                ),
                const SizedBox(height: 8),

                _Section(
                  title: data.efasGroup.title,
                  icon: data.efasGroup.icon,
                  metrics: data.efasGroup.metrics,
                  isWatch: false,
                  spanFrom: data.from,
                  spanTo: data.to,
                  periodeLabel: periodeLabel,
                ),
                _Section(
                  title: data.watchGroup.title,
                  icon: data.watchGroup.icon,
                  metrics: data.watchGroup.metrics,
                  isWatch: true,
                  spanFrom: data.from,
                  spanTo: data.to,
                  periodeLabel: periodeLabel,
                ),
                _Section(
                  title: data.vitaminsGroup.title,
                  icon: data.vitaminsGroup.icon,
                  metrics: data.vitaminsGroup.metrics,
                  isWatch: false,
                  spanFrom: data.from,
                  spanTo: data.to,
                  periodeLabel: periodeLabel,
                  isAverage: data.isAverage,
                  sunVitDUg: data.sunVitDUg,
                ),
                _Section(
                  title: data.mineralsGroup.title,
                  icon: data.mineralsGroup.icon,
                  metrics: data.mineralsGroup.metrics,
                  isWatch: false,
                  spanFrom: data.from,
                  spanTo: data.to,
                  periodeLabel: periodeLabel,
                ),
                _Section(
                  title: data.indicGroup.title,
                  icon: data.indicGroup.icon,
                  metrics: data.indicGroup.metrics,
                  isWatch: false,
                  spanFrom: data.from,
                  spanTo: data.to,
                  periodeLabel: periodeLabel,
                ),

                const SizedBox(height: 12),
                _HydrationSection(data: data.hydration),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EnergyChartCard extends StatefulWidget {
  final ReportSpan span;
  final List<DailyEnergyPoint> points;
  final double goalKcal;
  final bool show;
  final ValueChanged<bool> onToggleShow;
  final ValueChanged<DateTime>? onDayTap;

  const _EnergyChartCard({
    required this.span,
    required this.points,
    required this.goalKcal,
    required this.show,
    required this.onToggleShow,
    this.onDayTap,
  });

  @override
  State<_EnergyChartCard> createState() => _EnergyChartCardState();
}

class _EnergyChartCardState extends State<_EnergyChartCard> {
  // false = comparer à l'objectif, true = comparer à la dépense estimée par
  // le moteur adaptatif — même principe que la bascule Targets/Expenditure
  // du widget "Energy Balance" de MacroFactor (vérifié directement dans leur
  // documentation officielle), adaptée à notre propre moteur (Priorité 21).
  bool _vsExpenditure = false;

  String _titleForSpan(AppLocalizations l10n) {
    switch (widget.span) {
      case ReportSpan.d7:
        return l10n.bilanEnergyBalance7d;
      case ReportSpan.d30:
        return l10n.bilanEnergyBalance30d;
      case ReportSpan.d90:
        return l10n.bilanEnergyBalance90d;
      case ReportSpan.day:
        return l10n.bilanEnergyBalance1d;
    }
  }

  // Format simple type "4 Nov"
  String _formatShortDate(DateTime d, AppLocalizations l10n) {
    final months = [
      l10n.bilanMonthJan, l10n.bilanMonthFeb, l10n.bilanMonthMar, l10n.bilanMonthApr,
      l10n.bilanMonthMay, l10n.bilanMonthJun, l10n.bilanMonthJul, l10n.bilanMonthAug,
      l10n.bilanMonthSep, l10n.bilanMonthOct, l10n.bilanMonthNov, l10n.bilanMonthDec,
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _insightSentence(double avgDelta, bool vsExpenditure, AppLocalizations l10n) {
    final label = vsExpenditure ? l10n.bilanYourEstimatedExpenditure : l10n.bilanYourGoal;
    final scale = widget.goalKcal > 0 ? widget.goalKcal : 2000.0;
    if (avgDelta.abs() <= scale * 0.05) {
      return l10n.bilanVeryConsistent(label, avgDelta.abs().toStringAsFixed(0));
    }
    final dir = avgDelta > 0 ? l10n.bilanAboveDir : l10n.bilanBelowDir;
    return l10n.bilanAverageDeltaSummary(avgDelta.abs().toStringAsFixed(0), dir, label);
  }

  Color _insightColor(double avgDelta) {
    final scale = widget.goalKcal > 0 ? widget.goalKcal : 2000.0;
    if (avgDelta.abs() <= scale * 0.05) return TotumColors.positive;
    if (avgDelta.abs() <= scale * 0.15) return TotumColors.accent;
    return TotumColors.negative;
  }

  /// Sémantique de couleur symétrique (distance à la référence, peu importe
  /// le sens) — alignée sur celle déjà utilisée ailleurs dans cet écran pour
  /// les deltas directionnels (règle 5 de la charte, voir `_watchColor`
  /// plus haut) : mêmes 3 couleurs que partout dans l'app (accent/
  /// positive/negative), jamais une teinte propre à ce graphique. Corrige
  /// l'incohérence relevée par Alex entre l'ancien code (bande asymétrique
  /// 90-110 %, vert dès 90 %) et le ring "aujourd'hui" du Tableau de bord.
  Color _barColorFor(double value, double? ref) {
    if (ref == null || ref <= 0) return kTotumOrange;
    final dev = (value / ref) - 1.0;
    if (!dev.isFinite) return TotumColors.negative;
    final absDev = dev.abs();
    if (absDev <= 0.10) return TotumColors.positive;  // ±10 % : dans la cible
    if (absDev <= 0.25) return TotumColors.accent;    // ±10-25 % : écart modéré
    return TotumColors.negative;                       // au-delà : écart important
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final points = widget.points;
    final show = widget.show;

    // Si l'utilisateur a masqué le graphique : on affiche juste l'en-tête + switch
    if (!show) {
      return TotumCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(_titleForSpan(l10n),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Switch(value: show, onChanged: widget.onToggleShow),
          ],
        ),
      );
    }

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    // Bascule Objectif/Dépense estimée : seulement utilisable si le moteur
    // adaptatif a assez de données sur AU MOINS un jour de la période —
    // sinon on retombe silencieusement sur Objectif (aucune régression).
    final hasExpenditureData = points.any((p) => p.expenditureKcal != null);
    final vsExpenditure = _vsExpenditure && hasExpenditureData;

    // Référence par jour selon le mode choisi.
    final refs = <double?>[
      for (final p in points)
        vsExpenditure
            ? p.expenditureKcal
            : (p.goalKcal > 0 ? p.goalKcal : (widget.goalKcal > 0 ? widget.goalKcal : null)),
    ];

    final kcalValues = points.map((e) => e.kcal).toList();
    final validRefs = refs.whereType<double>().toList();
    final maxVal = [...kcalValues, ...validRefs].fold<double>(0.0, (p, e) => e > p ? e : p);
    final maxY = (maxVal <= 0) ? 200.0 : maxVal * 1.15;

    final avgKcal = kcalValues.fold(0.0, (a, b) => a + b) / kcalValues.length;

    // Écart moyen / part des jours "dans la cible" — uniquement sur les
    // jours où une référence (objectif ou dépense) est disponible.
    final withRef = <MapEntry<DailyEnergyPoint, double>>[
      for (int i = 0; i < points.length; i++)
        if (refs[i] != null && refs[i]! > 0) MapEntry(points[i], refs[i]!),
    ];
    final avgDelta = withRef.isEmpty
        ? null
        : withRef.fold(0.0, (s, e) => s + (e.key.kcal - e.value)) / withRef.length;
    final pctInZone = withRef.isEmpty
        ? null
        : (withRef.where((e) => ((e.key.kcal / e.value) - 1.0).abs() <= 0.10).length /
                withRef.length *
                100)
            .round();

    // Groupes de barres
    final barGroups = List.generate(points.length, (index) {
      final p = points[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: p.kcal,
            width: widget.span == ReportSpan.d7 ? 18 : (widget.span == ReportSpan.d30 ? 8 : 4),
            borderRadius: BorderRadius.circular(4),
            color: _barColorFor(p.kcal, refs[index]),
          ),
        ],
      );
    });

    // Ligne pointillée : uniquement en mode "Objectif" ET si l'objectif est
    // resté constant sur la période (sinon trompeur pour les jours
    // antérieurs à un changement). En mode "Dépense estimée", pas de ligne
    // unique : la dépense réelle varie chaque jour, une ligne plate serait
    // fausse — la couleur des barres et l'infobulle suffisent.
    final goalChangedDuringPeriod = points.any(
        (p) => p.goalKcal > 0 && widget.goalKcal > 0 && (p.goalKcal - widget.goalKcal).abs() > 1);
    final showDashedLine = !vsExpenditure && widget.goalKcal > 0 && !goalChangedDuringPeriod;

    final lastIndex = points.length - 1;
    final desiredLabels = () {
      switch (widget.span) {
        case ReportSpan.d7:
          return 3; // début, milieu, fin
        case ReportSpan.d30:
          return 3; // environ tous les 10 jours
        case ReportSpan.d90:
          return 9; // environ tous les 10 jours
        case ReportSpan.day:
          return 1;
      }
    }();

    final step = points.length <= 1 ? 1 : (points.length / desiredLabels).ceil();

    return TotumCard(
      accentBorder: true,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête + switch
          Row(
            children: [
              Expanded(
                child: Text(
                  _titleForSpan(l10n),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: TotumColors.textPrimary,
                  ),
                ),
              ),
              Switch(value: show, onChanged: widget.onToggleShow),
            ],
          ),

          // Bascule Objectif / Dépense estimée.
          if (hasExpenditureData) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _ModeChip(
                  label: l10n.bilanVsGoal,
                  selected: !vsExpenditure,
                  onTap: () => setState(() => _vsExpenditure = false),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: l10n.bilanVsExpenditure,
                  selected: vsExpenditure,
                  onTap: () => setState(() => _vsExpenditure = true),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          // Phrase de synthèse en langage clair — même esprit que le
          // résumé sous le widget "Energy Balance" de MacroFactor
          // ("You exceeded your targets by an average of X Calories/day").
          if (avgDelta != null)
            Text(
              _insightSentence(avgDelta, vsExpenditure, l10n),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _insightColor(avgDelta),
              ),
            ),
          const SizedBox(height: 10),

          // 📊 Graphique énergie
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                ),
                // Axes visibles (baseline gauche + bas)
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: TotumColors.outlineStrong, width: 1),
                    bottom: BorderSide(color: TotumColors.outlineStrong, width: 1),
                    right: const BorderSide(color: Colors.transparent),
                    top: const BorderSide(color: Colors.transparent),
                  ),
                ),
                titlesData: FlTitlesData(
                  // Axe Y : repères en kcal (y compris 0)
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value < 0) {
                          return const SizedBox.shrink();
                        }
                        final text = value.round().toString();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(text, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  // Axe X : dates échantillonnées (début / milieu / fin, etc.)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % step != 0 && index != lastIndex) {
                          return const SizedBox.shrink();
                        }
                        final label = _formatShortDate(points[index].date, l10n);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(label, style: const TextStyle(fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                // Ligne horizontale = objectif kcal (mode Objectif seulement)
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (showDashedLine)
                      HorizontalLine(
                        y: widget.goalKcal,
                        color: kTotumOrange.withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                      ),
                  ],
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response?.spot != null &&
                        widget.onDayTap != null) {
                      final idx = response!.spot!.touchedBarGroupIndex;
                      if (idx >= 0 && idx < points.length) {
                        widget.onDayTap!(points[idx].date);
                      }
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final idx = group.x.toInt();
                      if (idx < 0 || idx >= points.length) return null;
                      final p = points[idx];
                      final ref = refs[idx];
                      final diff = ref != null ? p.kcal - ref : null;
                      final dateStr = _formatShortDate(p.date, l10n);
                      final refLabel = vsExpenditure ? l10n.bilanExpenditureThatDay : l10n.bilanGoalThatDay;
                      String ecart = '';
                      if (ref != null && diff != null) {
                        ecart = l10n.bilanRefLabelLine(refLabel, ref.toStringAsFixed(0));
                        if (diff > 0) {
                          ecart += l10n.bilanAboveKcal(diff.toStringAsFixed(0));
                        } else if (diff < 0) {
                          ecart += l10n.bilanBelowKcal(diff.toStringAsFixed(0));
                        } else {
                          ecart += l10n.bilanRightOnTarget;
                        }
                      }
                      return BarTooltipItem(
                        '$dateStr\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${p.kcal.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          TextSpan(
                            text: ecart,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Statistiques compactes : moyenne, écart moyen, adhérence.
          Row(
            children: [
              Expanded(child: _StatChip(label: l10n.bilanAverageLabel, value: '${avgKcal.toStringAsFixed(0)} kcal/j')),
              if (avgDelta != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    label: l10n.bilanAverageDeltaLabel,
                    value: '${avgDelta >= 0 ? '+' : ''}${avgDelta.toStringAsFixed(0)} kcal/j',
                    valueColor: _insightColor(avgDelta),
                  ),
                ),
              ],
              if (pctInZone != null) ...[
                const SizedBox(width: 8),
                Expanded(child: _StatChip(label: l10n.bilanInTargetLabel, value: '$pctInZone %')),
              ],
            ],
          ),

          if (widget.span != ReportSpan.day) ...[
            const SizedBox(height: 10),
            // Légende — mêmes 3 couleurs que partout ailleurs dans l'app
            // (règle 5 de la charte), jamais une teinte propre à ce graphique.
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _LegendDot(color: TotumColors.positive, label: l10n.bilanInTargetLegend),
                _LegendDot(color: TotumColors.accent, label: l10n.bilanModerateDeltaLegend),
                _LegendDot(color: TotumColors.negative, label: l10n.bilanLargeDeltaLegend),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              goalChangedDuringPeriod && !vsExpenditure
                  ? l10n.bilanGoalChangedHint
                  : l10n.bilanTapBarHint,
              style: TextStyle(fontSize: 10.5, color: TotumColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bascule compacte Objectif / Dépense estimée (mode de comparaison des
/// barres) — même style de puce que le reste de l'app (fond accent plein
/// quand sélectionné, contour discret sinon).
class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? TotumColors.accent : TotumColors.page,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.transparent : TotumColors.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : TotumColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Petite statistique compacte (label + valeur) — 3 côte à côte sous le
/// graphique pour donner l'essentiel d'un coup d'œil, sans avoir à toucher
/// chaque barre.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: TotumColors.page,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10.5, color: TotumColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: valueColor ?? TotumColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Pastille de légende (couleur + libellé).
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10.5, color: TotumColors.textSecondary)),
      ],
    );
  }
}


/// ───────────────────────────── UI : Macro overview (donut + 4 curseurs) ─────────────────────────────

/// Enveloppe une vignette : un petit interrupteur discret en haut à droite
/// permet de masquer le contenu sans ajouter de ligne ni surcharger.
class _CollapsibleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _CollapsibleCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  State<_CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<_CollapsibleCard> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bande d'en-tête : titre à gauche, interrupteur à droite.
        // Discrète, sans carte, pour rester homogène et ne rien surcharger.
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 0, bottom: 2),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: TotumColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: TotumColors.textSecondary),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: _show,
                  onChanged: (v) => setState(() => _show = v),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _show ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: widget.child,
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _MacroOverview extends StatelessWidget {
  final MetricGroup group;
  final Map<String, double>? micros; // pour le panneau de répartition des glucides
  final DateTime? spanFrom;
  final DateTime? spanTo;
  final String? periodeLabel;
  const _MacroOverview({
    required this.group,
    this.micros,
    this.spanFrom,
    this.spanTo,
    this.periodeLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (group.metrics.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final effectivePeriodeLabel = periodeLabel ?? l10n.bilanPeriodToday;
    // On suppose : [Énergie, Protéines, Glucides, Lipides, Fibres]
    final energy = group.metrics[0];
    final others = group.metrics.skip(1).toList();

    final target = energy.target ?? 0.0;
    final pct = (target == 0)
        ? 0.0
        : (energy.value / target).clamp(0.0, double.infinity);
    final color = _barColor(pct);

    final remaining =
        target > 0 ? (target - energy.value).clamp(0.0, double.infinity) : 0.0;

    return TotumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 15, color: TotumColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.nutrientEnergy,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 94,
                  height: 94,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pct.clamp(0.02, 1.0),
                        strokeWidth: 9,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.18),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: TotumColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.bilanTargetKcal(target.toStringAsFixed(0)),
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Text(
                  l10n.bilanConsumedKcal(energy.value.toStringAsFixed(0)),
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Text(
                  l10n.bilanRemainingKcal(remaining.toStringAsFixed(0)),
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Builder(builder: (_) {
                  final excessKcal = (energy.value - target).clamp(0.0, double.infinity);
                  if (target <= 0 || energy.value <= target) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    l10n.bilanExceededByKcal(excessKcal.toStringAsFixed(0)),
                    style: TextStyle(
                        fontSize: 11,
                        color: TotumColors.negative,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: others.map((m) {
                final t = m.target ?? 0.0;
                final pct = (t == 0)
                    ? 0.0
                    : (m.value / t).clamp(0.0, double.infinity);
                final c = _barColor(pct);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                         Expanded(
                           child: Text(
                             nutrientDisplayLabel(m.label, l10n),
                             style: const TextStyle(
                               fontWeight: FontWeight.w600,
                               fontSize: 13,
                             ),
                           ),
                         ),
                         if (_microKeyForAnyLabel(m.label) != null)
                            InkWell(
                              onTap: () {
                                final to = spanTo ?? DateTime.now();
                                final from = spanFrom ?? to;
                                showConsumedFoodsSheet(
                                  context,
                                  label: m.label,
                                  microKey: _microKeyForAnyLabel(m.label)!,
                                  unit: m.unit,
                                  from: from,
                                  to: to,
                                  periodeLabel: effectivePeriodeLabel,
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.restaurant_menu,
                                    size: 16,
                                    color: TotumColors.accent
                                        .withValues(alpha: 0.8)),
                              ),
                            ),
                          if (m.label.contains('Glucides') && micros != null)
                            InkWell(
                              onTap: () =>
                                  showGlucidesBreakdown(context, micros!),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.donut_small,
                                    size: 16, color: TotumColors.accent),
                              ),
                            ),
                         if (m.ficheKey != null)
                          InkWell(
                            onTap: () =>
                                showNutrientFiche(context, m.ficheKey!),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.info_outline,
                                  size: 16,
                                  color: TotumColors.textMuted),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: c,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.02, 1.0),
                          minHeight: 9,
                          backgroundColor: c.withValues(alpha: 0.18),
                          color: c,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Builder(builder: (_) {
                        final t         = m.target ?? 0.0;
                        final remaining = (t - m.value).clamp(0.0, double.infinity);
                        final excess    = (m.value - t).clamp(0.0, double.infinity);
                        final overshot  = t > 0 && m.value > t;
                        return Text(
                          overshot
                              ? l10n.bilanMacroProgressOvershot(
                                  m.value.toStringAsFixed(m.decimals),
                                  t.toStringAsFixed(m.decimals),
                                  m.unit,
                                  excess.toStringAsFixed(m.decimals))
                              : l10n.bilanMacroProgressRemaining(
                                  m.value.toStringAsFixed(m.decimals),
                                  t.toStringAsFixed(m.decimals),
                                  m.unit,
                                  remaining.toStringAsFixed(m.decimals)),
                          style: TextStyle(
                            fontSize: 11,
                            color: overshot ? TotumColors.negative : TotumColors.textSecondary,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────────────── UI : Section générique de curseurs ─────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Metric> metrics;
  final bool isWatch;
  final DateTime? spanFrom;
  final DateTime? spanTo;
  final String? periodeLabel;
  final bool isAverage;
  // Apport solaire déjà inclus dans la valeur "Vit D" (voir _buildMetricGroups)
  // — permet d'afficher un détail séparé alimentation/soleil sur cette seule
  // ligne, sans dupliquer le calcul.
  final double sunVitDUg;
  const _Section({
    required this.title,
    required this.icon,
    required this.metrics,
    required this.isWatch,
    this.spanFrom,
    this.spanTo,
    this.periodeLabel,
    this.isAverage = false,
    this.sunVitDUg = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final effectivePeriodeLabel = periodeLabel ?? l10n.bilanPeriodToday;
    final colorOf = isWatch ? _watchColor : _barColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TotumCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: TotumColors.textSecondary,
            collapsedIconColor: TotumColors.textSecondary,
            initiallyExpanded: false,
            title: Row(
              children: [
                Icon(icon, size: 19, color: TotumColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _groupTitle(title, l10n),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: TotumColors.textPrimary),
                  ),
                ),
              ],
            ),
          children: metrics.map((m) {
            final pct = (m.target == null || m.target == 0)
                ? null
                : (m.value / m.target!).clamp(0.0, double.infinity).toDouble();
            final overUl = m.ul != null && m.value > m.ul!;
            Color effColor(double p) => overUl ? TotumColors.negative : colorOf(p);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        nutrientDisplayLabel(m.label, l10n),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_microKeyForAnyLabel(m.label) != null)
                      InkWell(
                        onTap: () {
                          final to = spanTo ?? DateTime.now();
                          final from = spanFrom ?? to;
                          showConsumedFoodsSheet(
                            context,
                            label: m.label,
                            microKey: _microKeyForAnyLabel(m.label)!,
                            unit: m.unit,
                            from: from,
                            to: to,
                            periodeLabel: effectivePeriodeLabel,
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.restaurant_menu,
                              size: 16,
                              color: TotumColors.accent.withValues(alpha: 0.8)),
                        ),
                      ),
                    // Icône soleil, uniquement sur la ligne Vitamine D — le
                    // fourchette/couteau montre déjà la part alimentaire
                    // (contributeurs food), ceci montre la part solaire déjà
                    // additionnée dans la valeur affichée (voir
                    // _buildMetricGroups, `m('Vitamine_D_µg_100g') + sunVitD`).
                    if (m.label == 'Vit D')
                      InkWell(
                        onTap: () {
                          final to = spanTo ?? DateTime.now();
                          final from = spanFrom ?? to;
                          showSunVitDSheet(
                            context,
                            sunVitDUg: sunVitDUg,
                            from: from,
                            to: to,
                            isAverage: isAverage,
                            periodeLabel: effectivePeriodeLabel,
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.wb_sunny,
                              size: 16,
                              color: Color(0xFFF9A825)),
                        ),
                      ),
                    if (m.ficheKey != null)
                      InkWell(
                        onTap: () => showNutrientFiche(context, m.ficheKey!),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.info_outline,
                              size: 16,
                              color: TotumColors.textMuted),
                        ),
                      ),
                    if (pct != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: effColor(pct).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: effColor(pct),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  if (pct != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.02, 1.0).toDouble(),
                        minHeight: 12,
                        backgroundColor: effColor(pct).withValues(alpha: 0.18),
                        color: effColor(pct),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.value.toStringAsFixed(m.decimals)} ${m.unit} / '
                      '${m.target!.toStringAsFixed(m.decimals)} ${m.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: TotumColors.textSecondary,
                      ),
                    ),
                    if (overUl)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 13, color: TotumColors.negative),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l10n.bilanExceedsSafetyLimit(
                                    m.ul!.toStringAsFixed(0), m.unit),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TotumColors.negative,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else
                    Text(
                      '${m.value.toStringAsFixed(m.decimals)} ${m.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: TotumColors.textSecondary,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          ),
        ),
      ),
    );
  }
}

/// ───────────────────────────── UI : Hydratation ─────────────────────────────

Widget _hydroPart(String label, double ml, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
          ),
          Text('${ml.toStringAsFixed(0)} ml',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    ),
  );
}

class _HydrationSection extends StatelessWidget {
  final HydrationData data;
  const _HydrationSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pct = data.ratio.clamp(0.0, double.infinity);
    final color = _barColor(pct);
    final reached = pct >= 1.0;

    return TotumCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.water_drop, size: 17, color: TotumColors.accent),
              const SizedBox(width: 6),
              Text(
                l10n.bilanHydrationTitle,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              InkWell(
                onTap: () => showNutrientFiche(context, 'hydratation'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.info_outline,
                      size: 17, color: TotumColors.textMuted),
                ),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).toStringAsFixed(0)} %',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_drink, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.02, 1.0),
                      minHeight: 10,
                      backgroundColor: color.withValues(alpha: 0.18),
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bilanHydrationOfTotal(
                  data.totalMl.toStringAsFixed(0), data.targetMl.toStringAsFixed(0)),
              style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _hydroPart(l10n.bilanDrinksLabel, data.manualMl, TotumColors.accent),
                const SizedBox(width: 8),
                _hydroPart(l10n.bilanFoodsWaterLabel, data.journalMl, TotumColors.accent),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reached
                  ? l10n.bilanHydrationGoalReached
                  : data.manualMl < 1200
                      ? l10n.bilanHydrationReminder
                      : l10n.bilanHydrationAddGlasses,
              style: TextStyle(
                fontSize: 12.5,
                color: reached ? TotumColors.positive : TotumColors.textSecondary,
                fontWeight: reached ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (data.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.bilanTopHydratingFoods,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: -6,
                children: data.sources
                    .take(8)
                    .map((s) => Chip(
                          label: Text(s,
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
    );
  }
}