// lib/screens/weight_trend_screen.dart
//
// Graphique "Poids" façon MacroFactor Weight Trend : poids brut + poids
// tendance (lissage exponentiel, voir calibration_service.emaTrend). Le
// widget de graphique (WeightTrendChart) est réutilisé en compact sur le
// tableau de bord et en grand ici.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/calibration_service.dart';
import '../services/units.dart';
import '../theme/totum_style.dart';

class WeightTrendChart extends StatelessWidget {
  final List<WeighIn> data;
  final double height;
  final bool compact;
  const WeightTrendChart({super.key, required this.data, this.height = 110, this.compact = true});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return Container(
        height: compact ? 90 : height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: TotumColors.page, borderRadius: BorderRadius.circular(12)),
        child: Text(
          'Sauvegarde ton profil à quelques jours d\'écart pour voir ta courbe apparaître ici.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted),
        ),
      );
    }
    return ValueListenableBuilder<UnitSystem>(
      valueListenable: AppSettings.unitSystem,
      builder: (context, system, _) => _buildChart(context, system),
    );
  }

  Widget _buildChart(BuildContext context, UnitSystem system) {
    double toDisplay(double kg) => system == UnitSystem.imperial ? Units.kgToLb(kg) : kg;
    final unitLabel = Units.weightUnitLabel(system);

    final trend = emaTrend(data).map(toDisplay).toList();
    final allY = [...data.map((w) => toDisplay(w.weightKg)), ...trend];
    final minY = allY.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = allY.reduce((a, b) => a > b ? a : b) + 0.5;
    // Priorité 58 (14/08/2026, audit captures Play Store) : sur une plage
    // resserrée (ex. poids stable sur 1 mois), un pas de grille fractionnaire
    // (ex. 0.77 kg) arrondi à l'entier le plus proche pour l'affichage
    // produisait 2 lignes voisines avec le MÊME libellé ("73" en double,
    // "71" en double, vu directement sur la capture). Un pas < 1 affiche
    // désormais 1 décimale — chaque ligne reste visuellement distincte.
    final yInterval = ((maxY - minY) / 3).clamp(0.5, 100).toDouble();
    final yLabelDecimals = yInterval < 1 ? 1 : 0;
    final firstDay = data.first.date;
    final rawSpots =
        data.map((w) => FlSpot(w.date.difference(firstDay).inDays.toDouble(), toDisplay(w.weightKg))).toList();
    final trendSpots = <FlSpot>[
      for (int i = 0; i < data.length; i++) FlSpot(data[i].date.difference(firstDay).inDays.toDouble(), trend[i]),
    ];
    String fmtDate(DateTime d) => '${d.day}/${d.month}';

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: rawSpots.last.x,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(color: TotumColors.outline, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: yInterval,
                getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(yLabelDecimals),
                    style: TextStyle(fontSize: 9.5, color: TotumColors.textMuted)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: (rawSpots.last.x / 3).clamp(1, 999),
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
          // Sans ce réglage, fl_chart utilise son tooltip par défaut qui
          // affiche la valeur brute (nombreuses décimales issues du calcul
          // de tendance EMA) — retour d'Alex (12/08/2026) : forcé à 2
          // décimales max, cohérent avec l'affichage du résumé au-dessus.
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final isTrend = s.barIndex == 1;
                return LineTooltipItem(
                  '${s.y.toStringAsFixed(2)} $unitLabel',
                  TextStyle(
                    color: isTrend ? TotumColors.accent : TotumColors.outlineStrong,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            // Poids brut — fin, en retrait, pour laisser la tendance dominer.
            LineChartBarData(
              spots: rawSpots,
              isCurved: true,
              color: TotumColors.outlineStrong,
              barWidth: 1.5,
              dotData: FlDotData(show: !compact && data.length <= 20),
            ),
            // Poids tendance — lissé, c'est la ligne qui porte le message
            // ("fin des montagnes russes du pèse-personne").
            LineChartBarData(
              spots: trendSpots,
              isCurved: true,
              color: TotumColors.accent,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                    colors: [TotumColors.accentSoft, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeightTrendScreen extends StatefulWidget {
  const WeightTrendScreen({super.key});
  @override
  State<WeightTrendScreen> createState() => _WeightTrendScreenState();
}

class _WeightTrendScreenState extends State<WeightTrendScreen> {
  static const _ranges = {30: '1M', 90: '3M', 180: '6M', 365: '1A', 3650: 'Tout'};
  int _rangeDays = 90;
  late Future<List<WeighIn>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = CalibrationService.instance.recentHistory(_rangeDays);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TotumColors.page,
      appBar: AppBar(
        backgroundColor: TotumColors.page,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: TotumColors.textPrimary,
        title: Text('Poids', style: TextStyle(fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
      ),
      body: FutureBuilder<List<WeighIn>>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data ?? const <WeighIn>[];
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
                      if (data.length >= 2) _summary(data),
                      if (data.length >= 2) const SizedBox(height: 14),
                      WeightTrendChart(data: data, height: 300, compact: false),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _legendDot(TotumColors.outlineStrong, 'Poids brut'),
                          const SizedBox(width: 16),
                          _legendDot(TotumColors.accent, 'Poids tendance'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (data.length >= 2) ...[
                  const SizedBox(height: 14),
                  _insightsCard(data),
                ],
                const SizedBox(height: 14),
                Text(
                  'Pèse-toi si possible tous les jours, dans les mêmes conditions à chaque fois — idéalement le matin à jeun, au lever. '
                  'La fiabilité de la tendance — et de tes objectifs recalculés — dépend directement de cette régularité.',
                  style: TextStyle(fontSize: 11.5, color: TotumColors.textMuted, height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// "Insights & Data" — évolution du poids tendance sur 3j/7j, même esprit
  /// que le détail que montre MacroFactor sous ses graphiques.
  Widget _insightsCard(List<WeighIn> data) {
    final system = AppSettings.unitSystem.value;
    final unitLabel = Units.weightUnitLabel(system);
    final trend = emaTrend(data);
    Widget row(String label, int days) {
      final lastIdx = data.length - 1;
      final targetDate = data[lastIdx].date.subtract(Duration(days: days));
      int refIdx = 0;
      for (int i = 0; i <= lastIdx; i++) {
        if (!data[i].date.isAfter(targetDate)) refIdx = i;
      }
      final actualSpan = data[lastIdx].date.difference(data[refIdx].date).inDays;
      if (actualSpan < (days * 0.5)) return const SizedBox.shrink();
      final deltaKg = trend[lastIdx] - trend[refIdx];
      final delta = system == UnitSystem.imperial ? Units.kgToLb(deltaKg) : deltaKg;
      final icon = delta.abs() < 0.05 ? Icons.trending_flat : (delta > 0 ? Icons.trending_up : Icons.trending_down);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: TotumColors.textSecondary))),
            Icon(icon, size: 15, color: TotumColors.textMuted),
            const SizedBox(width: 6),
            Text('${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unitLabel',
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
          Text('Évolution récente (poids tendance)',
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

  Widget _summary(List<WeighIn> data) {
    final system = AppSettings.unitSystem.value;
    final unitLabel = Units.weightUnitLabel(system);
    final current = Units.displayWeight(data.last.weightKg, system);
    final changeKg = data.last.weightKg - data.first.weightKg;
    final change = system == UnitSystem.imperial ? Units.kgToLb(changeKg) : changeKg;
    final totalDays = data.last.date.difference(data.first.date).inDays.clamp(1, 999);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(current.toStringAsFixed(1),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TotumColors.textPrimary)),
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 5),
            child: Text(unitLabel, style: TextStyle(fontSize: 13, color: TotumColors.textSecondary))),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: TotumColors.accentSoft, borderRadius: BorderRadius.circular(999)),
            child: Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} $unitLabel / ${totalDays}j',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TotumColors.accent)),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11.5, color: TotumColors.textSecondary)),
    ]);
  }
}
