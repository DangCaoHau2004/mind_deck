import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/fsrs_logic.dart';

class ForgettingCurveChart extends StatelessWidget {
  const ForgettingCurveChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Giả sử thẻ đang có S_old = 4 ngày (Grade 4 ở lần học đầu)
    List<FlSpot> spots = FsrsLogic.generateForgettingCurveSpots(4.0, 10);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value % 2 != 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(
                    'Ngày ${value.toInt()}',
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
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
