import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/test_attempt_model.dart';

enum TestHistoryStatus { initial, loading, success, failure }

class TestHistoryState extends Equatable {
  final TestHistoryStatus status;
  final List<TestAttemptModel> history;
  final String? errorMessage;
  final bool hasReachedMax;
  final int page;
  final String? selectedQuestionType;
  final String? searchQuery;

  const TestHistoryState({
    this.status = TestHistoryStatus.initial,
    this.history = const [],
    this.errorMessage,
    this.hasReachedMax = false,
    this.page = 1,
    this.selectedQuestionType,
    this.searchQuery,
  });

  TestHistoryState copyWith({
    TestHistoryStatus? status,
    List<TestAttemptModel>? history,
    String? errorMessage,
    bool? hasReachedMax,
    int? page,
    String? selectedQuestionType,
    String? searchQuery,
  }) {
    return TestHistoryState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      selectedQuestionType: selectedQuestionType ?? this.selectedQuestionType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  TestHistoryState clearFilter() {
    return TestHistoryState(
      status: status,
      history: history,
      errorMessage: errorMessage,
      hasReachedMax: hasReachedMax,
      page: page,
      selectedQuestionType: null,
      searchQuery: null,
    );
  }

  @override
  List<Object?> get props => [
    status,
    history,
    errorMessage,
    hasReachedMax,
    page,
    selectedQuestionType,
    searchQuery,
  ];
}
