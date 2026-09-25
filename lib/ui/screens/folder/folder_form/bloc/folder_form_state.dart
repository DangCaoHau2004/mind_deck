import 'package:equatable/equatable.dart';

enum FolderFormStatus { initial, loading, success, failure }

class FolderFormState extends Equatable {
  final FolderFormStatus status;
  final String? errorMessage;
  final String? successMessage;

  const FolderFormState({
    this.status = FolderFormStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  FolderFormState copyWith({
    FolderFormStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return FolderFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage];
}
