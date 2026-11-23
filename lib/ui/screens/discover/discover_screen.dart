import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/search_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/commons/tag_search_controller.dart';
import 'package:mind_deck/ui/screens/discover/widgets/discover_classroom_card.dart';
import 'package:mind_deck/ui/screens/discover/widgets/discover_recommended_card.dart';
import 'package:mind_deck/ui/screens/discover/widgets/discover_trending_list_item.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_results_view.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_search_bar.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_search_idle_view.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_sort_sheet.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_suggestion_list.dart';
import 'bloc/discover_bloc.dart';
import 'bloc/discover_event.dart';
import 'bloc/discover_state.dart';
import 'services/discover_search_history_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/native_ad_slot.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TagSearchController _tagSearch = TagSearchController();
  final FocusNode _searchFocusNode = FocusNode();
  final DiscoverSearchHistoryService _historyService = DiscoverSearchHistoryService();

  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _scope = 'all';

  /// Chuỗi tìm kiếm gần nhất đã gửi (đã trim) và chuỗi gợi ý gần nhất đã xin.
  String _submittedQuery = '';
  String _lastQuery = '';

  /// true khi controller bị đổi bằng code (chọn gợi ý, lịch sử...) -> không xin gợi ý.
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    context.read<DiscoverBloc>().add(DiscoverLoaded());
    _loadRecentSearches();
    _tagSearch.addListener(_onQueryChanged);
    _searchFocusNode.onKeyEvent = (_, event) =>
        DiscoverSearchBar.handleBackspace(_tagSearch, event);
  }

  @override
  void dispose() {
    _tagSearch.removeListener(_onQueryChanged);
    _tagSearch.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final history = await _historyService.getHistory();
    if (mounted) setState(() => _recentSearches = history);
  }

  void _mutate(VoidCallback change) {
    _muted = true;
    try {
      change();
    } finally {
      _muted = false;
    }
  }

  /// Người dùng gõ / xoá / thêm bớt pill: quay về gợi ý và xin gợi ý mới (bloc tự debounce).
  void _onQueryChanged() {
    if (_muted) return;
    final query = _tagSearch.fullQuery;
    if (query == _lastQuery) return;
    _lastQuery = query;

    if (_showResults && query.trim() != _submittedQuery) {
      setState(() => _showResults = false);
    }

    final bloc = context.read<DiscoverBloc>();
    if (query.trim().isEmpty) {
      bloc.add(DiscoverSuggestionsCleared());
    } else {
      bloc.add(DiscoverSuggestRequested(query));
    }
  }

  void _enterSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _exitSearch() {
    _mutate(_tagSearch.clear);
    _lastQuery = '';
    _submittedQuery = '';
    _searchFocusNode.unfocus();
    context.read<DiscoverBloc>().add(DiscoverSearchReset());
    setState(() {
      _isSearching = false;
      _showResults = false;
      _scope = 'all';
    });
  }

  /// Gửi tìm kiếm. Nếu có [query] thì dựng lại ô tìm kiếm từ chuỗi đó (lịch sử, gợi ý, trending).
  void _submit([String? query, Iterable<TagModel> knownTags = const []]) {
    if (query != null) {
      _mutate(() => _tagSearch.setFromQuery(query, knownTags: knownTags));
    }
    final clean = _tagSearch.submitQuery;
    if (clean.isEmpty) return;

    _lastQuery = _tagSearch.fullQuery;
    _submittedQuery = clean;

    _historyService.addSearch(clean).then((updated) {
      if (mounted) setState(() => _recentSearches = updated);
    });

    context.read<DiscoverBloc>().add(
      DiscoverSearched(clean, type: _scope, sort: context.read<DiscoverBloc>().state.searchSort),
    );
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = true;
      _showResults = true;
    });
  }

  /// Đổi chip lọc (hoặc "Xem tất cả" của một nhóm): tìm lại với loại mới.
  void _onScopeChanged(String scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _submit();
  }

  Future<void> _openSort() async {
    final bloc = context.read<DiscoverBloc>();
    final picked = await DiscoverSortSheet.show(context, current: bloc.state.searchSort);
    if (picked == null || picked == bloc.state.searchSort || !mounted) return;
    bloc.add(DiscoverSearched(_submittedQuery, type: _scope, sort: picked));
  }

  /// Chọn tag trong gợi ý: chốt thành pill, thay cho phần `#abc` đang gõ dở, giữ focus để gõ tiếp.
  void _onSelectSuggestedTag(TagModel tag) {
    _mutate(() {
      final cleaned = _tagSearch.text.text.replaceAll(RegExp(r'#[^\s]*$'), '').trim();
      _tagSearch.text.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
      _tagSearch.addTag(tag);
    });
    _searchFocusNode.requestFocus();
    _requestSuggestionsForCurrent();
  }

  /// Mũi tên ↖ trên một gợi ý: điền vào ô tìm kiếm để sửa tiếp, chưa tìm.
  void _onFillKeyword(SearchKeywordSuggestionModel keyword) {
    _mutate(() => _tagSearch.setFromQuery(keyword.query, knownTags: keyword.tags));
    _searchFocusNode.requestFocus();
    _requestSuggestionsForCurrent();
  }

  void _requestSuggestionsForCurrent() {
    final query = _tagSearch.fullQuery;
    _lastQuery = query;
    if (query.trim().isEmpty) return;
    context.read<DiscoverBloc>().add(DiscoverSuggestRequested(query));
  }

  void _onTagTappedInResult(TagModel tag) {
    _tagSearch.addTag(tag);
    _submit();
  }

  /// Bấm một chủ đề từ màn Khám phá / mục phổ biến -> tìm ngay theo `#tag`.
  void _searchByTag(TagModel tag) {
    _tagSearch.rememberColors([tag]);
    _submit('#${tag.name}', [tag]);
  }

  Color _hexToColor(String? code) {
    if (code == null || code.isEmpty) return Colors.grey;
    if (code.startsWith('#')) {
      code = code.substring(1);
    }
    if (code.length == 6) {
      code = 'FF$code';
    }
    try {
      return Color(int.parse(code, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSearch();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                // Màn kết quả dùng nền phẳng khác hẳn nền gradient của trang chủ / màn gõ.
                decoration: _showResults
                    ? BoxDecoration(color: colorScheme.surfaceContainerLow)
                    : BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: 40 / 255),
                            colorScheme.surfaceContainer,
                            colorScheme.secondaryContainer.withValues(alpha: 25 / 255),
                          ],
                        ),
                      ),
              ),
            ),
            SafeArea(
              child: BlocConsumer<DiscoverBloc, DiscoverState>(
                listenWhen: (prev, curr) =>
                    prev.suggestions != curr.suggestions ||
                    prev.discoveryData != curr.discoveryData ||
                    prev.searchResults != curr.searchResults,
                listener: (context, state) => _rememberColors(state),
                builder: (context, state) {
                  if (!_isSearching) {
                    return Column(
                      children: [
                        _buildHomeHeader(colorScheme, textTheme),
                        Expanded(child: _buildDiscoverView(state, colorScheme, textTheme)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      DiscoverSearchBar(
                        controller: _tagSearch,
                        focusNode: _searchFocusNode,
                        isResultMode: _showResults,
                        hasActiveSort: state.searchSort != DiscoverState.defaultSort,
                        onBack: _exitSearch,
                        onCancel: _exitSearch,
                        onFilter: _openSort,
                        onSubmit: _submit,
                        onClear: () {
                          _tagSearch.clear();
                          _searchFocusNode.requestFocus();
                        },
                      ),
                      Expanded(child: _buildSearchBody(state)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rememberColors(DiscoverState state) {
    final tags = <TagModel>[
      ...?state.discoveryData?.popularTopics,
      ...?state.suggestions?.tags,
      for (final kw in state.suggestions?.keywords ?? const <SearchKeywordSuggestionModel>[])
        ...kw.tags,
      for (final item in state.searchResults) ...item.tags,
    ];
    _tagSearch.rememberColors(tags);
  }

  /// Ô tìm kiếm "giả" ở màn Khám phá: bấm vào là mở trang tìm kiếm.
  Widget _buildHomeHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'discover_title'.tr,
            style: textTheme.displaySmall?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 14),
          Material(
            color: colorScheme.surface.withValues(alpha: 220 / 255),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _enterSearch,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'discover_search_hint'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBody(DiscoverState state) {
    return ListenableBuilder(
      listenable: _tagSearch,
      builder: (context, _) {
        final mode = _showResults ? 'results' : (_tagSearch.isEmpty ? 'idle' : 'suggest');
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(mode), child: _buildSearchBodyInner(state)),
        );
      },
    );
  }

  Widget _buildSearchBodyInner(DiscoverState state) {
    return ListenableBuilder(
      listenable: _tagSearch,
      builder: (context, _) {
        if (_showResults) {
          return DiscoverResultsView(
            state: state,
            highlight: _submittedQuery.replaceAll(RegExp(r'#[^\s]+'), '').trim(),
            scope: _scope,
            onScopeChanged: _onScopeChanged,
            onTagTap: _onTagTappedInResult,
            onRetry: _submit,
          );
        }

        if (!_tagSearch.isEmpty) {
          final plainText = _tagSearch.text.text.replaceAll(RegExp(r'#[^\s]*'), '').trim();
          return DiscoverSuggestionList(
            controller: _tagSearch,
            status: state.suggestStatus,
            suggestions: state.suggestions,
            highlight: plainText,
            onSubmitCurrent: _submit,
            onSearchKeyword: (kw) => _submit(kw.query, kw.tags),
            onFillKeyword: _onFillKeyword,
            onSelectTag: _onSelectSuggestedTag,
          );
        }

        return DiscoverSearchIdleView(
          controller: _tagSearch,
          history: _recentSearches,
          popularTags: state.discoveryData?.popularTopics ?? const [],
          trending: state.discoveryData?.trendingKeywords ?? const [],
          onSelectHistory: _submit,
          onRemoveHistory: (q) => _historyService.removeSearch(q).then((updated) {
            if (mounted) setState(() => _recentSearches = updated);
          }),
          onClearHistory: () => _historyService.clearAll().then((_) {
            if (mounted) setState(() => _recentSearches = []);
          }),
          onSelectTag: _searchByTag,
          onSelectTrending: _submit,
        );
      },
    );
  }

  Widget _buildDiscoverView(DiscoverState state, ColorScheme colorScheme, TextTheme textTheme) {
    if (state.status == DiscoverStatus.loading && state.discoveryData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == DiscoverStatus.failure && state.discoveryData == null) {
      return CommonFailure(errorMessage: state.errorMessage ?? 'discover_loading_failed'.tr);
    }

    final data = state.discoveryData;
    if (data == null) {
      return CommonEmpty(
        title: 'discover_no_data_title'.tr,
        subtitle: 'discover_no_data_subtitle'.tr,
      );
    }

    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<DiscoverBloc>();
        bloc.add(DiscoverRefreshed());
        await bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // --- 1. CHỦ ĐỀ ĐƯỢC QUAN TÂM (Tags) ---
            if (data.popularTopics.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                child: Text(
                  'discover_interested_topics'.tr,
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: data.popularTopics.length,
                  itemBuilder: (context, index) {
                    final tag = data.popularTopics[index];
                    final tagColor = _hexToColor(tag.color);
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ActionChip(
                        backgroundColor: tagColor.withValues(alpha: 30 / 255),
                        side: BorderSide(color: tagColor.withValues(alpha: 80 / 255)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        avatar: Icon(Icons.tag_rounded, size: 16, color: tagColor),
                        label: Text(
                          tag.name,
                          style: textTheme.labelMedium?.copyWith(color: tagColor),
                        ),
                        onPressed: () => _searchByTag(tag),
                      ),
                    );
                  },
                ),
              ),
            ],

            // --- 2. DÀNH CHO BẠN (Gợi ý cá nhân) ---
            if (data.personalizedDecks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                child: Text(
                  'discover_for_you'.tr,
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: data.personalizedDecks.length,
                  itemBuilder: (context, index) {
                    return DiscoverRecommendedCard(item: data.personalizedDecks[index]);
                  },
                ),
              ),
            ],

            // --- 3. NỘI DUNG THỊNH HÀNH ---
            if (data.suggestedContents.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'discover_popular_content'.tr,
                      style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                    ),
                    // GestureDetector(
                    //   onTap: () {
                    //     context.pushNamed(AppRoute.discoverPopular.name);
                    //   },
                    //   child: Text(
                    //     'Xem thêm',
                    //     style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                    //   ),
                    // ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: data.suggestedContents.take(5).length,
                itemBuilder: (context, index) {
                  return DiscoverTrendingListItem(item: data.suggestedContents[index]);
                },
              ),
            ],

            const NativeAdSlot(
              unit: AdUnit.nativeDiscover,
              templateType: TemplateType.medium,
              margin: EdgeInsets.fromLTRB(16, 24, 16, 0),
            ),

            // --- 4. LỚP HỌC DÀNH CHO BẠN ---
            if (data.suggestedClasses.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                child: Text(
                  'discover_suggested_classes'.tr,
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: data.suggestedClasses.length,
                  itemBuilder: (context, index) {
                    return DiscoverClassroomCard(item: data.suggestedClasses[index]);
                  },
                ),
              ),
            ],

            const SizedBox(height: 80),
          ]),
        ),
      ],
    );
  }
}
