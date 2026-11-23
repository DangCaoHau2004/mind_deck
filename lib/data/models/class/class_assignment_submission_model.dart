import 'class_assignment_model.dart';

/// Một dòng của `GET /classes/:id/my-submissions` và `GET /classes/:id/assignments/overdue`.
/// Hai API có shape khác nhau: `my-submissions` dùng `assignmentId`, `overdue` dùng `id`
/// (+ `my{}`) -> đọc cả hai.
class ClassAssignmentSubmissionModel {
  final String assignmentId;
  final String? title;
  final AssignmentType? type;
  final DateTime? endAt;
  final AssignmentStatus status;
  final int? targetCount;
  final int progressCount;

  /// null khi đề tắt `showScore`.
  final double? scorePercentage;
  final int attemptsCount;
  final DateTime? completedAt;
  final String? testAttemptId;

  /// Chỉ có ở `overdue`.
  final AssignmentMine? my;

  ClassAssignmentSubmissionModel({
    required this.assignmentId,
    this.title,
    this.type,
    this.endAt,
    required this.status,
    this.targetCount,
    this.progressCount = 0,
    this.scorePercentage,
    this.attemptsCount = 0,
    this.completedAt,
    this.testAttemptId,
    this.my,
  });

  /// Bí danh cũ của `endAt`.
  DateTime? get deadline => endAt;

  factory ClassAssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    final rawMy = json['my'];
    final mine = rawMy is Map<String, dynamic> ? AssignmentMine.fromJson(rawMy) : null;
    return ClassAssignmentSubmissionModel(
      assignmentId: json['assignmentId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String?,
      type: json['type'] != null ? AssignmentType.fromString(json['type'] as String?) : null,
      endAt: DateTime.tryParse(json['endAt']?.toString() ?? json['deadline']?.toString() ?? ''),
      // `overdue`: `status` là hằng số, trạng thái thật nằm ở `my.status`.
      status: mine?.status ?? AssignmentStatus.fromString(json['status'] as String?),
      targetCount: (json['targetCount'] as num?)?.toInt(),
      progressCount: (json['progressCount'] as num?)?.toInt() ?? 0,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble(),
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? mine?.attemptsCount ?? 0,
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      testAttemptId: json['testAttemptId'] as String?,
      my: mine,
    );
  }
}
