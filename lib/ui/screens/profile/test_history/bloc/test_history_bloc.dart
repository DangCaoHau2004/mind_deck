import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/ui/screens/profile/test_history/bloc/test_history_event.dart';
import 'package:mind_deck/ui/screens/profile/test_history/bloc/test_history_state.dart';

class TestHistoryBloc extends Bloc<TestHistoryEvent, TestHistoryState> {
  final TestRepository testRepository;

  TestHistoryBloc({required this.testRepository})
    : super(const TestHistoryState()) {
    on<TestHistoryFetched>(_onFetched);
    on<TestHistoryRefreshed>(_onRefreshed);
    on<TestHistoryFilterChanged>(_onFilterChanged);
  }

  Future<void> _onFilterChanged(
    TestHistoryFilterChanged event,
    Emitter<TestHistoryState> emit,
  ) async {
    final search = event.search ?? state.searchQuery;
    final questionType = event.questionTypes ?? state.selectedQuestionType;

    final newState = state.copyWith(
      status: TestHistoryStatus.loading,
      page: 1,
      hasReachedMax: false,
      selectedQuestionType:
          event.questionTypes != null && event.questionTypes!.isEmpty
          ? null
          : questionType,
      searchQuery: search,
    );

    emit(newState);

    try {
      final response = await testRepository.getHistoryTests(
        page: 1,
        limit: 15,
        questionTypes: event.questionTypes,
      );
      if (response.success && response.data != null) {
        final items = response.data!;
        emit(
          state.copyWith(
            status: TestHistoryStatus.success,
            history: items,
            hasReachedMax: items.length < 15,
            page: 2,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: TestHistoryStatus.failure,
            errorMessage: response.message ?? 'Lỗi khi tải lịch sử',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TestHistoryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFetched(
    TestHistoryFetched event,
    Emitter<TestHistoryState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      if (state.status == TestHistoryStatus.initial) {
        emit(state.copyWith(status: TestHistoryStatus.loading));
        final response = await testRepository.getHistoryTests(
          page: 1,
          limit: 15,
          questionTypes: state.selectedQuestionType,
        );
        if (response.success && response.data != null) {
          final items = response.data!;
          emit(
            state.copyWith(
              status: TestHistoryStatus.success,
              history: items,
              hasReachedMax: items.length < 15,
              page: 2,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: TestHistoryStatus.failure,
              errorMessage: response.message ?? 'Lỗi khi tải lịch sử',
            ),
          );
        }
        return;
      }

      final response = await testRepository.getHistoryTests(
        page: state.page,
        limit: 15,
        questionTypes: state.selectedQuestionType,
      );
      if (response.success && response.data != null) {
        final items = response.data!;
        emit(
          items.isEmpty
              ? state.copyWith(hasReachedMax: true)
              : state.copyWith(
                  status: TestHistoryStatus.success,
                  history: List.of(state.history)..addAll(items),
                  hasReachedMax: items.length < 15,
                  page: state.page + 1,
                ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TestHistoryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    TestHistoryRefreshed event,
    Emitter<TestHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TestHistoryStatus.loading,
        page: 1,
        hasReachedMax: false,
      ),
    );
    try {
      final response = await testRepository.getHistoryTests(
        page: 1,
        limit: 15,
        questionTypes: state.selectedQuestionType,
      );
      if (response.success && response.data != null) {
        final items = response.data!;
        emit(
          state.copyWith(
            status: TestHistoryStatus.success,
            history: items,
            hasReachedMax: items.length < 15,
            page: 2,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: TestHistoryStatus.failure,
            errorMessage: response.message ?? 'Lỗi khi làm mới lịch sử',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TestHistoryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
