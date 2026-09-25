import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_assignments_event.dart';
import 'class_assignments_state.dart';

class ClassAssignmentsBloc
    extends Bloc<ClassAssignmentsEvent, ClassAssignmentsState> {
  final ClassRepository repository;

  ClassAssignmentsBloc({required this.repository})
    : super(const ClassAssignmentsState()) {
    on<ClassAssignmentsLoaded>(_onClassAssignmentsLoaded);
    on<ClassAssignmentCreated>(_onClassAssignmentCreated);
    on<ClassAssignmentUpdated>(_onClassAssignmentUpdated);
    on<ClassAssignmentDeleted>(_onClassAssignmentDeleted);
  }

  Future<void> _onClassAssignmentsLoaded(
    ClassAssignmentsLoaded event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    emit(state.copyWith(status: ClassAssignmentsStatus.loading));
    try {
      final responses = await Future.wait([
        repository.getAssignments(event.classId, tab: event.tab),
        repository.getMySubmissions(event.classId),
        repository.getOverdueAssignments(event.classId),
      ]);

      final activeResponse = responses[0] as dynamic; // ApiListResponse<ClassAssignmentModel>
      final submissionsResponse = responses[1] as dynamic; // ApiListResponse<ClassAssignmentSubmissionModel>
      final overdueResponse = responses[2] as dynamic; // ApiListResponse<ClassAssignmentSubmissionModel>

      if (activeResponse.success && activeResponse.data != null) {
        emit(
          state.copyWith(
            status: ClassAssignmentsStatus.success,
            assignments: activeResponse.data,
            mySubmissions: submissionsResponse.success ? submissionsResponse.data : [],
            overdueAssignments: overdueResponse.success ? overdueResponse.data : [],
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ClassAssignmentsStatus.failure,
            errorMessage: activeResponse.message ?? 'Không thể tải danh sách bài tập',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassAssignmentsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onClassAssignmentCreated(
    ClassAssignmentCreated event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.createAssignment(
        event.classId,
        title: event.title,
        description: event.description,
        type: event.type,
        deckId: event.deckId,
        testId: event.testId,
        deadline: event.deadline,
      );
      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        add(ClassAssignmentsLoaded(event.classId));
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể tạo bài tập',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(isProcessing: false, processErrorMessage: e.toString()),
      );
    }
  }

  Future<void> _onClassAssignmentUpdated(
    ClassAssignmentUpdated event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.updateAssignment(
        event.classId,
        event.assignmentId,
        title: event.title,
        description: event.description,
        deadline: event.deadline,
      );
      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        add(ClassAssignmentsLoaded(event.classId)); // Reload sau khi update
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage:
                response.message ?? 'Không thể cập nhật bài tập',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(isProcessing: false, processErrorMessage: e.toString()),
      );
    }
  }

  Future<void> _onClassAssignmentDeleted(
    ClassAssignmentDeleted event,
    Emitter<ClassAssignmentsState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, processErrorMessage: null));
    try {
      final response = await repository.deleteAssignment(
        event.classId,
        event.assignmentId,
      );
      if (response.success) {
        emit(state.copyWith(isProcessing: false));
        add(ClassAssignmentsLoaded(event.classId)); // Reload sau khi xóa
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể xóa bài tập',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(isProcessing: false, processErrorMessage: e.toString()),
      );
    }
  }
}
