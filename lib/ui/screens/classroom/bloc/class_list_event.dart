import 'package:equatable/equatable.dart';

abstract class ClassListEvent extends Equatable {
  const ClassListEvent();

  @override
  List<Object?> get props => [];
}

class ClassListLoaded extends ClassListEvent {}

class ClassJoined extends ClassListEvent {
  final String classId;
  final String joinCode;

  const ClassJoined({required this.classId, required this.joinCode});

  @override
  List<Object?> get props => [classId, joinCode];
}

class ClassCreated extends ClassListEvent {
  final String name;
  final String? description;
  final bool requireApproval;
  final bool isPublic;

  const ClassCreated({
    required this.name,
    this.description,
    this.requireApproval = false,
    this.isPublic = false,
  });

  @override
  List<Object?> get props => [name, description, requireApproval, isPublic];
}
