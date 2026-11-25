import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';
import 'package:mind_deck/data/models/page_info.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_assignments_event.dart';
import 'class_assignments_state.dart';

class ClassAssignmentsBloc extends Bloc<ClassAssignmentsEvent, ClassAssignmentsState> {
  final ClassRepository repository;

  ClassAssignmentsBloc({required this.repository}) : super(const ClassAssignmentsState()) {
    on<ClassAssignmentsLoaded>(_onClassAssignmentsLoaded);
    on<ClassAssignmentCreated>(_onClassAssignmentCreated);
    on<ClassAssignmentUpdated>(_onClassAssignmentUpdated);
    on<ClassAssignmentDeleted>(_onClassAssignmentDeleted);
    on<ClassAssignmentsMoreLoaded>(_onMoreLoaded);
  }

  PageInfo _pageOf(AssignmentListKind kind) => switch (kind) {
    AssignmentListKind.active => state.activePage,
    AssignmentListKind.history => state.historyPage,
    AssignmentListKind.overdue => state.overduePage,
  };

  ClassAssignmentsState _withPage(AssignmentListKind kind, PageInfo info) => switch (kind) {
    AssignmentListKind.active => state.copyWith(activePage: info),
    AssignmentListKind.history => state.copyWith(historyPage: info),
    AssignmentListKind.overdue => state.copyWith(overduePage: info),
  };

  /// Tải trang kế tiếp của một danh sách (nối vào cuối, bỏ dòng trùng vì danh sách có thể dịch chuyển).
  Future<void> _onMoreLoaded(
    ClassAssignmentsMoreLoaded event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    final kind = event.kind;
    final info = _pageOf(kind);
    if (state.status != ClassAssignmentsStatus.success || !info.canLoadMore) return;
    emit(_withPage(kind, info.copyWith(isLoadingMore: true)));
    try {
      final page = info.page + 1;
      switch (kind) {
        case AssignmentListKind.active:
        case AssignmentListKind.history:
          final res = await repository.getAssignments(event.classId, tab: kind.name, page: page);
          final current = kind == AssignmentListKind.active ? state.active : state.history;
          final known = {for (final a in current) a.id};
          final merged = [...current, ...res.data.where((a) => !known.contains(a.id))];
          final next = PageInfo.loaded(page: page, loaded: res.data.length, limit: classPageSize);
          emit(
            kind == AssignmentListKind.active
                ? state.copyWith(active: merged, activePage: next)
                : state.copyWith(history: merged, historyPage: next),
          );
        case AssignmentListKind.overdue:
          final res = await repository.getOverdueAssignments(event.classId, page: page);
          final known = {for (final a in state.overdue) a.assignmentId};
          emit(
            state.copyWith(
              overdue: [
                ...state.overdue,
                ...res.data.where((a) => !known.contains(a.assignmentId)),
              ],
              overduePage: PageInfo.loaded(
                page: page,
                loaded: res.data.length,
                limit: classPageSize,
              ),
            ),
          );
      }
    } on Failure catch (f) {
      emit(
        _withPage(
          kind,
          info.copyWith(isLoadingMore: false),
        ).copyWith(notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }

  Future<void> _onClassAssignmentsLoaded(
    ClassAssignmentsLoaded event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    emit(state.copyWith(status: ClassAssignmentsStatus.loading, isTeacher: event.isTeacher));
    try {
      // Giảng viên không gọi `overdue` (luôn rỗng). Học viên cần thêm danh sách quá hạn.
      final results = await (
        repository.getAssignments(event.classId, tab: 'active'),
        repository.getAssignments(event.classId, tab: 'history'),
        event.isTeacher
            ? Future<ApiListResponse<ClassAssignmentSubmissionModel>?>.value(null)
            : repository
                  .getOverdueAssignments(event.classId)
                  .then<ApiListResponse<ClassAssignmentSubmissionModel>?>((r) => r)
                  .catchError((_) => null),
      ).wait;

      emit(
        state.copyWith(
          status: ClassAssignmentsStatus.success,
          active: results.$1.data,
          history: results.$2.data,
          overdue: results.$3?.data ?? const [],
          activePage: PageInfo.loaded(
            page: 1,
            loaded: results.$1.data.length,
            limit: classPageSize,
          ),
          historyPage: PageInfo.loaded(
            page: 1,
            loaded: results.$2.data.length,
            limit: classPageSize,
          ),
          overduePage: PageInfo.loaded(
            page: 1,
            loaded: results.$3?.data.length ?? 0,
            limit: classPageSize,
          ),
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          status: ClassAssignmentsStatus.failure,
          errorMessage: ClassErrorMessages.of(f),
        ),
      );
    }
  }

  Future<void> _onClassAssignmentCreated(
    ClassAssignmentCreated event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    if (state.isProcessing) return;
    emit(state.copyWith(isProcessing: true));
    final d = event.draft;
    try {
      await repository.createAssignment(
        event.classId,
        title: d.title,
        description: d.description,
        type: d.type,
        startAt: d.startAt,
        endAt: d.endAt,
        mode: d.mode,
        scope: d.scope,
        targetCount: d.targetCount,
        sources: d.type == AssignmentType.studyMission ? d.sources : null,
        testId: d.testId,
      );
      emit(
        state.copyWith(
          isProcessing: false,
          saved: true,
          notice: d.startAt != null && d.startAt!.isAfter(DateTime.now())
              ? 'Đã hẹn giờ giao bài'
              : 'Đã giao bài tập',
        ),
      );
      // `phase` trong response luôn là "scheduled": tải lại danh sách để có trạng thái thật.
      add(ClassAssignmentsLoaded(event.classId, isTeacher: state.isTeacher));
    } on Failure catch (f) {
      emit(state.copyWith(isProcessing: false, formError: ClassErrorMessages.of(f)));
    }
  }

  Future<void> _onClassAssignmentUpdated(
    ClassAssignmentUpdated event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    if (state.isProcessing) return;
    emit(state.copyWith(isProcessing: true));
    final d = event.draft;
    try {
      await repository.updateAssignment(
        event.classId,
        event.assignmentId,
        title: d.title,
        description: d.description,
        startAt: d.startAt,
        endAt: d.endAt,
        mode: d.mode,
        scope: d.scope,
        targetCount: d.targetCount,
        sources: d.type == AssignmentType.studyMission ? d.sources : null,
        testId: d.testId,
      );
      emit(state.copyWith(isProcessing: false, saved: true, notice: 'Đã lưu thay đổi'));
      add(ClassAssignmentsLoaded(event.classId, isTeacher: state.isTeacher));
    } on Failure catch (f) {
      // 403 CLASS_ASSIGNMENT_LOCKED: bài đã có hoạt động nên không đổi được nội dung / giờ bắt đầu.
      emit(state.copyWith(isProcessing: false, formError: ClassErrorMessages.of(f)));
    }
  }

  Future<void> _onClassAssignmentDeleted(
    ClassAssignmentDeleted event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    if (state.isProcessing) return;
    emit(state.copyWith(isProcessing: true));
    try {
      await repository.deleteAssignment(event.classId, event.assignmentId);
      emit(state.copyWith(isProcessing: false, notice: 'Đã xóa bài tập'));
      add(ClassAssignmentsLoaded(event.classId, isTeacher: state.isTeacher));
    } on Failure catch (f) {
      emit(
        state.copyWith(isProcessing: false, notice: ClassErrorMessages.of(f), noticeIsError: true),
      );
    }
  }
}
