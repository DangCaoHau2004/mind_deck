import 'package:equatable/equatable.dart';

abstract class TestHistoryDetailEvent extends Equatable {
  const TestHistoryDetailEvent();

  @override
  List<Object?> get props => [];
}

class TestHistoryDetailFetched extends TestHistoryDetailEvent {
  final String attemptId;

  const TestHistoryDetailFetched(this.attemptId);

  @override
  List<Object?> get props => [attemptId];
}
