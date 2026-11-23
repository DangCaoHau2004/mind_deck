import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DailyAccuracyChart extends StatelessWidget {
  const DailyAccuracyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: colorScheme.outline.withValues(alpha: 0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: colorScheme.outline.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    'N${value.toInt()}',
                    style: TextStyle(color: colorScheme.outline, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()}%',
                    style: TextStyle(color: colorScheme.outline, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: 7,
        minY: 50,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(1, 80),
              FlSpot(2, 85),
              FlSpot(3, 75),
              FlSpot(4, 90),
              FlSpot(5, 95),
              FlSpot(6, 88),
              FlSpot(7, 92),
            ],
            isCurved: false,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
