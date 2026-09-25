import 'package:equatable/equatable.dart';

abstract class ReportDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportDetailLoaded extends ReportDetailEvent {
  final String reportId;
  ReportDetailLoaded({required this.reportId});

  @override
  List<Object?> get props => [reportId];
}
