import 'class_assignment_model.dart';

class ClassAssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String userId;
  final AssignmentStatus status;
  final int progressCount;
  final String? testAttemptId;
  final double? scorePercentage;
  final DateTime? completedAt;
  final DateTime updatedAt;

  // Extra fields from joined query
  final String? title;
  final AssignmentType? type;
  final DateTime? deadline;

  ClassAssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.userId,
    required this.status,
    required this.progressCount,
    this.testAttemptId,
    this.scorePercentage,
    this.completedAt,
    required this.updatedAt,
    this.title,
    this.type,
    this.deadline,
  });

  factory ClassAssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return ClassAssignmentSubmissionModel(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignmentId'] as String? ?? json['assignment_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      status: AssignmentStatus.fromString(json['status'] as String?),
      progressCount: json['progressCount'] as int? ?? json['progress_count'] as int? ?? 0,
      testAttemptId: json['testAttemptId'] as String? ?? json['test_attempt_id'] as String?,
      scorePercentage:
          (json['scorePercentage'] as num?)?.toDouble() ??
          (json['score_percentage'] as num?)?.toDouble(),
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? json['completed_at']?.toString() ?? '',
      ),
      updatedAt:
          DateTime.tryParse(
            json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      title: json['title'] as String?,
      type: json['type'] != null ? AssignmentType.fromString(json['type'] as String?) : null,
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'userId': userId,
      'status': status.toJson(),
      'progressCount': progressCount,
      if (testAttemptId != null) 'testAttemptId': testAttemptId,
      if (scorePercentage != null) 'scorePercentage': scorePercentage,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (title != null) 'title': title,
      if (type != null) 'type': type!.toJson(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
    };
  }

  ClassAssignmentSubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? userId,
    AssignmentStatus? status,
    int? progressCount,
    String? testAttemptId,
    double? scorePercentage,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? title,
    AssignmentType? type,
    DateTime? deadline,
  }) {
    return ClassAssignmentSubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      progressCount: progressCount ?? this.progressCount,
      testAttemptId: testAttemptId ?? this.testAttemptId,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      type: type ?? this.type,
      deadline: deadline ?? this.deadline,
    );
  }
}
