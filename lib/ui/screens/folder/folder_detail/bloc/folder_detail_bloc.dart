import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/data/repositories/shared_repository.dart';
import 'package:mind_deck/core/failures.dart';
import 'folder_detail_event.dart';
import 'folder_detail_state.dart';

class FolderDetailBloc extends Bloc<FolderDetailEvent, FolderDetailState> {
  final FolderRepository folderRepository;
  final SharedRepository sharedRepository;

  FolderDetailBloc({
    required this.folderRepository,
    required this.sharedRepository,
  }) : super(const FolderDetailState()) {
    on<FolderDetailLoaded>(_onLoaded);
    on<FolderDetailRefreshed>(_onRefreshed);
    on<FolderDeleted>(_onDeleted);
    on<FolderShareUpdated>(_onShareUpdated);
    on<FolderAddDecks>(_onAddDecks);
    on<FolderRemoveDecks>(_onRemoveDecks);
    on<FolderDetailSelectionToggled>(_onSelectionToggled);
    on<FolderDetailSelectionCleared>(_onSelectionCleared);
    on<FolderDetailCloned>(_onCloned);
  }

  Future<void> _onLoaded(
    FolderDetailLoaded event,
    Emitter<FolderDetailState> emit,
  ) async {
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      final result = await folderRepository.getFolderById(
        event.id,
        token: event.token,
      );
      emit(
        state.copyWith(status: FolderDetailStatus.success, folder: result.data),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    FolderDetailRefreshed event,
    Emitter<FolderDetailState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final result = await folderRepository.getFolderById(
        event.id,
        token: event.token,
      );
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          isRefreshing: false,
          folder: result.data,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onDeleted(
    FolderDeleted event,
    Emitter<FolderDetailState> emit,
  ) async {
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      await folderRepository.deleteFolder(event.id, keepDecks: event.keepDecks);
      emit(
        state.copyWith(
          status: FolderDetailStatus.deleted,
          successMessage: 'Đã xóa thư mục',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onShareUpdated(
    FolderShareUpdated event,
    Emitter<FolderDetailState> emit,
  ) async {
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
      await folderRepository.shareFolder(
        event.id,
        accessLevel: event.accessLevel,
      );

      // Reload
      final result = await folderRepository.getFolderById(event.id);
      FolderModel? mergedFolder = result.data;
      if (mergedFolder != null) {
        mergedFolder = mergedFolder.copyWith(
          shareMode: event.accessLevel,
          isPublic: event.accessLevel == 'public',
          decks: currentFolder?.decks ?? mergedFolder.decks,
        );
      }

      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          folder: mergedFolder ?? currentFolder,
          successMessage: event.isSilent
              ? null
              : 'Cập nhật quyền riêng tư thành công',
          toastTriggerTime: event.isSilent ? null : DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          folder: currentFolder,
          errorMessage: event.isSilent
              ? null
              : (e is Failure ? e.message : e.toString()),
          toastTriggerTime: event.isSilent ? null : DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onAddDecks(
    FolderAddDecks event,
    Emitter<FolderDetailState> emit,
  ) async {
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      await folderRepository.addDecksToFolder(event.folderId, event.deckIds);
      final result = await folderRepository.getFolderById(event.folderId);
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          folder: result.data,
          successMessage: 'Thêm bộ thẻ thành công',
          toastTriggerTime: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onRemoveDecks(
    FolderRemoveDecks event,
    Emitter<FolderDetailState> emit,
  ) async {
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      await folderRepository.removeDecksFromFolder(
        event.folderId,
        event.deckIds,
      );
      final result = await folderRepository.getFolderById(event.folderId);
      emit(
        state.copyWith(
          status: FolderDetailStatus.success,
          folder: result.data,
          successMessage: 'Đã gỡ bộ thẻ',
          toastTriggerTime: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FolderDetailStatus.failure,
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }

  void _onSelectionToggled(
    FolderDetailSelectionToggled event,
    Emitter<FolderDetailState> emit,
  ) {
    final updatedSelectedIds = Set<String>.from(state.selectedDeckIds);
    if (updatedSelectedIds.contains(event.deckId)) {
      updatedSelectedIds.remove(event.deckId);
    } else {
      updatedSelectedIds.add(event.deckId);
    }

    if (updatedSelectedIds.isEmpty) {
      emit(
        state.copyWith(
          selectedDeckIds: updatedSelectedIds.toList(),
          isSelectionMode: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedDeckIds: updatedSelectedIds.toList(),
          isSelectionMode: true,
        ),
      );
    }
  }

  void _onSelectionCleared(
    FolderDetailSelectionCleared event,
    Emitter<FolderDetailState> emit,
  ) {
    emit(state.copyWith(selectedDeckIds: const [], isSelectionMode: false));
  }

  Future<void> _onCloned(
    FolderDetailCloned event,
    Emitter<FolderDetailState> emit,
  ) async {
    emit(state.copyWith(status: FolderDetailStatus.loading));
    try {
      final response = await folderRepository.cloneFolder(
        event.id,
        token: event.token,
      );
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
          errorMessage: e is Failure ? e.message : e.toString(),
          toastTriggerTime: DateTime.now(),
        ),
      );
    }
  }
}
