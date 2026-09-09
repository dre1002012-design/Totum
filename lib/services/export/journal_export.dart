// lib/services/export/journal_export.dart
//
// Génère un rapport HTML professionnel du journal alimentaire sur une
// période donnée : profil, objectifs, synthèse macro + micronutriments,
// puis détail jour par jour. Exploitable par un diététicien / naturopathe,
// convertible en PDF via Ctrl+P dans le navigateur.
//
// Données : 1 seule requête Supabase (bulk) + micros recalculés via la
// base CIQUAL / aliments perso (foods_loader). Cibles lues depuis
// SharedPreferences (mêmes clés que le Bilan) — aucune dépendance sur
// les classes de profile.dart pour rester robuste.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../foods_loader.dart' as foods_loader;

// Import conditionnel : web → download_web.dart, mobile → download_io.dart
import 'download_stub.dart'
    if (dart.library.html) 'download_web.dart'
    if (dart.library.io) 'download_io.dart';
/// Limites supérieures de sécurité journalières (UL) — EFSA, adultes.
const double _kUlRetinolUg  = 3000.0;
const double _kUlFerMg      = 40.0;
const double _kUlZincMg     = 25.0;
const double _kUlSeleniumUg = 255.0;

class JournalExporter {
  JournalExporter._();

  static const _meals = ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _frDate(DateTime d) {
    const wd = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
    const mo = ['janvier','février','mars','avril','mai','juin','juillet',
                'août','septembre','octobre','novembre','décembre'];
    return '${wd[d.weekday - 1]} ${d.day} ${mo[d.month - 1]} ${d.year}';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _n(double v, [int dec = 0]) => v.toStringAsFixed(dec);

  /// Couleur "objectif à atteindre" (macros, vitamines, minéraux)
  static String _pctColor(double pct) {
    if (!pct.isFinite || pct < 0.5) return '#D32F2F';
    if (pct < 0.8) return '#FF7A00';
    if (pct <= 1.1) return '#F0B429';
    return '#00A047';
  }

  /// Couleur inversée "à limiter" (saturés, sucres, sel)
  static String _watchColor(double pct) {
    if (!pct.isFinite) return '#D32F2F';
    if (pct <= 1.0) return '#00A047';
    if (pct <= 1.2) return '#FF7A00';
    return '#D32F2F';
  }

  // ══════════════════════════════════════════════════════════════════
  // POINT D'ENTRÉE
  // ══════════════════════════════════════════════════════════════════
  static Future<void> exportHtml({
    required DateTime from,
    required DateTime to,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // ── 1. Bulk fetch Supabase ─────────────────────────────────────
    // Limite explicite (21/08/2026, même correctif que calibration_service.dart/
    // bilan_screen.dart ce jour-là) : garde-fou contre le plafond de lignes
    // par défaut de PostgREST/Supabase sur un export portant sur une longue
    // période et une saisie très granulaire (aliment par aliment).
    final List<dynamic> rawRows = await client
        .from('food_entries')
        .select()
        .eq('user_id', user.id)
        .gte('entry_date', _ymd(from))
        .lte('entry_date', _ymd(to))
        .order('entry_date')
        .limit(10000);

    // Groupement : date → repas → entrées
    final byDate = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final raw in rawRows) {
      final r = Map<String, dynamic>.from(raw as Map);
      final d = (r['entry_date'] ?? '').toString();
      final meal = (r['meal_type'] ?? 'Déjeuner').toString();
      if (d.isEmpty) continue;
      byDate.putIfAbsent(d, () => {});
      byDate[d]!.putIfAbsent(meal, () => []).add(r);
    }

    // ── 2. Chargement base aliments (pour les micros) ──────────────
    final repo = foods_loader.FoodsRepository.instance;
    try {
      if ((repo.items as List).isEmpty) {
        try {
          await (repo as dynamic).loadFromAsset('assets/foods.csv');
        } catch (_) {}
      }
      await repo.loadCustomFoods();
    } catch (_) {}
    final allFoods = <foods_loader.FoodItem>[
      ...repo.items,
      ...repo.customs,
    ];
    foods_loader.FoodItem? findFood(String id) {
      for (final f in allFoods) {
        if (f.id == id) return f;
      }
      return null;
    }

    // ── 3. Profil + cibles (SharedPreferences, fallbacks sûrs) ─────
    final sp = await SharedPreferences.getInstance();
    final sexStr = sp.getString('profile_sex') ?? 'male';
    final isF = sexStr == 'female';
    final age = (sp.getDouble('profile_age') ?? 30).round();
    final height = sp.getDouble('profile_height') ?? 175.0;
    final weight = sp.getDouble('profile_weight') ?? 70.0;
    final actIdx = sp.getInt('profile_activity') ?? 0;
    final goalIdx = sp.getInt('profile_goal') ?? 1;

    const actLabels = [
      'Sédentaire', 'Léger (1–3/sem)', 'Modéré (3–5/sem)',
      'Soutenu (6–7/sem)', 'Très intense (2×/jour)',
    ];
    const goalLabels = [
      'Perte de poids (−20%)', 'Maintien', 'Prise de masse (+10%)',
      'Perte modérée (−12%)', 'Prise modérée (+6%)',
    ];
    final actLabel =
        actLabels[actIdx.clamp(0, actLabels.length - 1)];
    final goalLabel =
        goalLabels[goalIdx.clamp(0, goalLabels.length - 1)];

    final gKcal = sp.getDouble('goals_kcal') ?? 2000.0;
    final gProt = sp.getDouble('goals_prot') ?? 120.0;
    final gCarb = sp.getDouble('goals_carb') ?? (gKcal * 0.55) / 4.0;
    final gFat = sp.getDouble('goals_fat') ?? (gKcal * 0.35) / 9.0;
    final gFib = sp.getDouble('goals_fiber') ?? 30.0;

    // Cibles micros (mêmes clés/fallbacks que bilan_screen)
    final tSat = sp.getDouble('goals_sat') ?? (gKcal * 0.10) / 9.0;
    final tO9 = sp.getDouble('goals_o9') ?? (gKcal * 0.20) / 9.0;
    final tO6 = sp.getDouble('goals_o6') ?? (gKcal * 0.04) / 9.0;
    final tO3 = sp.getDouble('goals_o3') ?? (gKcal * 0.01) / 9.0;
    final tEpa = sp.getDouble('goals_epa') ?? 0.25;
    final tDha = sp.getDouble('goals_dha') ?? 0.25;
    final tSugars = sp.getDouble('goals_sugars') ?? (gKcal * 0.10) / 4.0;
    final tSalt = sp.getDouble('goals_salt') ?? 5.0;
    final tCa = sp.getDouble('goals_ca_mg') ?? 950.0;
    final tCu = sp.getDouble('goals_cu_mg') ?? (isF ? 1.5 : 1.9);
    final tFe = sp.getDouble('goals_fe_mg') ?? 11.0;
    final tI = sp.getDouble('goals_i_ug') ?? 150.0;
    final tMg = sp.getDouble('goals_mg_mg') ?? (isF ? 300.0 : 380.0);
    final tMn = sp.getDouble('goals_mn_mg') ?? 8.0;
    final tP = sp.getDouble('goals_p_mg') ?? 550.0;
    final tK = sp.getDouble('goals_k_mg') ?? 3500.0;
    final tSe = sp.getDouble('goals_se_ug') ?? 70.0;
    final tNa = sp.getDouble('goals_na_mg') ?? 1500.0;
    final tZn = sp.getDouble('goals_zn_mg') ?? (isF ? 11.0 : 14.0);
    final tVitA = sp.getDouble('goals_vita_ug') ?? (isF ? 650.0 : 750.0);
    final tBetaCar =
        sp.getDouble('goals_vitbetacar_ug') ?? (isF ? 2600.0 : 3000.0);
    final tVitD = sp.getDouble('goals_vitd_ug') ?? 15.0;
    final tVitE = sp.getDouble('goals_vite_mg') ?? (isF ? 9.0 : 10.0);
    final tVitK = sp.getDouble('goals_vitk_ug') ?? 79.0;
    final tVitC = sp.getDouble('goals_vitc_mg') ?? 110.0;
    final tB1 = sp.getDouble('goals_b1_mg') ?? 1.6;
    final tB2 = sp.getDouble('goals_b2_mg') ?? 1.6;
    final tB3 = sp.getDouble('goals_b3_mg') ?? (isF ? 11.0 : 14.0);
    final tB5 = sp.getDouble('goals_b5_mg') ?? (isF ? 5.0 : 6.0);
    final tB6 = sp.getDouble('goals_b6_mg') ?? (isF ? 1.6 : 1.7);
    final tB9 = sp.getDouble('goals_b9_ug') ?? 330.0;
    final tB12 = sp.getDouble('goals_b12_ug') ?? 4.0;

    // ── 4. Agrégats période ─────────────────────────────────────────
    double sumKcal = 0, sumProt = 0, sumCarb = 0, sumFat = 0, sumFib = 0;
    final mealKcal = <String, double>{for (final m in _meals) m: 0.0};
    final microTotals = <String, double>{};
    int daysWithData = 0;

    final totalDays = to.difference(from).inDays + 1;

    for (final entries in byDate.values) {
      bool dayHasData = false;
      for (final mealEntries in entries.entries) {
        for (final r in mealEntries.value) {
          dayHasData = true;
          final kcal = (r['energy_kcal'] as num?)?.toDouble() ?? 0;
          sumKcal += kcal;
          sumProt += (r['protein_g'] as num?)?.toDouble() ?? 0;
          sumCarb += (r['carbs_g'] as num?)?.toDouble() ?? 0;
          sumFat += (r['fat_g'] as num?)?.toDouble() ?? 0;
          sumFib += (r['fiber_g'] as num?)?.toDouble() ?? 0;
          if (mealKcal.containsKey(mealEntries.key)) {
            mealKcal[mealEntries.key] = mealKcal[mealEntries.key]! + kcal;
          }
          // Micros : snapshot figé dans la ligne si présent, sinon recalcul
          final snap = r['micros'];
          final fid = (r['food_id'] ?? '').toString();
          final grams = (r['quantity_grams'] as num?)?.toDouble() ?? 0;
          if (snap is Map && snap.isNotEmpty) {
            snap.forEach((k, v) {
              final d = (v is num) ? v.toDouble() : 0.0;
              microTotals[k.toString()] =
                  (microTotals[k.toString()] ?? 0) + d;
            });
          } else if (fid.isNotEmpty && grams > 0) {
            final food = findFood(fid);
            if (food != null) {
              food.microsFor(grams).forEach((k, v) {
                microTotals[k] = (microTotals[k] ?? 0) + v;
              });
            }
          }
        }
      }
      if (dayHasData) daysWithData++;
    }

    final div = daysWithData > 0 ? daysWithData.toDouble() : 1.0;
    final avgKcal = sumKcal / div;
    final avgProt = sumProt / div;
    final avgCarb = sumCarb / div;
    final avgFat = sumFat / div;
    final avgFib = sumFib / div;
    double mAvg(String k) => (microTotals[k] ?? 0) / div;

    // ── 5. Construction du HTML ─────────────────────────────────────
    final now = DateTime.now();
    final buf = StringBuffer();

    String bar(double value, double target,
        {bool watch = false, bool over = false}) {
      final pct = target > 0 ? value / target : 0.0;
      final color =
          over ? '#B71C1C' : (watch ? _watchColor(pct) : _pctColor(pct));
      final width = (pct * 100).clamp(2, 100).toStringAsFixed(0);
      final pctTxt = (pct * 100).toStringAsFixed(0);
      return '<div class="barwrap"><div class="bar">'
          '<span style="width:$width%;background:$color"></span></div>'
          '<span class="pct" style="color:$color">$pctTxt%</span></div>';
    }

    String microRow(String label, double value, double target, String unit,
        int dec, {bool watch = false, double? ul}) {
      final over = ul != null && value > ul;
      final ulBadge = over
          ? '<div class="ulwarn">⚠ Dépasse la limite de sécurité '
              '(${_n(ul, 0)} $unit/jour)</div>'
          : '';
      return '<tr><td>$label$ulBadge</td>'
          '<td class="num">${_n(value, dec)} $unit</td>'
          '<td class="num">${_n(target, dec)} $unit</td>'
          '<td>${bar(value, target, watch: watch, over: over)}</td></tr>';
    }

    buf.writeln('''<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TOTUM — Rapport nutritionnel ${_ymd(from)} au ${_ymd(to)}</title>
<style>
  :root { --orange:#FF7A00; --dark:#1A1A1A; --bg:#FAFAF8; }
  * { box-sizing:border-box; margin:0; padding:0; }
  body { font-family:-apple-system,Segoe UI,Roboto,sans-serif;
         background:var(--bg); color:#222; line-height:1.5; }
  .wrap { max-width:860px; margin:0 auto; padding:24px 16px 60px; }
  header { background:linear-gradient(135deg,#FF7A00,#E85D00);
           color:#fff; border-radius:16px; padding:28px 24px; margin-bottom:24px; }
  header h1 { font-size:26px; letter-spacing:1px; }
  header .sub { opacity:.92; margin-top:6px; font-size:14px; }
  h2 { font-size:17px; margin:28px 0 12px; color:var(--dark);
       border-left:4px solid var(--orange); padding-left:10px; }
  .card { background:#fff; border-radius:14px; padding:16px 18px;
          box-shadow:0 2px 8px rgba(0,0,0,.06); margin-bottom:14px; }
  .grid2 { display:grid; grid-template-columns:1fr 1fr; gap:6px 18px; font-size:14px; }
  .grid2 b { color:#555; font-weight:600; }
  table { width:100%; border-collapse:collapse; font-size:13px; }
  th { background:#FFF3E9; color:#8a4a00; text-align:left;
       padding:7px 8px; font-weight:700; }
  td { padding:6px 8px; border-bottom:1px solid #f0ede8; }
  td.num, th.num { text-align:right; white-space:nowrap; }
  tr.subtotal td { font-weight:700; background:#FFF9F3; }
  tr.daytotal td { font-weight:800; background:#FFEEDB; }
  .barwrap { display:flex; align-items:center; gap:8px; min-width:130px; }
  .bar { flex:1; height:9px; background:#eee; border-radius:6px; overflow:hidden; }
  .bar span { display:block; height:100%; border-radius:6px; }
  .pct { font-size:11px; font-weight:700; min-width:36px; text-align:right; }
  .synth { display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr));
           gap:10px; }
  .synth .item { background:#fff; border-radius:12px; padding:12px;
                 box-shadow:0 2px 6px rgba(0,0,0,.05); }
  .synth .item .lbl { font-size:12px; color:#777; }
  .synth .item .val { font-size:19px; font-weight:800; color:var(--dark); }
  .synth .item .tgt { font-size:11px; color:#999; }
  .day { margin-bottom:22px; }
  .day h3 { font-size:15px; margin-bottom:8px; color:var(--dark); }
  .day h4 { font-size:13px; margin:12px 0 4px; color:var(--orange); }
  .nodata { color:#999; font-style:italic; font-size:13px; padding:8px 0; }
  .ulwarn { color:#B71C1C; font-size:11px; font-weight:700; margin-top:2px; }
  .ulwarn { color:#B71C1C; font-size:11px; font-weight:700; margin-top:2px; }
  .note { font-size:12px; color:#888; margin-top:24px; padding:14px;
          background:#FFF9F3; border-radius:10px; border:1px dashed #f0c9a0; }
  footer { text-align:center; font-size:11px; color:#aaa; margin-top:30px; }
  @page { size: A4 portrait; margin: 11mm; }
  @media print {
    body { background:#fff; }
    .wrap { max-width:100%; padding:0; }
    .card, .synth .item { box-shadow:none; border:1px solid #eee; }
    h2 { break-after: avoid; page-break-after: avoid; }
    .card { break-inside: avoid; page-break-inside: avoid; }
    /* Chaque journée saisie démarre sur sa propre page et reste groupée */
    .day { break-before: page; page-break-before: always;
           break-inside: avoid; page-break-inside: avoid; }
    /* …sauf la toute première (collée au titre) et les jours sans données */
    h2 + .day, .day.nodataday { break-before: auto; page-break-before: auto; }
    /* Sécurité si une journée dépasse une page : coupures propres */
    .day table { break-inside: avoid; page-break-inside: avoid; }
    .day h4 { break-after: avoid; page-break-after: avoid; }
    tr { break-inside: avoid; }
    /* Compactage léger (impression uniquement) pour tenir 4 repas / page */
    table { font-size:11px; }
    td, th { padding:4px 6px; }
    header { -webkit-print-color-adjust:exact; print-color-adjust:exact; }
  }
</style>
</head>
<body><div class="wrap">

<header>
  <h1>TOTUM</h1>
  <div class="sub">Rapport de suivi nutritionnel<br>
  Du ${_frDate(from)} au ${_frDate(to)}
  — $totalDays jour${totalDays > 1 ? 's' : ''}, $daysWithData suivi${daysWithData > 1 ? 's' : ''}<br>
  Généré le ${_frDate(now)}</div>
</header>

<h2>Profil</h2>
<div class="card"><div class="grid2">
  <div><b>Sexe :</b> ${isF ? 'Femme' : 'Homme'}</div>
  <div><b>Âge :</b> $age ans</div>
  <div><b>Taille :</b> ${_n(height)} cm</div>
  <div><b>Poids :</b> ${_n(weight, 1)} kg</div>
  <div><b>Activité :</b> $actLabel</div>
  <div><b>Objectif :</b> $goalLabel</div>
</div></div>

<h2>Objectifs journaliers</h2>
<div class="synth">
  <div class="item"><div class="lbl">⚡ Énergie</div>
    <div class="val">${_n(gKcal)} kcal</div></div>
  <div class="item"><div class="lbl">🥩 Protéines</div>
    <div class="val">${_n(gProt)} g</div></div>
  <div class="item"><div class="lbl">🌾 Glucides</div>
    <div class="val">${_n(gCarb)} g</div></div>
  <div class="item"><div class="lbl">🫒 Lipides</div>
    <div class="val">${_n(gFat)} g</div></div>
  <div class="item"><div class="lbl">🌿 Fibres</div>
    <div class="val">${_n(gFib)} g</div></div>
</div>

<h2>Synthèse — moyennes journalières (sur $daysWithData jour${daysWithData > 1 ? 's' : ''} suivi${daysWithData > 1 ? 's' : ''})</h2>
<div class="card"><table>
  <tr><th>Indicateur</th><th class="num">Moyenne / j</th>
      <th class="num">Objectif</th><th>Atteinte</th></tr>
  ${microRow('⚡ Énergie', avgKcal, gKcal, 'kcal', 0)}
  ${microRow('🥩 Protéines', avgProt, gProt, 'g', 1)}
  ${microRow('🌾 Glucides', avgCarb, gCarb, 'g', 1)}
  ${microRow('🫒 Lipides', avgFat, gFat, 'g', 1)}
  ${microRow('🌿 Fibres', avgFib, gFib, 'g', 1)}
</table></div>

<h2>Répartition moyenne par repas</h2>
<div class="card"><table>
  <tr><th>Repas</th><th class="num">Moyenne kcal / j</th>
      <th class="num">Part de l'apport</th></tr>''');

    for (final m in _meals) {
      final avg = mealKcal[m]! / div;
      final part = avgKcal > 0 ? (avg / avgKcal * 100) : 0.0;
      buf.writeln('<tr><td>$m</td><td class="num">${_n(avg)} kcal</td>'
          '<td class="num">${_n(part)} %</td></tr>');
    }

    buf.writeln('''</table></div>''');

    // ── Micronutriments (moyennes / j vs cibles) — SYNTHÈSE EN HAUT ─
    buf.writeln('''
<h2>🧠 Acides gras essentiels — moyenne / jour</h2>
<div class="card"><table>
  <tr><th>Nutriment</th><th class="num">Moyenne / j</th>
      <th class="num">Cible</th><th>Atteinte</th></tr>
  ${microRow('Oméga 9 (Oléique)', mAvg('Acide_oléique_W9_g_100g'), tO9, 'g', 2)}
  ${microRow('Oméga 6 (LA)', mAvg('Acide_linoléique_W6_LA_g_100g'), tO6, 'g', 2)}
  ${microRow('Oméga 3 (ALA)', mAvg('Acide_alpha-linolénique_W3_ALA_g_100g'), tO3, 'g', 2)}
  ${microRow('EPA', mAvg('EPA_g_100g'), tEpa, 'g', 2)}
  ${microRow('DHA', mAvg('DHA_g_100g'), tDha, 'g', 2)}
</table></div>

<h2>🛑 À surveiller — moyenne / jour</h2>
<div class="card"><table>
  <tr><th>Nutriment</th><th class="num">Moyenne / j</th>
      <th class="num">Limite</th><th>Situation</th></tr>
  ${microRow('AG saturés', mAvg('AG_saturés_g_100g'), tSat, 'g', 1, watch: true)}
  ${microRow('Sucres', mAvg('Sucres_g_100g'), tSugars, 'g', 1, watch: true)}
  ${microRow('Sel', mAvg('Sel_g_100g'), tSalt, 'g', 1, watch: true)}
</table></div>

<h2>🍋 Vitamines — moyenne / jour</h2>
<div class="card"><table>
  <tr><th>Vitamine</th><th class="num">Moyenne / j</th>
      <th class="num">Cible</th><th>Atteinte</th></tr>
  ${microRow('Rétinol (A animale)', mAvg('Rétinol_µg_100g'), tVitA, 'µg', 0, ul: _kUlRetinolUg)}
  ${microRow('Bêta-carotène (A végétale)', mAvg('Beta-Carotène_µg_100g'), tBetaCar, 'µg', 0)}
  ${microRow('Vitamine D', mAvg('Vitamine_D_µg_100g'), tVitD, 'µg', 1)}
  ${microRow('Vitamine E', mAvg('Vitamine_E_mg_100g'), tVitE, 'mg', 1)}
  ${microRow('Vitamine K', mAvg('Vitamine_K1_µg_100g') + mAvg('Vitamine_K2_µg_100g'), tVitK, 'µg', 0)}
  ${microRow('Vitamine C', mAvg('Vitamine_C_mg_100g'), tVitC, 'mg', 0)}
  ${microRow('B1 (Thiamine)', mAvg('Vitamine_B1_mg_100g'), tB1, 'mg', 2)}
  ${microRow('B2 (Riboflavine)', mAvg('Vitamine_B2_mg_100g'), tB2, 'mg', 2)}
  ${microRow('B3 (Niacine)', mAvg('Vitamine_B3_mg_100g'), tB3, 'mg', 1)}
  ${microRow('B5 (Ac. pantothénique)', mAvg('Vitamine_B5_mg_100g'), tB5, 'mg', 1)}
  ${microRow('B6 (Pyridoxine)', mAvg('Vitamine_B6_mg_100g'), tB6, 'mg', 2)}
  ${microRow('B9 (Folates)', mAvg('Vitamine_B9_µg_100g'), tB9, 'µg', 0)}
  ${microRow('B12 (Cobalamine)', mAvg('Vitamine_B12_µg_100g'), tB12, 'µg', 1)}
</table></div>

<h2>🧱 Minéraux — moyenne / jour</h2>
<div class="card"><table>
  <tr><th>Minéral</th><th class="num">Moyenne / j</th>
      <th class="num">Cible</th><th>Atteinte</th></tr>
  ${microRow('Calcium', mAvg('Calcium_mg_100g'), tCa, 'mg', 0)}
  ${microRow('Cuivre', mAvg('Cuivre_mg_100g'), tCu, 'mg', 2)}
  ${microRow('Fer', mAvg('Fer_mg_100g'), tFe, 'mg', 1, ul: _kUlFerMg)}
  ${microRow('Iode', mAvg('Iode_µg_100g'), tI, 'µg', 0)}
  ${microRow('Magnésium', mAvg('Magnésium_mg_100g'), tMg, 'mg', 0)}
  ${microRow('Manganèse', mAvg('Manganèse_mg_100g'), tMn, 'mg', 1)}
  ${microRow('Phosphore', mAvg('Phosphore_mg_100g'), tP, 'mg', 0)}
  ${microRow('Potassium', mAvg('Potassium_mg_100g'), tK, 'mg', 0)}
  ${microRow('Sélénium', mAvg('Sélénium_µg_100g'), tSe, 'µg', 0, ul: _kUlSeleniumUg)}
  ${microRow('Sodium', mAvg('Sodium_mg_100g'), tNa, 'mg', 0)}
  ${microRow('Zinc', mAvg('Zinc_mg_100g'), tZn, 'mg', 1, ul: _kUlZincMg)}
</table></div>''');

    // ── Détail jour par jour ────────────────────────────────────────
    buf.writeln('''
<h2>Détail jour par jour</h2>''');

    for (DateTime d = from;
        !d.isAfter(to);
        d = d.add(const Duration(days: 1))) {
      final key = _ymd(d);
      final dayMeals = byDate[key];
      final isEmptyDay = dayMeals == null || dayMeals.isEmpty;

      buf.writeln('<div class="day card${isEmptyDay ? ' nodataday' : ''}">');
      buf.writeln('<h3>📅 ${_frDate(d)}</h3>');

      if (dayMeals == null || dayMeals.isEmpty) {
        buf.writeln(
            '<div class="nodata">Aucune donnée enregistrée ce jour.</div>');
        buf.writeln('</div>');
        continue;
      }

      double dayK = 0, dayP = 0, dayC = 0, dayF = 0, dayFi = 0;

      for (final meal in _meals) {
        final entries = dayMeals[meal];
        if (entries == null || entries.isEmpty) continue;

        buf.writeln('<h4>$meal</h4>');
        buf.writeln('<table><tr><th>Aliment</th><th class="num">Qté</th>'
            '<th class="num">kcal</th><th class="num">P</th>'
            '<th class="num">G</th><th class="num">L</th>'
            '<th class="num">F</th></tr>');

        double mK = 0, mP = 0, mC = 0, mF = 0, mFi = 0;
        for (final r in entries) {
          final name = _esc((r['food_name'] ?? 'Aliment').toString());
          final g = (r['quantity_grams'] as num?)?.toDouble() ?? 0;
          final k = (r['energy_kcal'] as num?)?.toDouble() ?? 0;
          final p = (r['protein_g'] as num?)?.toDouble() ?? 0;
          final c = (r['carbs_g'] as num?)?.toDouble() ?? 0;
          final f = (r['fat_g'] as num?)?.toDouble() ?? 0;
          final fi = (r['fiber_g'] as num?)?.toDouble() ?? 0;
          mK += k; mP += p; mC += c; mF += f; mFi += fi;
          buf.writeln('<tr><td>$name</td><td class="num">${_n(g)} g</td>'
              '<td class="num">${_n(k)}</td><td class="num">${_n(p, 1)}</td>'
              '<td class="num">${_n(c, 1)}</td><td class="num">${_n(f, 1)}</td>'
              '<td class="num">${_n(fi, 1)}</td></tr>');
        }
        buf.writeln('<tr class="subtotal"><td>Sous-total $meal</td>'
            '<td></td><td class="num">${_n(mK)}</td>'
            '<td class="num">${_n(mP, 1)}</td><td class="num">${_n(mC, 1)}</td>'
            '<td class="num">${_n(mF, 1)}</td><td class="num">${_n(mFi, 1)}</td></tr>');
        buf.writeln('</table>');

        dayK += mK; dayP += mP; dayC += mC; dayF += mF; dayFi += mFi;
      }

      buf.writeln('<table style="margin-top:8px">'
          '<tr class="daytotal"><td>TOTAL JOUR</td>'
          '<td class="num">${_n(dayK)} kcal</td>'
          '<td class="num">P ${_n(dayP, 1)} g</td>'
          '<td class="num">G ${_n(dayC, 1)} g</td>'
          '<td class="num">L ${_n(dayF, 1)} g</td>'
          '<td class="num">F ${_n(dayFi, 1)} g</td></tr></table>');
      buf.writeln('</div>');
    }

    // ── Note + footer ───────────────────────────────────────────────
    buf.writeln('''

<div class="note">
  💡 <b>Convertir en PDF :</b> ouvrez ce fichier dans votre navigateur puis
  Ctrl+P (Cmd+P sur Mac) → « Enregistrer au format PDF ».<br>
  📊 Les macronutriments proviennent des saisies du journal ; les
  micronutriments sont recalculés à partir de la base CIQUAL (ANSES) et des
  aliments personnalisés. Les cibles affichées sont personnalisées selon le
  profil (sexe, âge, activité, objectif).<br>
  ⚕️ Ce rapport est un outil de suivi : il ne remplace pas un avis médical.
</div>

<footer>Rapport généré par TOTUM — Suivi nutritionnel</footer>
</div></body></html>''');

    // ── 6. Téléchargement / partage ─────────────────────────────────
    final filename = 'totum_journal_${_ymd(from)}_au_${_ymd(to)}.html';
    await saveAndShareHtml(buf.toString(), filename);
  }
}
