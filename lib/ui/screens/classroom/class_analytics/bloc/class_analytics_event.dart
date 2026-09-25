import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';

abstract class ClassAnalyticsEvent extends Equatable {
  const ClassAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class ClassAnalyticsLoaded extends ClassAnalyticsEvent {
  final String classId;

  const ClassAnalyticsLoaded(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassAnalyticsRefreshed extends ClassAnalyticsEvent {
  final String classId;

  const ClassAnalyticsRefreshed(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassAnalyticsMemberSelected extends ClassAnalyticsEvent {
  final String classId;
  final ClassMemberModel member;

  const ClassAnalyticsMemberSelected(this.classId, this.member);

  @override
  List<Object?> get props => [classId, member];
}

class ClassAnalyticsAssignmentSelected extends ClassAnalyticsEvent {
  final String classId;
  final ClassAssignmentModel assignment;

  const ClassAnalyticsAssignmentSelected(this.classId, this.assignment);

  @override
  List<Object?> get props => [classId, assignment];
}
