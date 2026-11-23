import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_analytics_event.dart';
import 'class_analytics_state.dart';

/// Số liệu cá nhân của một học viên (hoặc của chính mình khi là học viên).
class _PersonalData {
  final DeckHealthResponse? health;
  final List<HardestCardModel> hardest;
  final List<ReviewWorkloadModel> workload;
  final List<StudentAssignmentResult> assignments;

  const _PersonalData({
    this.health,
    this.hardest = const [],
    this.workload = const [],
    this.assignments = const [],
  });
}

class ClassAnalyticsBloc extends Bloc<ClassAnalyticsEvent, ClassAnalyticsState> {
  final ClassRepository repository;

  ClassAnalyticsBloc({required this.repository}) : super(const ClassAnalyticsState()) {
    on<ClassAnalyticsLoaded>(_onLoaded);
    on<ClassAnalyticsRefreshed>(_onRefreshed);
    on<ClassAnalyticsMemberSelected>(_onMemberSelected);
    on<ClassAnalyticsAssignmentSelected>(_onAssignmentSelected);
  }

  /// Chạy một lời gọi API; lỗi được ghi lại thay vì làm hỏng cả màn hình.
  Future<T?> _safe<T>(Future<T> Function() call, List<Failure> errors) async {
    try {
      return await call();
    } on Failure catch (f) {
      errors.add(f);
      return null;
    }
  }

  Future<void> _onLoaded(ClassAnalyticsLoaded event, Emitter<ClassAnalyticsState> emit) async {
    emit(state.copyWith(status: ClassAnalyticsStatus.loading, isTeacher: event.isTeacher));
    await _fetchData(event.classId, emit, isTeacher: event.isTeacher);
  }

  Future<void> _onRefreshed(
    ClassAnalyticsRefreshed event,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _fetchData(event.classId, emit, isTeacher: state.isTeacher);
  }

  Future<_PersonalData> _loadPersonal(
    String classId, {
    required String? studentId,
    required bool isTeacher,
    required List<Failure> errors,
  }) async {
    final results = await (
      _safe(() => repository.getDeckHealth(classId, studentId: studentId), errors),
      _safe(() => repository.getHardestCards(classId, studentId: studentId), errors),
      _safe(() => repository.getReviewWorkload(classId, studentId: studentId), errors),
      // Kết quả theo từng bài giao của một học viên: API dành cho giảng viên.
      isTeacher && studentId != null
          ? _safe(() => repository.getStudentAssignments(classId, studentId), errors)
          : Future<ApiListResponse<StudentAssignmentResult>?>.value(null),
    ).wait;

    return _PersonalData(
      health: results.$1?.data,
      hardest: results.$2?.data ?? const [],
      workload: results.$3 == null ? const [] : ReviewWorkloadModel.fillNext7Days(results.$3!.data),
      assignments: results.$4?.data ?? const [],
    );
  }

  Future<void> _fetchData(
    String classId,
    Emitter<ClassAnalyticsState> emit, {
    required bool isTeacher,
  }) async {
    final errors = <Failure>[];

    var members = state.members;
    var assignments = state.assignments;
    ClassMemberModel? selectedMember = state.selectedMember;
    ClassAssignmentModel? selectedAssignment = state.selectedAssignment;

    if (isTeacher) {
      // 1. Danh sách thành viên + bài giao (đang chạy/chưa kết thúc rồi đến đã kết thúc).
      final lists = await (
        _safe(() => repository.getMembers(classId), errors),
        _safe(() => repository.getAssignments(classId, tab: 'active'), errors),
        _safe(() => repository.getAssignments(classId, tab: 'history'), errors),
      ).wait;

      members = lists.$1?.data ?? members;
      final merged = <String, ClassAssignmentModel>{
        for (final a in [...?lists.$2?.data, ...?lists.$3?.data]) a.id: a,
      };
      if (merged.isNotEmpty) assignments = merged.values.toList();

      // Mặc định phân tích một học viên (nếu có), nếu không thì người đầu tiên.
      bool stillThere(ClassMemberModel? m) => m != null && members.any((x) => x.userId == m.userId);
      if (!stillThere(selectedMember)) {
        selectedMember = members.isEmpty
            ? null
            : members.firstWhere((m) => m.role == ClassRole.student, orElse: () => members.first);
      }
      final keep = selectedAssignment == null
          ? null
          : assignments.where((a) => a.id == selectedAssignment!.id).firstOrNull;
      selectedAssignment = keep ?? (assignments.isNotEmpty ? assignments.first : null);
    }

    // 2. Số liệu toàn lớp (giảng viên) và cá nhân.
    final isTest = selectedAssignment?.type == AssignmentType.gradedTest;
    final overview = await (
      isTeacher
          ? _safe(() => repository.getDeckHealth(classId), errors)
          : Future<ApiResponse<DeckHealthResponse>?>.value(null),
      isTeacher
          ? _safe(() => repository.getHardestCards(classId), errors)
          : Future<ApiListResponse<HardestCardModel>?>.value(null),
      isTeacher && selectedAssignment != null
          ? _safe(() => repository.getAssignmentProgress(classId, selectedAssignment!.id), errors)
          : Future<ApiListResponse<AssignmentProgressModel>?>.value(null),
      isTeacher && selectedAssignment != null && isTest
          ? _safe(() => repository.getScoreDistribution(classId, selectedAssignment!.id), errors)
          : Future<ApiResponse<ScoreDistribution>?>.value(null),
      _loadPersonal(
        classId,
        studentId: isTeacher ? selectedMember?.userId : null,
        // Giảng viên bắt buộc có học viên được chọn (BE trả 400 nếu thiếu `student_id`).
        isTeacher: isTeacher,
        errors: errors,
      ),
    ).wait;

    final personal = overview.$5;
    final hasAnyData =
        overview.$1?.data != null ||
        overview.$2 != null ||
        personal.health != null ||
        personal.hardest.isNotEmpty ||
        personal.workload.isNotEmpty ||
        members.isNotEmpty;

    if (errors.isNotEmpty && !hasAnyData) {
      emit(
        state.copyWith(
          status: ClassAnalyticsStatus.failure,
          errorMessage: ClassErrorMessages.of(errors.first),
          isRefreshing: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ClassAnalyticsStatus.success,
        isRefreshing: false,
        members: members,
        assignments: assignments,
        selectedMember: selectedMember,
        selectedAssignment: selectedAssignment,
        classDeckHealth: overview.$1?.data,
        classHardestCards: overview.$2?.data ?? const [],
        assignmentProgress: overview.$3?.data ?? const [],
        scoreDistribution: overview.$4?.data,
        clearScoreDistribution: overview.$4?.data == null,
        personalDeckHealth: personal.health,
        personalHardestCards: personal.hardest,
        personalReviewWorkload: personal.workload,
        personalAssignments: personal.assignments,
      ),
    );
  }

  Future<void> _onMemberSelected(
    ClassAnalyticsMemberSelected event,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    emit(state.copyWith(selectedMember: event.member, status: ClassAnalyticsStatus.loading));
    final errors = <Failure>[];
    final personal = await _loadPersonal(
      event.classId,
      studentId: event.member.userId,
      isTeacher: state.isTeacher,
      errors: errors,
    );

    emit(
      state.copyWith(
        status: ClassAnalyticsStatus.success,
        errorMessage: errors.isEmpty ? null : ClassErrorMessages.of(errors.first),
        personalDeckHealth: personal.health,
        personalHardestCards: personal.hardest,
        personalReviewWorkload: personal.workload,
        personalAssignments: personal.assignments,
      ),
    );
  }

  Future<void> _onAssignmentSelected(
    ClassAnalyticsAssignmentSelected event,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedAssignment: event.assignment,
        clearScoreDistribution: true,
        status: ClassAnalyticsStatus.loading,
      ),
    );
    final errors = <Failure>[];
    final isTest = event.assignment.type == AssignmentType.gradedTest;
    final results = await (
      _safe(() => repository.getAssignmentProgress(event.classId, event.assignment.id), errors),
      isTest
          ? _safe(() => repository.getScoreDistribution(event.classId, event.assignment.id), errors)
          : Future<ApiResponse<ScoreDistribution>?>.value(null),
    ).wait;

    emit(
      state.copyWith(
        status: ClassAnalyticsStatus.success,
        errorMessage: errors.isEmpty ? null : ClassErrorMessages.of(errors.first),
        assignmentProgress: results.$1?.data ?? const [],
        scoreDistribution: results.$2?.data,
        clearScoreDistribution: results.$2?.data == null,
      ),
    );
  }
}
