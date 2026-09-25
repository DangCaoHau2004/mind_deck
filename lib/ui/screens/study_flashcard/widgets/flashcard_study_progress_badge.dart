import 'package:flutter/material.dart';

class FlashcardStudyProgressBadge extends StatelessWidget {
  final int count;
  final Color color;
  final bool showPlusOne;
  final bool isLeft;

  const FlashcardStudyProgressBadge({
    super.key,
    required this.count,
    required this.color,
    required this.showPlusOne,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topRight: isLeft ? const Radius.circular(20) : Radius.zero,
          bottomRight: isLeft ? const Radius.circular(20) : Radius.zero,
          topLeft: !isLeft ? const Radius.circular(20) : Radius.zero,
          bottomLeft: !isLeft ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (showPlusOne)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                '+1',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
