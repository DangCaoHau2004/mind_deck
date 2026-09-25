import 'package:equatable/equatable.dart';

abstract class ReportHistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportHistoryLoaded extends ReportHistoryEvent {
  final int page;
  final int limit;
  ReportHistoryLoaded({this.page = 1, this.limit = 50});
}

class ReportHistoryRefreshed extends ReportHistoryEvent {}
