import 'package:equatable/equatable.dart';

abstract class ClassSettingsEvent extends Equatable {
  const ClassSettingsEvent();

  @override
  List<Object?> get props => [];
}

class UpdateClassRequested extends ClassSettingsEvent {
  final String classId;
  final String name;
  final String? description;
  final bool isPublic;
  final bool requireApproval;

  const UpdateClassRequested({
    required this.classId,
    required this.name,
    this.description,
    required this.isPublic,
    required this.requireApproval,
  });

  @override
  List<Object?> get props => [
    classId,
    name,
    description,
    isPublic,
    requireApproval,
  ];
}
