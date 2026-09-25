import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';

enum ClassAssignmentsStatus { initial, loading, success, failure }

class ClassAssignmentsState extends Equatable {
  final ClassAssignmentsStatus status;
  final List<ClassAssignmentModel> assignments;
  final List<ClassAssignmentSubmissionModel> mySubmissions;
  final List<ClassAssignmentSubmissionModel> overdueAssignments;
  final String? errorMessage;

  final bool isProcessing;
  final String? processErrorMessage;

  const ClassAssignmentsState({
    this.status = ClassAssignmentsStatus.initial,
    this.assignments = const [],
    this.mySubmissions = const [],
    this.overdueAssignments = const [],
    this.errorMessage,
    this.isProcessing = false,
    this.processErrorMessage,
  });

  ClassAssignmentsState copyWith({
    ClassAssignmentsStatus? status,
    List<ClassAssignmentModel>? assignments,
    List<ClassAssignmentSubmissionModel>? mySubmissions,
    List<ClassAssignmentSubmissionModel>? overdueAssignments,
    String? errorMessage,
    bool? isProcessing,
    String? processErrorMessage,
  }) {
    return ClassAssignmentsState(
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      mySubmissions: mySubmissions ?? this.mySubmissions,
      overdueAssignments: overdueAssignments ?? this.overdueAssignments,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      processErrorMessage: processErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    assignments,
    mySubmissions,
    overdueAssignments,
    errorMessage,
    isProcessing,
    processErrorMessage,
  ];
}
