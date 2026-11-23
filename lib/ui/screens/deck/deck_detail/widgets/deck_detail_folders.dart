import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_folder_ref_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// "Nằm trong N thư mục": các chip thư mục chứa bộ thẻ (thu gọn còn 2 chip + "+N"). Bấm chip mở màn thư mục.
/// Chỉ chủ sở hữu có danh sách này; người khác thì ẩn cả khối ở màn gọi.
class DeckDetailFolders extends StatefulWidget {
  final List<DeckFolderRef> folders;

  const DeckDetailFolders({super.key, required this.folders});

  @override
  State<DeckDetailFolders> createState() => _DeckDetailFoldersState();
}

class _DeckDetailFoldersState extends State<DeckDetailFolders> {
  static const int _collapsedCount = 2;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final folders = widget.folders;
    final visible = _expanded ? folders : folders.take(_collapsedCount).toList();
    final hidden = folders.length - visible.length;

    Widget chip({required Widget child, VoidCallback? onTap, bool dashed = false, Color? fill}) {
      return Material(
        color: fill ?? colorScheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: dashed ? 0.5 : 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: child,
          ),
        ),
      );
    }

    final title = folders.isEmpty
        ? 'deck_folders_title_empty'.tr
        : folders.length == 1
        ? 'deck_folders_title_one'.tr
        : 'deck_folders_title'.tr.replaceAll('{count}', '${folders.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (folders.isEmpty)
          chip(
            dashed: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'deck_no_folders'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final folder in visible)
                chip(
                  onTap: () => context.pushNamed(
                    AppRoute.folderDetail.name,
                    pathParameters: {'id': folder.id},
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 20,
                        color: ColorUtils.parseHex(folder.color),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          folder.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (hidden > 0)
                chip(
                  fill: colorScheme.primary.withValues(alpha: 0.08),
                  onTap: () => setState(() => _expanded = true),
                  child: Text(
                    '+$hidden',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (_expanded && folders.length > _collapsedCount)
                chip(
                  fill: colorScheme.primary.withValues(alpha: 0.08),
                  onTap: () => setState(() => _expanded = false),
                  child: Text(
                    'deck_folders_collapse'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
