import 'package:equatable/equatable.dart';

enum ClassSettingsStatus { initial, loading, success, failure }

class ClassSettingsState extends Equatable {
  final ClassSettingsStatus status;
  final String? errorMessage;

  const ClassSettingsState({
    this.status = ClassSettingsStatus.initial,
    this.errorMessage,
  });

  ClassSettingsState copyWith({
    ClassSettingsStatus? status,
    String? errorMessage,
  }) {
    return ClassSettingsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
