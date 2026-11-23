import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mind_deck/constants/custom_colors.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/home/home_fsrs_stats_model.dart';
import 'package:mind_deck/core/theme/app_styles.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Độ chính xác 7 ngày: số lớn ở đầu thẻ, cột theo ngày với hàng % thẳng hàng trên cùng,
/// đường nét đứt ở mức trung bình (chú thích "trung bình" dưới số lớn), cột mọc dần khi tải xong.
/// Ngày chưa học hiện "–" màu xám; ngày ôn sai hết hiện "0%" màu đỏ nhạt (cột đều chỉ có nền).
class AccuracyChartCard extends StatefulWidget {
  final HomeFsrsStatsModel stats;

  const AccuracyChartCard({super.key, required this.stats});

  @override
  State<AccuracyChartCard> createState() => _AccuracyChartCardState();
}

class _AccuracyChartCardState extends State<AccuracyChartCard> {
  /// Ngưỡng màu (do thiết kế chọn): từ 80% là ổn, 30–79% chưa ổn (cam), dưới 30% đỏ nhạt.
  static const double _goodThreshold = 80;
  static const double _okThreshold = 30;
  static const Duration _growDuration = Duration(milliseconds: 900);

  static const double _chartHeight = 200;
  static const double _topLabelsHeight = 24;
  static const double _bottomLabelsHeight = 28;

  /// Màu đường trung bình, dùng chung cho đường trong biểu đồ và mẫu nét đứt ở chú thích.
  static Color _avgLineColor(ColorScheme colorScheme) =>
      colorScheme.onSurface.withValues(alpha: 0.45);

  /// false: cột đang ở 0, chờ khung hình đầu tiên (sau khi hết skeleton) rồi mới mọc lên.
  bool _grown = false;
  bool _growScheduled = false;

  /// Nhãn thứ viết tắt theo ngôn ngữ (DateTime.weekday: thứ 2 = 1 … chủ nhật = 7).
  static String _weekdayLabel(DateTime d) => 'weekday_short_${d.weekday}'.tr;

  static Color _levelColor(double accuracy, ColorScheme colorScheme) {
    if (accuracy >= _goodThreshold) return colorScheme.primary;
    if (accuracy >= _okThreshold) return CustomColors.accuracyWarning;
    return CustomColors.accuracyBad;
  }

  /// Lúc skeleton thì giữ cột ở 0; hết skeleton thì sang khung hình sau cho cột mọc lên (BarChart tự animate).
  void _scheduleGrowIfNeeded(bool skeleton) {
    if (skeleton || _grown || _growScheduled) return;
    _growScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final skeleton = Skeletonizer.maybeOf(context)?.enabled ?? false;
    _scheduleGrowIfNeeded(skeleton);

    final days = widget.stats.filledChart();
    final avg = widget.stats.accuracy;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppStyles.cardShadow(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'home_accuracy_title'.tr,
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            avg == null ? 'home_not_studied'.tr : '${avg.round()}%',
            style: (avg == null ? textTheme.headlineMedium : textTheme.displayLarge)?.copyWith(
              color: avg == null ? colorScheme.outline : colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          if (avg != null)
            // "câu trả lời đúng" bên trái, chú thích đường nét đứt "trung bình" bên phải.
            Row(
              children: [
                Expanded(
                  child: Text(
                    'home_accuracy_caption'.tr,
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                CustomPaint(
                  size: const Size(24, 2),
                  painter: _DashedLinePainter(color: _avgLineColor(colorScheme)),
                ),
                const SizedBox(width: 6),
                Text(
                  'home_accuracy_avg_legend'.tr,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Biểu đồ vẽ bằng canvas, Skeletonizer không tự phủ được nên thay bằng một khối lúc tải.
          Skeleton.replace(
            width: double.infinity,
            height: _chartHeight,
            child: SizedBox(
              height: _chartHeight,
              child: _buildChart(days, avg, colorScheme, textTheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    List<HomeChartModel> days,
    double? avg,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return BarChart(
      duration: _growDuration,
      curve: Curves.easeOutCubic,
      BarChartData(
        minY: 0,
        maxY: 100,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: const BarTouchData(enabled: false),
        // Đường trung bình 7 ngày, chỉ vẽ khi đã có số và cột đã mọc.
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (avg != null && _grown)
              HorizontalLine(
                y: avg,
                color: _avgLineColor(colorScheme),
                strokeWidth: 1.5,
                dashArray: [6, 4],
              ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // Hàng % thẳng hàng trên cùng, cùng màu với cột.
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _topLabelsHeight,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final acc = days[i].accuracy;
                return Text(
                  acc == null ? '–' : '${acc.round()}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: acc == null ? colorScheme.outline : _levelColor(acc, colorScheme),
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _bottomLabelsHeight,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final isToday = i == days.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _weekdayLabel(days[i].date),
                    style: textTheme.labelMedium?.copyWith(
                      color: isToday ? colorScheme.primary : colorScheme.outline,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _grown ? (days[i].accuracy ?? 0) : 0,
                  width: 28,
                  borderRadius: BorderRadius.circular(8),
                  color: _levelColor(days[i].accuracy ?? 0, colorScheme),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Đoạn nét đứt nằm ngang, dùng làm mẫu cho chú thích "trung bình".
class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + _dash).clamp(0, size.width), y), paint);
      x += _dash + _gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
