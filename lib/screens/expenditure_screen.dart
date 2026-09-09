// lib/screens/expenditure_screen.dart
//
// Graphique "Dépense énergétique" façon MacroFactor Expenditure : ligne de
// dépense estimée + bande d'incertitude, dérivées de calibration_service
// .expenditureHistory(). Approximation inspirée du rendu MacroFactor, PAS
// une reproduction de leur algorithme propriétaire — voir le commentaire de
// expenditureHistory() dans calibration_service.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../services/calibration_service.dart';
import '../services/profile.dart'
    show ProfileStore, UserProfile, computeBmr, minSafeKcalFor,
        nearestActivityLevel, ActivityLevelX;
import '../theme/totum_style.dart';

/// BUG CORRIGÉ (19/08/2026, retour d'Alex — comparaison à la courbe
/// MacroFactor fournie en exemple, "il manque le niveau de détail") : ce
/// composant était `StatelessWidget`, sans aucune interaction — la ligne
/// n'avait pas de points visibles, le tooltip par défaut de fl_chart était
/// trop petit/fugace ("illisible"), et rien n'expliquait à l'utilisateur
/// POURQUOI un point donné avait cette valeur. Passé en `StatefulWidget` :
/// points visibles sur la ligne, sélection au tap qui persiste (pas un
/// tooltip qui disparaît), et une fiche de détail sous le graphique
/// affichant les 2 ingrédients RÉELS de l'estimation (poids tendance,
/// calories loguées — voir `ExpenditurePoint`), jamais un texte inventé.
class ExpenditureChart extends StatefulWidget {
  final List<ExpenditurePoint> data;
  final double height;
  /// Si fourni, affiché sous le graphique (uniquement quand assez de
  /// points) — permet à l'appelant de placer la fiche de détail dans son
  /// propre layout (ex. l'écran dédié a plus de place que la vignette
  /// compacte du tableau de bord, qui n'affiche pas la fiche).
  final bool showDetailCard;
  const ExpenditureChart({super.key, required this.data, this.height = 110, this.showDetailCard = true});

  @override
  State<ExpenditureChart> createState() => _ExpenditureChartState();
}

class _ExpenditureChartState extends State<ExpenditureChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant ExpenditureChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Une nouvelle période sélectionnée (1M/3M/6M/1A) change complètement
    // les points disponibles — un index sélectionné de l'ancienne liste n'a
    // plus aucun sens ici, on retombe sur le dernier point (comportement
    // par défaut) plutôt que de risquer un index hors bornes ou un point
    // silencieusement faux.
    if (oldWidget.data != widget.data) _selectedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final height = widget.height;
    if (data.length < 2) {
      // Bug corrigé (14/08/2026, retour d'Alex — toujours coupée malgré la
      // Priorité 48) : ce panneau empile un titre + 2 lignes complètes
      // (libellé + compteur + barre de progression), bien plus dense que la
      // simple courbe de la vignette Poids qui, elle, tient sans problème
      // dans 110px — 110px restait juste trop serré une fois le padding du
      // conteneur déduit, même avec les libellés compacts. Relevé
      // spécifiquement pour cet état (jamais pour le vrai graphique une
      // fois assez de données, qui reste à la hauteur demandée par l'appelant).
      //
      // `data.length` transmis tel quel (0 ou 1 ici) — BUG CORRIGÉ (19/08/2026,
      // retour d'Alex : "j'ai 10/10 jours pesés et 17 jours de repas, ça
      // devrait être bon, mais ça dit encore presque prêt") : avant ce
      // correctif, ce panneau recalculait SA PROPRE notion de "prêt" via
      // `expenditureReadiness()` (seuils calibration, un seul point-dans-le-
      // temps) — complètement indépendante du VRAI nombre de points que
      // produit `expenditureHistory()` pour tracer une ligne (qui, LUI, a
      // structurellement besoin d'au moins 2 fenêtres glissantes
      // indépendantes, donc d'au moins 1 jour de suivi DE PLUS que le strict
      // minimum de calibration). Avec exactement le minimum (10 jours
      // pesés), l'objectif calorique EST déjà affiné (1 fenêtre suffit) mais
      // le graphique ne peut PAS encore avoir 2 points — d'où le message
      // "presque prêt" qui semblait contredire des barres déjà pleines.
      // `data.length` (le nombre RÉEL de points déjà obtenus) est
      // maintenant la seule source de vérité passée à ce panneau.
      return _ExpenditureProgress(
          height: height < 160 ? 132 : height, chartPointsSoFar: data.length);
    }
    final firstDay = data.first.date;
    double x(DateTime d) => d.difference(firstDay).inDays.toDouble();
    final lowSpots = data.map((p) => FlSpot(x(p.date), p.lowKcal)).toList();
    final highSpots = data.map((p) => FlSpot(x(p.date), p.highKcal)).toList();
    final centerSpots = data.map((p) => FlSpot(x(p.date), p.estimateKcal)).toList();
    final minY = data.map((p) => p.lowKcal).reduce((a, b) => a < b ? a : b) - 30;
    final maxY = data.map((p) => p.highKcal).reduce((a, b) => a > b ? a : b) + 30;
    String fmtDate(DateTime d) => '${d.day}/${d.month}';

    final selectedIndex = (_selectedIndex ?? data.length - 1).clamp(0, data.length - 1);

    final chart = SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: centerSpots.last.x,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 3).clamp(10, 1000),
            getDrawingHorizontalLine: (_) => FlLine(color: TotumColors.outline, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: ((maxY - minY) / 3).clamp(10, 1000),
                getTitlesWidget: (v, meta) =>
                    Text(v.toStringAsFixed(0), style: TextStyle(fontSize: 9.5, color: TotumColors.textMuted)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: (centerSpots.last.x / 3).clamp(1, 999),
                getTitlesWidget: (v, meta) {
                  final d = firstDay.add(Duration(days: v.round()));
                  return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(fmtDate(d), style: TextStyle(fontSize: 9.5, color: TotumColors.textMuted)));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          // BUG CORRIGÉ (19/08/2026, retour d'Alex vs la capture MacroFactor
          // fournie en exemple — "les vignettes illisibles quand on clique
          // sur la courbe") : le tooltip flottant par défaut de fl_chart est
          // désactivé quand la fiche de détail persistante est affichée
          // (écran dédié, `showDetailCard: true` — voir `_PointDetailCard`) :
          // plus lisible, ne disparaît pas au relâché du doigt, et explique
          // le POURQUOI (poids/calories réels de la fenêtre), pas seulement
          // la valeur. En revanche, la vignette COMPACTE (tableau de bord,
          // `showDetailCard: false`) n'a pas cette fiche — BUG CORRIGÉ
          // (19/08/2026, retour d'Alex : "sur la petite vignette Poids on
          // peut faire varier le curseur, ce n'est pas le cas pour la
          // dépense énergétique") : elle utilise maintenant le même tooltip
          // flottant natif que `WeightTrendChart` (weight_trend_screen.dart),
          // pour une interaction cohérente entre les deux vignettes.
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              // BUG CORRIGÉ (21/08/2026, retour d'Alex — "tu as mis les
              // trois [bornes basse/haute + estimation] de la même couleur,
              // on n'arrive pas à dissocier les éléments") : les 3 lignes du
              // graphique (bornes invisibles + estimation) recevaient
              // exactement le même style, quel que soit `s.barIndex`. Chaque
              // valeur a maintenant sa propre icône + sa propre teinte de la
              // rampe unique de l'app (jamais une couleur hors charte) —
              // même principe que le tooltip Poids juste en dessous (icône +
              // couleur), pour une interaction homogène entre les 2
              // vignettes.
              getTooltipItems: (spots) => spots.map((s) {
                if (widget.showDetailCard) return null;
                final IconData icon;
                final Color color;
                switch (s.barIndex) {
                  case 0:
                    icon = Icons.arrow_downward_rounded;
                    color = TotumProgress.stop25;
                  case 1:
                    icon = Icons.arrow_upward_rounded;
                    color = TotumProgress.stop75;
                  default:
                    icon = Icons.local_fire_department_outlined;
                    color = TotumColors.accent;
                }
                return LineTooltipItem(
                  String.fromCharCode(icon.codePoint),
                  TextStyle(fontFamily: icon.fontFamily, fontSize: 12, color: color),
                  children: [
                    TextSpan(
                      text: ' ${s.y.toStringAsFixed(0)} kcal',
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
            touchCallback: (event, response) {
              final spots = response?.lineBarSpots;
              if (spots == null || spots.isEmpty) return;
              final spot = spots.firstWhere((s) => s.barIndex == 2, orElse: () => spots.first);
              if (spot.spotIndex != _selectedIndex) {
                setState(() => _selectedIndex = spot.spotIndex);
              }
            },
          ),
          lineBarsData: [
            // Bornes basse/haute — invisibles, elles ne servent qu'à ancrer
            // la bande d'incertitude ombragée (betweenBarsData ci-dessous).
            LineChartBarData(
                spots: lowSpots, isCurved: true, color: Colors.transparent, barWidth: 0, dotData: const FlDotData(show: false)),
            LineChartBarData(
                spots: highSpots, isCurved: true, color: Colors.transparent, barWidth: 0, dotData: const FlDotData(show: false)),
            // Ligne centrale — l'estimation elle-même. Points désormais
            // visibles (façon MacroFactor) — celui sélectionné (tap, ou le
            // dernier par défaut) ressort avec un anneau plus marqué.
            LineChartBarData(
              spots: centerSpots,
              isCurved: true,
              color: TotumColors.accent,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: index == selectedIndex ? 4.5 : 2.0,
                  color: TotumColors.accent,
                  strokeWidth: index == selectedIndex ? 2.5 : 0,
                  strokeColor: TotumColors.surface,
                ),
              ),
            ),
          ],
          betweenBarsData: [
            BetweenBarsData(fromIndex: 0, toIndex: 1, color: TotumColors.accentSoft),
          ],
        ),
      ),
    );

    if (!widget.showDetailCard) return chart;

    final point = data[selectedIndex];
    final previous = selectedIndex > 0 ? data[selectedIndex - 1] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chart,
        const SizedBox(height: 12),
        _PointDetailCard(point: point, previous: previous, fmtDate: fmtDate),
      ],
    );
  }
}

/// Fiche de détail d'un point du graphique — affichée sous la courbe,
/// persistante (pas un tooltip flottant), toujours renseignée depuis les
/// champs RÉELS d'[ExpenditurePoint] (voir son commentaire dans
/// calibration_service.dart) : jamais de texte d'explication inventé.
class _PointDetailCard extends StatelessWidget {
  final ExpenditurePoint point;
  final ExpenditurePoint? previous;
  final String Function(DateTime) fmtDate;
  const _PointDetailCard({required this.point, required this.previous, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    final delta = previous == null ? null : point.estimateKcal - previous!.estimateKcal;
    final uncertainty = ((point.highKcal - point.lowKcal) / 2).round();
    // BUG CORRIGÉ (19/08/2026, repéré en générant la capture de démonstration
    // — un poids parfaitement stable sur la fenêtre peut produire un zéro
    // négatif en virgule flottante, ex. -0.4 * (1-1) = -0.0) : `-0.0 >= 0`
    // vaut `true` en Dart, donc le préfixe "+" s'ajoutait quand même devant
    // "-0.00" (déjà signé par toStringAsFixed) → "+-0.00 kg", illisible.
    // `-0.0 == 0.0` valant également `true`, cette normalisation remplace
    // silencieusement le zéro négatif par un zéro positif.
    final weightChangeKg = point.weightChangeKg == 0 ? 0.0 : point.weightChangeKg;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(label,
                      style: TextStyle(fontSize: 12, color: TotumColors.textSecondary))),
              Text(value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TotumColors.textPrimary)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: TotumColors.page, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmtDate(point.date),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
              Row(children: [
                Text('${point.estimateKcal.round()} ${context.l10n.kcalPerDay}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: TotumColors.accent)),
                if (delta != null) ...[
                  const SizedBox(width: 6),
                  Text('(${delta >= 0 ? '+' : ''}${delta.round()})',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: TotumColors.textMuted)),
                ],
              ]),
            ],
          ),
          const Divider(height: 18),
          Text(context.l10n.expenditureDetailWhy,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: TotumColors.textSecondary)),
          const SizedBox(height: 4),
          row(context.l10n.expenditureDetailWeightChange,
              '${weightChangeKg >= 0 ? '+' : ''}${weightChangeKg.toStringAsFixed(2)} kg'),
          row(context.l10n.expenditureDetailAvgLogged, '${point.avgKcalLogged.round()} kcal/j'),
          row(context.l10n.expenditureDetailCoverage,
              '${point.daysWithFoodLogged}/${point.windowDays} ${context.l10n.dayAbbrev}'),
          row(context.l10n.expenditureDetailUncertainty, '± $uncertainty kcal'),
          // Priorité 71ter — couverture < 50 % de la fenêtre : les jours non
          // loggés (repas oubliés, sauces/boissons non notées) tirent
          // mécaniquement `avgKcalLogged` — et donc l'estimation — vers le
          // bas. Avertissement visible directement là où le chiffre est
          // affiché, jamais caché dans un écran séparé.
          if (point.windowDays > 0 && point.daysWithFoodLogged / point.windowDays < 0.5) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: TotumColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(context.l10n.expenditureLowCoverageBadge,
                      style: TextStyle(fontSize: 11, height: 1.35, color: TotumColors.textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Remplace l'ancien message générique ("continue quelques semaines...")
/// par un état d'avancement concret — retour d'Alex (12/08/2026) : sans
/// repère chiffré, "l'utilisateur va se dire qu'on lui vend du rêve" en
/// voyant un graphique vide une semaine après avoir commencé à renseigner
/// ses données. S'appuie sur CalibrationService.expenditureReadiness(),
/// qui reprend exactement les seuils réels du calcul (aucun chiffre
/// inventé ici).
class _ExpenditureProgress extends StatefulWidget {
  final double height;
  final int chartPointsSoFar;
  const _ExpenditureProgress({required this.height, required this.chartPointsSoFar});

  @override
  State<_ExpenditureProgress> createState() => _ExpenditureProgressState();
}

class _ExpenditureProgressState extends State<_ExpenditureProgress> {
  // Priorité 59 (14/08/2026, audit des graphiques) : la Future était créée
  // directement dans build() — recréée (et refetchée : SharedPreferences +
  // requête Supabase) à CHAQUE reconstruction de cet écran, même pour un
  // setState totalement sans rapport (ex. modification d'un champ du
  // profil), avec un flash du spinner de chargement à chaque fois. Créée
  // une seule fois ici, dans initState() — l'élément StatefulWidget est
  // préservé par Flutter à travers les reconstructions des ancêtres.
  late final Future<ExpenditureReadiness> _future =
      CalibrationService.instance.expenditureReadiness();

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    return FutureBuilder<ExpenditureReadiness>(
      future: _future,
      builder: (context, snap) {
        final r = snap.data;
        return Container(
          height: height,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: TotumColors.page, borderRadius: BorderRadius.circular(12)),
          child: r == null
              ? const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: TotumColors.accent),
                  ),
                )
              : _ProgressBody(r: r, compact: height < 160, chartPointsSoFar: widget.chartPointsSoFar),
        );
      },
    );
  }
}

/// "12/20 j" tant que le seuil n'est pas atteint (lecture naturelle en
/// fraction) ; "18 j (min. 8)" une fois dépassé, pour éviter la lecture en
/// fraction cassée ("18/8" ne veut rien dire visuellement). Encore utilisé
/// dans la fiche de détail au tap (voir _ProgressDetailSheet).
String _thresholdLabel(int value, int min, String dayAbbrev) =>
    value <= min ? '$value/$min $dayAbbrev' : '$value $dayAbbrev (min. $min)';

/// Anneau de progression COMBINÉ — refonte du 21/08/2026 (retour d'Alex :
/// "la notion des deux curseurs avec les jours/jours restants, je trouve que
/// c'est nul, ça parle pas trop à l'utilisateur, c'est pas motivant" —
/// remplace les 2 barres fines (vignette compacte) ET les 2 anneaux séparés
/// (écran dédié) par UN seul anneau + pourcentage, validé sur maquette avant
/// implémentation). Même composant "donut" que le reste de l'onglet Profil
/// (`PieChart` 2 sections + `TotumProgress.forFraction`) — aucun nouveau
/// vocabulaire visuel.
///
/// Le pourcentage affiché est le MINIMUM des 2 volets (poids, repas) —
/// jamais une moyenne : on n'est jamais "plus prêt" que son maillon le plus
/// faible, une moyenne aurait pu annoncer un pourcentage trompeusement
/// optimiste (ex. 100% pesées + 20% repas → moyenne 60%, alors que le calcul
/// réel reste bloqué par les repas).
/// Fiche de détail (au tap sur la vignette, écran dédié uniquement — la
/// vignette compacte du tableau de bord navigue déjà vers cet écran, voir
/// `_evolutionTapCard` dans profile_screen.dart, pas besoin d'un 2e niveau
/// d'interaction là). Retour d'Alex (21/08/2026) : le détail (conditions de
/// pesée, régularité du journal) doit rester accessible mais ne plus être
/// imposé en permanence sur la vignette — validé sur maquette avant
/// implémentation.
class _ProgressDetailSheet extends StatelessWidget {
  final ExpenditureReadiness r;
  const _ProgressDetailSheet({required this.r});

  Widget _task(BuildContext context, {
    required bool done,
    required String title,
    required String desc,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: TotumColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? TotumColors.positive : TotumColors.accentSoft,
            ),
            child: Icon(done ? Icons.check : Icons.info_outline,
                size: 15, color: done ? Colors.white : TotumColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, height: 1.45, color: TotumColors.textSecondary)),
                if (progress != null) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: TotumColors.outline,
                      color: TotumProgress.forFraction(progress),
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

  @override
  Widget build(BuildContext context) {
    final weighDone = r.weighInsCount >= r.minWeighDays;
    final foodDone = r.daysWithFoodLogged >= r.minFoodDays;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: TotumColors.outlineStrong, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            Text(context.l10n.expenditureDetailTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
            const SizedBox(height: 4),
            Text(context.l10n.expenditureDetailLead,
                style: TextStyle(fontSize: 12, color: TotumColors.textMuted)),
            const SizedBox(height: 18),
            _task(context,
                done: weighDone,
                title: '${context.l10n.expenditureSpanBetweenWeighInsCompact} — '
                    '${_thresholdLabel(r.weighInsCount, r.minWeighDays, context.l10n.dayAbbrev)}',
                desc: context.l10n.weightTrendAdviceText,
                progress: weighDone ? null : r.weighDaysProgress),
            const SizedBox(height: 10),
            _task(context,
                done: foodDone,
                title: '${context.l10n.expenditureMealsLoggedCompact} — '
                    '${_thresholdLabel(r.daysWithFoodLogged, r.minFoodDays, context.l10n.dayAbbrev)}',
                desc: context.l10n.expenditureFoodAdviceText,
                progress: foodDone ? null : r.foodProgress),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(14)),
              child: Text(context.l10n.expenditureDetailTip,
                  style: TextStyle(fontSize: 11.5, height: 1.5, color: TotumColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  final ExpenditureReadiness r;
  final bool compact;
  final int chartPointsSoFar;
  const _ProgressBody({required this.r, required this.compact, required this.chartPointsSoFar});

  /// Jours de suivi restants estimés avant que l'OBJECTIF CALORIQUE lui-même
  /// puisse être affiné (1 seule fenêtre d'analyse suffit — voir
  /// `computeCalibration()`), EN CONTINUANT à se peser/loguer chaque jour.
  /// Volontairement un MAJORANT simple (le pire des 2 seuils), pas une
  /// prédiction précise. Ne concerne PAS le graphique lui-même — voir
  /// `chartPointsSoFar` pour ça (le graphique a une exigence légèrement
  /// différente et strictement plus élevée, voir son commentaire dans
  /// `ExpenditureChart`).
  int get _daysRemaining {
    final weighRemaining = r.minWeighDays - r.weighInsCount;
    final foodRemaining = r.minFoodDays - r.daysWithFoodLogged;
    final worst = weighRemaining > foodRemaining ? weighRemaining : foodRemaining;
    return worst < 0 ? 0 : worst;
  }

  /// % combiné = le PLUS FAIBLE des 2 volets (poids, repas) — jamais une
  /// moyenne (voir le commentaire de _ReadinessRing).
  double get _combinedProgress {
    final w = r.weighDaysProgress;
    final f = r.foodProgress;
    return w < f ? w : f;
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TotumColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _ProgressDetailSheet(r: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Titre dynamique : un compte à rebours concret ("Encore X jours") est
    // beaucoup plus compréhensible/moderne qu'un "arrive bientôt" statique
    // qui ne dit rien du temps réellement restant (demande explicite
    // d'Alex, 19/08/2026 — "il faut que ça évolue bien en fonction de ce
    // qu'on a renseigné"). Dérivé des 2 mêmes compteurs affichés dans la
    // fiche de détail, jamais un nouveau chiffre indépendant.
    //
    // BUG CORRIGÉ (19/08/2026, retour d'Alex — "j'ai 10/10 jours pesés et 17
    // jours de repas renseignés, ça devrait être bon pour la courbe" mais le
    // message disait encore "presque prêt") : `_daysRemaining` ci-dessus
    // reflète le seuil de CALIBRATION (1 seule fenêtre, déjà satisfait à
    // 10/10) — pas le seuil, structurellement plus élevé, du GRAPHIQUE
    // (2 fenêtres glissantes indépendantes). `chartPointsSoFar` (le nombre
    // RÉEL de points déjà produits par expenditureHistory(), transmis par
    // ExpenditureChart) permet de distinguer honnêtement les 2 : l'objectif
    // calorique peut déjà être affiné pendant que le graphique, lui, attend
    // encore 1 jour de suivi.
    String headline;
    if (r.weighInsCount < 2) {
      headline = context.l10n.expenditureNotEnoughWeighIns;
    } else if (chartPointsSoFar >= 1) {
      headline = context.l10n.expenditureGoalReadyChartPending;
    } else if (_daysRemaining > 0) {
      headline = context.l10n.expenditureDaysRemaining(_daysRemaining);
    } else {
      headline = context.l10n.expenditureAlmostReady;
    }
    final subtext = r.weighInsCount < 2
        ? context.l10n.expenditureAddSecondWeighIn(r.weighInsCount)
        : (chartPointsSoFar < 1 ? context.l10n.expenditureContinueHint : null);

    // Refonte du 21/08/2026 (retour d'Alex, maquette validée avant
    // implémentation) : les 2 barres fines (vignette compacte) ET les 2
    // anneaux séparés (écran dédié) remplacés par UN seul anneau + %
    // combiné + texte motivant — "la notion des deux curseurs... c'est nul,
    // ça parle pas à l'utilisateur". Le détail (conditions de pesée,
    // régularité du journal) n'est plus imposé en permanence : accessible
    // au tap, écran dédié uniquement (la vignette compacte navigue déjà
    // vers cet écran via _evolutionTapCard, profile_screen.dart — un 2e
    // niveau de tap y serait redondant).
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TotumReadinessRing(fraction: _combinedProgress, compact: compact),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary, height: 1.3)),
              if (subtext != null) ...[
                const SizedBox(height: 4),
                Text(subtext, style: TextStyle(fontSize: 11, height: 1.4, color: TotumColors.textSecondary)),
              ],
            ],
          ),
        ),
      ],
    );

    if (compact) return content;

    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.chevron_right, size: 14, color: TotumColors.textMuted),
                const SizedBox(width: 2),
                Text(context.l10n.expenditureTapForDetail,
                    style: TextStyle(fontSize: 10.5, color: TotumColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenditureScreen extends StatefulWidget {
  const ExpenditureScreen({super.key});
  @override
  State<ExpenditureScreen> createState() => _ExpenditureScreenState();
}

class _ExpenditureScreenState extends State<ExpenditureScreen> {
  // Jeu de plages recalibré (19/08/2026) sur la convention usuelle des apps
  // de suivi (MacroFactor notamment, cf. capture fournie par Alex) —
  // 1M/3M/6M/1A — plus lisible que l'ancien 1M/2M/3M/6M ("2M" est un
  // intervalle atypique, absent de la plupart des sélecteurs de plage).
  static const _ranges = {30: '1M', 90: '3M', 180: '6M', 365: '1A'};
  int _rangeDays = 90;
  late Future<List<ExpenditurePoint>> _future;
  // Chargé une seule fois (purement local, SharedPreferences — voir
  // ProfileStore.load()) pour la comparaison "ton chiffre vs ton métabolisme
  // de base théorique" dans la fiche d'information redessinée (demande
  // d'Alex, 20/08/2026 — comprendre IMMÉDIATEMENT pourquoi ce nombre peut
  // sembler bas).
  late final Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileStore.instance.load();
    _load();
  }

  void _load() => _future = CalibrationService.instance.expenditureHistory(days: _rangeDays);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: TotumColors.textPrimary,
        title: Text(context.l10n.expenditureScreenTitle,
            style: TextStyle(fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
      ),
      body: FutureBuilder<List<ExpenditurePoint>>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data ?? const <ExpenditurePoint>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rangeSelector(),
                const SizedBox(height: 16),
                TotumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BUG CORRIGÉ (19/08/2026, retour d'Alex — "1478 kcal"
                      // affiché seul, sans graphique, en contradiction avec
                      // le message "arrive bientôt" juste en dessous) :
                      // `data.isNotEmpty` (>=1 point) est un seuil PLUS BAS
                      // que celui d'[ExpenditureChart] pour tracer une vraie
                      // courbe (data.length<2 => repli "en cours"), donc un
                      // unique point (souvent lui-même instable, calculé sur
                      // une fenêtre à peine suffisante) pouvait afficher un
                      // chiffre nu pendant que le composant juste en dessous
                      // affichait encore l'état "pas prêt". Même seuil
                      // partout : le résumé n'apparaît que si le graphique
                      // apparaît aussi.
                      if (data.length >= 2) _summary(data),
                      if (data.length >= 2) const SizedBox(height: 14),
                      ExpenditureChart(data: data, height: 300),
                      const SizedBox(height: 14),
                      Row(children: [
                        Container(width: 9, height: 9, decoration: const BoxDecoration(color: TotumColors.accent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(context.l10n.expenditureEstimatedLegend, style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
                        const SizedBox(width: 16),
                        Container(width: 12, height: 9, color: TotumColors.accentSoft),
                        const SizedBox(width: 6),
                        Text(context.l10n.expenditureUncertaintyLegend, style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
                if (data.length >= 2) ...[
                  const SizedBox(height: 14),
                  _insightsCard(data),
                ],
                const SizedBox(height: 14),
                Text(
                  context.l10n.expenditureDisclaimer,
                  style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted, height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// "Insights & Data" — évolution de la dépense estimée sur 3j/7j, même
  /// esprit que le détail affiché sous le graphique Expenditure de
  /// MacroFactor.
  Widget _insightsCard(List<ExpenditurePoint> data) {
    Widget row(String label, int days) {
      final lastIdx = data.length - 1;
      final targetDate = data[lastIdx].date.subtract(Duration(days: days));
      int refIdx = 0;
      for (int i = 0; i <= lastIdx; i++) {
        if (!data[i].date.isAfter(targetDate)) refIdx = i;
      }
      final actualSpan = data[lastIdx].date.difference(data[refIdx].date).inDays;
      if (actualSpan < (days * 0.5)) return const SizedBox.shrink();
      final delta = data[lastIdx].estimateKcal - data[refIdx].estimateKcal;
      final icon = delta.abs() < 20 ? Icons.trending_flat : (delta > 0 ? Icons.trending_up : Icons.trending_down);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary))),
            Icon(icon, size: 15, color: TotumColors.textMuted),
            const SizedBox(width: 6),
            Text('${delta >= 0 ? '+' : ''}${delta.round()} kcal',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
          ],
        ),
      );
    }

    return TotumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.expenditureRecentEvolution,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
          row(context.l10n.lastNDays(3), 3),
          row(context.l10n.lastNDays(7), 7),
        ],
      ),
    );
  }

  Widget _rangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ranges.entries.map((e) {
          final selected = _rangeDays == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) => setState(() {
                _rangeDays = e.key;
                _load();
              }),
              selectedColor: TotumColors.accentSoft,
              labelStyle: TextStyle(
                  color: selected ? TotumColors.accent : TotumColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600),
              backgroundColor: TotumColors.surface,
              side: BorderSide(color: selected ? TotumColors.accentBorder : TotumColors.outline),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _summary(List<ExpenditurePoint> data) {
    final current = data.last.estimateKcal;
    final change = data.last.estimateKcal - data.first.estimateKcal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(current.round().toString(),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 5),
            child: Text(context.l10n.kcalPerDay, style: TextStyle(fontSize: 13, color: TotumColors.textSecondary))),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(999)),
            child: Text('${change >= 0 ? '+' : ''}${change.round()} kcal',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TotumColors.accent)),
          ),
        ),
        const Spacer(),
        // Priorité 71ter (20/08/2026, retour d'Alex — "je ne sais pas du tout
        // à quoi correspond ce chiffre... est-ce que ça correspond au
        // métabolisme de base, au mouvement, je ne comprends pas") : ce
        // nombre est une moyenne empirique glissante (poids réel + calories
        // réellement loguées sur ~20 jours), à ne SURTOUT PAS confondre avec
        // "Métabolisme de base" + "Mouvement" affichés sur le tableau de
        // bord (formule pour la journée en cours) — les deux peuvent
        // légitimement diverger nettement, en particulier quand le journal
        // n'est pas rempli tous les jours. Fiche d'information factuelle,
        // jamais de texte inventé — mêmes ingrédients que "Pourquoi ce
        // chiffre ?" juste en dessous.
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: IconButton(
            icon: Icon(Icons.info_outline, size: 20, color: TotumColors.textMuted),
            tooltip: context.l10n.expenditureInfoTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: () => _showInfoSheet(context, data),
          ),
        ),
      ],
    );
  }

  void _showInfoSheet(BuildContext context, List<ExpenditurePoint> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => ExpenditureInfoSheet(data: data, profileFuture: _profileFuture),
    );
  }
}

/// Fiche d'information "D'où vient ce chiffre ?" — refonte du 20/08/2026
/// (retour d'Alex : la version texte précédente, Priorité 71ter, "c'est
/// trop, on comprend pas" — demande explicite d'un rendu "effet waouh",
/// ultra visuel, façon slide de vulgarisation, compréhensible en quelques
/// secondes sans connaissance préalable). Extrait en widget public séparé
/// (au lieu de méthodes privées de `_ExpenditureScreenState`) précisément
/// pour être capturable par un test d'écran indépendant, sans dépendre du
/// chargement réseau Supabase de l'écran complet — voir
/// test/screens/expenditure_info_sheet_screenshot_test.dart.
class ExpenditureInfoSheet extends StatelessWidget {
  final List<ExpenditurePoint> data;
  final Future<UserProfile> profileFuture;
  const ExpenditureInfoSheet({super.key, required this.data, required this.profileFuture});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        // Scrollable : sur un petit écran, le contenu visuel dépasse
        // largement une hauteur de bottom sheet standard.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Retour d'Alex (21/08/2026) : sous-titre "En 30 secondes..."
              // retiré — le titre de _equation() ("Ta dépense totale : le
              // TDEE") enchaîne directement, sans texte d'accroche
              // intermédiaire redondant.
              Text(context.l10n.expenditureInfoTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
              const SizedBox(height: 16),
              _equation(context),
              const SizedBox(height: 22),
              _methods(context),
              const SizedBox(height: 22),
              _balance(context),
              const SizedBox(height: 20),
              FutureBuilder<UserProfile>(
                future: profileFuture,
                builder: (context, snap) {
                  final profile = snap.data;
                  if (profile == null || data.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _liveCompare(context, profile, data.last),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              Text(context.l10n.expenditureInfoCoverageWarning,
                  style: TextStyle(fontSize: 12, height: 1.45, color: TotumColors.textSecondary)),
              const SizedBox(height: 12),
              // Retour d'Alex (01/09/2026) : "j'ai peur que l'utilisateur ne
              // comprenne pas quand il doit enregistrer ses objectifs" —
              // explique ici, au seul endroit où l'utilisateur cherche
              // activement une explication (il vient de taper sur "ⓘ"), le
              // fonctionnement automatique déjà en place côté code
              // (computeAndSaveTargetsFromStoredProfile recalcule la
              // calibration à chaque ouverture) et la règle du jour en cours
              // jamais compté tant qu'il n'est pas terminé (voir le
              // correctif du même jour dans calibration_service.dart).
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TotumColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.autorenew_rounded, size: 16, color: TotumColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(context.l10n.expenditureInfoAutoRefresh,
                          style: TextStyle(fontSize: 12, height: 1.45, color: TotumColors.textPrimary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: TotumColors.outline, height: 1),
              const SizedBox(height: 14),
              Text(context.l10n.expenditureInfoScienceTitle,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4,
                      color: TotumColors.textMuted)),
              const SizedBox(height: 6),
              Text(context.l10n.expenditureInfoScienceBody,
                  style: TextStyle(fontSize: 11.5, height: 1.5, color: TotumColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TotumColors.textPrimary));

  /// VISUEL 1 — le TDEE (Total Daily Energy Expenditure) décomposé en ses 4
  /// composantes physiologiques réelles (BMR/TEF/EAT/NEAT), refonte du
  /// 21/08/2026 (retour explicite : employer ces termes précis, avec une
  /// barre PROPORTIONNELLE façon littérature de physiologie de l'exercice —
  /// la 1re version, 3 blocs de taille égale + émojis, ne montrait aucune
  /// proportion réelle). Pourcentages moyens (~70/15/10/5) largement admis
  /// en physiologie de l'exercice pour un adulte à activité modérée — PAS
  /// les chiffres personnels de l'utilisateur (voir _liveCompare plus bas
  /// pour ceux-là) ; couleurs = 4 arrêts de LA rampe accent unique de l'app
  /// (TotumProgress.stop100/75/50/25, jamais une nouvelle teinte — charte
  /// graphique, règle 5 de totum_style.dart), jamais un dégradé arc-en-ciel.
  Widget _equation(BuildContext context) {
    final segments = <({double pct, Color color, String label, String desc, String? lever})>[
      (pct: 0.70, color: TotumProgress.stop100, label: context.l10n.expenditureInfoEquationBmr,
          desc: context.l10n.expenditureInfoEquationBmrDesc, lever: null),
      (pct: 0.15, color: TotumProgress.stop75, label: context.l10n.expenditureInfoEquationNeat,
          desc: context.l10n.expenditureInfoEquationNeatDesc, lever: context.l10n.expenditureInfoNeatLeverBadge),
      (pct: 0.10, color: TotumProgress.stop50, label: context.l10n.expenditureInfoEquationTef,
          desc: context.l10n.expenditureInfoEquationTefDesc, lever: null),
      (pct: 0.05, color: TotumProgress.stop25, label: context.l10n.expenditureInfoEquationEat,
          desc: context.l10n.expenditureInfoEquationEatDesc, lever: null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.l10n.expenditureInfoEquationTitle),
        const SizedBox(height: 8),
        Text(context.l10n.expenditureInfoTdeeSpellOut,
            style: TextStyle(fontSize: 12, height: 1.4, color: TotumColors.textSecondary)),
        const SizedBox(height: 14),
        // Barre empilée — reflète l'ORDRE et l'échelle relative réelle
        // (structure = information), pas une simple décoration.
        //
        // Retour d'Alex (21/08/2026, 2e passe) : "essaye d'être proportionnel
        // au niveau des éléments, mais pour qu'on ait bien les 4 éléments qui
        // apparaissent sur le curseur" — la version strictement proportionnelle
        // (70/15/10/5%) rendait TEF (10%) et EAT (5%) trop étroits pour
        // afficher leur sigle, seuls BMR/NEAT apparaissaient. Un PLANCHER de
        // largeur visuelle (10% chacun) est appliqué avant répartition du
        // reste au prorata des vraies proportions — les 4 segments restent
        // dans le MÊME ORDRE et la MÊME hiérarchie relative (BMR > NEAT > TEF
        // > EAT), juste assez larges pour porter leur sigle. Les VRAIS
        // pourcentages (70/15/10/5, jamais modifiés) restent affichés en
        // toutes lettres juste en dessous et dans la légende — la barre est
        // une lecture d'ensemble, pas la source du chiffre.
        Builder(
          builder: (context) {
            const visualFloor = 0.10;
            final n = segments.length;
            final remaining = 1 - visualFloor * n;
            final visualFlex = [for (final s in segments) visualFloor + s.pct * remaining];
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 18,
                child: Row(
                  children: [
                    for (int i = 0; i < segments.length; i++)
                      Expanded(
                        flex: (visualFlex[i] * 1000).round(),
                        child: Container(
                          color: segments[i].color,
                          alignment: Alignment.center,
                          child: Text(segments[i].label.split('—').first.trim(),
                              style: const TextStyle(
                                  fontSize: 9.5, fontWeight: FontWeight.w800,
                                  color: Colors.white, letterSpacing: 0.3)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(context.l10n.expenditureInfoTdeeCaption,
            style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: TotumColors.textMuted)),
        const SizedBox(height: 14),
        for (final s in segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.label,
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                          ),
                          Text('${(s.pct * 100).round()} %',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TotumColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(s.desc,
                          style: TextStyle(fontSize: 11.5, height: 1.4, color: TotumColors.textSecondary)),
                      if (s.lever != null) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                          child: Text(s.lever!,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: TotumColors.accent)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// VISUEL 2 — les 2 méthodes utilisées ensemble par Totum : la formule
  /// (théorique, pilote l'objectif du jour) vs la calibration (réelle,
  /// pilote CE graphique). Reprend le contenu factuel déjà validé
  /// (expenditureInfoWhatItIs/VsToday), mais en 2 cartes côte à côte avec
  /// icône + titre + description courte, plutôt qu'un paragraphe dense.
  Widget _methods(BuildContext context) {
    // Charte graphique (règle 3, totum_style.dart) : pictogrammes = icônes
    // Material monochromes uniquement, jamais d'emoji — corrigé le
    // 21/08/2026 (audit charte demandé par Alex).
    Widget card(IconData icon, String title, String desc) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: TotumColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TotumColors.outline)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: TotumColors.accent),
                const SizedBox(height: 6),
                Text(title,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(fontSize: 11, height: 1.4, color: TotumColors.textSecondary)),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.l10n.expenditureInfoMethodsTitle),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(Icons.calculate_outlined, context.l10n.expenditureInfoMethodFormulaTitle, context.l10n.expenditureInfoMethodFormulaDesc),
              const SizedBox(width: 10),
              card(Icons.show_chart_rounded, context.l10n.expenditureInfoMethodCalibTitle, context.l10n.expenditureInfoMethodCalibDesc),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(context.l10n.expenditureInfoMethodsFooter,
            style: TextStyle(fontSize: 11.5, height: 1.4, fontStyle: FontStyle.italic, color: TotumColors.textMuted)),
      ],
    );
  }

  /// VISUEL 3 — le principe d'équilibre énergétique en une image mentale
  /// simple (balance ⚖️) : c'est littéralement toute l'équation utilisée par
  /// [CalibrationService.computeCalibration]/[CalibrationService.expenditureHistory].
  Widget _balance(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Charte graphique (règle 3) : icône Material monochrome, jamais
          // d'emoji — corrigé le 21/08/2026.
          const Icon(Icons.balance, size: 24, color: TotumColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.expenditureInfoBalanceTitle,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
                const SizedBox(height: 4),
                Text(context.l10n.expenditureInfoBalanceBody,
                    style: TextStyle(fontSize: 12, height: 1.45, color: TotumColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Comparaison EN DIRECT du chiffre affiché vs le plancher métabolique de
  /// sécurité déjà utilisé ailleurs dans l'app pour l'objectif calorique
  /// (voir minSafeKcalFor dans profile.dart, 90% du BMR théorique) — jamais
  /// un nouveau seuil inventé ici. Répond directement à la question d'Alex
  /// ("est-ce que le calcul est correct ?") en rendant visible, au moment où
  /// le chiffre est consulté, la seule vérification de plausibilité qui
  /// compte vraiment : ce nombre est-il physiologiquement crédible ?
  Widget _liveCompare(BuildContext context, UserProfile profile, ExpenditurePoint latest) {
    final bmr = computeBmr(profile);
    final floor = minSafeKcalFor(profile.sex, bmr);
    final estimate = latest.estimateKcal;
    final below = estimate < floor;
    // Retour d'Alex (21/08/2026) : "cohérent avec une activité normale" ne
    // disait rien de concret. `nearestActivityLevel` existe déjà (profile.dart)
    // — explicitement documenté "affichage/diagnostic uniquement, jamais pour
    // recalculer protéines/micronutriments" (voir son commentaire), exactement
    // cet usage. Rattache le chiffre à un repère concret et déjà connu de
    // l'utilisateur (le même palier qu'il choisit dans Profil), au lieu d'un
    // qualificatif vague.
    final impliedLevel = bmr > 0 ? nearestActivityLevel(estimate / bmr) : profile.activity;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TotumColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: below ? TotumColors.negative.withValues(alpha: 0.4) : TotumColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(below ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  size: 16, color: below ? TotumColors.negative : TotumColors.positive),
              const SizedBox(width: 6),
              Text(context.l10n.expenditureInfoLiveCompareTitle,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            below
                ? context.l10n.expenditureInfoBelowBmr(estimate.round(), bmr.round())
                : context.l10n.expenditureInfoAboveBmr(
                    estimate.round(), bmr.round(), impliedLevel.titleFor(context.l10n)),
            style: TextStyle(fontSize: 12, height: 1.45, color: TotumColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
