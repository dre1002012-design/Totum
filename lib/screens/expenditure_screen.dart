// lib/screens/expenditure_screen.dart
//
// Graphique "Dépense énergétique" façon MacroFactor Expenditure : ligne de
// dépense estimée + bande d'incertitude, dérivées de calibration_service
// .expenditureHistory(). Approximation inspirée du rendu MacroFactor, PAS
// une reproduction de leur algorithme propriétaire — voir le commentaire de
// expenditureHistory() dans calibration_service.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/calibration_service.dart';
import '../theme/totum_style.dart';

class ExpenditureChart extends StatelessWidget {
  final List<ExpenditurePoint> data;
  final double height;
  const ExpenditureChart({super.key, required this.data, this.height = 110});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      // Bug corrigé (14/08/2026, retour d'Alex — toujours coupée malgré la
      // Priorité 48) : ce panneau empile un titre + 2 lignes complètes
      // (libellé + compteur + barre de progression), bien plus dense que la
      // simple courbe de la vignette Poids qui, elle, tient sans problème
      // dans 110px — 110px restait juste trop serré une fois le padding du
      // conteneur déduit, même avec les libellés compacts. Relevé
      // spécifiquement pour cet état (jamais pour le vrai graphique une
      // fois assez de données, qui reste à la hauteur demandée par l'appelant).
      return _ExpenditureProgress(height: height < 160 ? 132 : height);
    }
    final firstDay = data.first.date;
    double x(DateTime d) => d.difference(firstDay).inDays.toDouble();
    final lowSpots = data.map((p) => FlSpot(x(p.date), p.lowKcal)).toList();
    final highSpots = data.map((p) => FlSpot(x(p.date), p.highKcal)).toList();
    final centerSpots = data.map((p) => FlSpot(x(p.date), p.estimateKcal)).toList();
    final minY = data.map((p) => p.lowKcal).reduce((a, b) => a < b ? a : b) - 30;
    final maxY = data.map((p) => p.highKcal).reduce((a, b) => a > b ? a : b) + 30;
    String fmtDate(DateTime d) => '${d.day}/${d.month}';

    return SizedBox(
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
          lineBarsData: [
            // Bornes basse/haute — invisibles, elles ne servent qu'à ancrer
            // la bande d'incertitude ombragée (betweenBarsData ci-dessous).
            LineChartBarData(
                spots: lowSpots, isCurved: true, color: Colors.transparent, barWidth: 0, dotData: const FlDotData(show: false)),
            LineChartBarData(
                spots: highSpots, isCurved: true, color: Colors.transparent, barWidth: 0, dotData: const FlDotData(show: false)),
            // Ligne centrale — l'estimation elle-même.
            LineChartBarData(
                spots: centerSpots, isCurved: true, color: TotumColors.accent, barWidth: 2.5, dotData: const FlDotData(show: false)),
          ],
          betweenBarsData: [
            BetweenBarsData(fromIndex: 0, toIndex: 1, color: TotumColors.accentSoft),
          ],
        ),
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
  const _ExpenditureProgress({required this.height});

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
              : _ProgressBody(r: r, compact: height < 160),
        );
      },
    );
  }
}

class _ProgressBody extends StatelessWidget {
  final ExpenditureReadiness r;
  final bool compact;
  const _ProgressBody({required this.r, required this.compact});

  @override
  Widget build(BuildContext context) {
    // Bug retour d'Alex (13/08/2026) : "la vignette est coupée" — le libellé
    // long ("Repas renseignés (20 derniers jours)") passait sur 2 lignes
    // dans la carte étroite du tableau de bord, dépassant les 110px fixes
    // (même hauteur que la vignette Poids) — silencieusement rogné par le
    // SingleChildScrollView. Libellés courts en mode compact, garantis sur
    // une seule ligne ; version complète conservée sur l'écran dédié.
    Widget bar(String label, String compactLabel, String count, double progress) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(compact ? compactLabel : label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
                Text(count, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: TotumColors.outline,
                color: progress >= 1.0 ? TotumColors.positive : TotumColors.accent,
              ),
            ),
          ],
        );

    // Hauteur compacte (carte du tableau de bord) : titre + 2 barres, sans
    // le texte d'accompagnement, pour ne jamais déborder du conteneur.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.weighInsCount < 2
                ? 'Pas encore assez de pesées pour démarrer le calcul'
                : 'Ta dépense énergétique estimée arrive bientôt',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: TotumColors.textPrimary),
          ),
          SizedBox(height: compact ? 6 : 10),
          if (r.weighInsCount < 2)
            Text(
              'Ajoute au moins une 2e pesée (tu en as ${r.weighInsCount}/2) pour que le calcul puisse démarrer.',
              style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted, height: 1.4),
            )
          else ...[
            bar('Écart entre 2 pesées', 'Écart pesées', '${r.spanDays}/${r.minSpanDays} j', r.spanProgress),
            SizedBox(height: compact ? 6 : 10),
            bar('Repas renseignés (20 derniers jours)', 'Repas renseignés', '${r.daysWithFoodLogged}/${r.minFoodDays} j', r.foodProgress),
            if (!compact) ...[
              const SizedBox(height: 10),
              Text(
                'Continue à te peser et à noter tes repas régulièrement — ta dépense apparaîtra automatiquement dès ces deux seuils atteints.',
                style: TextStyle(fontSize: 11, color: TotumColors.textMuted, height: 1.35),
              ),
            ],
          ],
        ],
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
  static const _ranges = {30: '1M', 60: '2M', 90: '3M', 180: '6M'};
  int _rangeDays = 60;
  late Future<List<ExpenditurePoint>> _future;

  @override
  void initState() {
    super.initState();
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
        title: Text('Dépense énergétique',
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
                      if (data.isNotEmpty) _summary(data),
                      if (data.isNotEmpty) const SizedBox(height: 14),
                      ExpenditureChart(data: data, height: 300),
                      const SizedBox(height: 14),
                      Row(children: [
                        Container(width: 9, height: 9, decoration: const BoxDecoration(color: TotumColors.accent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Dépense estimée', style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
                        const SizedBox(width: 16),
                        Container(width: 12, height: 9, color: TotumColors.accentSoft),
                        const SizedBox(width: 6),
                        Text('Marge d\'incertitude', style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
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
                  'Cette estimation est calculée à partir de ton poids et de ton journal alimentaire (même principe que la '
                  'calibration adaptative de TOTUM) — ce n\'est pas une mesure directe, ni une reproduction de l\'algorithme '
                  'propriétaire d\'une autre application. Plus tu renseignes ton poids et tes repas régulièrement, plus la '
                  'marge d\'incertitude se resserre.',
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
          Text('Évolution récente',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TotumColors.textPrimary)),
          row('3 derniers jours', 3),
          row('7 derniers jours', 7),
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
            child: Text('kcal/j', style: TextStyle(fontSize: 13, color: TotumColors.textSecondary))),
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
      ],
    );
  }
}
