import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_class_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/global_search_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/screens/discover/bloc/discover_bloc.dart';
import 'package:mind_deck/ui/screens/discover/bloc/discover_event.dart';
import 'package:mind_deck/ui/screens/discover/bloc/discover_state.dart';
import 'package:mind_deck/ui/screens/discover/widgets/discover_classroom_card.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_filter_chips.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_result_card.dart';

/// Màn kết quả tìm kiếm (tách hẳn khỏi màn gõ/gợi ý).
/// - Chip "Tất cả": 3 nhóm Bộ thẻ → Thư mục → Lớp học (vuốt ngang), cùng thứ tự với chip, mỗi nhóm ≤5 mục, nhóm nào có kết quả cũng có "Xem tất cả".
/// - Chip khác: danh sách phẳng một loại, cuộn vô hạn.
class DiscoverResultsView extends StatefulWidget {
  final DiscoverState state;

  /// Từ khóa (không gồm #tag) để tô đậm trong tên.
  final String highlight;
  final String scope;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<TagModel> onTagTap;
  final VoidCallback onRetry;

  const DiscoverResultsView({
    super.key,
    required this.state,
    required this.highlight,
    required this.scope,
    required this.onScopeChanged,
    required this.onTagTap,
    required this.onRetry,
  });

  @override
  State<DiscoverResultsView> createState() => _DiscoverResultsViewState();
}

class _DiscoverResultsViewState extends State<DiscoverResultsView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiscoverResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
    _loadMoreIfNeededAfterLayout();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 320) {
      context.read<DiscoverBloc>().add(DiscoverSearchLoadMore());
    }
  }

  /// Trang đầu có thể chưa lấp đầy màn hình (không có gì để cuộn) -> tự xin trang kế.
  void _loadMoreIfNeededAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final s = widget.state;
      if (s.searchType != 'all' &&
          s.searchHasMore &&
          !s.isLoadingMore &&
          _scroll.position.maxScrollExtent <= 0) {
        context.read<DiscoverBloc>().add(DiscoverSearchLoadMore());
      }
    });
  }

  DiscoverySuggestedClassModel _toClass(GlobalSearchModel item) => DiscoverySuggestedClassModel(
    id: item.entityId,
    name: item.name,
    description: item.description,
    ownerName: item.ownerName,
    memberCount: item.memberCount,
    isJoined: item.isJoined,
    isPending: item.isPending,
    joinCode: item.joinCode,
  );

  Widget _contentCard(GlobalSearchModel item) {
    return DiscoverResultCard(
      item: item,
      highlight: widget.highlight,
      onTagTap: widget.onTagTap,
      onTap: () => context.pushNamed(
        item.type == SearchType.folder ? AppRoute.folderDetail.name : AppRoute.deckDetail.name,
        pathParameters: {'id': item.entityId},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        DiscoverFilterChips(value: widget.scope, onChanged: widget.onScopeChanged),
        const SizedBox(height: 4),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    final state = widget.state;

    if (state.searchStatus == SearchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchStatus == SearchStatus.failure) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CommonFailure(errorMessage: state.searchErrorMessage ?? 'discover_search_failed'.tr),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('discover_retry'.tr),
          ),
        ],
      );
    }

    if (state.searchType == 'all') return _buildSections(state);
    return _buildFlatList(state);
  }

  // ---- Chip "Tất cả": các nhóm ----
  static const _sectionOrder = [SearchType.deck, SearchType.folder, SearchType.classroom];

  Widget _buildSections(DiscoverState state) {
    final byType = {for (final s in state.searchSections) s.type: s};
    final sections = [
      for (final type in _sectionOrder)
        if (byType[type] != null && byType[type]!.items.isNotEmpty) byType[type]!,
    ];

    if (sections.isEmpty) {
      return CommonEmpty.search(subtitle: 'discover_empty_hint'.tr);
    }

    return ListView(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [for (final section in sections) _buildSection(section)],
    );
  }

  Widget _buildSection(GlobalSearchSectionModel section) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isClass = section.type == SearchType.classroom;

    final (icon, title) = switch (section.type) {
      SearchType.classroom => (Icons.school_rounded, 'discover_group_class'.tr),
      SearchType.folder => (Icons.folder_rounded, 'discover_group_folder'.tr),
      _ => (Icons.style_rounded, 'discover_group_deck'.tr),
    };
    final scope = isClass
        ? 'class'
        : section.type == SearchType.folder
        ? 'folder'
        : 'deck';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // Luôn hiện: bấm để lọc riêng loại này (BE chỉ báo hasMore khi >5 kết quả).
                TextButton(
                  onPressed: () => widget.onScopeChanged(scope),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('discover_see_all'.tr),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isClass)
            SizedBox(
              height: 166,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: section.items.length,
                itemBuilder: (_, i) => DiscoverClassroomCard(item: _toClass(section.items[i])),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [for (final item in section.items) _contentCard(item)]),
            ),
        ],
      ),
    );
  }

  // ---- Chip một loại: danh sách phẳng + cuộn vô hạn ----
  Widget _buildFlatList(DiscoverState state) {
    final results = state.searchResults;
    if (results.isEmpty) {
      return CommonEmpty.search(subtitle: 'discover_empty_hint'.tr);
    }

    return ListView.builder(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: results.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = results[index];
        if (item.type == SearchType.classroom) {
          return DiscoverClassroomCard(item: _toClass(item), width: null);
        }
        return _contentCard(item);
      },
    );
  }
}
