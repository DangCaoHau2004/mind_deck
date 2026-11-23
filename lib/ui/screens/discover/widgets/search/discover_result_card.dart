import 'package:flutter/material.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/global_search_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/screens/discover/discover_save_helper.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_highlight.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_tag_pill.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Thẻ kết quả cho bộ thẻ / thư mục: ô icon theo icon + màu của entity, tên (tô phần khớp),
/// tag, người tạo và số liệu. Không hiển thị mô tả.
/// Thư mục khác bộ thẻ ở hình ô icon (góc trên-trái "tab" nhỏ như tệp thư mục).
class DiscoverResultCard extends StatelessWidget {
  final GlobalSearchModel item;

  /// Từ khóa (không gồm #tag) để tô đậm trong tên.
  final String highlight;
  final VoidCallback onTap;
  final ValueChanged<TagModel> onTagTap;

  const DiscoverResultCard({
    super.key,
    required this.item,
    required this.highlight,
    required this.onTap,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final accent = ColorUtils.parseHex(item.colorHex);
    final isFolder = item.type == SearchType.folder;
    final countText = isFolder
        ? 'discover_result_decks'.tr.replaceAll('{count}', '${item.deckCount ?? 0}')
        : 'discover_result_cards'.tr.replaceAll('{count}', '${item.cardCount ?? 0}');
    final savedText = 'discover_result_saved'.tr.replaceAll('{count}', '${item.savedCount}');
    final tags = item.tags.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: isFolder
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          )
                        : BorderRadius.circular(16),
                  ),
                  child: Icon(
                    AppIcons.getIconFromKey(item.iconKey),
                    color: ColorUtils.getContrastColor(accent),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        discoverHighlight(
                          item.name,
                          highlight,
                          base: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          accent: colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in tags)
                              DiscoverTagPill(
                                name: tag.name,
                                compact: true,
                                color: tag.color != null && tag.color!.isNotEmpty
                                    ? ColorUtils.parseHex(tag.color!)
                                    : null,
                                onTap: () => onTagTap(tag),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14, color: colorScheme.outline),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.ownerName ?? 'discover_anonymous'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$countText · $savedText',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.bookmark_add_outlined, color: colorScheme.onSurfaceVariant),
                  onPressed: () => DiscoverSaveHelper.saveToLibrary(
                    context,
                    id: item.entityId,
                    isFolder: isFolder,
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
