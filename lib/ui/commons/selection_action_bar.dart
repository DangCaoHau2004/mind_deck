import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

/// Thẻ nổi thay thanh điều hướng khi đang chọn nhiều (thư mục hoặc học phần): tóm tắt đã chọn, Hủy, gắn sao, xóa và
/// "Ôn cùng lúc".
class SelectionActionBar extends StatelessWidget {
  /// Icon của mục đầu tiên đã chọn.
  final Widget leading;
  final String title;
  final String subtitle;

  /// Dòng nhỏ dưới "Ôn cùng lúc", vd "17 thẻ cần ôn"; null thì không hiện.
  final String? reviewSubtitle;

  /// Tất cả mục đang chọn đã gắn sao: nút sao hiện dạng đã gắn.
  final bool allStarred;
  final VoidCallback onCancel;
  final VoidCallback onStar;
  final VoidCallback onDelete;
  final VoidCallback onReview;

  const SelectionActionBar({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.allStarred,
    required this.onCancel,
    required this.onStar,
    required this.onDelete,
    required this.onReview,
    this.reviewSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget squareButton({
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
    }) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(56, 56),
        padding: EdgeInsets.zero,
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Icon(icon, size: 26),
    );

    // Nổi đúng chỗ thanh điều hướng (lề ngang 24, cách đáy 16), cao dần từ dưới lên
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  child: Text(
                    'common_cancel'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                squareButton(
                  icon: allStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: allStarred ? Colors.amber.shade700 : colorScheme.onSurface,
                  onTap: onStar,
                ),
                const SizedBox(width: 10),
                squareButton(
                  icon: Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  onTap: onDelete,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onReview,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 28),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'library_review_together'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (reviewSubtitle != null)
                              Text(
                                reviewSubtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimary.withValues(alpha: 0.85),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon cho [SelectionActionBar]: ô vuông màu của mục đầu tiên, thêm một ô nhạt phía sau khi chọn nhiều.
class SelectionStackIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool stacked;

  const SelectionStackIcon({
    super.key,
    required this.color,
    required this.icon,
    required this.stacked,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 52,
      child: Stack(
        children: [
          if (stacked)
            Positioned(
              right: 0,
              top: 0,
              width: 42,
              height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          Positioned(
            left: 0,
            bottom: 0,
            width: 42,
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(
                icon,
                size: 22,
                color: color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
