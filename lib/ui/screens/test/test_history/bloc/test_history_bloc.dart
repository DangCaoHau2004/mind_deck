import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'test_history_event.dart';
import 'test_history_state.dart';

class TestHistoryBloc extends Bloc<TestHistoryEvent, TestHistoryState> {
  final TestRepository testRepository;

  TestHistoryBloc({required this.testRepository})
    : super(const TestHistoryState()) {
    on<TestHistoryInitialized>(_onInitialized);
    on<TestHistoryRefreshed>(_onRefreshed);
  }

  Future<void> _onInitialized(
    TestHistoryInitialized event,
    Emitter<TestHistoryState> emit,
  ) async {
    emit(state.copyWith(status: TestHistoryStatus.loading));
    try {
      final response = await testRepository.getHistoryTests();
      emit(
        state.copyWith(
          status: TestHistoryStatus.success,
          historyAttempts: response.data,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TestHistoryStatus.failure,
          errorMessage: 'Lỗi tải lịch sử: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    TestHistoryRefreshed event,
    Emitter<TestHistoryState> emit,
  ) async {
    try {
      final response = await testRepository.getHistoryTests();
      emit(
        state.copyWith(
          status: TestHistoryStatus.success,
          historyAttempts: response.data,
        ),
      );
    } catch (_) {}
  }
}
