import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mind_deck/data/models/stats_model.dart';

Widget buildCardContainer(BuildContext context, String title, Widget child) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class StreakSection extends StatelessWidget {
  final StreakStats streak;
  const StreakSection({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Chuỗi hiện tại',
            value: '${streak.currentStreak} ngày',
            icon: Icons.local_fire_department,
            iconColor: streak.isIntact ? Colors.orange : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Kỷ lục',
            value: '${streak.maxStreak} ngày',
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class HeatmapSection extends StatelessWidget {
  final List<HeatmapStats> data;
  const HeatmapSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return buildCardContainer(
        context,
        'Tần suất học tập',
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chưa có đủ dữ liệu học tập',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final Map<String, int> dateCountMap = {};
    for (final item in data) {
      final date = DateTime.tryParse(item.date)?.toLocal();
      if (date != null) {
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        dateCountMap[dateStr] = item.count;
      }
    }

    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 29));
    final emptyStartCells = startDate.weekday - 1; // 0 for Monday
    final colorScheme = Theme.of(context).colorScheme;

    return buildCardContainer(
      context,
      'Tần suất học tập (30 ngày qua)',
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
                Expanded(
                  child: Center(child: Text(day, style: Theme.of(context).textTheme.labelSmall)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: emptyStartCells + 30,
            itemBuilder: (ctx, index) {
              if (index < emptyStartCells) return const SizedBox.shrink();

              final dayIndex = index - emptyStartCells;
              final date = startDate.add(Duration(days: dayIndex));
              final dateStr =
                  "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              final count = dateCountMap[dateStr] ?? 0;

              Color color;
              if (count == 0) {
                color = colorScheme.surfaceContainerHigh;
              } else if (count <= 5) {
                color = colorScheme.primary.withValues(alpha: 0.2);
              } else if (count <= 10) {
                color = colorScheme.primary.withValues(alpha: 0.4);
              } else if (count <= 20) {
                color = colorScheme.primary.withValues(alpha: 0.7);
              } else {
                color = colorScheme.primary;
              }
              return Tooltip(
                message: '${date.day}/${date.month}/${date.year}: $count thẻ',
                preferBelow: false,
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      width: 0.5, // Độ mỏng của viền
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Ít',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2), // Bo góc nhẹ cho đồng bộ
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    width: 0.5,
                  ), // Viền nhẹ
                ),
              ),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Nhiều',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AccuracySection extends StatelessWidget {
  final List<AccuracyStats> data;
  const AccuracySection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return buildCardContainer(
        context,
        'Độ chính xác',
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chưa có đủ dữ liệu học tập',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return buildCardContainer(
      context,
      'Độ chính xác',
      SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            // 1. THÊM ĐOẠN NÀY: Tùy chỉnh Tooltip khi click vào điểm
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.black87, // Màu nền của tooltip (đen mờ)
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y}%', // Hiển thị số %
                      const TextStyle(
                        color: Colors.white, // Sửa chữ thành màu trắng để dễ đọc trên nền đen
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: colorScheme.surfaceContainerHigh, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= data.length) return const SizedBox.shrink();
                    final item = data[value.toInt()];
                    final date = DateTime.tryParse(item.date)?.toLocal();
                    if (date == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  // 2. SỬA Ở ĐÂY: Tăng reservedSize từ 32 lên 44 (hoặc 48) để kéo giãn cột số ra xa biểu đồ
                  reservedSize: 58,
                  getTitlesWidget: (value, meta) {
                    // Thêm Padding để ép chữ sát sang lề trái hoặc lề phải tùy ý
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 24.0,
                      ), // Đẩy chữ cách cái biểu đồ ra 8 pixel
                      child: Text(
                        '${value.toInt()}%',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value.accuracy);
                }).toList(),
                isCurved: true,
                color: colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.3),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FutureReviewsSection extends StatelessWidget {
  final List<FutureReviewStats> data;
  const FutureReviewsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final Map<String, int> dateDueMap = {};
    // BE trả `futureReviews` 7 ngày GỒM HÔM NAY (hôm nay + 6 ngày tới, theo giờ máy);
    // ngày không có thẻ đến hạn không có trong mảng nên tự điền 0. Thẻ quá hạn từ trước hôm nay
    // không nằm trong lịch này (xem `dueNow.overdue`).
    for (final item in data) {
      final date = DateTime.tryParse(item.date)?.toLocal();
      if (date != null) {
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        dateDueMap[dateStr] = item.dueCount;
      }
    }

    final List<FutureReviewStats> denseData = [];
    for (int i = 0; i < 7; i++) {
      // Dựng bằng DateTime(y, m, d + i) để không lệch khi có đổi giờ mùa hè.
      final date = DateTime(today.year, today.month, today.day + i);
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      denseData.add(
        FutureReviewStats(date: date.toIso8601String(), dueCount: dateDueMap[dateStr] ?? 0),
      );
    }

    double maxDue =
        denseData.map((e) => e.dueCount).reduce((a, b) => a > b ? a : b).toDouble() * 1.2;
    if (maxDue == 0) maxDue = 5;

    final colorScheme = Theme.of(context).colorScheme;

    return buildCardContainer(
      context,
      'Dự đoán khối lượng ôn tập',
      SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxDue,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} thẻ',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= denseData.length) {
                      return const SizedBox.shrink();
                    }
                    final item = denseData[value.toInt()];
                    final date = DateTime.tryParse(item.date)?.toLocal();
                    if (date == null) return const SizedBox.shrink();

                    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                    // Cột đầu là HÔM NAY (lịch 7 ngày gồm hôm nay): ghi rõ để phân biệt.
                    final weekdayStr = value.toInt() == 0 ? 'H.nay' : weekdays[date.weekday - 1];

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(weekdayStr, style: Theme.of(context).textTheme.labelSmall),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    if (value == maxDue || value % (maxDue / 5).ceil() != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: colorScheme.surfaceContainerHigh, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: denseData.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.dueCount.toDouble(),
                    color: colorScheme.secondary,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class DifficultCardsSection extends StatelessWidget {
  final List<DifficultCardStats> data;
  const DifficultCardsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return buildCardContainer(
        context,
        'Thẻ cần chú ý (Tử huyệt)',
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Bạn chưa có thẻ khó nào!', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return buildCardContainer(
      context,
      'Thẻ cần chú ý (Tử huyệt)',
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        separatorBuilder: (context, index) => Divider(color: colorScheme.surfaceContainerHigh),
        itemBuilder: (context, index) {
          final item = data[index];
          final bool isVeryHard = item.difficulty > 8;
          final source = item.classId != null
              ? (item.className?.isNotEmpty == true ? item.className! : 'Lớp học')
              : 'Cá nhân';
          final deck = item.deckName.isNotEmpty ? item.deckName : null;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            subtitle: Text(
              deck == null ? source : '$deck · $source',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            leading: CircleAvatar(
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Text('${index + 1}', style: TextStyle(color: colorScheme.onSurface)),
            ),
            title: Text(
              item.frontText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isVeryHard ? colorScheme.error : colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.difficulty.toStringAsFixed(1),
                style: TextStyle(
                  color: isVeryHard ? colorScheme.onError : colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
