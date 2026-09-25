import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/report_model.dart';

enum ReportHistoryStatus { initial, loading, success, failure }

class ReportHistoryState extends Equatable {
  final ReportHistoryStatus status;
  final List<ReportModel> reports;
  final String? errorMessage;
  final bool isRefreshing;

  const ReportHistoryState({
    this.status = ReportHistoryStatus.initial,
    this.reports = const [],
    this.errorMessage,
    this.isRefreshing = false,
  });

  ReportHistoryState copyWith({
    ReportHistoryStatus? status,
    List<ReportModel>? reports,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return ReportHistoryState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, reports, errorMessage, isRefreshing];
}
