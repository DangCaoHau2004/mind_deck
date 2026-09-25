import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/bloc/test_history_detail_event.dart';
import 'package:mind_deck/ui/screens/profile/test_history_detail/bloc/test_history_detail_state.dart';

class TestHistoryDetailBloc
    extends Bloc<TestHistoryDetailEvent, TestHistoryDetailState> {
  final TestRepository testRepository;

  TestHistoryDetailBloc({required this.testRepository})
    : super(const TestHistoryDetailState()) {
    on<TestHistoryDetailFetched>(_onFetched);
  }

  Future<void> _onFetched(
    TestHistoryDetailFetched event,
    Emitter<TestHistoryDetailState> emit,
  ) async {
    emit(state.copyWith(status: TestHistoryDetailStatus.loading));
    try {
      final response = await testRepository.getTestAttemptDetail(
        event.attemptId,
      );
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: TestHistoryDetailStatus.success,
            detail: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: TestHistoryDetailStatus.failure,
            errorMessage: response.message ?? 'Lỗi khi tải chi tiết lịch sử',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TestHistoryDetailStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
