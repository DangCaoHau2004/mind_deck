import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/deck_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/screens/deck/services/deck_search_history_service.dart';
import 'package:mind_deck/utils/color_utils.dart';

class DeckSearchSuggestionsPanel extends StatelessWidget {
  final bool isVisible;
  final String currentQuery;
  final Set<String> activeTagNames;
  final List<DeckSearchHistoryItem> recentSearches;
  final DeckSuggestionModel? suggestions;
  final ValueChanged<DeckKeywordSuggestionModel> onSelectKeyword;
  final ValueChanged<DeckSearchHistoryItem> onSelectRecent;
  final ValueChanged<TagModel> onSelectTag;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearAllRecent;
  final VoidCallback? onClose;

  const DeckSearchSuggestionsPanel({
    super.key,
    required this.isVisible,
    required this.currentQuery,
    this.activeTagNames = const {},
    required this.recentSearches,
    required this.suggestions,
    required this.onSelectKeyword,
    required this.onSelectRecent,
    required this.onSelectTag,
    required this.onRemoveRecent,
    required this.onClearAllRecent,
    this.onClose,
  });

  static final RegExp _tagRegex = RegExp(r'(#[^\s]+)');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isAllEmpty = currentQuery.trim().isEmpty && activeTagNames.isEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      child: !isVisible
          ? const SizedBox(width: double.infinity, height: 0)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAllEmpty)
                    _buildEmptyQueryContent(context, theme, colorScheme)
                  else
                    _buildActiveQueryContent(context, theme, colorScheme),
                ],
              ),
            ),
    );
  }

  /// Giao diện khi người dùng chưa gõ hoặc chưa chọn thẻ nào
  Widget _buildEmptyQueryContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final hasRecent = recentSearches.isNotEmpty;
    final tags = suggestions?.tags ?? [];
    final hasTags = tags.isNotEmpty;

    // Trường hợp cả Lịch sử và Tags đều rỗng -> Hiển thị Default Empty State
    if (!hasRecent && !hasTags) {
      return _buildDefaultEmptyState(theme, colorScheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Mục Tìm kiếm gần đây (Local)
        if (hasRecent) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Tìm kiếm gần đây',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onClearAllRecent,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Xóa tất cả',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((item) {
              return _buildRecentChip(theme, colorScheme, item);
            }).toList(),
          ),
        ],

        // Khoảng cách giữa 2 khối
        if (hasRecent && hasTags) const SizedBox(height: 14),

        // 2. Mục Thẻ gợi ý (Backend)
        if (hasTags) ...[
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Chủ đề gợi ý',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return _buildTagChip(theme, colorScheme, tag);
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Lấy danh sách tên các tag đã có trong ô tìm kiếm để loại bỏ khỏi gợi ý
  Set<String> _extractExistingTags(String query) {
    final matches = _tagRegex.allMatches(query);
    final Set<String> result = Set.from(activeTagNames.map((e) => e.toLowerCase()));
    for (final m in matches) {
      final raw = m.group(1);
      if (raw != null) {
        final name = raw.startsWith('#') ? raw.substring(1) : raw;
        result.add(name.toLowerCase());
      }
    }
    return result;
  }

  /// Giao diện khi người dùng đang nhập từ khóa hoặc đã chọn tag
  Widget _buildActiveQueryContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final existingTags = _extractExistingTags(currentQuery);
    // Lọc bỏ các tag đã có trong ô tìm kiếm
    final tags = (suggestions?.tags ?? [])
        .where((tag) => !existingTags.contains(tag.name.toLowerCase()))
        .toList();

    // Lọc bỏ keyword nếu query của nó trùng khớp 100% với từ khóa đang gõ
    final cleanQuery = currentQuery.trim().toLowerCase();
    final keywords = (suggestions?.keywords ?? [])
        .where((kw) => kw.query.trim().toLowerCase() != cleanQuery)
        .toList();

    final hasKeywords = keywords.isNotEmpty;
    final hasTags = tags.isNotEmpty;

    if (!hasKeywords && !hasTags) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nhấn phím Tìm kiếm hoặc Enter để xem kết quả',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Danh sách từ khóa gợi ý (Keywords)
        if (hasKeywords) ...[
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Gợi ý từ khóa',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...keywords.take(5).map((kw) {
            return InkWell(
              onTap: () => onSelectKeyword(kw),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.north_west_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildKeywordRow(theme, colorScheme, kw)),
                  ],
                ),
              ),
            );
          }),
        ],

        if (hasKeywords && hasTags) const SizedBox(height: 12),

        // 2. Thẻ liên quan (Tags)
        if (hasTags) ...[
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Thẻ liên quan',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return _buildTagChip(theme, colorScheme, tag);
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Trạng thái mặc định khi cả Lịch sử và Tags đều rỗng
  Widget _buildDefaultEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 26,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 6),
            Text(
              'Khám phá học phần',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• Gõ từ khóa để tìm học phần theo tên\n• Gõ # kèm tên thẻ (vd: #tieng-anh) để lọc theo chủ đề',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip hiển thị từ khóa lịch sử gần đây
  Widget _buildRecentChip(ThemeData theme, ColorScheme colorScheme, DeckSearchHistoryItem item) {
    final query = item.query.trim();
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final isOnlyOneTag = tokens.length == 1 && tokens.first.startsWith('#');

    // 1. Trường hợp: Lịch sử chỉ chứa duy nhất 1 Tag (vd: "#tieng-anh")
    // -> Render hình dạng viên thuốc y hệt như Tag ở phần Chủ đề gợi ý
    if (isOnlyOneTag) {
      final rawTag = tokens.first;
      final tagName = rawTag.substring(1).toLowerCase();
      Color tagColor = colorScheme.primary;
      final hex = item.tagColors[tagName];
      if (hex != null && hex.isNotEmpty) {
        try {
          tagColor = ColorUtils.parseHex(hex);
        } catch (_) {}
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelectRecent(item),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tagColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$tagName',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tagColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onRemoveRecent(item.query),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded, size: 14, color: tagColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Trường hợp: Có từ khóa thường + Tag (vd: "Vocabulary #tieng-anh") hoặc nhiều Tag
    // -> Phần tag bên trong được bo tròn dạng viên thuốc y hệt tag
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectRecent(item),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMixedHistoryContent(theme, colorScheme, item),
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onRemoveRecent(item.query),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Render nội dung lịch sử kết hợp giữa chữ thường và các viên tag thu nhỏ
  Widget _buildMixedHistoryContent(
    ThemeData theme,
    ColorScheme colorScheme,
    DeckSearchHistoryItem item,
  ) {
    final tokens = item.query.trim().split(RegExp(r'\s+'));
    final widgets = <Widget>[];

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.isEmpty) continue;

      if (token.startsWith('#') && token.length > 1) {
        final tagName = token.substring(1).toLowerCase();
        Color tagColor = colorScheme.primary;
        final hex = item.tagColors[tagName];
        if (hex != null && hex.isNotEmpty) {
          try {
            tagColor = ColorUtils.parseHex(hex);
          } catch (_) {}
        }

        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tagColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              '#$tagName',
              style: theme.textTheme.labelSmall?.copyWith(
                color: tagColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Text(token, style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurface)),
        );
      }

      if (i < tokens.length - 1) {
        widgets.add(const SizedBox(width: 4));
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }

  /// Render dòng gợi ý từ khóa kèm các thẻ Tag có màu sắc
  Widget _buildKeywordRow(ThemeData theme, ColorScheme colorScheme, DeckKeywordSuggestionModel kw) {
    final hasTags = kw.tags.isNotEmpty;

    return Row(
      children: [
        Flexible(
          child: Text(
            kw.displayText.isNotEmpty ? kw.displayText : kw.query,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasTags) ...[
          const SizedBox(width: 8),
          ...kw.tags.map((tag) {
            Color tagColor = colorScheme.primary;
            if (tag.color != null && tag.color!.isNotEmpty) {
              try {
                tagColor = ColorUtils.parseHex(tag.color!);
              } catch (_) {}
            }
            return Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tagColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                '#${tag.name}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tagColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Chip hiển thị thẻ (Tag) ở mục Chủ đề gợi ý
  Widget _buildTagChip(ThemeData theme, ColorScheme colorScheme, TagModel tag) {
    Color tagColor = colorScheme.primary;
    if (tag.color != null && tag.color!.isNotEmpty) {
      try {
        tagColor = ColorUtils.parseHex(tag.color!);
      } catch (_) {}
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectTag(tag),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tagColor.withValues(alpha: 0.35)),
          ),
          child: Text(
            '#${tag.name}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tagColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
