import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/repositories/tag_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/deck_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_dialog.dart';
import 'package:mind_deck/ui/commons/selection_action_bar.dart';
import 'package:mind_deck/ui/commons/shimmer_sweep.dart';
import 'package:mind_deck/ui/screens/main_shell/bottom_bar_slot.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_bloc.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_event.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_state.dart';
import 'package:mind_deck/ui/screens/deck/services/deck_search_history_service.dart';
import 'package:mind_deck/ui/screens/deck/widgets/deck_item_widget.dart';
import 'package:mind_deck/ui/screens/deck/widgets/deck_search_suggestions_panel.dart';
import 'package:mind_deck/ui/screens/folder/widgets/tag_highlight_editing_controller.dart';
import 'package:mind_deck/ui/screens/library/widgets/library_header.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/native_ad_slot.dart';

class LibraryDeckTab extends StatefulWidget {
  const LibraryDeckTab({super.key});

  @override
  State<LibraryDeckTab> createState() => _LibraryDeckTabState();
}

class _LibraryDeckTabState extends State<LibraryDeckTab> {
  final TagHighlightEditingController _searchController = TagHighlightEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DeckSearchHistoryService _historyService = DeckSearchHistoryService();

  Timer? _debounceTimer;
  List<DeckSearchHistoryItem> _recentSearches = [];
  List<TagModel> _selectedSearchTags = [];
  final Map<String, String> _tagColorMemory = {};
  bool _isSearchFocused = false;
  String _lastSearchText = '';

  final ScrollController _scrollController = ScrollController();

  /// Chỉ báo "đang tìm" (vệt sáng + vòng xoay) chỉ hiện khi chờ quá 300ms để khỏi nháy khi mạng nhanh.
  static const Duration _searchIndicatorDelay = Duration(milliseconds: 300);
  Timer? _searchIndicatorTimer;
  bool _showSearchIndicator = false;
  int _lastListVersion = 0;

  String get _fullSearchQuery {
    final tagPart = _selectedSearchTags.map((t) => '#${t.name}').join(' ');
    final textPart = _searchController.text.trim();
    if (tagPart.isEmpty) return textPart;
    if (textPart.isEmpty) return tagPart;
    return '$tagPart $textPart';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    _scrollController.addListener(_onScroll);
    _loadRecentSearches();
    // Tải trước tag để form tạo/sửa mở ra là có sẵn
    unawaited(DI().sl<TagRepository>().prefetch());
  }

  /// Gần cuối danh sách thì tải trang tiếp (bloc tự bỏ qua khi đang tải hoặc đã hết).
  void _onScroll() {
    if (_scrollController.position.extentAfter < 600) {
      context.read<LibraryDeckBloc>().add(LibraryDeckLoadMore());
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _searchController.text.isEmpty &&
        _selectedSearchTags.isNotEmpty) {
      setState(() {
        final lastTag = _selectedSearchTags.removeLast();
        final tagText = '#${lastTag.name}';
        _searchController.text = tagText;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: tagText.length),
        );
        _lastSearchText = tagText;
      });
      _executeSearch(_fullSearchQuery);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _loadRecentSearches() async {
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _recentSearches = history;
      });
      for (final item in history) {
        for (final entry in item.tagColors.entries) {
          _tagColorMemory[entry.key] = entry.value;
        }
      }
      _syncColorMemoryToController();
    }
  }

  void _rememberTagColors(LibraryDeckState? state) {
    if (state != null) {
      for (final tag in state.activeTags) {
        if (tag.color != null && tag.color!.isNotEmpty) {
          _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
        }
      }
      for (final tag in state.suggestions?.tags ?? <TagModel>[]) {
        if (tag.color != null && tag.color!.isNotEmpty) {
          _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
        }
      }
      for (final kw in state.suggestions?.keywords ?? <DeckKeywordSuggestionModel>[]) {
        for (final tag in kw.tags) {
          if (tag.color != null && tag.color!.isNotEmpty) {
            _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
          }
        }
      }
      for (final deck in state.decks) {
        for (final tag in (deck.tags ?? <TagModel>[])) {
          if (tag.color != null && tag.color!.isNotEmpty) {
            _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
          }
        }
      }
    }
    for (final tag in _selectedSearchTags) {
      if (tag.color != null && tag.color!.isNotEmpty) {
        _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
      }
    }
  }

  void _syncColorMemoryToController() {
    final Map<String, Color> colorMap = {};
    for (final entry in _tagColorMemory.entries) {
      try {
        colorMap[entry.key] = ColorUtils.parseHex(entry.value);
      } catch (_) {}
    }
    _searchController.addTagColors(colorMap);
  }

  void _onFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _onSearchChanged() {
    final currentText = _searchController.text;
    if (currentText == _lastSearchText) {
      return;
    }
    _lastSearchText = currentText;

    // Khi người dùng nhấn phím Space kết thúc một #tag (vd: "#abc ") -> Đóng gói thành viên thuốc Tag
    final tagRegex = RegExp(r'#([^\s]+)\s');
    final match = tagRegex.firstMatch(currentText);
    if (match != null) {
      final tagName = match.group(1)!;
      final remaining = currentText.replaceFirst(tagRegex, '');

      final state = context.read<LibraryDeckBloc>().state;
      _rememberTagColors(state);

      final hex = _tagColorMemory[tagName.toLowerCase()];
      final newTag = TagModel(id: '', name: tagName, color: hex);

      if (!_selectedSearchTags.any((t) => t.name.toLowerCase() == tagName.toLowerCase())) {
        _selectedSearchTags.add(newTag);
      }

      _searchController.text = remaining;
      _lastSearchText = remaining;
      _executeSearch(_fullSearchQuery);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final fullQuery = _fullSearchQuery;
      final currentBlocSearch = context.read<LibraryDeckBloc>().state.search;
      if (fullQuery != currentBlocSearch) {
        context.read<LibraryDeckBloc>().add(LibraryDeckFilterChanged(search: fullQuery));
      }
    });
    setState(() {});
  }

  void _executeSearch(String query, [LibraryDeckState? currentState]) {
    _debounceTimer?.cancel();
    final clean = query.trim();
    if (clean.isNotEmpty) {
      final state = currentState ?? context.read<LibraryDeckBloc>().state;
      _rememberTagColors(state);
      _historyService.addSearch(clean, tagColors: _tagColorMemory).then((updated) {
        if (mounted) setState(() => _recentSearches = updated);
      });
    }
    final currentBlocSearch = context.read<LibraryDeckBloc>().state.search;
    if (clean != currentBlocSearch) {
      context.read<LibraryDeckBloc>().add(LibraryDeckFilterChanged(search: clean));
    }
  }

  void _removeSearchTag(TagModel tag) {
    setState(() {
      _selectedSearchTags.removeWhere((t) => t.name.toLowerCase() == tag.name.toLowerCase());
    });
    _executeSearch(_fullSearchQuery);
  }

  void _onSelectKeyword(DeckKeywordSuggestionModel keyword) {
    for (final tag in keyword.tags) {
      if (tag.color != null && tag.color!.isNotEmpty) {
        _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
      }
    }
    _syncColorMemoryToController();

    setState(() {
      _selectedSearchTags = List<TagModel>.from(keyword.tags);
      if (keyword.displayText.isNotEmpty && keyword.displayText != keyword.query) {
        _searchController.text = keyword.displayText;
      } else {
        final nonTagWords = keyword.query
            .split(RegExp(r'\s+'))
            .where((t) => !t.startsWith('#'))
            .join(' ');
        _searchController.text = nonTagWords;
      }
      _lastSearchText = _searchController.text;
    });
    _searchFocusNode.unfocus();
    _executeSearch(keyword.query);
  }

  void _onSelectRecent(DeckSearchHistoryItem item) {
    for (final entry in item.tagColors.entries) {
      _tagColorMemory[entry.key] = entry.value;
    }
    _syncColorMemoryToController();

    final tokens = item.query.trim().split(RegExp(r'\s+'));
    final tags = <TagModel>[];
    final words = <String>[];

    for (final token in tokens) {
      if (token.startsWith('#') && token.length > 1) {
        final tagName = token.substring(1);
        final hex = _tagColorMemory[tagName.toLowerCase()];
        tags.add(TagModel(id: '', name: tagName, color: hex));
      } else if (token.isNotEmpty) {
        words.add(token);
      }
    }

    setState(() {
      _selectedSearchTags = tags;
      _searchController.text = words.join(' ');
      _lastSearchText = _searchController.text;
    });
    _searchFocusNode.unfocus();
    _executeSearch(item.query);
  }

  void _onSelectTag(TagModel tag) {
    if (tag.color != null && tag.color!.isNotEmpty) {
      _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
      _syncColorMemoryToController();
    }

    final currentText = _searchController.text;
    final tagPattern = RegExp(r'#[^\s]*$');
    final cleaned = currentText.replaceAll(tagPattern, '').trim();

    setState(() {
      if (!_selectedSearchTags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase())) {
        _selectedSearchTags.add(tag);
      }
      _searchController.text = cleaned;
      _lastSearchText = cleaned;
    });

    _searchFocusNode.requestFocus();
    _executeSearch(_fullSearchQuery);
  }

  void _clearSearch() {
    setState(() {
      _selectedSearchTags.clear();
      _searchController.clear();
      _lastSearchText = '';
    });
    context.read<LibraryDeckBloc>().add(const LibraryDeckFilterChanged(search: ''));
    _searchFocusNode.unfocus();
  }

  void _onRemoveRecent(String query) async {
    final updated = await _historyService.removeSearch(query);
    if (mounted) setState(() => _recentSearches = updated);
  }

  void _onClearAllRecent() async {
    await _historyService.clearAll();
    if (mounted) setState(() => _recentSearches = []);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchIndicatorTimer?.cancel();
    _scrollController.dispose();
    // Trả thanh điều hướng lại (đợi khung hình sau vì đang gỡ widget)
    WidgetsBinding.instance.addPostFrameCallback((_) => bottomBarSlot.value = null);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Thanh hành động nổi thay chỗ thanh điều hướng khi đang chọn nhiều; null khi chưa chọn mục nào.
  Widget? _buildSelectionBar(BuildContext context, LibraryDeckState state) {
    final selected = state.selected.values.toList();
    if (selected.isEmpty) return null;
    final bloc = context.read<LibraryDeckBloc>();
    return SelectionActionBar(
      leading: SelectionStackIcon(
        color: ColorUtils.parseHex(selected.first.color),
        icon: AppIcons.getIconFromKey(selected.first.icon),
        stacked: selected.length > 1,
      ),
      title: 'library_selected_decks'.tr.replaceAll('{count}', '${selected.length}'),
      subtitle: selected.map((d) => d.name).join(', '),
      reviewSubtitle: selected.fold<int>(0, (sum, d) => sum + (d.dueCount ?? 0)) > 0
          ? 'library_due_cards'.tr.replaceAll(
              '{count}',
              '${selected.fold<int>(0, (sum, d) => sum + (d.dueCount ?? 0))}',
            )
          : null,
      allStarred: selected.every((d) => d.isStarred),
      onCancel: () => bloc.add(LibraryDeckSelectionCleared()),
      onStar: () => bloc.add(LibraryDeckSelectedStarToggled()),
      onDelete: () async {
        final confirmed = await CustomDialog.show<bool>(
          context,
          icon: Icons.delete_outline_rounded,
          title: 'deck_delete_title'.tr.replaceAll('{count}', '${selected.length}'),
          description: 'deck_delete_irreversible'.tr,
          confirmText: 'library_delete'.tr,
          confirmButtonColor: Theme.of(context).colorScheme.error,
        );
        if (confirmed == true) bloc.add(LibraryDecksSelectedDeleted());
      },
      onReview: () {
        final decks = selected.map((d) => d.toJson()).toList();
        bloc.add(LibraryDeckSelectionCleared());
        context.pushNamed(AppRoute.testSetup.name, extra: {'type': 'decks', 'data': decks});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LibraryDeckBloc, LibraryDeckState>(
      listener: (context, state) {
        _rememberTagColors(state);
        _syncColorMemoryToController();
        bottomBarSlot.value = _buildSelectionBar(context, state);

        if (state.isSearching) {
          _searchIndicatorTimer ??= Timer(_searchIndicatorDelay, () {
            if (mounted) setState(() => _showSearchIndicator = true);
          });
        } else {
          _searchIndicatorTimer?.cancel();
          _searchIndicatorTimer = null;
          if (_showSearchIndicator) setState(() => _showSearchIndicator = false);
        }

        // Kết quả tìm/lọc mới thay danh sách: cuộn nhẹ về đầu
        if (state.listVersion != _lastListVersion) {
          _lastListVersion = state.listVersion;
          if (_scrollController.hasClients && _scrollController.offset > 0) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }

        if (state.activeTags.isNotEmpty) {
          bool updated = false;
          final updatedTags = _selectedSearchTags.map((t) {
            final foundHex = _tagColorMemory[t.name.toLowerCase()];
            if (foundHex != null && foundHex.isNotEmpty && t.color != foundHex) {
              updated = true;
              return t.copyWith(color: foundHex);
            }
            return t;
          }).toList();
          if (updated) {
            setState(() {
              _selectedSearchTags = updatedTags;
            });
          }
        }

        if (state.toastTriggerTime != null) {
          if (state.isToastError) {
            CustomToast.show(
              context,
              CustomToast.danger(message: state.toastMessage ?? 'common_error_occurred'.tr),
            );
          } else {
            CustomToast.show(
              context,
              CustomToast.success(message: state.toastMessage ?? 'common_success'.tr),
            );
          }
        }
      },
      listenWhen: (previous, current) =>
          previous.toastTriggerTime != current.toastTriggerTime ||
          previous.isSearching != current.isSearching ||
          previous.listVersion != current.listVersion ||
          previous.selected != current.selected ||
          previous.activeTags != current.activeTags ||
          previous.suggestions != current.suggestions,
      builder: (context, state) {
        // Mỗi danh sách chỉ một ô quảng cáo, sau mục thứ 2 (ẩn khi dưới 2 mục hoặc đang chọn nhiều).
        final deckAds = NativeAdPositions(itemCount: state.decks.length, first: 2, maxAds: 1);
        // Lỗi lần đầu vẫn giữ skeleton (báo bằng toast), kéo để làm mới là tải lại.
        final bool isInitialLoading =
            (state.status == LibraryDeckStatus.initial ||
                state.status == LibraryDeckStatus.loading ||
                state.status == LibraryDeckStatus.failure) &&
            state.decks.isEmpty;
        // Danh sách trống mà đang tìm lại quá 300ms thì cũng hiện skeleton (trước đó giữ màn trống)
        final bool showSkeleton =
            isInitialLoading || (state.isSearching && _showSearchIndicator && state.decks.isEmpty);
        final bloc = context.read<LibraryDeckBloc>();

        return Stack(
          children: [
            ShimmerScope(
              active: _showSearchIndicator,
              child: CommonRefresh(
                controller: _scrollController,
                onRefresh: () async {
                  bloc.add(LibraryDeckRefreshed());
                  await bloc.stream.firstWhere((LibraryDeckState s) => !s.isRefreshing);
                },
                slivers: [
                  // Đang chọn nhiều thì làm mờ và chặn bấm phần đầu trang
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: state.isSelectionMode ? 0.4 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: state.isSelectionMode,
                        child: const LibraryHeader(selectedIndex: 1),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildActionBar(context, theme, state)),
                  if (showSkeleton)
                    SliverToBoxAdapter(
                      child: Skeletonizer(
                        child: Column(
                          children: [
                            for (var i = 0; i < 5; i++)
                              DeckItemWidget(
                                deck: DeckModel.placeholder(),
                                isSelected: false,
                                isSelectionMode: false,
                              ),
                          ],
                        ),
                      ),
                    )
                  else if (state.decks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: state.search.isNotEmpty
                          ? CommonEmpty.search(
                              title: 'deck_empty_search_title'.tr,
                              subtitle: 'deck_empty_search_subtitle'.tr,
                            )
                          : state.filter == 'starred'
                          ? CommonEmpty(
                              icon: Icons.star_outline_rounded,
                              title: 'deck_empty_starred_title'.tr,
                              subtitle: 'deck_empty_starred_subtitle'.tr,
                            )
                          : CommonEmpty(
                              icon: Icons.style_outlined,
                              title: 'deck_empty_title'.tr,
                              subtitle: 'deck_empty_subtitle'.tr,
                              actionText: 'deck_empty_action'.tr,
                              onActionPressed: _createDeck,
                            ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: state.isSelectionMode ? 220 : 80),
                      sliver: SliverList.builder(
                        itemCount: deckAds.totalCount + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (deckAds.isAd(index)) {
                            return const NativeAdSlot(unit: AdUnit.nativeLibrary);
                          }
                          index = deckAds.itemIndex(index);
                          if (index >= state.decks.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final deck = state.decks[index];
                          final isSelected = state.selected.containsKey(deck.id);

                          return ShimmerSweep(
                            child: DeckItemWidget(
                              deck: deck,
                              isSelected: isSelected,
                              isSelectionMode: state.isSelectionMode,
                              onLongPress: () => bloc.add(LibraryDeckSelectionToggled(deck.id)),
                              onTap: () async {
                                if (state.isSelectionMode) {
                                  bloc.add(LibraryDeckSelectionToggled(deck.id));
                                } else {
                                  final query = _fullSearchQuery;
                                  if (query.isNotEmpty) {
                                    _rememberTagColors(state);
                                    _historyService
                                        .addSearch(query, tagColors: _tagColorMemory)
                                        .then((updated) {
                                          if (mounted) setState(() => _recentSearches = updated);
                                        });
                                  }
                                  final result = await context.pushNamed(
                                    AppRoute.deckDetail.name,
                                    pathParameters: {'id': deck.id},
                                    extra: deck.toJson(),
                                  );
                                  if (!context.mounted) return;
                                  if (result is DeckModel) {
                                    // Back bình thường: cập nhật tại chỗ mục vừa xem (vd đổi sao), không gọi API
                                    bloc.add(LibraryDeckItemUpdated(result));
                                  } else if (result != null) {
                                    bloc.add(LibraryDeckRefreshed());
                                  }
                                }
                              },
                              onStarTap: () => bloc.add(LibraryDeckStarToggled(deck.id)),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Mở màn tạo học phần; tạo xong thì báo và làm mới danh sách.
  Future<void> _createDeck() async {
    final result = await context.pushNamed(AppRoute.deckCreate.name);
    if (result != null && mounted) {
      if (result is String) {
        CustomToast.show(context, CustomToast.success(message: result));
      }
      context.read<LibraryDeckBloc>().add(LibraryDeckRefreshed());
    }
  }

  Widget _buildActionBar(BuildContext context, ThemeData theme, LibraryDeckState state) {
    final colorScheme = theme.colorScheme;
    final bloc = context.read<LibraryDeckBloc>();
    final hasContent = _selectedSearchTags.isNotEmpty || _searchController.text.isNotEmpty;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);
    final sort = state.sort ?? 'recent';
    final order = state.order ?? 'desc';

    Widget filterChip(String label, bool selected, VoidCallback onTap, {IconData? icon}) {
      final fg = selected ? colorScheme.onPrimary : colorScheme.primary;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Material(
          color: selected ? colorScheme.primary : colorScheme.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? Colors.transparent : colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 4)],
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ô tìm kiếm: các tag đã chốt nằm ngay trong ô, gõ xong tự tìm (debounce)
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isSearchFocused
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search_rounded, color: colorScheme.primary),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            children: [
                              for (final tag in _selectedSearchTags)
                                _buildSearchTagChip(tag, theme, colorScheme),
                              IntrinsicWidth(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 80),
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (_) {
                                      _searchFocusNode.unfocus();
                                      _executeSearch(_fullSearchQuery, state);
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          (_selectedSearchTags.isEmpty
                                                  ? 'deck_search_hint'
                                                  : 'deck_search_hint_more')
                                              .tr,
                                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                        color: mutedColor.withValues(alpha: 0.7),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showSearchIndicator)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else if (hasContent)
                        IconButton(
                          icon: Icon(Icons.cancel_rounded, color: mutedColor, size: 20),
                          onPressed: _clearSearch,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nút tạo học phần
              Material(
                color: state.isSelectionMode
                    ? colorScheme.onSurface.withValues(alpha: 0.08)
                    : colorScheme.primary,
                elevation: state.isSelectionMode ? 0 : 6,
                shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: state.isSelectionMode
                      ? () => bloc.add(LibraryDeckSelectionCleared())
                      : _createDeck,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      state.isSelectionMode ? Icons.close_rounded : Icons.add_rounded,
                      color: state.isSelectionMode ? colorScheme.onSurface : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
          DeckSearchSuggestionsPanel(
            isVisible: _isSearchFocused,
            currentQuery: _searchController.text,
            activeTagNames: _selectedSearchTags.map((t) => t.name).toSet(),
            recentSearches: _recentSearches,
            suggestions: state.suggestions,
            onSelectKeyword: _onSelectKeyword,
            onSelectRecent: _onSelectRecent,
            onSelectTag: _onSelectTag,
            onRemoveRecent: _onRemoveRecent,
            onClearAllRecent: _onClearAllRecent,
            onClose: () => _searchFocusNode.unfocus(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              filterChip(
                'library_filter_all'.tr,
                state.filter != 'starred',
                () => bloc.add(const LibraryDeckFilterChanged(filter: 'all')),
              ),
              filterChip(
                'deck_filter_starred'.tr,
                state.filter == 'starred',
                () => bloc.add(const LibraryDeckFilterChanged(filter: 'starred')),
                icon: Icons.star_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: state.isSelectionMode
                    ? Text(
                        'library_select_hint_deck'.tr,
                        style: theme.textTheme.bodyLarge?.copyWith(color: mutedColor),
                      )
                    : const SizedBox.shrink(),
              ),
              CustomDropdown<String>(
                value: sort,
                items: const ['recent', 'name'],
                itemLabelBuilder: (v) => (v == 'recent' ? 'sort_recent' : 'sort_name').tr,
                // Chọn lại mục đang chọn thì đảo chiều; icon cho biết chiều hiện tại
                trailing: Icon(
                  order == 'desc' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                onChanged: (v) => bloc.add(
                  LibraryDeckFilterChanged(
                    sort: v,
                    order: v == sort
                        ? (order == 'desc' ? 'asc' : 'desc')
                        : (v == 'name' ? 'asc' : 'desc'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Render Viên thuốc Tag NGAY TRONG thanh tìm kiếm (Chuẩn màu DB hoặc màu xám nếu không tồn tại, kèm nút X xóa nhanh)
  Widget _buildSearchTagChip(TagModel tag, ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    Color tagColor;
    final hex = tag.color ?? _tagColorMemory[tag.name.toLowerCase()];
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
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
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
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _removeSearchTag(tag),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 14, color: tagColor),
            ),
          ),
        ],
      ),
    );
  }
}
