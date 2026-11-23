import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/search_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/commons/tag_search_controller.dart';
import 'package:mind_deck/ui/screens/discover/bloc/discover_state.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_highlight.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_tag_pill.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Danh sách gợi ý khi đang gõ. Hàng gợi ý: icon loại · tên (in đậm phần khớp) · pill tag · mũi tên điền.
class DiscoverSuggestionList extends StatelessWidget {
  final TagSearchController controller;
  final SuggestStatus status;
  final SearchSuggestionResponseModel? suggestions;

  /// Phần chữ người dùng đang gõ (không gồm #tag) để in đậm trong tên gợi ý.
  final String highlight;
  final VoidCallback onSubmitCurrent;
  final ValueChanged<SearchKeywordSuggestionModel> onSearchKeyword;
  final ValueChanged<SearchKeywordSuggestionModel> onFillKeyword;
  final ValueChanged<TagModel> onSelectTag;

  const DiscoverSuggestionList({
    super.key,
    required this.controller,
    required this.status,
    required this.suggestions,
    required this.highlight,
    required this.onSubmitCurrent,
    required this.onSearchKeyword,
    required this.onFillKeyword,
    required this.onSelectTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final active = controller.tagNames;
    final tags = (suggestions?.tags ?? const <TagModel>[])
        .where((t) => !active.contains(t.name.toLowerCase()))
        .toList();
    final submitted = controller.submitQuery.toLowerCase();
    final keywords = (suggestions?.keywords ?? const <SearchKeywordSuggestionModel>[])
        .where((k) => k.query.trim().toLowerCase() != submitted)
        .toList();

    final isLoading = status == SuggestStatus.loading;
    final showSkeleton = isLoading && suggestions == null;
    final pureTagMode = keywords.isEmpty && tags.isNotEmpty;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        _SubmitRow(controller: controller, onTap: onSubmitCurrent),
        if (showSkeleton)
          for (var i = 0; i < 4; i++) const _SkeletonRow()
        else
          Opacity(
            opacity: isLoading ? 0.5 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tags.isNotEmpty && !pureTagMode) ...[
                  _SectionLabel(icon: Icons.tag_rounded, text: 'discover_suggest_tags'.tr),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          DiscoverTagPill(
                            name: tag.name,
                            color: _color(tag),
                            onTap: () => onSelectTag(tag),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (pureTagMode)
                  for (final tag in tags)
                    InkWell(
                      onTap: () => onSelectTag(tag),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            DiscoverTagPill(name: tag.name, color: _color(tag)),
                            const Spacer(),
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (keywords.isNotEmpty)
                  _SectionLabel(
                    icon: Icons.lightbulb_outline_rounded,
                    text: 'discover_suggest_keywords'.tr,
                  ),
                for (final kw in keywords)
                  _KeywordRow(
                    keyword: kw,
                    highlight: highlight,
                    controller: controller,
                    onTap: () => onSearchKeyword(kw),
                    onFill: () => onFillKeyword(kw),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Color? _color(TagModel tag) =>
      tag.color != null && tag.color!.isNotEmpty ? ColorUtils.parseHex(tag.color!) : null;
}

class _SubmitRow extends StatelessWidget {
  final TagSearchController controller;
  final VoidCallback onTap;

  const _SubmitRow({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final text = controller.text.text.trim();
    final hasTags = controller.tags.isNotEmpty;

    final label = text.isNotEmpty
        ? 'discover_search_for'.tr.replaceAll('{query}', text)
        : 'discover_search_for_tags'.tr.replaceAll(
            '{tags}',
            controller.tags.map((t) => '#${t.name}').join(' '),
          );

    if (text.isEmpty && !hasTags) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordRow extends StatelessWidget {
  final SearchKeywordSuggestionModel keyword;
  final String highlight;
  final TagSearchController controller;
  final VoidCallback onTap;
  final VoidCallback onFill;

  const _KeywordRow({
    required this.keyword,
    required this.highlight,
    required this.controller,
    required this.onTap,
    required this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = keyword.displayText.isNotEmpty ? keyword.displayText : keyword.query;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    discoverHighlight(
                      title,
                      highlight,
                      base: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                      underline: false,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (keyword.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final tag in keyword.tags)
                          DiscoverTagPill(
                            name: tag.name,
                            compact: true,
                            color: tag.color != null && tag.color!.isNotEmpty
                                ? ColorUtils.parseHex(tag.color!)
                                : controller.colorOf(tag.name),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'discover_fill_suggestion'.tr,
              icon: Icon(
                Icons.north_west_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              onPressed: onFill,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
