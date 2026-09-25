import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'class_hub_event.dart';
import 'class_hub_state.dart';

class ClassHubBloc extends Bloc<ClassHubEvent, ClassHubState> {
  final ClassRepository repository;
  final String classId;

  ClassHubBloc({required this.repository, required this.classId, ClassModel? initialClass})
    : super(ClassHubState(classModel: initialClass)) {
    on<ClassHubLoaded>(_onClassHubLoaded);
  }

  Future<void> _onClassHubLoaded(ClassHubLoaded event, Emitter<ClassHubState> emit) async {
    emit(state.copyWith(status: ClassHubStatus.loading));
    try {
      ClassModel? currentClass = state.classModel;

      final res = await repository.getClassById(classId);
      if (res.success && res.data != null) {
        currentClass = res.data;
      }

      if (currentClass == null) {
        emit(
          state.copyWith(
            status: ClassHubStatus.failure,
            errorMessage: res.message ?? "Không tìm thấy thông tin lớp học",
          ),
        );
        return;
      }

      int pendingCount = 0;
      if (currentClass.isOwner ||
          currentClass.myRole == 'admin' ||
          currentClass.myRole == 'tutor') {
        final pendingRes = await repository.getPendingMembers(currentClass.id);
        if (pendingRes.success) {
          pendingCount = pendingRes.data.length;
        }
      }

      int totalScore = 0;
      int rank = 0;
      if (!currentClass.isOwner && currentClass.myRole == 'student') {
        // Fetch personal stats from leaderboard if needed, mock for now
        totalScore = 12500;
        rank = 4;
      }

      emit(
        state.copyWith(
          status: ClassHubStatus.success,
          classModel: currentClass,
          pendingCount: pendingCount,
          totalScore: totalScore,
          rank: rank,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ClassHubStatus.failure, errorMessage: e.toString()));
    }
  }
}
