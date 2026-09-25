import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_list_event.dart';
import 'class_list_state.dart';

class ClassListBloc extends Bloc<ClassListEvent, ClassListState> {
  final ClassRepository repository;

  ClassListBloc({required this.repository}) : super(const ClassListState()) {
    on<ClassListLoaded>(_onClassListLoaded);
    on<ClassJoined>(_onClassJoined);
    on<ClassCreated>(_onClassCreated);
  }

  Future<void> _onClassListLoaded(ClassListLoaded event, Emitter<ClassListState> emit) async {
    emit(state.copyWith(status: ClassListStatus.loading));
    try {
      final response = await repository.getClasses();
      if (response.success) {
        emit(state.copyWith(status: ClassListStatus.success, classes: response.data));
      } else {
        emit(state.copyWith(status: ClassListStatus.failure, errorMessage: response.message));
      }
    } catch (e) {
      emit(state.copyWith(status: ClassListStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onClassJoined(ClassJoined event, Emitter<ClassListState> emit) async {
    emit(state.copyWith(isProcessing: true, processSuccess: false, processErrorMessage: null));
    try {
      final response = await repository.joinClass(classId: event.classId, joinCode: event.joinCode);
      if (response.success) {
        emit(state.copyWith(isProcessing: false, processSuccess: true));
        add(ClassListLoaded()); // Reload list after joining
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Mã lớp không hợp lệ',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }

  Future<void> _onClassCreated(ClassCreated event, Emitter<ClassListState> emit) async {
    emit(state.copyWith(isProcessing: true, processSuccess: false, processErrorMessage: null));
    try {
      final response = await repository.createClass(
        name: event.name,
        description: event.description,
        requireApproval: event.requireApproval,
        isPublic: event.isPublic,
      );
      if (response.success) {
        emit(state.copyWith(isProcessing: false, processSuccess: true));
        add(ClassListLoaded()); // Reload list after creating
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            processErrorMessage: response.message ?? 'Không thể tạo lớp học',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, processErrorMessage: e.toString()));
    }
  }
}
