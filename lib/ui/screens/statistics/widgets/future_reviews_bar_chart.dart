import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FutureReviewsBarChart extends StatelessWidget {
  const FutureReviewsBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData group) => colorScheme.onSurface,
            getTooltipItem:
                (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.round()} thẻ\n~ ${(rod.toY * 0.1).round()} phút',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    days[value.toInt()],
                    style: TextStyle(color: colorScheme.outline, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: colorScheme.outline.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBar(0, 45, colorScheme),
          _buildBar(1, 80, colorScheme),
          _buildBar(2, 30, colorScheme),
          _buildBar(3, 50, colorScheme),
          _buildBar(4, 90, colorScheme),
          _buildBar(5, 20, colorScheme),
          _buildBar(6, 10, colorScheme),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y, ColorScheme colorScheme) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: colorScheme.tertiary,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: colorScheme.surfaceContainer,
          ),
        ),
      ],
    );
  }
}
