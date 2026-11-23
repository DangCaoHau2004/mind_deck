import 'package:flutter/material.dart';

/// Viên thông tin màu trắng trong phần đầu màn chi tiết (công khai/riêng tư, số thẻ, ngày...).
class InfoChip extends StatelessWidget {
  final IconData? icon;
  final String text;

  const InfoChip({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: textColor), const SizedBox(width: 4)],
          Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
