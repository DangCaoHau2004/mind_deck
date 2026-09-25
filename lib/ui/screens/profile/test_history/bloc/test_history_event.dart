import 'package:equatable/equatable.dart';

abstract class TestHistoryEvent extends Equatable {
  const TestHistoryEvent();

  @override
  List<Object?> get props => [];
}

class TestHistoryFetched extends TestHistoryEvent {}

class TestHistoryRefreshed extends TestHistoryEvent {}

class TestHistoryFilterChanged extends TestHistoryEvent {
  final String? questionTypes;
  final String? search;

  const TestHistoryFilterChanged({this.questionTypes, this.search});

  @override
  List<Object?> get props => [questionTypes, search];
}
