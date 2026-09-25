import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';

abstract class ClassAssignmentsEvent extends Equatable {
  const ClassAssignmentsEvent();

  @override
  List<Object?> get props => [];
}

class ClassAssignmentsLoaded extends ClassAssignmentsEvent {
  final String classId;
  final String tab; // 'active' or 'past'

  const ClassAssignmentsLoaded(this.classId, {this.tab = 'active'});

  @override
  List<Object?> get props => [classId, tab];
}

class ClassAssignmentCreated extends ClassAssignmentsEvent {
  final String classId;
  final String title;
  final String? description;
  final AssignmentType type;
  final String? deckId;
  final String? testId;
  final String deadline;

  const ClassAssignmentCreated({
    required this.classId,
    required this.title,
    this.description,
    required this.type,
    this.deckId,
    this.testId,
    required this.deadline,
  });

  @override
  List<Object?> get props => [classId, title, description, type, deckId, testId, deadline];
}

class ClassAssignmentUpdated extends ClassAssignmentsEvent {
  final String classId;
  final String assignmentId;
  final String title;
  final String? description;
  final String deadline;

  const ClassAssignmentUpdated({
    required this.classId,
    required this.assignmentId,
    required this.title,
    this.description,
    required this.deadline,
  });

  @override
  List<Object?> get props => [classId, assignmentId, title, description, deadline];
}

class ClassAssignmentDeleted extends ClassAssignmentsEvent {
  final String classId;
  final String assignmentId;

  const ClassAssignmentDeleted({required this.classId, required this.assignmentId});

  @override
  List<Object?> get props => [classId, assignmentId];
}
