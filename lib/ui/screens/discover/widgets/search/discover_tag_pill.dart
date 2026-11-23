import 'package:flutter/material.dart';

/// Viên thuốc `#tag` dùng chung cho thanh tìm kiếm, gợi ý, lịch sử và thẻ kết quả.
class DiscoverTagPill extends StatelessWidget {
  final String name;
  final Color? color;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const DiscoverTagPill({
    super.key,
    required this.name,
    this.color,
    this.compact = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tagColor = color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    final label = Text(
      '#$name',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)?.copyWith(
        color: tagColor,
        fontWeight: FontWeight.w700,
        fontSize: compact ? 11 : null,
      ),
    );

    return Material(
      color: tagColor.withValues(alpha: isDark ? 0.2 : 0.12),
      shape: StadiumBorder(side: BorderSide(color: tagColor.withValues(alpha: 0.35))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 7 : 10,
            compact ? 2 : 4,
            onRemove != null ? 4 : (compact ? 7 : 10),
            compact ? 2 : 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              if (onRemove != null) ...[
                const SizedBox(width: 2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(Icons.close_rounded, size: 14, color: tagColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
