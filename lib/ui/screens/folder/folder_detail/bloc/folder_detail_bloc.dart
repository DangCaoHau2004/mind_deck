import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/data/repositories/shared_repository.dart';
import 'folder_detail_event.dart';
import 'folder_detail_state.dart';

class FolderDetailBloc extends Bloc<FolderDetailEvent, FolderDetailState> {
  final FolderRepository folderRepository;
  final SharedRepository sharedRepository;
  final int limit = 20;

  /// Token xem thư mục qua link chia sẻ (nhớ lại để các lần tải thêm/tìm kiếm dùng chung).
  String? _token;

  /// Id thư mục đang xem (nhớ từ lúc tải đầu), để tìm/sắp xếp được ngay cả khi thông tin thư mục chưa về.
  String? _folderId;

  /// Tăng mỗi lần tải lại hoặc đổi từ khóa/sắp xếp. Kết quả của lượt cũ (kể cả tải thêm trang của từ
  /// khóa cũ) thấy số này đã đổi thì bị bỏ.
  int _generation = 0;

  FolderDetailBloc({required this.folderRepository, required this.sharedRepository})
    : super(const FolderDetailState()) {
    on<FolderDetailLoaded>(_onLoaded);
    on<FolderDetailRefreshed>(_onRefreshed);
    on<FolderDetailDecksLoadMore>(_onDecksLoadMore);
    on<FolderDetailDecksFilterChanged>(_onDecksFilterChanged);
    on<FolderDeleted>(_onDeleted);
    on<FolderShareUpdated>(_onShareUpdated);
    on<FolderAddDecks>(_onAddDecks);
    on<FolderRemoveDecks>(_onRemoveDecks);
    on<FolderDetailSelectionToggled>(_onSelectionToggled);
    on<FolderDetailSelectionCleared>(_onSelectionCleared);
    on<FolderDetailCloned>(_onCloned);
  }

  /// Một API cho mọi lượt tải: thông tin thư mục (luôn mới nhất) kèm một trang bộ thẻ theo tìm kiếm và
  /// sắp xếp hiện tại. [page] 1 cho lần vào đầu, kéo làm mới, tìm, đổi sắp xếp; trang sau khi cuộn.
  Future<({FolderModel? folder, List<DeckModel> decks})> _fetch(
    String id, {
    int page = 1,
    String? search,
    String? sort,
    String? order,
  }) async {
    final response = await folderRepository.getFolderById(
      id,
      page: page,
      limit: limit,
      search: search ?? state.search,
      sort: sort ?? state.sort,
      order: order ?? state.order,
      token: _token,
    );
    final folder = response.data;
    return (folder: folder, decks: folder?.decks ?? const <DeckModel>[]);
  }

  Future<void> _onLoaded(FolderDetailLoaded event, Emitter<FolderDetailState> emit) async {
    _token = event.token;
    _folderId = event.id;
    final generation = ++_generation;
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      final result = await _fetch(event.id);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          folder: result.folder,
          decks: result.decks,
          currentPage: 1,
          hasReachedMax: result.decks.length < limit,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(FolderDetailRefreshed event, Emitter<FolderDetailState> emit) async {
    _token = event.token;
    _folderId = event.id;
    final generation = ++_generation;
    emit(state.copyWith(isRefreshing: true, isLoadingMore: false));
    try {
      final result = await _fetch(event.id);
      if (generation != _generation) {
        emit(state.copyWith(isRefreshing: false));
        return;
      }
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          isRefreshing: false,
          folder: result.folder,
          decks: result.decks,
          currentPage: 1,
          hasReachedMax: result.decks.length < limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onDecksLoadMore(
    FolderDetailDecksLoadMore event,
    Emitter<FolderDetailState> emit,
  ) async {
    final folderId = state.folder?.id;
    if (folderId == null ||
        state.hasReachedMax ||
        state.isLoadingMore ||
        state.isSearching ||
        state.isRefreshing ||
        state.status != FolderDetailStatus.success) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _fetch(folderId, page: state.currentPage + 1);
      // Từ khóa/sắp xếp đã đổi trong lúc chờ: bỏ trang của lượt cũ.
      if (generation != _generation) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          folder: result.folder ?? state.folder,
          decks: [...state.decks, ...result.decks],
          currentPage: state.currentPage + 1,
          hasReachedMax: result.decks.length < limit,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onDecksFilterChanged(
    FolderDetailDecksFilterChanged event,
    Emitter<FolderDetailState> emit,
  ) async {
    final folderId = _folderId ?? state.folder?.id;
    if (folderId == null) return;
    final search = event.search ?? state.search;
    final sort = event.sort ?? state.sort;
    final order = event.order ?? state.order;

    final generation = ++_generation;
    emit(
      state.copyWith(
        isSearching: true,
        isLoadingMore: false,
        search: search,
        sort: sort,
        order: order,
      ),
    );
    try {
      final result = await _fetch(folderId, search: search, sort: sort, order: order);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          isSearching: false,
          folder: result.folder ?? state.folder,
          decks: result.decks,
          currentPage: 1,
          hasReachedMax: result.decks.length < limit,
          listVersion: state.listVersion + 1,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          isSearching: false,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onDeleted(FolderDeleted event, Emitter<FolderDetailState> emit) async {
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      await folderRepository.deleteFolder(event.id);
      emit(state.copyWith(status: FolderDetailStatus.deleted, successMessage: 'folder_deleted'.tr));
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onShareUpdated(FolderShareUpdated event, Emitter<FolderDetailState> emit) async {
    final currentFolder = state.folder;

    // Optimistic Update cho UI cập nhật ngay tức thì
    if (currentFolder != null) {
      final updatedFolder = currentFolder.copyWith(
        shareMode: event.accessLevel,
        isPublic: event.accessLevel == 'public',
      );
      emit(state.copyWith(folder: updatedFolder));
    }

    try {
      await folderRepository.shareFolder(event.id, accessLevel: event.accessLevel);

      // Reload
      final result = await folderRepository.getFolderById(event.id);
      FolderModel? mergedFolder = result.data;
      if (mergedFolder != null) {
        mergedFolder = mergedFolder.copyWith(
          shareMode: event.accessLevel,
          isPublic: event.accessLevel == 'public',
        );
      }

      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          folder: mergedFolder ?? currentFolder,
          successMessage: event.isSilent ? null : 'Cập nhật quyền riêng tư thành công',
          toastTriggerTime: event.isSilent ? null : DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          folder: currentFolder,
          errorMessage: event.isSilent ? null : (e is Failure ? e.displayMessage : e.toString()),
          toastTriggerTime: event.isSilent ? null : DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onAddDecks(FolderAddDecks event, Emitter<FolderDetailState> emit) async {
    final generation = ++_generation;
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      await folderRepository.addDecksToFolder(event.folderId, event.deckIds);
      final result = await _fetch(event.folderId);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          folder: result.folder,
          decks: result.decks,
          currentPage: 1,
          hasReachedMax: result.decks.length < limit,
          successMessage: 'Thêm bộ thẻ thành công',
          toastTriggerTime: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onRemoveDecks(FolderRemoveDecks event, Emitter<FolderDetailState> emit) async {
    final generation = ++_generation;
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      await folderRepository.removeDecksFromFolder(event.folderId, event.deckIds);
      final result = await _fetch(event.folderId);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          folder: result.folder,
          decks: result.decks,
          currentPage: 1,
          hasReachedMax: result.decks.length < limit,
          successMessage: 'Đã gỡ bộ thẻ',
          toastTriggerTime: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  void _onSelectionToggled(FolderDetailSelectionToggled event, Emitter<FolderDetailState> emit) {
    final updatedSelectedIds = Set<String>.from(state.selectedDeckIds);
    if (updatedSelectedIds.contains(event.deckId)) {
      updatedSelectedIds.remove(event.deckId);
    } else {
      updatedSelectedIds.add(event.deckId);
    }

    emit(
      state.copyWith(
        selectedDeckIds: updatedSelectedIds.toList(),
        isSelectionMode: updatedSelectedIds.isNotEmpty,
      ),
    );
  }

  void _onSelectionCleared(FolderDetailSelectionCleared event, Emitter<FolderDetailState> emit) {
    emit(state.copyWith(selectedDeckIds: const [], isSelectionMode: false));
  }

  Future<void> _onCloned(FolderDetailCloned event, Emitter<FolderDetailState> emit) async {
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      final response = await folderRepository.cloneFolder(event.id, token: event.token);
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          successMessage: 'Nhân bản thư mục thành công!',
          toastTriggerTime: DateTime.now(),
          clonedFolderId: response.data?.id,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.displayMessage : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }
}
