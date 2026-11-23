import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';
import 'package:mind_deck/utils/color_utils.dart';

class SourceFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final String searchQuery;
  final List<TagModel> selectedSearchTags;
  final Map<String, String> tagColorMap;
  final ValueChanged<TagModel>? onRemoveSearchTag;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback onClearSearch;
  final String selectedFilterType; // 'all', 'folder', 'deck'
  final ValueChanged<String> onFilterTypeChanged;
  final bool onlyDue;
  final ValueChanged<bool> onOnlyDueChanged;

  /// Lọc thẻ chưa học (BE `onlyNew`). Null = ẩn bộ lọc này.
  final bool onlyNew;
  final ValueChanged<bool>? onOnlyNewChanged;
  final bool isStarred;
  final ValueChanged<bool> onStarredChanged;
  final String currentSort;
  final String currentOrder;
  final Function(String sort, String order) onSortChanged;

  const SourceFilterBar({
    super.key,
    required this.searchController,
    this.searchFocusNode,
    required this.searchQuery,
    this.selectedSearchTags = const [],
    this.tagColorMap = const {},
    this.onRemoveSearchTag,
    required this.onSearchChanged,
    this.onSearchSubmitted,
    required this.onClearSearch,
    required this.selectedFilterType,
    required this.onFilterTypeChanged,
    required this.onlyDue,
    required this.onOnlyDueChanged,
    this.onlyNew = false,
    this.onOnlyNewChanged,
    required this.isStarred,
    required this.onStarredChanged,
    required this.currentSort,
    required this.currentOrder,
    required this.onSortChanged,
  });

  String _getSortLabel(String sortKey, bool isCurrent) {
    final effectiveOrder = isCurrent ? currentOrder : (sortKey == 'name' ? 'asc' : 'desc');
    if (sortKey == 'name') {
      return effectiveOrder == 'asc' ? 'Tên (A → Z)' : 'Tên (Z → A)';
    } else if (sortKey == 'due_desc') {
      return effectiveOrder == 'desc' ? 'Đến hạn (Nhiều)' : 'Đến hạn (Ít)';
    } else {
      return effectiveOrder == 'desc' ? 'Gần đây (Mới)' : 'Gần đây (Cũ)';
    }
  }

  IconData _getSortIcon(String sortKey) {
    if (sortKey == 'name') return Icons.sort_by_alpha_rounded;
    if (sortKey == 'due_desc') return Icons.bolt_rounded;
    return Icons.access_time_rounded;
  }

  Widget _buildSearchTagChip(TagModel tag, ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    Color tagColor;
    final hex = tag.color ?? tagColorMap[tag.name.toLowerCase()];
    if (hex != null && hex.isNotEmpty) {
      try {
        tagColor = ColorUtils.parseHex(hex);
      } catch (_) {
        tagColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      }
    } else {
      tagColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(10, 3, 6, 3),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tagColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${tag.name}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tagColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onRemoveSearchTag?.call(tag),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 14, color: tagColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasContent = selectedSearchTags.isNotEmpty || searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dòng 1: Ô Tìm kiếm có hỗ trợ Tag chips trực tiếp
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Tag Chips
                        for (final tag in selectedSearchTags)
                          _buildSearchTagChip(tag, theme, colorScheme),

                        // 2. Text Input
                        IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 100),
                            child: TextField(
                              controller: searchController,
                              focusNode: searchFocusNode,
                              onChanged: onSearchChanged,
                              onSubmitted: (val) {
                                searchFocusNode?.unfocus();
                                onSearchSubmitted?.call(val);
                              },
                              textInputAction: TextInputAction.search,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: selectedSearchTags.isEmpty
                                    ? 'Tìm kiếm thư mục, bộ thẻ, #tag...'
                                    : 'Thêm từ khóa...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasContent)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: onClearSearch,
                    splashRadius: 18,
                  ),
              ],
            ),
          ),
        ),

        // Dòng 2: Lọc thuộc tính (Multi-select) + Dropdown Sắp xếp
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              // ⚡ Có thẻ đến hạn
              _buildFilterChip(
                label: '⚡ Đến hạn',
                isSelected: onlyDue,
                onTap: () => onOnlyDueChanged(!onlyDue),
                theme: theme,
                colorScheme: colorScheme,
                activeColor: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),

              // 🆕 Có thẻ chưa học
              if (onOnlyNewChanged != null) ...[
                _buildFilterChip(
                  label: '🆕 Mới',
                  isSelected: onlyNew,
                  onTap: () => onOnlyNewChanged!(!onlyNew),
                  theme: theme,
                  colorScheme: colorScheme,
                  activeColor: Colors.teal.shade600,
                ),
                const SizedBox(width: 8),
              ],

              // ⭐ Đã đánh dấu
              _buildFilterChip(
                label: '⭐ Đã gắn sao',
                isSelected: isStarred,
                onTap: () => onStarredChanged(!isStarred),
                theme: theme,
                colorScheme: colorScheme,
                activeColor: Colors.amber.shade700,
              ),

              const Spacer(),

              // Dropdown Sắp xếp
              CustomDropdown<String>(
                value: currentSort,
                items: const ['recent', 'name', 'due_desc'],
                itemLabelBuilder: (val) => _getSortLabel(val, val == currentSort),
                itemBuilder: (val, isSelected) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSortIcon(val),
                        size: 16,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getSortLabel(val, val == currentSort),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                },
                onChanged: (val) {
                  String newOrder = val == 'name' ? 'asc' : 'desc';
                  if (val == currentSort) {
                    newOrder = currentOrder == 'desc' ? 'asc' : 'desc';
                  }
                  onSortChanged(val, newOrder);
                },
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),

        // Dòng 3: Phân loại tài nguyên (Chọn 1 trong 3: Tất cả | Thư mục | Bộ thẻ)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                _buildSegmentedTypeBtn(
                  label: 'Tất cả',
                  icon: Icons.dashboard_outlined,
                  typeKey: 'all',
                  isSelected: selectedFilterType == 'all',
                  onTap: () => onFilterTypeChanged('all'),
                  theme: theme,
                  colorScheme: colorScheme,
                ),
                _buildSegmentedTypeBtn(
                  label: 'Thư mục',
                  icon: Icons.folder_outlined,
                  typeKey: 'folder',
                  isSelected: selectedFilterType == 'folder',
                  onTap: () => onFilterTypeChanged('folder'),
                  theme: theme,
                  colorScheme: colorScheme,
                ),
                _buildSegmentedTypeBtn(
                  label: 'Bộ thẻ',
                  icon: Icons.layers_outlined,
                  typeKey: 'deck',
                  isSelected: selectedFilterType == 'deck',
                  onTap: () => onFilterTypeChanged('deck'),
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTypeBtn({
    required String label,
    required IconData icon,
    required String typeKey,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.0),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
    Color? activeColor,
  }) {
    final effectiveActiveColor = activeColor ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveActiveColor.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? effectiveActiveColor.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? effectiveActiveColor : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
