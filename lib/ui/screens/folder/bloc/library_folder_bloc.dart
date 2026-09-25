import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_event.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_state.dart';

class LibraryFolderBloc extends Bloc<LibraryFolderEvent, LibraryFolderState> {
  final FolderRepository folderRepository;
  final int limit = 20;

  LibraryFolderBloc({required this.folderRepository})
    : super(const LibraryFolderState()) {
    on<LibraryFolderLoadStarted>(_onLoadStarted);
    on<LibraryFolderRefreshed>(_onRefreshed);
    on<LibraryFolderLoadMore>(_onLoadMore);
    on<LibraryFolderFilterChanged>(_onFilterChanged);
    on<LibraryFolderSelectionToggled>(_onSelectionToggled);
    on<LibraryFolderSelectionCleared>(_onSelectionCleared);
    on<LibraryFoldersSelectedDeleted>(_onSelectedDeleted);
    on<LibraryFolderStarToggled>(_onStarToggled);
  }

  Future<void> _onLoadStarted(
    LibraryFolderLoadStarted event,
    Emitter<LibraryFolderState> emit,
  ) async {
    emit(state.copyWith(status: LibraryFolderStatus.loading));
    try {
      final result = await folderRepository.getFolders(
        page: 1,
        limit: limit,
        search: state.search,
        sort: state.sort,
        order: state.order,
        isStarred: state.isStarred,
      );
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          folders: result.data,
          suggestions: result.suggestions,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
          selectedIds: const {},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryFolderStatus.failure,
          toastMessage: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    LibraryFolderRefreshed event,
    Emitter<LibraryFolderState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final result = await folderRepository.getFolders(
        page: 1,
        limit: limit,
        search: state.search,
        sort: state.sort,
        order: state.order,
        isStarred: state.isStarred,
      );
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          isRefreshing: false,
          folders: result.data,
          suggestions: result.suggestions,
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
    LibraryFolderLoadMore event,
    Emitter<LibraryFolderState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      final result = await folderRepository.getFolders(
        page: state.currentPage + 1,
        limit: limit,
        search: state.search,
        sort: state.sort,
        order: state.order,
        isStarred: state.isStarred,
      );
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          folders: [...state.folders, ...result.data],
          suggestions: state.suggestions,
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
    LibraryFolderFilterChanged event,
    Emitter<LibraryFolderState> emit,
  ) async {
    final search = event.search ?? state.search;
    final sort = event.sort ?? state.sort;
    final order = event.order ?? state.order;
    final isStarred = event.clearIsStarred
        ? null
        : (event.isStarred ?? state.isStarred);

    emit(
      state.copyWith(
        status: LibraryFolderStatus.loading,
        search: search,
        sort: sort,
        order: order,
        isStarred: isStarred,
        clearIsStarred: event.clearIsStarred,
        selectedIds: const {},
      ),
    );
    try {
      final result = await folderRepository.getFolders(
        page: 1,
        limit: limit,
        search: search,
        sort: sort,
        order: order,
        isStarred: isStarred,
      );
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          folders: result.data,
          suggestions: result.suggestions,
          currentPage: 1,
          hasReachedMax: result.data.length < limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryFolderStatus.failure,
          toastMessage: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }

  Future<void> _onStarToggled(
    LibraryFolderStarToggled event,
    Emitter<LibraryFolderState> emit,
  ) async {
    final originalFolders = state.folders;
    final targetIndex = originalFolders.indexWhere((f) => f.id == event.id);
    if (targetIndex == -1) return;

    final targetFolder = originalFolders[targetIndex];
    final previousStarred = targetFolder.isStarred;
    final newStarred = !previousStarred;

    // 1. Cập nhật UI tức thì (Optimistic Update) & giữ nguyên dữ liệu danh sách
    final updatedFolders = List<FolderModel>.from(originalFolders);
    updatedFolders[targetIndex] = targetFolder.copyWith(isStarred: newStarred);
    emit(state.copyWith(folders: updatedFolders));

    try {
      // 2. Gọi API thay đổi trạng thái yêu thích
      await folderRepository.starFolder(event.id);
    } catch (e) {
      // 3. Nếu lỗi -> Khôi phục (revert) danh sách về trạng thái ban đầu & báo lỗi
      emit(
        state.copyWith(
          folders: originalFolders,
          toastMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  void _onSelectionToggled(
    LibraryFolderSelectionToggled event,
    Emitter<LibraryFolderState> emit,
  ) {
    final currentSelected = Set<String>.from(state.selectedIds);
    if (currentSelected.contains(event.id)) {
      currentSelected.remove(event.id);
    } else {
      currentSelected.add(event.id);
    }
    emit(state.copyWith(selectedIds: currentSelected));
  }

  void _onSelectionCleared(
    LibraryFolderSelectionCleared event,
    Emitter<LibraryFolderState> emit,
  ) {
    emit(state.copyWith(selectedIds: const {}));
  }

  Future<void> _onSelectedDeleted(
    LibraryFoldersSelectedDeleted event,
    Emitter<LibraryFolderState> emit,
  ) async {
    emit(state.copyWith(status: LibraryFolderStatus.loading));
    try {
      final ids = state.selectedIds.toList();
      for (final id in ids) {
        await folderRepository.deleteFolder(id, keepDecks: false);
      }
      final remainingData = state.folders
          .where((item) => !state.selectedIds.contains(item.id))
          .toList();
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          folders: remainingData,
          selectedIds: const {},
          toastMessage: 'Xóa thư mục thành công',
          toastTriggerTime: DateTime.now(),
          isToastError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryFolderStatus.failure,
          toastMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }
}
