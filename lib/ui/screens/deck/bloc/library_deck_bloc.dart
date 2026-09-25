import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_event.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_state.dart';

class LibraryDeckBloc extends Bloc<LibraryDeckEvent, LibraryDeckState> {
  final DeckRepository deckRepository;
  final int limit = 20;

  LibraryDeckBloc({required this.deckRepository})
    : super(const LibraryDeckState()) {
    on<LibraryDeckLoadStarted>(_onLoadStarted);
    on<LibraryDeckRefreshed>(_onRefreshed);
    on<LibraryDeckLoadMore>(_onLoadMore);
    on<LibraryDeckFilterChanged>(_onFilterChanged);
    on<LibraryDeckSelectionToggled>(_onSelectionToggled);
    on<LibraryDeckStarToggled>(_onStarToggled);
    on<LibraryDeckSelectionCleared>(_onSelectionCleared);
    on<LibraryDecksSelectedDeleted>(_onSelectedDeleted);
  }

  Future<void> _onLoadStarted(
    LibraryDeckLoadStarted event,
    Emitter<LibraryDeckState> emit,
  ) async {
    emit(state.copyWith(status: LibraryDeckStatus.loading));
    try {
      final result = await deckRepository.getDecks(
        page: 1,
        limit: limit,
        search: state.search,
        filter: state.filter,
        sort: state.sort,
      );
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          decks: result.data,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
          selectedIds: const {},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryDeckStatus.failure,
          toastMessage: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    LibraryDeckRefreshed event,
    Emitter<LibraryDeckState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final result = await deckRepository.getDecks(
        page: 1,
        limit: limit,
        search: state.search,
        filter: state.filter,
        sort: state.sort,
      );
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          isRefreshing: false,
          decks: result.data,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
          selectedIds: const {},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          toastMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    LibraryDeckLoadMore event,
    Emitter<LibraryDeckState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      final result = await deckRepository.getDecks(
        page: state.currentPage + 1,
        limit: limit,
        search: state.search,
      );
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          decks: [...state.decks, ...result.data],
          currentPage: state.currentPage + 1,
          hasReachedMax: result.data.isEmpty || result.data.length < limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          toastMessage: e is Failure ? e.message : e.toString(),
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

    emit(
      state.copyWith(
        status: LibraryDeckStatus.loading,
        search: search,
        filter: filter,
        sort: sort,
        order: order,
        selectedIds: const {},
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
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          decks: result.data,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryDeckStatus.failure,
          toastMessage: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }

  void _onSelectionToggled(
    LibraryDeckSelectionToggled event,
    Emitter<LibraryDeckState> emit,
  ) {
    final currentSelected = Set<String>.from(state.selectedIds);
    if (currentSelected.contains(event.id)) {
      currentSelected.remove(event.id);
    } else {
      currentSelected.add(event.id);
    }
    emit(state.copyWith(selectedIds: currentSelected));
  }

  Future<void> _onStarToggled(
    LibraryDeckStarToggled event,
    Emitter<LibraryDeckState> emit,
  ) async {
    final originalDecks = state.decks;
    final targetIndex = originalDecks.indexWhere((d) => d.id == event.id);
    if (targetIndex == -1) return;

    final targetDeck = originalDecks[targetIndex];
    final previousStarred = targetDeck.isStarred;
    final newStarred = !previousStarred;

    // 1. Cập nhật UI tức thì (Optimistic Update) & giữ nguyên 100% dữ liệu cũ của danh sách
    final updatedDecks = List<DeckModel>.from(originalDecks);
    updatedDecks[targetIndex] = targetDeck.copyWith(isStarred: newStarred);
    emit(state.copyWith(decks: updatedDecks));

    try {
      // 2. Gọi API thay đổi trạng thái yêu thích
      await deckRepository.starDeck(event.id);
    } catch (e) {
      // 3. Nếu lỗi -> Khôi phục (revert) danh sách về trạng thái ban đầu & báo lỗi
      emit(
        state.copyWith(
          decks: originalDecks,
          toastMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  void _onSelectionCleared(
    LibraryDeckSelectionCleared event,
    Emitter<LibraryDeckState> emit,
  ) {
    emit(state.copyWith(selectedIds: const {}));
  }

  Future<void> _onSelectedDeleted(
    LibraryDecksSelectedDeleted event,
    Emitter<LibraryDeckState> emit,
  ) async {
    emit(state.copyWith(status: LibraryDeckStatus.loading));
    try {
      final ids = state.selectedIds.toList();
      for (final id in ids) {
        await deckRepository.deleteDeck(id);
      }
      final remainingData = state.decks
          .where((item) => !state.selectedIds.contains(item.id))
          .toList();
      emit(
        state.copyWith(
          status: LibraryDeckStatus.success,
          decks: remainingData,
          selectedIds: const {},
          toastMessage: 'Xóa học phần thành công',
          toastTriggerTime: DateTime.now(),
          isToastError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryDeckStatus.failure,
          toastMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }
}
