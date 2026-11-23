import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';

/// Nội dung form tạo / sửa bài giao.
class AssignmentDraft extends Equatable {
  final String title;
  final String? description;
  final AssignmentType type;

  /// null = giao ngay.
  final DateTime? startAt;
  final DateTime endAt;

  // Bài học
  final String? mode;
  final String? scope;
  final int? targetCount;
  final List<AssignmentSource> sources;

  // Bài kiểm tra
  final String? testId;

  const AssignmentDraft({
    required this.title,
    this.description,
    required this.type,
    this.startAt,
    required this.endAt,
    this.mode,
    this.scope,
    this.targetCount,
    this.sources = const [],
    this.testId,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    type,
    startAt,
    endAt,
    mode,
    scope,
    targetCount,
    sources.map((s) => '${s.type}:${s.id}').toList(),
    testId,
  ];
}

abstract class ClassAssignmentsEvent extends Equatable {
  const ClassAssignmentsEvent();

  @override
  List<Object?> get props => [];
}

class ClassAssignmentsLoaded extends ClassAssignmentsEvent {
  final String classId;

  /// Giảng viên: tab đang diễn ra / đã kết thúc. Học viên: thêm danh sách quá hạn.
  final bool isTeacher;

  const ClassAssignmentsLoaded(this.classId, {this.isTeacher = false});

  @override
  List<Object?> get props => [classId, isTeacher];
}

class ClassAssignmentCreated extends ClassAssignmentsEvent {
  final String classId;
  final AssignmentDraft draft;

  const ClassAssignmentCreated({required this.classId, required this.draft});

  @override
  List<Object?> get props => [classId, draft];
}

class ClassAssignmentUpdated extends ClassAssignmentsEvent {
  final String classId;
  final String assignmentId;
  final AssignmentDraft draft;

  const ClassAssignmentUpdated({
    required this.classId,
    required this.assignmentId,
    required this.draft,
  });

  @override
  List<Object?> get props => [classId, assignmentId, draft];
}

class ClassAssignmentDeleted extends ClassAssignmentsEvent {
  final String classId;
  final String assignmentId;

  const ClassAssignmentDeleted({required this.classId, required this.assignmentId});

  @override
  List<Object?> get props => [classId, assignmentId];
}
