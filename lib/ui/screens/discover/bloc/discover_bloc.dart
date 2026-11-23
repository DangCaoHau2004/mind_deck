import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/repositories/discovery_repository.dart';
import 'package:mind_deck/data/repositories/search_repository.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  static const int searchPageSize = 20;
  static const Duration suggestDebounce = Duration(milliseconds: 300);

  final DiscoveryRepository discoveryRepository;
  final SearchRepository searchRepository;

  DiscoverBloc({required this.discoveryRepository, required this.searchRepository})
    : super(const DiscoverState()) {
    on<DiscoverLoaded>(_onLoaded);
    on<DiscoverRefreshed>(_onRefreshed);
    on<DiscoverSearched>(_onSearched, transformer: restartable());
    on<DiscoverSearchLoadMore>(_onSearchLoadMore, transformer: droppable());
    on<DiscoverSuggestRequested>(_onSuggestRequested, transformer: restartable());
    on<DiscoverSuggestionsCleared>(_onSuggestionsCleared);
    on<DiscoverSearchReset>(_onSearchReset);
  }

  String _messageOf(Object e) => e is Failure ? e.message : e.toString();

  Future<void> _onLoaded(DiscoverLoaded event, Emitter<DiscoverState> emit) async {
    emit(state.copyWith(status: DiscoverStatus.loading));
    try {
      final response = await discoveryRepository.getDiscoveryFeed();
      if (response.success && response.data != null) {
        emit(state.copyWith(status: DiscoverStatus.success, discoveryData: response.data));
      } else {
        emit(state.copyWith(status: DiscoverStatus.failure, errorMessage: response.message));
      }
    } catch (e) {
      emit(state.copyWith(status: DiscoverStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRefreshed(DiscoverRefreshed event, Emitter<DiscoverState> emit) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final response = await discoveryRepository.getDiscoveryFeed();
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: DiscoverStatus.success,
            discoveryData: response.data,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscoverStatus.failure,
            errorMessage: response.message,
            isRefreshing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onSearched(DiscoverSearched event, Emitter<DiscoverState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      add(DiscoverSearchReset());
      return;
    }

    emit(
      state.copyWith(
        searchStatus: SearchStatus.loading,
        searchQuery: query,
        searchType: event.type,
        searchSort: event.sort,
        searchPage: 1,
        searchHasMore: false,
        isLoadingMore: false,
        searchResults: const [],
        searchSections: const [],
        suggestStatus: SuggestStatus.initial,
        suggestions: () => null,
      ),
    );
    try {
      final page = await searchRepository.search(
        query: query,
        type: event.type,
        sort: event.sort,
        page: 1,
        limit: searchPageSize,
      );
      emit(
        state.copyWith(
          searchStatus: SearchStatus.success,
          searchResults: page.items,
          searchSections: page.sections ?? const [],
          searchPage: page.page,
          searchHasMore: page.hasMore,
        ),
      );
    } catch (e) {
      emit(state.copyWith(searchStatus: SearchStatus.failure, searchErrorMessage: _messageOf(e)));
    }
  }

  Future<void> _onSearchLoadMore(DiscoverSearchLoadMore event, Emitter<DiscoverState> emit) async {
    // Tab Tất cả hiển thị theo nhóm (≤5 mục/nhóm), không phân trang.
    if (state.searchType == 'all' ||
        !state.searchHasMore ||
        state.isLoadingMore ||
        state.searchStatus != SearchStatus.success) {
      return;
    }
    final query = state.searchQuery;
    final type = state.searchType;
    final sort = state.searchSort;
    final nextPage = state.searchPage + 1;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await searchRepository.search(
        query: query,
        type: type,
        sort: sort,
        page: nextPage,
        limit: searchPageSize,
      );
      // Bỏ kết quả nếu trong lúc chờ người dùng đã chuyển sang truy vấn khác.
      if (state.searchQuery != query || state.searchType != type || state.searchSort != sort) {
        return;
      }

      // Trang có thể ít hơn limit (BE loại mục đã xoá) nên lọc trùng cho chắc.
      final seen = state.searchResults.map((e) => e.objectId).toSet();
      final fresh = page.items.where((e) => !seen.contains(e.objectId)).toList();
      emit(
        state.copyWith(
          searchResults: [...state.searchResults, ...fresh],
          searchPage: nextPage,
          searchHasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (state.searchQuery == query && state.searchType == type && state.searchSort == sort) {
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onSuggestRequested(
    DiscoverSuggestRequested event,
    Emitter<DiscoverState> emit,
  ) async {
    final cleanQuery = event.query.trim();
    if (cleanQuery.isEmpty) {
      emit(state.copyWith(suggestStatus: SuggestStatus.initial, suggestions: () => null));
      return;
    }

    // restartable() đánh dấu emitter cũ là isDone khi có event mới, nhưng không dừng code đang chạy:
    // phải tự thoát sau khoảng chờ thì mới thành debounce (nếu không vẫn gọi API cho mọi ký tự).
    await Future<void>.delayed(suggestDebounce);
    if (emit.isDone) return;

    emit(state.copyWith(suggestStatus: SuggestStatus.loading));
    try {
      final response = await searchRepository.suggest(query: cleanQuery, type: event.type);

      if (response.success && response.data != null) {
        emit(
          state.copyWith(suggestStatus: SuggestStatus.success, suggestions: () => response.data),
        );
      } else {
        emit(state.copyWith(suggestStatus: SuggestStatus.failure, suggestions: () => null));
      }
    } catch (_) {
      emit(state.copyWith(suggestStatus: SuggestStatus.failure, suggestions: () => null));
    }
  }

  void _onSuggestionsCleared(DiscoverSuggestionsCleared event, Emitter<DiscoverState> emit) {
    emit(state.copyWith(suggestStatus: SuggestStatus.initial, suggestions: () => null));
  }

  void _onSearchReset(DiscoverSearchReset event, Emitter<DiscoverState> emit) {
    emit(
      state.copyWith(
        searchStatus: SearchStatus.initial,
        searchResults: const [],
        searchSections: const [],
        searchQuery: '',
        searchType: 'all',
        searchSort: DiscoverState.defaultSort,
        searchPage: 1,
        searchHasMore: false,
        isLoadingMore: false,
        suggestStatus: SuggestStatus.initial,
        suggestions: () => null,
      ),
    );
  }
}
