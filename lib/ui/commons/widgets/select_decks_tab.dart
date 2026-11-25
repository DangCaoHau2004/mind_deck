import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Danh sách chọn nhiều bộ thẻ. Mặc định tìm trên danh sách đã có sẵn; truyền [onSearchChanged] thì việc tìm
/// do bên ngoài làm (vd gọi API) và [decks] là kết quả đã lọc.
class SelectDecksTab extends StatefulWidget {
  final List<DeckModel> decks;
  final List<DeckModel> selectedDecks;
  final Function(DeckModel) onDeckToggled;

  /// Id bộ thẻ đã có trong đích (vd lớp học, thư mục) -> hiện [existingLabel].
  final Set<String> existingIds;

  /// Nhãn cho bộ thẻ đã có trong đích; null thì dùng "Đã có trong lớp".
  final String? existingLabel;

  /// true: bộ thẻ đã có hiện mờ, đánh dấu sẵn và không chạm để chọn được.
  final bool lockExisting;

  /// Có thì bỏ lọc trên máy, báo từ khóa mới cho bên ngoài tự tìm.
  final ValueChanged<String>? onSearchChanged;

  /// Đang tìm/tải lại danh sách: hiện vòng xoay thay cho danh sách.
  final bool isLoading;

  /// Gọi khi cuộn gần cuối danh sách (bên ngoài tự quyết định còn trang để tải hay không).
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const SelectDecksTab({
    super.key,
    required this.decks,
    required this.selectedDecks,
    required this.onDeckToggled,
    this.existingIds = const {},
    this.existingLabel,
    this.lockExisting = false,
    this.onSearchChanged,
    this.isLoading = false,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  State<SelectDecksTab> createState() => _SelectDecksTabState();
}

class _SelectDecksTabState extends State<SelectDecksTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text == _query) return;
      setState(() {
        _query = _searchController.text;
      });
      widget.onSearchChanged?.call(_query);
    });
    _scrollController.addListener(() {
      if (widget.onLoadMore != null && _scrollController.position.extentAfter < 600) {
        widget.onLoadMore!();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredDecks = widget.onSearchChanged != null
        ? widget.decks
        : widget.decks.where((d) => d.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        // Search Bar specific to Decks
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'select_decks_search_hint'.tr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredDecks.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? 'select_decks_empty'.tr : 'select_decks_search_empty'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredDecks.length + (widget.isLoadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == filteredDecks.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final deck = filteredDecks[i];
                    final isExisting = widget.existingIds.contains(deck.id);
                    final isLocked = isExisting && widget.lockExisting;
                    final isSelected = isLocked || widget.selectedDecks.any((d) => d.id == deck.id);

                    return Opacity(
                      opacity: isLocked ? 0.55 : 1,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.05)
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: isLocked ? null : () => widget.onDeckToggled(deck),
                          leading: Icon(
                            isSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          title: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: ColorUtils.parseHex(deck.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  deck.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(left: 24.0),
                            child: Text(
                              '${'select_decks_card_count'.tr.replaceAll('{count}', '${deck.cardCount ?? 0}')}'
                              '${isExisting ? ' · ${widget.existingLabel ?? 'select_decks_in_class'.tr}' : ''}',
                              style: isExisting && !isLocked
                                  ? TextStyle(color: Colors.orange.shade800)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
