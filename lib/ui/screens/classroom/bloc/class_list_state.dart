import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_model.dart';

enum ClassListStatus { initial, loading, success, failure }

class ClassListState extends Equatable {
  final ClassListStatus status;
  final List<ClassModel> classes;
  final String? errorMessage;

  // Trạng thái xử lý tham gia / tạo lớp
  final bool isProcessing;
  final String? processErrorMessage;
  final bool processSuccess;

  const ClassListState({
    this.status = ClassListStatus.initial,
    this.classes = const [],
    this.errorMessage,
    this.isProcessing = false,
    this.processErrorMessage,
    this.processSuccess = false,
  });

  ClassListState copyWith({
    ClassListStatus? status,
    List<ClassModel>? classes,
    String? errorMessage,
    bool? isProcessing,
    String? processErrorMessage,
    bool? processSuccess,
  }) {
    return ClassListState(
      status: status ?? this.status,
      classes: classes ?? this.classes,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      processErrorMessage: processErrorMessage,
      processSuccess: processSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
    status,
    classes,
    errorMessage,
    isProcessing,
    processErrorMessage,
    processSuccess,
  ];
}
