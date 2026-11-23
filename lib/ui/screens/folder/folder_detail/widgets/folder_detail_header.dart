import 'package:flutter/material.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/ui/commons/folder_illustration.dart';
import 'package:mind_deck/ui/commons/info_chip.dart';
import 'package:mind_deck/ui/commons/tag_pill.dart';

/// Phần đầu màn chi tiết thư mục: nền nhạt theo màu thư mục, hình thư mục bên trái, tên + mô tả bên phải,
/// các viên thông tin màu trắng và hàng nút hành động ([actions]) nằm ở đáy.
class FolderDetailHeader extends StatelessWidget {
  final FolderModel folder;
  final Color themeColor;
  final int deckCount;
  final Widget actions;

  const FolderDetailHeader({
    super.key,
    required this.folder,
    required this.themeColor,
    required this.deckCount,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = folder.description?.trim() ?? '';
    final author = folder.authorName;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
        24,
        24,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(themeColor.withValues(alpha: 0.14), Colors.white),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FolderIllustration(
                color: themeColor,
                icon: AppIcons.getIconFromKey(folder.icon),
                scale: 1.3,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 6,
            children: [
              InfoChip(
                icon: folder.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                text: (folder.isPublic ? 'library_public' : 'library_private').tr,
              ),
              InfoChip(text: 'folder_deck_count'.tr.replaceAll('{count}', '$deckCount')),
              for (final tag in folder.tags ?? const [])
                TagPill(text: '#${tag.name}', hex: tag.color),
            ],
          ),
          if (author != null && author.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: themeColor.withValues(alpha: 0.15),
                  child: Icon(Icons.person, size: 14, color: themeColor),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Tác giả: $author',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          actions,
        ],
      ),
    );
  }
}
