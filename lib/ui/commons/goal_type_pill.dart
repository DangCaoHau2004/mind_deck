import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/enums.dart';

/// Viên nhỏ "Dài hạn" / "Ngắn hạn" của bộ thẻ (dài hạn xanh lá, ngắn hạn cam).
class GoalTypePill extends StatelessWidget {
  final GoalType goalType;

  const GoalTypePill({super.key, required this.goalType});

  @override
  Widget build(BuildContext context) {
    final isLong = goalType == GoalType.longTerm;
    final color = isLong ? Colors.green.shade700 : Colors.orange.shade800;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLong ? Icons.all_inclusive_rounded : Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            (isLong ? 'deck_goal_long' : 'deck_goal_short').tr,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
