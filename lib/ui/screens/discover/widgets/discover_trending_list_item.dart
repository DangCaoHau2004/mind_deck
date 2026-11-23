import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/screens/discover/discover_save_helper.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_content_model.dart';

class DiscoverTrendingListItem extends StatelessWidget {
  final DiscoverySuggestedContentModel item;

  const DiscoverTrendingListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isFolder = item.type == 'folder';
    final colorVal = item.id.hashCode & 0xFFFFFF;
    final itemColor = Color(colorVal).withValues(alpha: 1.0);

    return InkWell(
      onTap: () {
        if (isFolder) {
          context.pushNamed(AppRoute.folderDetail.name, pathParameters: {'id': item.id});
        } else {
          context.pushNamed(AppRoute.deckDetail.name, pathParameters: {'id': item.id});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 20 / 255)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 8 / 255),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: itemColor.withValues(alpha: 25 / 255),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isFolder ? Icons.folder_copy_rounded : Icons.style_rounded,
                color: itemColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description != null && item.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!.trim(),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.edit_document, size: 12, color: colorScheme.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.ownerName ?? 'Ẩn danh',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline.withValues(alpha: 100 / 255),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${isFolder ? '${item.deckCount ?? 0} bộ thẻ' : '${item.cardCount ?? 0} thẻ'} • ${item.savedCount} lưu",
                          style: textTheme.bodySmall?.copyWith(
                            color: itemColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: itemColor.withValues(alpha: 15 / 255),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.bookmark_add_outlined, color: itemColor, size: 20),
                onPressed: () =>
                    DiscoverSaveHelper.saveToLibrary(context, id: item.id, isFolder: isFolder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
