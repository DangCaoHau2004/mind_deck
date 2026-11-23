import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_leaderboard_response_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'class_leaderboard_event.dart';
import 'class_leaderboard_state.dart';

class ClassLeaderboardBloc extends Bloc<ClassLeaderboardEvent, ClassLeaderboardState> {
  final ClassRepository repository;

  /// Số dòng tối đa BE cho phép (kẹp [1, 50]).
  static const int pageLimit = 50;

  ClassLeaderboardBloc({required this.repository}) : super(const ClassLeaderboardState()) {
    on<ClassLeaderboardLoaded>(_onLoaded);
    on<ClassLeaderboardRefreshed>(_onRefreshed);
    on<ClassLeaderboardMonthChanged>(_onMonthChanged);
  }

  Future<void> _fetch(String classId, Emitter<ClassLeaderboardState> emit, {String? month}) async {
    try {
      final response = await repository.getLeaderboard(classId, month: month, limit: pageLimit);
      final board = response.data;
      if (response.success && board != null) {
        emit(
          state.copyWith(
            status: ClassLeaderboardStatus.success,
            leaderboard: board,
            isRefreshing: false,
            isDisabled: false,
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
    } on Failure catch (f) {
      // Tháng không hợp lệ thường do lỗi client: quay về tháng hiện tại (chỉ thử lại một lần).
      if (f.errorCode == AppErrorCodes.analyticsLeaderboardMonthInvalid && month != null) {
        emit(state.copyWith(clearSelectedMonth: true, clearLeaderboard: true));
        await _fetch(classId, emit);
        return;
      }
      emit(
        state.copyWith(
          status: ClassLeaderboardStatus.failure,
          errorMessage: ClassErrorMessages.of(f),
          isRefreshing: false,
          isDisabled: f.errorCode == AppErrorCodes.classLeaderboardDisabled,
        ),
      );
    }
  }

  Future<void> _onLoaded(ClassLeaderboardLoaded event, Emitter<ClassLeaderboardState> emit) async {
    emit(state.copyWith(status: ClassLeaderboardStatus.loading, isDisabled: false));
    await _fetch(event.classId, emit, month: state.selectedMonth);
  }

  Future<void> _onRefreshed(
    ClassLeaderboardRefreshed event,
    Emitter<ClassLeaderboardState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _fetch(event.classId, emit, month: state.selectedMonth);
  }

  Future<void> _onMonthChanged(
    ClassLeaderboardMonthChanged event,
    Emitter<ClassLeaderboardState> emit,
  ) async {
    // Chọn đúng tháng hiện tại thì coi như "Tháng này" (không gửi `month`).
    final month = event.month == LeaderboardMonth.current() ? null : event.month;
    if (month == state.selectedMonth && state.status == ClassLeaderboardStatus.success) return;
    emit(
      state.copyWith(
        selectedMonth: month,
        clearSelectedMonth: month == null,
        status: ClassLeaderboardStatus.loading,
        clearLeaderboard: true,
        isDisabled: false,
      ),
    );
    await _fetch(event.classId, emit, month: month);
  }
}
