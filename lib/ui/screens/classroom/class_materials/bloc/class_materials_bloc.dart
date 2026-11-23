import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_materials_event.dart';
import 'class_materials_state.dart';

class ClassMaterialsBloc extends Bloc<ClassMaterialsEvent, ClassMaterialsState> {
  final ClassRepository repository;

  static const int pageSize = 20;

  ClassMaterialsBloc({required this.repository}) : super(const ClassMaterialsState()) {
    on<ClassMaterialsLoaded>(_onClassMaterialsLoaded);
    on<ClassMaterialsLoadMore>(_onClassMaterialsLoadMore);
    on<ClassMaterialsSearchChanged>(_onClassMaterialsSearchChanged);
    on<ClassMaterialsRefreshed>(_onClassMaterialsRefreshed);
    on<ClassMaterialAdded>(_onClassMaterialAdded);
    on<ClassMaterialDuplicateDismissed>(
      (event, emit) => emit(state.copyWith(clearPendingAdd: true)),
    );
    on<ClassMaterialCloned>(_onClassMaterialCloned);
    on<ClassMaterialsSelectionModeToggled>(_onSelectionModeToggled);
    on<ClassMaterialSelectionToggled>(_onSelectionToggled);
    on<ClassMaterialsSelectionCleared>(_onSelectionCleared);
    on<ClassMaterialsDeleted>(_onDeleted);
  }

  Future<void> _loadFirstPage(
    String classId,
    Emitter<ClassMaterialsState> emit, {
    required bool refreshing,
  }) async {
    try {
      final page = await repository.getMaterials(
        classId,
        page: 1,
        limit: pageSize,
        search: state.searchQuery,
      );
      emit(
        state.copyWith(
          status: ClassMaterialsStatus.success,
          items: page.items,
          // Phân trang theo `meta.pagination.hasMore` của BE (không đoán theo số phần tử).
          hasMore: page.hasMore,
          currentPage: 1,
          isRefreshing: false,
          isLoadingMore: false,
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          status: ClassMaterialsStatus.failure,
          errorMessage: ClassErrorMessages.of(f),
          isGone: ClassErrorMessages.isClassGone(f),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onClassMaterialsLoaded(
    ClassMaterialsLoaded event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(state.copyWith(status: ClassMaterialsStatus.loading, currentPage: 1, hasMore: false));
    await _loadFirstPage(event.classId, emit, refreshing: false);
  }

  Future<void> _onClassMaterialsLoadMore(
    ClassMaterialsLoadMore event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.status != ClassMaterialsStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final page = await repository.getMaterials(
        event.classId,
        page: nextPage,
        limit: pageSize,
        search: state.searchQuery,
      );
      final known = {for (final i in state.items) i.id};
      emit(
        state.copyWith(
          items: [...state.items, ...page.items.where((i) => !known.contains(i.id))],
          hasMore: page.hasMore,
          currentPage: nextPage,
          isLoadingMore: false,
        ),
      );
    } on Failure {
      // Tải thêm thất bại: giữ danh sách hiện tại, cho phép kéo tiếp để thử lại.
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onClassMaterialsSearchChanged(
    ClassMaterialsSearchChanged event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: event.query,
        status: ClassMaterialsStatus.loading,
        currentPage: 1,
        hasMore: false,
      ),
    );
    await _loadFirstPage(event.classId, emit, refreshing: false);
  }

  Future<void> _onClassMaterialsRefreshed(
    ClassMaterialsRefreshed event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, currentPage: 1, hasMore: false));
    await _loadFirstPage(event.classId, emit, refreshing: true);
  }

  String _addSummary(AddMaterialsResult r) {
    if (r.isNothingAdded) {
      return 'Không có học liệu mới nào được thêm (đều đã có trong lớp)';
    }
    final parts = [
      if (r.addedFolders.isNotEmpty) '${r.addedFolders.length} thư mục',
      if (r.addedDecks.isNotEmpty) '${r.addedDecks.length} bộ thẻ',
      if (r.mergedDecks > 0) 'gộp ${r.mergedDecks} bộ thẻ vào thư mục',
    ];
    final skipped = r.skipped.isEmpty ? '' : ' (bỏ qua ${r.skipped.length} mục trùng)';
    return 'Đã thêm ${parts.join(', ')}$skipped';
  }

  Future<void> _onClassMaterialAdded(
    ClassMaterialAdded event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    // Khóa thao tác trong lúc thêm (BE chạy một transaction, có thể chậm với folder lớn).
    if (state.isProcessing) return;
    emit(state.copyWith(isProcessing: true, clearPendingAdd: true));
    try {
      final response = await repository.addMaterials(
        event.classId,
        folderIds: event.folderIds,
        deckIds: event.deckIds,
        duplicatePolicy: event.duplicatePolicy,
      );
      final result = response.data;
      emit(
        state.copyWith(
          isProcessing: false,
          notice: result == null ? 'Đã thêm học liệu' : _addSummary(result),
        ),
      );
      add(ClassMaterialsLoaded(event.classId));
    } on Failure catch (f) {
      if (f.errorCode == AppErrorCodes.classMaterialDuplicate) {
        // BE không ghi gì; hỏi người dùng rồi gửi lại CÙNG body kèm `duplicatePolicy`.
        emit(
          state.copyWith(
            isProcessing: false,
            pendingAdd: PendingMaterialAdd(
              classId: event.classId,
              deckIds: event.deckIds,
              folderIds: event.folderIds,
              duplicates: DuplicateInfo.listFrom(f.params?['duplicates']),
            ),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isProcessing: false,
          notice: ClassErrorMessages.of(f),
          noticeIsError: true,
          isGone: ClassErrorMessages.isClassGone(f),
        ),
      );
    }
  }

  Future<void> _onClassMaterialCloned(
    ClassMaterialCloned event,
    Emitter<ClassMaterialsState> emit,
  ) async {
    if (state.isProcessing) return;
    emit(state.copyWith(isProcessing: true));
    try {
      await repository.cloneClassMaterials(
        event.classId,
        targetType: event.item.type,
        targetId: event.item.id,
      );
      emit(
        state.copyWith(
          isProcessing: false,
          notice: event.item.isFolder
              ? 'Đã sao chép thư mục về thư viện của bạn'
              : 'Đã sao chép bộ thẻ về thư viện của bạn',
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(isProcessing: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }

  void _onSelectionModeToggled(
    ClassMaterialsSelectionModeToggled event,
    Emitter<ClassMaterialsState> emit,
  ) {
    emit(
      state.copyWith(
        isSelectionMode: event.isSelectionMode ?? !state.isSelectionMode,
        selectedIds: const {},
      ),
    );
  }

  void _onSelectionToggled(ClassMaterialSelectionToggled event, Emitter<ClassMaterialsState> emit) {
    final next = Set<String>.from(state.selectedIds);
    if (!next.remove(event.id)) next.add(event.id);
    emit(state.copyWith(selectedIds: next));
  }

  void _onSelectionCleared(
    ClassMaterialsSelectionCleared event,
    Emitter<ClassMaterialsState> emit,
  ) {
    emit(state.copyWith(isSelectionMode: false, selectedIds: const {}));
  }

  Future<void> _onDeleted(ClassMaterialsDeleted event, Emitter<ClassMaterialsState> emit) async {
    final selected = state.selectedItems;
    if (selected.isEmpty || state.isProcessing) return;

    emit(state.copyWith(isProcessing: true));
    try {
      // Id phải là id BẢN SAO (đúng là `item.id` lấy từ GET /materials).
      final response = await repository.deleteMaterials(
        event.classId,
        folderIds: [
          for (final i in selected)
            if (i.isFolder) i.id,
        ],
        deckIds: [
          for (final i in selected)
            if (i.isDeck) i.id,
        ],
      );
      final removed = response.data;
      emit(
        state.copyWith(
          isProcessing: false,
          isSelectionMode: false,
          selectedIds: const {},
          notice: removed == null
              ? 'Đã gỡ học liệu khỏi lớp'
              : 'Đã gỡ ${removed.removedFolders} thư mục, ${removed.removedDecks} bộ thẻ khỏi lớp',
        ),
      );
      add(ClassMaterialsLoaded(event.classId));
    } on Failure catch (f) {
      // 409 CLASS_MATERIAL_IN_USE: đang là nguồn của bài giao -> xóa/đổi bài giao trước.
      emit(
        state.copyWith(isProcessing: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }
}
