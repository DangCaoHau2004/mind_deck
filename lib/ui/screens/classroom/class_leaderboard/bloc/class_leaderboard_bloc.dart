import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_leaderboard_event.dart';
import 'class_leaderboard_state.dart';

class ClassLeaderboardBloc
    extends Bloc<ClassLeaderboardEvent, ClassLeaderboardState> {
  final ClassRepository repository;

  ClassLeaderboardBloc({required this.repository})
    : super(const ClassLeaderboardState()) {
    on<ClassLeaderboardLoaded>(_onLoaded);
    on<ClassLeaderboardRefreshed>(_onRefreshed);
  }

  Future<void> _onLoaded(
    ClassLeaderboardLoaded event,
    Emitter<ClassLeaderboardState> emit,
  ) async {
    emit(state.copyWith(status: ClassLeaderboardStatus.loading));
    try {
      final response = await repository.getLeaderboard(event.classId);
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: ClassLeaderboardStatus.success,
            leaderboard: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ClassLeaderboardStatus.failure,
            errorMessage: response.message ?? 'Không thể tải bảng xếp hạng',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassLeaderboardStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    ClassLeaderboardRefreshed event,
    Emitter<ClassLeaderboardState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final response = await repository.getLeaderboard(event.classId);
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: ClassLeaderboardStatus.success,
            leaderboard: response.data,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ClassLeaderboardStatus.failure,
            errorMessage: response.message ?? 'Không thể tải bảng xếp hạng',
            isRefreshing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ClassLeaderboardStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }
}
