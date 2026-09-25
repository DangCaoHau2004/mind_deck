import 'package:equatable/equatable.dart';

abstract class TestHistoryEvent extends Equatable {
  const TestHistoryEvent();

  @override
  List<Object?> get props => [];
}

class TestHistoryInitialized extends TestHistoryEvent {
  const TestHistoryInitialized();
}

class TestHistoryRefreshed extends TestHistoryEvent {
  const TestHistoryRefreshed();
}
