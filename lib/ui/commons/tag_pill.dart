import 'package:flutter/material.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Viên thuốc tag (vd "#lap-trinh") theo màu của tag; không có màu thì dùng xám trung tính.
class TagPill extends StatelessWidget {
  final String text;
  final String? hex;

  const TagPill({super.key, required this.text, this.hex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hex != null && hex!.isNotEmpty
        ? ColorUtils.parseHex(hex!)
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
