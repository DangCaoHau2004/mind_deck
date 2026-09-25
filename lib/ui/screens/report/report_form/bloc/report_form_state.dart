import 'package:equatable/equatable.dart';

enum ReportFormStatus { initial, loading, success, failure }

class ReportFormState extends Equatable {
  final ReportFormStatus status;
  final String? errorMessage;
  final String? successMessage;

  const ReportFormState({
    this.status = ReportFormStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  ReportFormState copyWith({
    ReportFormStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return ReportFormState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage];
}
