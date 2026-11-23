import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';
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
