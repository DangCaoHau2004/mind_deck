enum AssignmentType {
  studyMission('study_mission'),
  gradedTest('graded_test');

  final String value;
  const AssignmentType(this.value);

  static AssignmentType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'graded_test':
        return AssignmentType.gradedTest;
      case 'study_mission':
      default:
        return AssignmentType.studyMission;
    }
  }

  String toJson() => value;
}

enum AssignmentStatus {
  pending,
  inProgress,
  completed,
  overdue;

  static AssignmentStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'in_progress':
        return AssignmentStatus.inProgress;
      case 'completed':
        return AssignmentStatus.completed;
      case 'overdue':
        return AssignmentStatus.overdue;
      case 'pending':
      default:
        return AssignmentStatus.pending;
    }
  }

  String toJson() => name;
}

class ClassAssignmentModel {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final AssignmentType type;
  final String? deckId;
  final String? testId;
  final DateTime deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassAssignmentModel({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    required this.type,
    this.deckId,
    this.testId,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassAssignmentModel.fromJson(Map<String, dynamic> json) {
    return ClassAssignmentModel(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? json['class_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: AssignmentType.fromString(json['type'] as String?),
      deckId: json['deckId'] as String? ?? json['deck_id'] as String?,
      testId: json['testId'] as String? ?? json['test_id'] as String?,
      deadline:
          DateTime.tryParse(json['deadline']?.toString() ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            json['updatedAt']?.toString() ??
                json['updated_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'title': title,
      if (description != null) 'description': description,
      'type': type.toJson(),
      if (deckId != null) 'deckId': deckId,
      if (testId != null) 'testId': testId,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ClassAssignmentModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    AssignmentType? type,
    String? deckId,
    String? testId,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassAssignmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      deckId: deckId ?? this.deckId,
      testId: testId ?? this.testId,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
