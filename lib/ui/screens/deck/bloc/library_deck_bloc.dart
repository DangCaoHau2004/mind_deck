import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_event.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_state.dart';

class LibraryDeckBloc extends Bloc<LibraryDeckEvent, LibraryDeckState> {
  final DeckRepository deckRepository;
  final int limit = 20;

  /// BE chỉ nhận tối đa 50 id mỗi lần gắn sao / xóa hàng loạt.
  static const int maxSelection = 50;

  /// Tăng mỗi lần tải lại hoặc đổi từ khóa/lọc/sắp xếp. Kết quả của lượt cũ (kể cả tải thêm trang
  /// của từ khóa cũ) thấy số này đã đổi thì bị bỏ.
  int _generation = 0;

  LibraryDeckBloc({required this.deckRepository}) : super(const LibraryDeckState()) {
    on<LibraryDeckLoadStarted>(_onLoadStarted);
    on<LibraryDeckRefreshed>(_onRefreshed);
    on<LibraryDeckLoadMore>(_onLoadMore);
    on<LibraryDeckFilterChanged>(_onFilterChanged);
    on<LibraryDeckSelectionToggled>(_onSelectionToggled);
    on<LibraryDeckStarToggled>(_onStarToggled);
    on<LibraryDeckItemUpdated>(_onItemUpdated);
    on<LibraryDeckSelectionCleared>(_onSelectionCleared);
    on<LibraryDeckSelectedStarToggled>(_onSelectedStarToggled);
    on<LibraryDecksSelectedDeleted>(_onSelectedDeleted);
  }

  Future<void> _onLoadStarted(LibraryDeckLoadStarted event, Emitter<LibraryDeckState> emit) async {
    final generation = ++_generation;
    emit(state.copyWith(status: LibraryDeckStatus.loading));
    try {
      final result = await deckRepository.getDecks(
        page: 1,
        limit: limit,
        search: state.search,
        filter: state.filter,
        sort: state.sort,
        order: state.order,
      );
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          decks: result.data,
          suggestions: result.suggestions,
          activeTags: result.activeTags,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
          selected: const {},
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: LibraryDeckStatus.failure,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  Future<void> _onRefreshed(LibraryDeckRefreshed event, Emitter<LibraryDeckState> emit) async {
    final generation = ++_generation;
    emit(state.copyWith(isRefreshing: true, isLoadingMore: false));
    try {
      final result = await deckRepository.getDecks(
        page: 1,
        limit: limit,
        search: state.search,
        filter: state.filter,
        sort: state.sort,
        order: state.order,
      );
      if (generation != _generation) {
        emit(state.copyWith(isRefreshing: false));
        return;
      }
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          isRefreshing: false,
          decks: result.data,
          suggestions: result.suggestions,
          activeTags: result.activeTags,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
          selected: _syncSelected(state.selected, result.data),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  Future<void> _onLoadMore(LibraryDeckLoadMore event, Emitter<LibraryDeckState> emit) async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.isSearching ||
        state.isRefreshing ||
        state.status != LibraryDeckStatus.success) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await deckRepository.getDecks(
        page: state.currentPage + 1,
        limit: limit,
        search: state.search,
        filter: state.filter,
        sort: state.sort,
        order: state.order,
      );
      // Từ khóa/lọc đã đổi trong lúc chờ: bỏ trang của lượt cũ.
      if (generation != _generation) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          decks: [...state.decks, ...result.data],
          activeTags: result.activeTags.isNotEmpty ? result.activeTags : state.activeTags,
          currentPage: state.currentPage + 1,
          hasReachedMax: result.data.isEmpty || result.data.length < limit,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  Future<void> _onFilterChanged(
    LibraryDeckFilterChanged event,
    Emitter<LibraryDeckState> emit,
  ) async {
    final search = event.search ?? state.search;
    final filter = event.filter ?? state.filter;
    final sort = event.sort ?? state.sort;
    final order = event.order ?? state.order;

    final generation = ++_generation;
    // Đã tải xong ít nhất một lần (kể cả danh sách đang trống): tìm lại thì giữ màn hiện tại và chỉ báo "đang tìm".
    final hasList = state.status == LibraryDeckStatus.success;
    emit(
      state.copyWith(
        // Có danh sách thì giữ nguyên và chỉ báo "đang tìm"; chưa có thì dùng skeleton.
        status: hasList ? state.status : LibraryDeckStatus.loading,
        isSearching: hasList,
        isLoadingMore: false,
        search: search,
        filter: filter,
        sort: sort,
        order: order,
      ),
    );

    try {
      final result = await deckRepository.getDecks(
        page: 1,
        limit: limit,
        search: search,
        filter: filter,
        sort: sort,
        order: order,
      );
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          isSearching: false,
          decks: result.data,
          suggestions: result.suggestions,
          activeTags: result.activeTags,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
          listVersion: state.listVersion + 1,
          selected: _syncSelected(state.selected, result.data),
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: hasList ? LibraryDeckStatus.success : LibraryDeckStatus.failure,
          isSearching: false,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  void _onItemUpdated(LibraryDeckItemUpdated event, Emitter<LibraryDeckState> emit) {
    final updated = event.deck;
    if (!state.decks.any((d) => d.id == updated.id)) return;
    emit(
      state.copyWith(
        decks: [for (final d in state.decks) d.id == updated.id ? updated : d],
        selected: state.selected.containsKey(updated.id)
            ? {...state.selected, updated.id: updated}
            : state.selected,
      ),
    );
  }

  void _onSelectionToggled(LibraryDeckSelectionToggled event, Emitter<LibraryDeckState> emit) {
    final selected = Map<String, DeckModel>.from(state.selected);
    if (selected.containsKey(event.id)) {
      selected.remove(event.id);
    } else if (selected.length >= maxSelection) {
      emit(
        state.copyWith(
          toastMessage: 'library_select_limit'.tr,
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
      return;
    } else {
      // Mục vừa bấm luôn nằm trong danh sách đang hiện
      final item = state.decks.where((x) => x.id == event.id).firstOrNull;
      if (item == null) return;
      selected[event.id] = item;
    }
    emit(state.copyWith(selected: selected));
  }

  Future<void> _onStarToggled(LibraryDeckStarToggled event, Emitter<LibraryDeckState> emit) async {
    final original = state.decks;
    final originalSelected = state.selected;
    final targetIndex = original.indexWhere((x) => x.id == event.id);
    if (targetIndex == -1) return;

    // Cập nhật giao diện ngay (optimistic), lỗi thì khôi phục
    final updated = original[targetIndex].copyWith(isStarred: !original[targetIndex].isStarred);
    final updatedList = List<DeckModel>.from(original)..[targetIndex] = updated;
    emit(
      state.copyWith(
        decks: updatedList,
        selected: originalSelected.containsKey(event.id)
            ? {...originalSelected, event.id: updated}
            : originalSelected,
      ),
    );

    try {
      await deckRepository.starDeck(event.id);
    } catch (e) {
      emit(
        state.copyWith(
          decks: original,
          selected: originalSelected,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  Future<void> _onSelectedStarToggled(
    LibraryDeckSelectedStarToggled event,
    Emitter<LibraryDeckState> emit,
  ) async {
    final ids = state.selected.keys.toList();
    final original = state.decks;
    final originalSelected = state.selected;
    // BE đặt giá trị rõ ràng cho cả lô: tất cả đã gắn sao thì bỏ sao, ngược lại gắn sao.
    final target = !originalSelected.values.every((x) => x.isStarred);

    emit(
      state.copyWith(
        decks: [
          for (final x in original)
            originalSelected.containsKey(x.id) ? x.copyWith(isStarred: target) : x,
        ],
        selected: {
          for (final e in originalSelected.entries) e.key: e.value.copyWith(isStarred: target),
        },
      ),
    );
    try {
      await deckRepository.starDecks(ids, isStarred: target);
      emit(state.copyWith(selected: const {}));
    } catch (e) {
      emit(
        state.copyWith(
          decks: original,
          selected: originalSelected,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  void _onSelectionCleared(LibraryDeckSelectionCleared event, Emitter<LibraryDeckState> emit) {
    emit(state.copyWith(selected: const {}));
  }

  Future<void> _onSelectedDeleted(
    LibraryDecksSelectedDeleted event,
    Emitter<LibraryDeckState> emit,
  ) async {
    final ids = state.selected.keys.toList();
    try {
      await deckRepository.deleteDecks(ids);
      emit(
        state.copyWith(
          decks: state.decks.where((x) => !ids.contains(x.id)).toList(),
          selected: const {},
          toastMessage: 'deck_deleted'.tr,
          toastTriggerTime: DateTime.now(),
          isToastError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  /// Cập nhật dữ liệu mới nhất cho các mục đang chọn nếu chúng có trong [fresh]; mục không có trong
  /// [fresh] (vd bị tìm/lọc loại khỏi danh sách) vẫn được giữ chọn.
  Map<String, DeckModel> _syncSelected(Map<String, DeckModel> selected, List<DeckModel> fresh) {
    if (selected.isEmpty) return selected;
    final byId = {for (final x in fresh) x.id: x};
    return {for (final e in selected.entries) e.key: byId[e.key] ?? e.value};
  }
}
