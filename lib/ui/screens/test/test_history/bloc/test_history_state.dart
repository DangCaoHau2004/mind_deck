import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/test_attempt_model.dart';

enum TestHistoryStatus { initial, loading, success, failure }

class TestHistoryState extends Equatable {
  final TestHistoryStatus status;
  final List<TestAttemptModel> historyAttempts;
  final String? errorMessage;

  const TestHistoryState({
    this.status = TestHistoryStatus.initial,
    this.historyAttempts = const [],
    this.errorMessage,
  });

  TestHistoryState copyWith({
    TestHistoryStatus? status,
    List<TestAttemptModel>? historyAttempts,
    String? errorMessage,
  }) {
    return TestHistoryState(
      status: status ?? this.status,
      historyAttempts: historyAttempts ?? this.historyAttempts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, historyAttempts, errorMessage];
}
