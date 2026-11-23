import 'package:flutter/material.dart';
import 'package:mind_deck/ui/commons/folder_illustration.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/ui/commons/due_badge.dart';
import 'package:mind_deck/ui/commons/tag_pill.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

class FolderItemWidget extends StatelessWidget {
  final FolderModel folder;
  final bool isSelected;
  final bool isSelectionMode;
  final String? searchQuery;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStarTap;

  const FolderItemWidget({
    super.key,
    required this.folder,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.searchQuery,
    this.onTap,
    this.onLongPress,
    this.onStarTap,
  });

  static const int _maxVisibleTags = 2;

  /// Tag khớp từ khóa tìm kiếm được đưa lên đầu.
  List<TagModel> get _sortedTags {
    final tags = folder.tags ?? const <TagModel>[];
    final tokens = (searchQuery ?? '')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map((s) => s.startsWith('#') ? s.substring(1) : s);
    if (tokens.isEmpty) return tags;
    bool matches(TagModel t) => tokens.any((k) => t.name.toLowerCase().contains(k));
    return [...tags.where(matches), ...tags.where((t) => !matches(t))];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tags = _sortedTags;
    final extraTags = tags.length - _maxVisibleTags;

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
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onLongPress?.call();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              children: [
                Skeleton.leaf(child: _FolderIcon(folder: folder)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            folder.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${(folder.isPublic ? 'library_public' : 'library_private').tr} · '
                              '${'folder_deck_count'.tr.replaceAll('{count}', '${folder.deckCount ?? folder.decks?.length ?? 0}')}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Luôn chừa chỗ cho hàng tag để thẻ không tag vẫn cao bằng thẻ có tag
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: Row(
                          children: [
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
                isSelectionMode
                    ? Padding(
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
                    : IconButton(
                        onPressed: onStarTap == null
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                onStarTap!();
                              },
                        icon: Icon(
                          folder.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: folder.isStarred
                              ? Colors.amber
                              : colorScheme.onSurface.withValues(alpha: 0.35),
                          size: 30,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon thư mục trong danh sách (hình dùng chung); góc phải trên có số thẻ cần ôn.
class _FolderIcon extends StatelessWidget {
  final FolderModel folder;

  const _FolderIcon({required this.folder});

  @override
  Widget build(BuildContext context) {
    final due = folder.dueCount ?? 0;

    return SizedBox(
      width: 60,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FolderIllustration(
            color: ColorUtils.parseHex(folder.color),
            icon: AppIcons.getIconFromKey(folder.icon),
          ),
          if (due > 0) Positioned(right: -8, top: -6, child: DueBadge(count: due)),
        ],
      ),
    );
  }
}
