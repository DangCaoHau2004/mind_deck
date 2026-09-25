import 'package:equatable/equatable.dart';

abstract class ClassMembersEvent extends Equatable {
  const ClassMembersEvent();

  @override
  List<Object?> get props => [];
}

class ClassMembersLoaded extends ClassMembersEvent {
  final String classId;

  const ClassMembersLoaded(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassMembersRefreshed extends ClassMembersEvent {
  final String classId;

  const ClassMembersRefreshed(this.classId);

  @override
  List<Object?> get props => [classId];
}

class MemberApproved extends ClassMembersEvent {
  final String classId;
  final String userId;

  const MemberApproved(this.classId, this.userId);

  @override
  List<Object?> get props => [classId, userId];
}

class MemberKicked extends ClassMembersEvent {
  final String classId;
  final String userId;

  const MemberKicked(this.classId, this.userId);

  @override
  List<Object?> get props => [classId, userId];
}

class MemberRoleUpdated extends ClassMembersEvent {
  final String classId;
  final String userId;
  final String newRole;

  const MemberRoleUpdated(this.classId, this.userId, this.newRole);

  @override
  List<Object?> get props => [classId, userId, newRole];
}
