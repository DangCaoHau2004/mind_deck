import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_analytics_event.dart';
import 'class_analytics_state.dart';

class ClassAnalyticsBloc
    extends Bloc<ClassAnalyticsEvent, ClassAnalyticsState> {
  final ClassRepository repository;

  ClassAnalyticsBloc({required this.repository})
    : super(const ClassAnalyticsState()) {
    on<ClassAnalyticsLoaded>(_onLoaded);
    on<ClassAnalyticsRefreshed>(_onRefreshed);
    on<ClassAnalyticsMemberSelected>(_onMemberSelected);
    on<ClassAnalyticsAssignmentSelected>(_onAssignmentSelected);
  }

  Future<void> _onLoaded(
    ClassAnalyticsLoaded event,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: ClassAnalyticsStatus.loading));
    await _fetchData(event.classId, emit);
  }

  Future<void> _onRefreshed(
    ClassAnalyticsRefreshed event,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _fetchData(event.classId, emit);
  }

  Future<void> _fetchData(
    String classId,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    try {
      // 1. Fetch initial basic lists (Members & Assignments)
      final membersResp = await repository.getMembers(classId);
      final assignmentsResp = await repository.getAssignments(
        classId,
        tab: 'active',
      );

      final members = membersResp.success ? membersResp.data : state.members;
      final assignments = assignmentsResp.success
          ? assignmentsResp.data
          : state.assignments;

      final selectedMember =
          state.selectedMember ?? (members.isNotEmpty ? members.first : null);
      final selectedAssignment =
          state.selectedAssignment ??
          (assignments.isNotEmpty ? assignments.first : null);

      // 2. Fetch class-wide analytics
      final classDeckHealthResp = await repository.getDeckHealth(classId);
      final classHardestCardsResp = await repository.getHardestCards(classId);

      final assignmentProgressResp = selectedAssignment != null
          ? await repository.getAssignmentProgress(
              classId,
              selectedAssignment.id,
            )
          : null;

      // 3. Fetch personal analytics (if selectedMember exists)
      final personalDeckHealthResp = selectedMember != null
          ? await repository.getDeckHealth(
              classId,
              studentId: selectedMember.userId,
            )
          : null;
      final personalHardestCardsResp = selectedMember != null
          ? await repository.getHardestCards(
              classId,
              studentId: selectedMember.userId,
            )
          : null;
      final personalReviewWorkloadResp = selectedMember != null
          ? await repository.getReviewWorkload(
              classId,
              studentId: selectedMember.userId,
            )
          : null;

      emit(
        state.copyWith(
          status: ClassAnalyticsStatus.success,
          isRefreshing: false,
          members: members,
          assignments: assignments,
          selectedMember: selectedMember,
          selectedAssignment: selectedAssignment,
          classDeckHealth: classDeckHealthResp.success
              ? classDeckHealthResp.data
              : [],
          classHardestCards: classHardestCardsResp.success
              ? classHardestCardsResp.data
              : [],
          assignmentProgress: assignmentProgressResp?.success == true
              ? assignmentProgressResp!.data
              : [],
          personalDeckHealth: personalDeckHealthResp?.success == true
              ? personalDeckHealthResp!.data
              : [],
          personalHardestCards: personalHardestCardsResp?.success == true
              ? personalHardestCardsResp!.data
              : [],
          personalReviewWorkload: personalReviewWorkloadResp?.success == true
              ? personalReviewWorkloadResp!.data
              : [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassAnalyticsStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onMemberSelected(
    ClassAnalyticsMemberSelected event,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedMember: event.member,
        status: ClassAnalyticsStatus.loading,
      ),
    );
    try {
      final personalDeckHealthResp = await repository.getDeckHealth(
        event.classId,
        studentId: event.member.userId,
      );
      final personalHardestCardsResp = await repository.getHardestCards(
        event.classId,
        studentId: event.member.userId,
      );
      final personalReviewWorkloadResp = await repository.getReviewWorkload(
        event.classId,
        studentId: event.member.userId,
      );

      emit(
        state.copyWith(
          status: ClassAnalyticsStatus.success,
          personalDeckHealth: personalDeckHealthResp.success
              ? personalDeckHealthResp.data
              : [],
          personalHardestCards: personalHardestCardsResp.success
              ? personalHardestCardsResp.data
              : [],
          personalReviewWorkload: personalReviewWorkloadResp.success
              ? personalReviewWorkloadResp.data
              : [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassAnalyticsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAssignmentSelected(
    ClassAnalyticsAssignmentSelected event,
    Emitter<ClassAnalyticsState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedAssignment: event.assignment,
        status: ClassAnalyticsStatus.loading,
      ),
    );
    try {
      final assignmentProgressResp = await repository.getAssignmentProgress(
        event.classId,
        event.assignment.id,
      );

      emit(
        state.copyWith(
          status: ClassAnalyticsStatus.success,
          assignmentProgress: assignmentProgressResp.success
              ? assignmentProgressResp.data
              : [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassAnalyticsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
