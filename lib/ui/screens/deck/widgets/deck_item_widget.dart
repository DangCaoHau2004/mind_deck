import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/commons/due_badge.dart';
import 'package:mind_deck/ui/commons/goal_type_pill.dart';
import 'package:mind_deck/ui/commons/tag_pill.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DeckItemWidget extends StatelessWidget {
  final DeckModel deck;
  final bool isSelected;
  final bool isSelectionMode;

  /// Hiện dòng thư mục chứa học phần (tắt khi đang xem bên trong một thư mục).
  final bool showFolder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStarTap;

  const DeckItemWidget({
    super.key,
    required this.deck,
    required this.isSelected,
    required this.isSelectionMode,
    this.showFolder = true,
    this.onTap,
    this.onLongPress,
    this.onStarTap,
  });

  static const int _maxVisibleTags = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);
    final tags = deck.tags ?? const <TagModel>[];
    final extraTags = tags.length - _maxVisibleTags;
    final hasFolder = deck.folders.isNotEmpty;
    final folderColor = hasFolder
        ? ColorUtils.parseHex(deck.folders.first.color)
        : colorScheme.primary;
    final extraFolders = deck.folders.length - 1;
    final isPublic = deck.isPublic || deck.shareMode == 'public';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Material(
        color: isSelected
            ? Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.08), colorScheme.surface)
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (isSelectionMode) HapticFeedback.selectionClick();
            onTap?.call();
          },
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              children: [
                // Icon hai thẻ xếp chồng + số thẻ ngay bên dưới
                SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Skeleton.leaf(child: _DeckIcon(deck: deck)),
                      const SizedBox(height: 6),
                      Text(
                        'deck_card_count'.tr.replaceAll(
                          '{count}',
                          '${deck.cardCount ?? deck.flashcards?.length ?? 0}',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showFolder) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              hasFolder ? Icons.folder_rounded : Icons.folder_open_outlined,
                              size: 18,
                              color: hasFolder ? folderColor : mutedColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                hasFolder
                                    ? (extraFolders > 0
                                          ? '${deck.folders.first.name} +$extraFolders'
                                          : deck.folders.first.name)
                                    : 'deck_no_folder'.tr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: hasFolder ? folderColor : mutedColor,
                                  fontWeight: hasFolder ? FontWeight.w600 : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Luôn chừa chỗ cho hàng tag để thẻ không tag vẫn cao bằng thẻ có tag
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: Row(
                          children: [
                            GoalTypePill(goalType: deck.goalType),
                            for (final tag in tags.take(_maxVisibleTags))
                              Flexible(
                                child: TagPill(text: '#${tag.name}', hex: tag.color),
                              ),
                            if (extraTags > 0) TagPill(text: '+$extraTags'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.35),
                      size: 26,
                    ),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onStarTap != null)
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onStarTap!();
                          },
                          icon: Icon(
                            deck.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: deck.isStarred
                                ? Colors.amber
                                : colorScheme.onSurface.withValues(alpha: 0.35),
                            size: 30,
                          ),
                        ),
                      // Chỉ hiện icon khóa cho học phần riêng tư, công khai thì không cần nói
                      if (!isPublic)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.lock_outline_rounded, size: 20, color: mutedColor),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon học phần: hai thẻ xếp chồng theo màu học phần; góc phải trên có số thẻ cần ôn.
class _DeckIcon extends StatelessWidget {
  final DeckModel deck;

  const _DeckIcon({required this.deck});

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.parseHex(deck.color);
    final due = deck.dueCount ?? 0;

    return SizedBox(
      width: 56,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                AppIcons.getIconFromKey(deck.icon),
                color: ColorUtils.getContrastColor(color),
                size: 22,
              ),
            ),
          ),
          if (due > 0) Positioned(right: -6, top: -8, child: DueBadge(count: due)),
        ],
      ),
    );
  }
}
