import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/repositories/tag_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/folder_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_dialog.dart';
import 'package:mind_deck/ui/commons/selection_action_bar.dart';
import 'package:mind_deck/ui/commons/shimmer_sweep.dart';
import 'package:mind_deck/ui/screens/main_shell/bottom_bar_slot.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_bloc.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_event.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_state.dart';
import 'package:mind_deck/ui/screens/folder/services/folder_search_history_service.dart';
import 'package:mind_deck/ui/screens/folder/widgets/folder_item_widget.dart';
import 'package:mind_deck/ui/screens/folder/widgets/folder_search_suggestions_panel.dart';
import 'package:mind_deck/ui/screens/folder/widgets/tag_highlight_editing_controller.dart';
import 'package:mind_deck/ui/screens/library/widgets/library_header.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/native_ad_slot.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';

class LibraryFolderTab extends StatefulWidget {
  const LibraryFolderTab({super.key});

  @override
  State<LibraryFolderTab> createState() => _LibraryFolderTabState();
}

class _LibraryFolderTabState extends State<LibraryFolderTab> {
  final TagHighlightEditingController _searchController = TagHighlightEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FolderSearchHistoryService _historyService = FolderSearchHistoryService();

  Timer? _debounceTimer;
  List<FolderSearchHistoryItem> _recentSearches = [];
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
      context.read<LibraryFolderBloc>().add(LibraryFolderLoadMore());
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _searchController.text.isEmpty &&
        _selectedSearchTags.isNotEmpty) {
      // Khi text trống và bấm Backspace -> Gỡ tag cuối cùng thành chuỗi text "#tag" để user xóa lùi từng chữ
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

  /// Ghi nhớ màu sắc của các tag vào bộ nhớ (không bao giờ bị xóa khi BLoC loading)
  void _rememberTagColors(LibraryFolderState? state) {
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
      for (final kw in state.suggestions?.keywords ?? <FolderKeywordSuggestionModel>[]) {
        for (final tag in kw.tags) {
          if (tag.color != null && tag.color!.isNotEmpty) {
            _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
          }
        }
      }
      for (final folder in state.folders) {
        for (final tag in (folder.tags ?? <TagModel>[])) {
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

      final state = context.read<LibraryFolderBloc>().state;
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
      final currentBlocSearch = context.read<LibraryFolderBloc>().state.search;
      if (fullQuery != currentBlocSearch) {
        context.read<LibraryFolderBloc>().add(LibraryFolderFilterChanged(search: fullQuery));
      }
    });
    setState(() {});
  }

  void _executeSearch(String query, [LibraryFolderState? currentState]) {
    _debounceTimer?.cancel();
    final clean = query.trim();
    if (clean.isNotEmpty) {
      final state = currentState ?? context.read<LibraryFolderBloc>().state;
      _rememberTagColors(state);
      _historyService.addSearch(clean, tagColors: _tagColorMemory).then((updated) {
        if (mounted) setState(() => _recentSearches = updated);
      });
    }
    final currentBlocSearch = context.read<LibraryFolderBloc>().state.search;
    if (clean != currentBlocSearch) {
      context.read<LibraryFolderBloc>().add(LibraryFolderFilterChanged(search: clean));
    }
  }

  /// Xóa hẳn một Tag khi ấn nút X trên viên thuốc Tag
  void _removeSearchTag(TagModel tag) {
    setState(() {
      _selectedSearchTags.removeWhere((t) => t.name.toLowerCase() == tag.name.toLowerCase());
    });
    _executeSearch(_fullSearchQuery);
  }

  void _onSelectKeyword(FolderKeywordSuggestionModel keyword) {
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

  void _onSelectRecent(FolderSearchHistoryItem item) {
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
    context.read<LibraryFolderBloc>().add(const LibraryFolderFilterChanged(search: ''));
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
  Widget? _buildSelectionBar(BuildContext context, LibraryFolderState state) {
    final selected = state.selected.values.toList();
    if (selected.isEmpty) return null;
    final bloc = context.read<LibraryFolderBloc>();
    return SelectionActionBar(
      leading: SelectionStackIcon(
        color: ColorUtils.parseHex(selected.first.color),
        icon: AppIcons.getIconFromKey(selected.first.icon),
        stacked: selected.length > 1,
      ),
      title: 'library_selected_folders'.tr.replaceAll('{count}', '${selected.length}'),
      subtitle: selected.map((f) => f.name).join(', '),
      reviewSubtitle: selected.fold<int>(0, (sum, f) => sum + (f.dueCount ?? 0)) > 0
          ? 'library_due_cards'.tr.replaceAll(
              '{count}',
              '${selected.fold<int>(0, (sum, f) => sum + (f.dueCount ?? 0))}',
            )
          : null,
      allStarred: selected.every((f) => f.isStarred),
      onCancel: () => bloc.add(LibraryFolderSelectionCleared()),
      onStar: () => bloc.add(LibraryFolderSelectedStarToggled()),
      onDelete: () async {
        final confirmed = await CustomDialog.show<bool>(
          context,
          icon: Icons.delete_outline_rounded,
          title: 'folder_delete_title'.tr.replaceAll('{count}', '${selected.length}'),
          description: 'folder_delete_keep_decks'.tr,
          confirmText: 'library_delete'.tr,
          confirmButtonColor: Theme.of(context).colorScheme.error,
        );
        if (confirmed == true) bloc.add(LibraryFoldersSelectedDeleted());
      },
      onReview: () {
        final folders = selected.map((f) => f.toJson()).toList();
        bloc.add(LibraryFolderSelectionCleared());
        context.pushNamed(AppRoute.testSetup.name, extra: {'type': 'folders', 'data': folders});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LibraryFolderBloc, LibraryFolderState>(
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

        // Cập nhật màu sắc mới nhất từ Backend vào các chip tag đang chọn nếu trước đó chưa có màu
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
              CustomToast.danger(message: state.toastMessage ?? 'Có lỗi xảy ra'),
            );
          } else {
            CustomToast.show(
              context,
              CustomToast.success(message: state.toastMessage ?? 'Thành công'),
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
        final folderAds = NativeAdPositions(itemCount: state.folders.length, first: 2, maxAds: 1);
        // Lỗi lần đầu vẫn giữ skeleton (báo bằng toast), kéo để làm mới là tải lại.
        final bool isInitialLoading =
            (state.status == LibraryFolderStatus.initial ||
                state.status == LibraryFolderStatus.loading ||
                state.status == LibraryFolderStatus.failure) &&
            state.folders.isEmpty;
        // Danh sách trống mà đang tìm lại quá 300ms thì cũng hiện skeleton (trước đó giữ màn trống)
        final bool showSkeleton =
            isInitialLoading ||
            (state.isSearching && _showSearchIndicator && state.folders.isEmpty);
        final bloc = context.read<LibraryFolderBloc>();

        return Stack(
          children: [
            ShimmerScope(
              active: _showSearchIndicator,
              child: CommonRefresh(
                controller: _scrollController,
                onRefresh: () async {
                  bloc.add(LibraryFolderRefreshed());
                  await bloc.stream.firstWhere((LibraryFolderState s) => !s.isRefreshing);
                },
                slivers: [
                  // Đang chọn nhiều thì làm mờ và chặn bấm phần đầu trang
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: state.isSelectionMode ? 0.4 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: state.isSelectionMode,
                        child: const LibraryHeader(selectedIndex: 0),
                      ),
                    ),
                  ),
                  // Thanh tìm kiếm/lọc cuộn cùng danh sách: trượt đi khi cuộn xuống, chỉ hiện lại ở đầu danh sách
                  SliverToBoxAdapter(child: _buildActionBar(context, theme, state)),
                  if (showSkeleton)
                    SliverToBoxAdapter(
                      child: Skeletonizer(
                        child: Column(
                          children: [
                            for (var i = 0; i < 5; i++)
                              FolderItemWidget(folder: FolderModel.placeholder()),
                          ],
                        ),
                      ),
                    )
                  else if (state.folders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: state.search.isNotEmpty
                          ? CommonEmpty.search(
                              title: 'folder_empty_search_title'.tr,
                              subtitle: 'folder_empty_search_subtitle'.tr,
                            )
                          : state.isStarred == true
                          ? CommonEmpty(
                              icon: Icons.star_outline_rounded,
                              title: 'folder_empty_starred_title'.tr,
                              subtitle: 'folder_empty_starred_subtitle'.tr,
                            )
                          : CommonEmpty(
                              icon: Icons.folder_open_rounded,
                              title: 'folder_empty_title'.tr,
                              subtitle: 'folder_empty_subtitle'.tr,
                              actionText: 'folder_empty_action'.tr,
                              onActionPressed: _createFolder,
                            ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: state.isSelectionMode ? 220 : 80),
                      sliver: SliverList.builder(
                        itemCount: folderAds.totalCount + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (folderAds.isAd(index)) {
                            return const NativeAdSlot(unit: AdUnit.nativeLibrary);
                          }
                          index = folderAds.itemIndex(index);
                          if (index >= state.folders.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final folder = state.folders[index];
                          final isSelected = state.selected.containsKey(folder.id);

                          return ShimmerSweep(
                            child: FolderItemWidget(
                              folder: folder,
                              isSelected: isSelected,
                              isSelectionMode: state.isSelectionMode,
                              searchQuery: _fullSearchQuery,
                              onStarTap: () => bloc.add(LibraryFolderStarToggled(folder.id)),
                              onLongPress: () => bloc.add(LibraryFolderSelectionToggled(folder.id)),
                              onTap: () async {
                                if (state.isSelectionMode) {
                                  bloc.add(LibraryFolderSelectionToggled(folder.id));
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
                                    AppRoute.folderDetail.name,
                                    pathParameters: {'id': folder.id},
                                    extra: folder.toJson(),
                                  );
                                  if (!context.mounted) return;
                                  if (result is FolderModel) {
                                    // Back bình thường: cập nhật tại chỗ mục vừa xem, không gọi API
                                    bloc.add(LibraryFolderItemUpdated(result));
                                  } else if (result != null) {
                                    // Đã xóa thư mục: báo và tải lại danh sách
                                    if (result is String) {
                                      CustomToast.show(
                                        context,
                                        CustomToast.success(message: result),
                                      );
                                    }
                                    bloc.add(LibraryFolderRefreshed());
                                  }
                                }
                              },
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

  /// Mở màn tạo thư mục; tạo xong thì báo và làm mới danh sách.
  Future<void> _createFolder() async {
    final result = await context.pushNamed(AppRoute.folderCreate.name);
    if (result is String && mounted) {
      CustomToast.show(context, CustomToast.success(message: result));
      context.read<LibraryFolderBloc>().add(LibraryFolderRefreshed());
    }
  }

  Widget _buildActionBar(BuildContext context, ThemeData theme, LibraryFolderState state) {
    final colorScheme = theme.colorScheme;
    final bloc = context.read<LibraryFolderBloc>();
    final hasContent = _selectedSearchTags.isNotEmpty || _searchController.text.isNotEmpty;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);

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
                                                  ? 'folder_search_hint'
                                                  : 'folder_search_hint_more')
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
              // Nút tạo thư mục
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
                      ? () => bloc.add(LibraryFolderSelectionCleared())
                      : _createFolder,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      state.isSelectionMode
                          ? Icons.close_rounded
                          : Icons.create_new_folder_outlined,
                      color: state.isSelectionMode ? colorScheme.onSurface : Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          FolderSearchSuggestionsPanel(
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
                state.isStarred != true,
                () => bloc.add(const LibraryFolderFilterChanged(clearIsStarred: true)),
              ),
              filterChip(
                'deck_filter_starred'.tr,
                state.isStarred == true,
                () => bloc.add(const LibraryFolderFilterChanged(isStarred: true)),
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
                        'library_select_hint_folder'.tr,
                        style: theme.textTheme.bodyLarge?.copyWith(color: mutedColor),
                      )
                    : const SizedBox.shrink(),
              ),
              CustomDropdown<String>(
                value: state.sort,
                items: const ['recent', 'name'],
                itemLabelBuilder: (v) => (v == 'recent' ? 'sort_recent' : 'sort_name').tr,
                // Chọn lại mục đang chọn thì đảo chiều; icon cho biết chiều hiện tại
                trailing: Icon(
                  state.order == 'desc' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                onChanged: (v) => bloc.add(
                  LibraryFolderFilterChanged(
                    sort: v,
                    order: v == state.sort
                        ? (state.order == 'desc' ? 'asc' : 'desc')
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
      // Tag không tồn tại trong DB -> Dùng màu xám trung tính
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
