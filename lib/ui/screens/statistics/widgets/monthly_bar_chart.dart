import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';

class MonthlyBarChart extends StatelessWidget {
  final Map<int, double> monatsKm;
  final double? monatlichesZiel;

  const MonthlyBarChart({
    super.key,
    required this.monatsKm,
    this.monatlichesZiel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWert = monatsKm.values.fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = (maxWert * 1.2).clamp(100.0, double.infinity);

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} km',
                  TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= 12) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      AppDateUtils.monatsNamen[index],
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
          ),
          extraLinesData: monatlichesZiel != null
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: monatlichesZiel!,
                      color: Colors.red.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [8, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Ziel',
                        style: TextStyle(
                          color: Colors.red.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          barGroups: List.generate(12, (index) {
            final monat = index + 1;
            final km = monatsKm[monat] ?? 0.0;
            final istAktuellerMonat =
                monat == DateTime.now().month;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: km,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  color: istAktuellerMonat
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
