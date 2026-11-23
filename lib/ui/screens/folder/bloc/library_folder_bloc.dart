import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_event.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_state.dart';

class LibraryFolderBloc extends Bloc<LibraryFolderEvent, LibraryFolderState> {
  final FolderRepository folderRepository;
  final int limit = 20;

  /// BE chỉ nhận tối đa 50 id mỗi lần gắn sao / xóa hàng loạt.
  static const int maxSelection = 50;

  /// Tăng mỗi lần tải lại hoặc đổi từ khóa/lọc/sắp xếp. Kết quả của lượt cũ (kể cả tải thêm trang
  /// của từ khóa cũ) thấy số này đã đổi thì bị bỏ.
  int _generation = 0;

  LibraryFolderBloc({required this.folderRepository}) : super(const LibraryFolderState()) {
    on<LibraryFolderLoadStarted>(_onLoadStarted);
    on<LibraryFolderRefreshed>(_onRefreshed);
    on<LibraryFolderLoadMore>(_onLoadMore);
    on<LibraryFolderFilterChanged>(_onFilterChanged);
    on<LibraryFolderSelectionToggled>(_onSelectionToggled);
    on<LibraryFolderSelectionCleared>(_onSelectionCleared);
    on<LibraryFolderSelectedStarToggled>(_onSelectedStarToggled);
    on<LibraryFoldersSelectedDeleted>(_onSelectedDeleted);
    on<LibraryFolderStarToggled>(_onStarToggled);
    on<LibraryFolderItemUpdated>(_onItemUpdated);
  }

  Future<void> _onLoadStarted(
    LibraryFolderLoadStarted event,
    Emitter<LibraryFolderState> emit,
  ) async {
    final generation = ++_generation;
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
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          folders: result.data,
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
          status: LibraryFolderStatus.failure,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  Future<void> _onRefreshed(LibraryFolderRefreshed event, Emitter<LibraryFolderState> emit) async {
    final generation = ++_generation;
    emit(state.copyWith(isRefreshing: true, isLoadingMore: false));
    try {
      final result = await folderRepository.getFolders(
        page: 1,
        limit: limit,
        search: state.search,
        sort: state.sort,
        order: state.order,
        isStarred: state.isStarred,
      );
      if (generation != _generation) {
        emit(state.copyWith(isRefreshing: false));
        return;
      }
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          isRefreshing: false,
          folders: result.data,
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

  Future<void> _onLoadMore(LibraryFolderLoadMore event, Emitter<LibraryFolderState> emit) async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.isSearching ||
        state.isRefreshing ||
        state.status != LibraryFolderStatus.success) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await folderRepository.getFolders(
        page: state.currentPage + 1,
        limit: limit,
        search: state.search,
        sort: state.sort,
        order: state.order,
        isStarred: state.isStarred,
      );
      // Từ khóa/lọc đã đổi trong lúc chờ: bỏ trang của lượt cũ.
      if (generation != _generation) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          folders: [...state.folders, ...result.data],
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
    LibraryFolderFilterChanged event,
    Emitter<LibraryFolderState> emit,
  ) async {
    final search = event.search ?? state.search;
    final sort = event.sort ?? state.sort;
    final order = event.order ?? state.order;
    final isStarred = event.clearIsStarred ? null : (event.isStarred ?? state.isStarred);

    final generation = ++_generation;
    // Đã tải xong ít nhất một lần (kể cả danh sách đang trống): tìm lại thì giữ màn hiện tại và chỉ báo "đang tìm".
    final hasList = state.status == LibraryFolderStatus.success;
    emit(
      state.copyWith(
        // Có danh sách thì giữ nguyên và chỉ báo "đang tìm"; chưa có thì dùng skeleton.
        status: hasList ? state.status : LibraryFolderStatus.loading,
        isSearching: hasList,
        isLoadingMore: false,
        search: search,
        sort: sort,
        order: order,
        isStarred: isStarred,
        clearIsStarred: event.clearIsStarred,
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
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: LibraryFolderStatus.success,
          isSearching: false,
          folders: result.data,
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
          status: hasList ? LibraryFolderStatus.success : LibraryFolderStatus.failure,
          isSearching: false,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  void _onItemUpdated(LibraryFolderItemUpdated event, Emitter<LibraryFolderState> emit) {
    final updated = event.folder;
    if (!state.folders.any((f) => f.id == updated.id)) return;
    emit(
      state.copyWith(
        folders: [for (final f in state.folders) f.id == updated.id ? updated : f],
        selected: state.selected.containsKey(updated.id)
            ? {...state.selected, updated.id: updated}
            : state.selected,
      ),
    );
  }

  void _onSelectionToggled(LibraryFolderSelectionToggled event, Emitter<LibraryFolderState> emit) {
    final selected = Map<String, FolderModel>.from(state.selected);
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
      final item = state.folders.where((x) => x.id == event.id).firstOrNull;
      if (item == null) return;
      selected[event.id] = item;
    }
    emit(state.copyWith(selected: selected));
  }

  Future<void> _onStarToggled(
    LibraryFolderStarToggled event,
    Emitter<LibraryFolderState> emit,
  ) async {
    final original = state.folders;
    final originalSelected = state.selected;
    final targetIndex = original.indexWhere((x) => x.id == event.id);
    if (targetIndex == -1) return;

    // Cập nhật giao diện ngay (optimistic), lỗi thì khôi phục
    final updated = original[targetIndex].copyWith(isStarred: !original[targetIndex].isStarred);
    final updatedList = List<FolderModel>.from(original)..[targetIndex] = updated;
    emit(
      state.copyWith(
        folders: updatedList,
        selected: originalSelected.containsKey(event.id)
            ? {...originalSelected, event.id: updated}
            : originalSelected,
      ),
    );

    try {
      await folderRepository.starFolder(event.id);
    } catch (e) {
      emit(
        state.copyWith(
          folders: original,
          selected: originalSelected,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  Future<void> _onSelectedStarToggled(
    LibraryFolderSelectedStarToggled event,
    Emitter<LibraryFolderState> emit,
  ) async {
    final ids = state.selected.keys.toList();
    final original = state.folders;
    final originalSelected = state.selected;
    // BE đặt giá trị rõ ràng cho cả lô: tất cả đã gắn sao thì bỏ sao, ngược lại gắn sao.
    final target = !originalSelected.values.every((x) => x.isStarred);

    emit(
      state.copyWith(
        folders: [
          for (final x in original)
            originalSelected.containsKey(x.id) ? x.copyWith(isStarred: target) : x,
        ],
        selected: {
          for (final e in originalSelected.entries) e.key: e.value.copyWith(isStarred: target),
        },
      ),
    );
    try {
      await folderRepository.starFolders(ids, isStarred: target);
      emit(state.copyWith(selected: const {}));
    } catch (e) {
      emit(
        state.copyWith(
          folders: original,
          selected: originalSelected,
          toastMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
          isToastError: true,
        ),
      );
    }
  }

  void _onSelectionCleared(LibraryFolderSelectionCleared event, Emitter<LibraryFolderState> emit) {
    emit(state.copyWith(selected: const {}));
  }

  Future<void> _onSelectedDeleted(
    LibraryFoldersSelectedDeleted event,
    Emitter<LibraryFolderState> emit,
  ) async {
    final ids = state.selected.keys.toList();
    try {
      await folderRepository.deleteFolders(ids);
      emit(
        state.copyWith(
          folders: state.folders.where((x) => !ids.contains(x.id)).toList(),
          selected: const {},
          toastMessage: 'folder_deleted'.tr,
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
  Map<String, FolderModel> _syncSelected(
    Map<String, FolderModel> selected,
    List<FolderModel> fresh,
  ) {
    if (selected.isEmpty) return selected;
    final byId = {for (final x in fresh) x.id: x};
    return {for (final e in selected.entries) e.key: byId[e.key] ?? e.value};
  }
}
