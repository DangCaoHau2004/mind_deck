import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Chuỗi ngày học dạng viên thuốc viền nét đứt: icon lửa + số ngày. Chạm để xem lời nhắc.
class StreakBadge extends StatelessWidget {
  final int streak;

  /// false: hôm nay chưa ôn, chuỗi sắp đứt.
  final bool isIntact;

  const StreakBadge({super.key, required this.streak, required this.isIntact});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final active = streak > 0 && isIntact;
    final atRisk = streak > 0 && !isIntact;
    final color = active
        ? Colors.deepOrange
        : atRisk
        ? colorScheme.error
        : colorScheme.outline;
    final message = active
        ? 'home_streak_intact'.tr
        : atRisk
        ? 'home_streak_at_risk'.tr
        : 'home_streak_none'.tr;

    return Tooltip(
      message: message.replaceAll('{count}', '$streak'),
      triggerMode: TooltipTriggerMode.tap,
      child: CustomPaint(
        // Lúc skeleton thì bỏ viền nét đứt (vẽ bằng canvas nên không bị phủ xám).
        painter: (Skeletonizer.maybeOf(context)?.enabled ?? false)
            ? null
            : _DashedBorderPainter(color: color.withValues(alpha: 0.7)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  static const double _strokeWidth = 1.5;
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(_strokeWidth / 2), Radius.circular(size.height / 2)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
