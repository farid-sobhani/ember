import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'theme.dart';
import 'utils.dart';

const _axisStyle = TextStyle(color: AppColors.muted, fontSize: 11);

FlTitlesData _titles(double interval, String Function(int) bottom, {int every = 1}) =>
    FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 38,
          interval: interval,
          getTitlesWidget: (v, meta) => v == meta.max
              ? const SizedBox()
              : Text(compactNum(v), style: _axisStyle),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i % every != 0) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(bottom(i), style: _axisStyle),
            );
          },
        ),
      ),
    );

FlGridData _grid(double interval) => FlGridData(
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: AppColors.line, strokeWidth: 1, dashArray: [4, 4]),
    );

ExtraLinesData _goalLine(double goal) => ExtraLinesData(horizontalLines: [
      HorizontalLine(
        y: goal,
        color: AppColors.mint.withAlpha(170),
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: const TextStyle(
              color: AppColors.mint, fontSize: 11, fontWeight: FontWeight.w600),
          labelResolver: (_) => 'goal',
        ),
      ),
    ]);

const _rodRadius = BorderRadius.vertical(top: Radius.circular(5));
const _rodGradient = LinearGradient(
  colors: [AppColors.ember, AppColors.rose],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
);

/// 7 days: current week (ember) vs previous week (slate), side by side.
class WeekCompareChart extends StatelessWidget {
  final List<double> current;
  final List<double> previous;
  final double goal;
  const WeekCompareChart(
      {super.key, required this.current, required this.previous, required this.goal});

  @override
  Widget build(BuildContext context) {
    final all = [...current, ...previous, goal];
    final maxY = niceMax(all.reduce((a, b) => a > b ? a : b));
    final interval = maxY / 4;
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: _grid(interval),
        borderData: FlBorderData(show: false),
        titlesData: _titles(interval, (i) => weekdayShort[i]),
        extraLinesData: _goalLine(goal),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface2,
            tooltipRoundedRadius: 10,
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${ri == 0 ? 'Prev' : 'This'}: ${fmtNum(rod.toY)}',
              TextStyle(
                  color: ri == 0 ? AppColors.muted : AppColors.ember,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ),
        barGroups: List.generate(
          7,
          (i) => BarChartGroupData(x: i, barsSpace: 3, barRods: [
            BarChartRodData(
                toY: previous[i], width: 9, color: AppColors.slate, borderRadius: _rodRadius),
            BarChartRodData(
                toY: current[i], width: 9, gradient: _rodGradient, borderRadius: _rodRadius),
          ]),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 350),
    );
  }
}

/// Single series of bars; the bar at [highlight] is ember, others dimmer.
class SimpleBarChart extends StatelessWidget {
  final List<double> values;
  final String Function(int) label;
  final double? goal;
  final int? highlight;
  final int labelEvery;
  final double barWidth;
  final String tooltipSuffix;
  const SimpleBarChart({
    super.key,
    required this.values,
    required this.label,
    this.goal,
    this.highlight,
    this.labelEvery = 1,
    this.barWidth = 18,
    this.tooltipSuffix = 'kcal',
  });

  @override
  Widget build(BuildContext context) {
    final m = [...values, goal ?? 0].reduce((a, b) => a > b ? a : b);
    final maxY = niceMax(m);
    final interval = maxY / 4;
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: _grid(interval),
        borderData: FlBorderData(show: false),
        titlesData: _titles(interval, label, every: labelEvery),
        extraLinesData: goal == null ? null : _goalLine(goal!),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface2,
            tooltipRoundedRadius: 10,
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${label(group.x)}\n${fmtNum(rod.toY)} $tooltipSuffix',
              const TextStyle(
                  color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),
        barGroups: List.generate(values.length, (i) {
          final hot = highlight == null || highlight == i;
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: values[i],
              width: barWidth,
              borderRadius: _rodRadius,
              gradient: hot ? _rodGradient : null,
              color: hot ? null : AppColors.slate,
            ),
          ]);
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 350),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const LegendDot(this.color, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ]);
}
