import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';

/// Phổ điểm của một bài kiểm tra (10 khoảng 0-10, ..., 90-100) kèm số liệu tóm tắt.
class ScoreDistributionCard extends StatelessWidget {
  final ScoreDistribution distribution;

  const ScoreDistributionCard({super.key, required this.distribution});

  String _fmt(double? v) =>
      v == null ? '--' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final d = distribution;
    final maxCount = d.buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.teal.shade500, size: 22),
              const SizedBox(width: 8),
              Text(
                'PHỔ ĐIỂM',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'Nộp ${d.submittedCount}/${d.totalStudents}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat(colorScheme, 'Trung bình', _fmt(d.averageScore)),
              _stat(colorScheme, 'Trung vị', _fmt(d.medianScore)),
              _stat(colorScheme, 'Thấp nhất', _fmt(d.minScore)),
              _stat(colorScheme, 'Cao nhất', _fmt(d.maxScore)),
            ],
          ),
          const SizedBox(height: 24),
          if (d.submittedCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Chưa có học viên nào nộp bài',
                  style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in d.buckets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              b.count > 0 ? '${b.count}' : '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: maxCount == 0 ? 2 : (b.count / maxCount * 80).clamp(2, 80),
                              decoration: BoxDecoration(
                                color: b.count > 0
                                    ? Colors.teal.shade400
                                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${b.from}',
                              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(ColorScheme colorScheme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
