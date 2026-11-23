import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/commons/tag_search_controller.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_tag_pill.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Trạng thái chưa gõ gì: lịch sử (dòng) · chủ đề phổ biến (cuộn ngang) · thịnh hành (xếp hạng).
class DiscoverSearchIdleView extends StatelessWidget {
  final TagSearchController controller;
  final List<String> history;
  final List<TagModel> popularTags;
  final List<String> trending;
  final ValueChanged<String> onSelectHistory;
  final ValueChanged<String> onRemoveHistory;
  final VoidCallback onClearHistory;
  final ValueChanged<TagModel> onSelectTag;
  final ValueChanged<String> onSelectTrending;

  const DiscoverSearchIdleView({
    super.key,
    required this.controller,
    required this.history,
    required this.popularTags,
    required this.trending,
    required this.onSelectHistory,
    required this.onRemoveHistory,
    required this.onClearHistory,
    required this.onSelectTag,
    required this.onSelectTrending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (history.isNotEmpty) ...[
          _Header(
            title: 'discover_recent'.tr,
            action: 'discover_clear_all'.tr,
            onAction: onClearHistory,
          ),
          for (final item in history)
            _HistoryRow(
              query: item,
              controller: controller,
              onTap: () => onSelectHistory(item),
              onRemove: () => onRemoveHistory(item),
            ),
        ],
        if (popularTags.isNotEmpty) ...[
          _Header(title: 'discover_popular_tags'.tr),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in popularTags)
                  DiscoverTagPill(
                    name: tag.name,
                    color: tag.color != null && tag.color!.isNotEmpty
                        ? ColorUtils.parseHex(tag.color!)
                        : null,
                    onTap: () => onSelectTag(tag),
                  ),
              ],
            ),
          ),
        ],
        _Header(title: 'discover_trending'.tr, leading: Icons.local_fire_department_rounded),
        if (trending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'discover_trending_empty'.tr,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final keyword in trending)
                  ActionChip(
                    onPressed: () => onSelectTrending(keyword),
                    avatar: Icon(Icons.trending_up_rounded, size: 16, color: colorScheme.primary),
                    label: Text(keyword),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final IconData? leading;
  final String? action;
  final VoidCallback? onAction;

  const _Header({required this.title, this.leading, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: 20, color: colorScheme.error),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!, style: TextStyle(color: colorScheme.error)),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String query;
  final TagSearchController controller;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryRow({
    required this.query,
    required this.controller,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final token in tokens)
                    if (token.startsWith('#') && token.length > 1)
                      DiscoverTagPill(
                        name: token.substring(1),
                        compact: true,
                        color: controller.colorOf(token.substring(1)),
                      )
                    else
                      Text(token, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 18, color: colorScheme.outline),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
