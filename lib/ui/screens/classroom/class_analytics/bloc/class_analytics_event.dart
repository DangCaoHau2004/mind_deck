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

  /// Giảng viên (owner/admin/tutor) xem được cả lớp, chọn học viên và tiến độ bài giao.
  /// Học viên chỉ xem số liệu của chính mình (BE bỏ qua `student_id` của học viên).
  final bool isTeacher;

  const ClassAnalyticsLoaded(this.classId, {this.isTeacher = false});

  @override
  List<Object?> get props => [classId, isTeacher];
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
