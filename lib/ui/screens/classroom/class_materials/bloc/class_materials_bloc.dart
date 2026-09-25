import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_materials_event.dart';
import 'class_materials_state.dart';

class ClassMaterialsBloc extends Bloc<ClassMaterialsEvent, ClassMaterialsState> {
  final ClassRepository repository;

  ClassMaterialsBloc({required this.repository}) : super(const ClassMaterialsState()) {
    on<ClassMaterialsLoaded>(_onClassMaterialsLoaded);
    on<ClassMaterialsLoadMore>(_onClassMaterialsLoadMore);
    on<ClassMaterialsSearchChanged>(_onClassMaterialsSearchChanged);
    on<ClassMaterialsRefreshed>(_onClassMaterialsRefreshed);
    on<ClassMaterialAdded>(_onClassMaterialAdded);
    on<ClassMaterialCloned>(_onClassMaterialCloned);
    on<ClassMaterialsSelectionModeToggled>(_onSelectionModeToggled);
    on<ClassMaterialDeckSelectionToggled>(_onDeckSelectionToggled);
    on<ClassMaterialFolderSelectionToggled>(_onFolderSelectionToggled);
    on<ClassMaterialsSelectionCleared>(_onSelectionCleared);
    on<ClassMaterialsDeleted>(_onDeleted);
  }

  Future<void> _onClassMaterialsLoaded(
    ClassMaterialsLoaded event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(
      state.copyWith(status: ClassMaterialsStatus.loading, currentPage: 1, hasReachedMax: false),
    );
    try {
      final response = await repository.getMaterials(
        event.classId,
        page: 1,
        limit: 20,
        search: state.searchQuery,
      );
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: ClassMaterialsStatus.success,
            decks: response.data!.decks,
            folders: response.data!.folders,
            hasReachedMax: response.data!.decks.length < 20,
            currentPage: 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ClassMaterialsStatus.failure,
            errorMessage: response.message ?? 'Không thể tải danh sách học liệu',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: ClassMaterialsStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onClassMaterialsLoadMore(
    ClassMaterialsLoadMore event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    if (state.hasReachedMax || state.status != ClassMaterialsStatus.success) {
      return;
    }

    try {
      final nextPage = state.currentPage + 1;
      final response = await repository.getMaterials(
        event.classId,
        page: nextPage,
        limit: 20,
        search: state.searchQuery,
      );
      if (response.success && response.data != null) {
        final newDecks = response.data!.decks;
        emit(
          state.copyWith(
            decks: List.of(state.decks)..addAll(newDecks),
            // Folders are fully returned so we don't append them usually, or maybe backend handles it.
            // Let's assume folders are fully returned in page 1. We just keep the existing ones.
            folders: state.folders,
            hasReachedMax: newDecks.length < 20,
            currentPage: nextPage,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _onClassMaterialsSearchChanged(
    ClassMaterialsSearchChanged event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    add(ClassMaterialsLoaded(event.classId));
  }

  Future<void> _onClassMaterialsRefreshed(
    ClassMaterialsRefreshed event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, currentPage: 1, hasReachedMax: false));
    try {
      final response = await repository.getMaterials(
        event.classId,
        page: 1,
        limit: 20,
        search: state.searchQuery,
      );
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: ClassMaterialsStatus.success,
            decks: response.data!.decks,
            folders: response.data!.folders,
            isRefreshing: false,
            hasReachedMax: response.data!.decks.length < 20,
            currentPage: 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ClassMaterialsStatus.failure,
            errorMessage: response.message,
            isRefreshing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassMaterialsStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onClassMaterialAdded(
    ClassMaterialAdded event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.addMaterials(
        event.classId,
        folderIds: event.folderIds,
        deckIds: event.deckIds,
      );

      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        add(ClassMaterialsLoaded(event.classId));
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể thêm học liệu',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }

  Future<void> _onClassMaterialCloned(
    ClassMaterialCloned event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.cloneClassMaterials(
        event.classId,
        folderId: event.folderId,
        deckId: event.deckId,
      );
      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        // Nếu clone thành công thì thường là student muốn copy về thư viện cá nhân
        // Có thể emit event hoặc show success ở UI.
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể sao chép học liệu',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }

  void _onSelectionModeToggled(
    ClassMaterialsSelectionModeToggled event,
    Emitter<ClassMaterialsState> emit,
  ) {
    emit(
      state.copyWith(
        isSelectionMode: event.isSelectionMode ?? !state.isSelectionMode,
        selectedDecks: [],
        selectedFolders: [],
      ),
    );
  }

  void _onDeckSelectionToggled(
    ClassMaterialDeckSelectionToggled event,
    Emitter<ClassMaterialsState> emit,
  ) {
    final currentSelected = List<String>.from(state.selectedDecks);
    if (currentSelected.contains(event.deckId)) {
      currentSelected.remove(event.deckId);
    } else {
      currentSelected.add(event.deckId);
    }
    emit(state.copyWith(selectedDecks: currentSelected));
  }

  void _onFolderSelectionToggled(
    ClassMaterialFolderSelectionToggled event,
    Emitter<ClassMaterialsState> emit,
  ) {
    final currentSelected = List<String>.from(state.selectedFolders);
    if (currentSelected.contains(event.folderId)) {
      currentSelected.remove(event.folderId);
    } else {
      currentSelected.add(event.folderId);
    }
    emit(state.copyWith(selectedFolders: currentSelected));
  }

  void _onSelectionCleared(
    ClassMaterialsSelectionCleared event,
    Emitter<ClassMaterialsState> emit,
  ) {
    emit(state.copyWith(isSelectionMode: false, selectedDecks: [], selectedFolders: []));
  }

  Future<void> _onDeleted(ClassMaterialsDeleted event, Emitter<ClassMaterialsState> emit) async {
    if (state.selectedDecks.isEmpty && state.selectedFolders.isEmpty) return;

    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.deleteMaterials(
        event.classId,
        folderIds: state.selectedFolders,
        deckIds: state.selectedDecks,
      );

      if (response.success) {
        emit(
          state.copyWith(
            isProcessing: false,
            isSelectionMode: false,
            selectedDecks: [],
            selectedFolders: [],
          ),
        );
        add(ClassMaterialsLoaded(event.classId));
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể xóa học liệu',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }
}
