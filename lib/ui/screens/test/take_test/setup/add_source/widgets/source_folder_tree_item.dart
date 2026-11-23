import 'package:flutter/material.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/data/models/test_source_models.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'source_deck_item.dart';

class SourceFolderTreeItem extends StatelessWidget {
  final SourceFolderModel folder;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final bool isSelected;
  final bool isIndeterminate;
  final VoidCallback onToggleFolder;
  final Set<String> selectedDeckIds;
  final Function(SourceDeckModel) onDeckToggled;

  const SourceFolderTreeItem({
    super.key,
    required this.folder,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.isSelected,
    required this.isIndeterminate,
    required this.onToggleFolder,
    required this.selectedDeckIds,
    required this.onDeckToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final themeColor = folder.color != null && folder.color!.isNotEmpty
        ? ColorUtils.parseHex(folder.color!)
        : Colors.amber.shade700;
    final hasDue = folder.dueCount > 0;
    final hasDecks = folder.decks.isNotEmpty;
    final deckCount = folder.deckCount > 0 ? folder.deckCount : folder.decks.length;

    // Gradient mặt trước của thư mục
    final frontBgGradient = isDark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(themeColor, colorScheme.surface, isSelected ? 0.78 : 0.88)!,
              colorScheme.surfaceContainerHighest.withValues(alpha: isSelected ? 0.9 : 0.7),
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(themeColor, Colors.white, isSelected ? 0.88 : 0.94)!,
              Color.lerp(themeColor, Colors.white, isSelected ? 0.96 : 0.985)!,
            ],
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. LỚP LƯNG & TAI THƯ MỤC APPLE (Folder Tab Backing)
          Positioned.fill(
            child: CustomPaint(
              painter: _AppleFolderBackPainter(
                color: isDark ? themeColor.withValues(alpha: 0.85) : themeColor,
                borderColor: themeColor.withValues(alpha: isDark ? 0.6 : 0.4),
              ),
            ),
          ),

          // 2. TỜ TÀI LIỆU TRƯỢT LÊN KHI ĐƯỢC CHỌN (Document Peeking on Select)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            top: (isSelected || isIndeterminate) ? -5.0 : 14.0,
            left: 26,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              opacity: (isSelected || isIndeterminate) ? 1.0 : 0.0,
              child: SizedBox(
                width: 78,
                height: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tờ giấy lót sau
                    Positioned(
                      left: 5,
                      top: 2,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ),
                    ),
                    // Tờ giấy chính
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 5,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade100 : Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 3,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 20,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. MẶT TRƯỚC THƯ MỤC (Nắp thư mục + Khoang chứa Deck con khi mở rộng)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              gradient: frontBgGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: isSelected || isIndeterminate
                    ? themeColor
                    : themeColor.withValues(alpha: isDark ? 0.45 : 0.3),
                width: isSelected || isIndeterminate ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected || isIndeterminate
                      ? themeColor.withValues(alpha: isDark ? 0.4 : 0.28)
                      : (isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : themeColor.withValues(alpha: 0.1)),
                  blurRadius: isSelected || isIndeterminate ? 10 : 6,
                  offset: Offset(0, isSelected || isIndeterminate ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header thư mục
                InkWell(
                  onTap: onToggleFolder,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(14),
                    bottom: isExpanded && hasDecks ? Radius.zero : const Radius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 11, 8, 11),
                    child: Row(
                      children: [
                        // Checkbox (Tristate)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isSelected ? true : (isIndeterminate ? null : false),
                            tristate: true,
                            onChanged: (_) => onToggleFolder(),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            activeColor: themeColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Icon Box Thư mục với Gradient
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [themeColor, themeColor.withValues(alpha: 0.85)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              AppIcons.getIconFromKey(folder.icon ?? 'default_folder'),
                              color: ColorUtils.getContrastColor(themeColor),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Chi tiết thư mục
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      folder.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (folder.isStarred) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$deckCount bộ thẻ • ${folder.cardCount} thẻ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),

                              // Hàng Tags (Cố định chiều cao 20px để mọi thẻ luôn đồng nhất kích thước)
                              SizedBox(
                                height: 20,
                                child: folder.tags.isNotEmpty
                                    ? Row(
                                        children: [
                                          for (final tag in folder.tags.take(2)) ...[
                                            Flexible(
                                              child: _buildTagPill(tag, theme, colorScheme, isDark),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          if (folder.tags.length > 2)
                                            _buildRemainingTagsBadge(
                                              folder.tags.length - 2,
                                              theme,
                                              colorScheme,
                                            ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Due Badge
                        if (hasDue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '${folder.dueCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Nút mũi tên mở rộng >
                        if (hasDecks)
                          GestureDetector(
                            onTap: onToggleExpand,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.25 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isExpanded ? themeColor : colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),

                // 4. KHOANG CHỨA BÊN TRONG THƯ MỤC KHI MỞ RỘNG (Folder Pocket for Child Decks)
                if (isExpanded && hasDecks) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                          : themeColor.withValues(alpha: 0.04),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      border: Border(
                        top: Border(
                          top: BorderSide(
                            color: themeColor.withValues(alpha: isDark ? 0.35 : 0.2),
                            width: 1,
                          ),
                        ).top,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
                          child: Text(
                            'BỘ THẺ TRONG THƯ MỤC (${folder.decks.length})',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? colorScheme.onSurfaceVariant
                                  : themeColor.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        ...folder.decks.map((deck) {
                          final isDeckSelected = selectedDeckIds.contains(deck.id);
                          return SourceDeckItem(
                            deck: deck,
                            isSelected: isDeckSelected,
                            isChild: true,
                            onToggle: () => onDeckToggled(deck),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(TagModel tag, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    Color tagColor = colorScheme.primary;
    if (tag.color != null && tag.color!.isNotEmpty) {
      try {
        tagColor = ColorUtils.parseHex(tag.color!);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tagColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        '#${tag.name}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: tagColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRemainingTagsBadge(int count, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Text(
        '+$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

/// Custom Painter vẽ lưng thư mục Apple (macOS / iOS) với đường cong chuyển tiếp tai thư mục mượt mà
class _AppleFolderBackPainter extends CustomPainter {
  final Color color;
  final Color? borderColor;

  _AppleFolderBackPainter({required this.color, this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tabWidth = (w * 0.36).clamp(85.0, 125.0);
    const tabHeight = 16.0;
    const cornerRadius = 18.0;

    final path = Path();
    path.moveTo(0, h - cornerRadius);
    path.lineTo(0, cornerRadius);
    path.arcToPoint(const Offset(cornerRadius, 0), radius: const Radius.circular(cornerRadius));
    path.lineTo(tabWidth - 12, 0);
    path.cubicTo(tabWidth + 4, 0, tabWidth - 4, tabHeight, tabWidth + 16, tabHeight);
    path.lineTo(w - cornerRadius, tabHeight);
    path.arcToPoint(
      Offset(w, tabHeight + cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    path.lineTo(w, h - cornerRadius);
    path.arcToPoint(Offset(w - cornerRadius, h), radius: const Radius.circular(cornerRadius));
    path.lineTo(cornerRadius, h);
    path.arcToPoint(Offset(0, h - cornerRadius), radius: const Radius.circular(cornerRadius));
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AppleFolderBackPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
