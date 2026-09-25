import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/test_attempt_detail_model.dart';

enum TestHistoryDetailStatus { initial, loading, success, failure }

class TestHistoryDetailState extends Equatable {
  final TestHistoryDetailStatus status;
  final TestAttemptDetailModel? detail;
  final String? errorMessage;

  const TestHistoryDetailState({
    this.status = TestHistoryDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  TestHistoryDetailState copyWith({
    TestHistoryDetailStatus? status,
    TestAttemptDetailModel? detail,
    String? errorMessage,
  }) {
    return TestHistoryDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, errorMessage];
}
