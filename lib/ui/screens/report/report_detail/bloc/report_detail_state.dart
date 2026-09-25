import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/report_model.dart';

enum ReportDetailStatus { initial, loading, success, failure }

class ReportDetailState extends Equatable {
  final ReportDetailStatus status;
  final ReportModel? report;
  final String? errorMessage;

  const ReportDetailState({
    this.status = ReportDetailStatus.initial,
    this.report,
    this.errorMessage,
  });

  ReportDetailState copyWith({
    ReportDetailStatus? status,
    ReportModel? report,
    String? errorMessage,
  }) {
    return ReportDetailState(
      status: status ?? this.status,
      report: report ?? this.report,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, report, errorMessage];
}
