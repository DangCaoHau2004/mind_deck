import 'package:flutter/material.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/data/models/test_source_models.dart';
import 'package:mind_deck/utils/color_utils.dart';

class SourceDeckItem extends StatelessWidget {
  final SourceDeckModel deck;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool isChild;
  final bool isLastChild;

  const SourceDeckItem({
    super.key,
    required this.deck,
    required this.isSelected,
    required this.onToggle,
    this.isChild = false,
    this.isLastChild = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final deckColor = deck.color != null && deck.color!.isNotEmpty
        ? ColorUtils.parseHex(deck.color!)
        : colorScheme.primary;

    final hasDue = deck.dueCount > 0;

    // Phân biệt chế độ hiển thị: Deck con trong Thư mục vs Deck độc lập (Standalone)
    if (isChild) {
      const childBorderRadius = BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(6),
        bottomRight: Radius.circular(16),
        bottomLeft: Radius.circular(6),
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? deckColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? colorScheme.surface : Colors.white),
          borderRadius: childBorderRadius,
          border: Border.all(
            color: isSelected ? deckColor : deckColor.withValues(alpha: isDark ? 0.35 : 0.22),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: deckColor.withValues(alpha: isDark ? 0.3 : 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onToggle,
          borderRadius: childBorderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Checkbox
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    activeColor: deckColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),

                // Icon Thẻ học dạng Tròn (Đặc trưng của Deck)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: deckColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? colorScheme.surface : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: isSelected ? 0.35 : 0.18)
                            : deckColor.withValues(alpha: isSelected ? 0.35 : 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      AppIcons.getIconFromKey(deck.icon ?? 'default_deck'),
                      color: ColorUtils.getContrastColor(deckColor),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              deck.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (deck.isStarred) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${deck.cardCount} thẻ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Hàng Tags cố định chiều cao (để mọi item luôn bằng nhau tuyệt đối)
                      SizedBox(
                        height: 20,
                        child: deck.tags.isNotEmpty
                            ? Row(
                                children: [
                                  for (final tag in deck.tags.take(2)) ...[
                                    Flexible(child: _buildTagPill(tag, theme, colorScheme, isDark)),
                                    const SizedBox(width: 4),
                                  ],
                                  if (deck.tags.length > 2)
                                    _buildRemainingTagsBadge(
                                      deck.tags.length - 2,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${deck.dueCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Standalone Deck Card (Thẻ học độc lập lấy cảm hứng hình dáng bo góc bất đối xứng đặc trưng từ DeckItemWidget)
    const deckBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(8),
      bottomRight: Radius.circular(24),
      bottomLeft: Radius.circular(8),
    );

    final standaloneGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                deckColor.withValues(alpha: isSelected ? 0.28 : 0.22),
                colorScheme.surface,
              ),
              Color.alphaBlend(
                deckColor.withValues(alpha: isSelected ? 0.09 : 0.05),
                colorScheme.surface,
              ),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                deckColor.withValues(alpha: isSelected ? 0.22 : 0.16),
                colorScheme.surface,
              ),
              Color.alphaBlend(
                deckColor.withValues(alpha: isSelected ? 0.05 : 0.02),
                colorScheme.surface,
              ),
            ],
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: standaloneGradient,
        borderRadius: deckBorderRadius,
        border: Border.all(
          color: isSelected ? deckColor : deckColor.withValues(alpha: isDark ? 0.55 : 0.38),
          width: isSelected ? 2.2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? (isSelected
                      ? deckColor.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.25))
                : deckColor.withValues(alpha: isSelected ? 0.28 : 0.12),
            blurRadius: isSelected ? 10 : 6,
            offset: Offset(0, isSelected ? 4 : 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: deckBorderRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
          child: Row(
            children: [
              // Checkbox (Aligned at start)
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: deckColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),

              // Icon Thẻ học dạng Tròn với viền nổi (Đặc trưng thiết kế Deck)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: deckColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? colorScheme.surface : Colors.white,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: isSelected ? 0.45 : 0.25)
                          : deckColor.withValues(alpha: isSelected ? 0.45 : 0.28),
                      blurRadius: isSelected ? 8 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    AppIcons.getIconFromKey(deck.icon ?? 'default_deck'),
                    color: ColorUtils.getContrastColor(deckColor),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Meta Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            deck.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (deck.isStarred) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deck.cardCount} thẻ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Hàng Tags cố định chiều cao (để mọi thẻ luôn bằng nhau tuyệt đối)
                    SizedBox(
                      height: 20,
                      child: deck.tags.isNotEmpty
                          ? Row(
                              children: [
                                for (final tag in deck.tags.take(2)) ...[
                                  Flexible(child: _buildTagPill(tag, theme, colorScheme, isDark)),
                                  const SizedBox(width: 4),
                                ],
                                if (deck.tags.length > 2)
                                  _buildRemainingTagsBadge(
                                    deck.tags.length - 2,
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
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${deck.dueCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withValues(alpha: isDark ? 0.45 : 0.3), width: 0.8),
      ),
      child: Text(
        '#${tag.name}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: tagColor,
          fontWeight: FontWeight.bold,
          fontSize: 10.5,
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
        borderRadius: BorderRadius.circular(12),
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
