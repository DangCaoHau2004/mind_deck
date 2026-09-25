import '../user_model.dart';

class ClassStudentStatsModel {
  final String classId;
  final String userId;
  final int totalScore;
  final int cardsMasteredCount;
  final int assignmentsCompleted;
  final DateTime lastActiveInClass;

  // Optional relations
  final UserModel? user;

  ClassStudentStatsModel({
    required this.classId,
    required this.userId,
    required this.totalScore,
    required this.cardsMasteredCount,
    required this.assignmentsCompleted,
    required this.lastActiveInClass,
    this.user,
  });

  factory ClassStudentStatsModel.fromJson(Map<String, dynamic> json) {
    return ClassStudentStatsModel(
      classId: json['classId'] as String? ?? json['class_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      totalScore: json['totalScore'] as int? ?? json['total_score'] as int? ?? 0,
      cardsMasteredCount:
          json['cardsMasteredCount'] as int? ?? json['cards_mastered_count'] as int? ?? 0,
      assignmentsCompleted:
          json['assignmentsCompleted'] as int? ?? json['assignments_completed'] as int? ?? 0,
      lastActiveInClass:
          DateTime.tryParse(
            json['lastActiveInClass']?.toString() ?? json['last_active_in_class']?.toString() ?? '',
          ) ??
          DateTime.now(),
      user: json['user'] != null ? UserModel.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'userId': userId,
      'totalScore': totalScore,
      'cardsMasteredCount': cardsMasteredCount,
      'assignmentsCompleted': assignmentsCompleted,
      'lastActiveInClass': lastActiveInClass.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  ClassStudentStatsModel copyWith({
    String? classId,
    String? userId,
    int? totalScore,
    int? cardsMasteredCount,
    int? assignmentsCompleted,
    DateTime? lastActiveInClass,
    UserModel? user,
  }) {
    return ClassStudentStatsModel(
      classId: classId ?? this.classId,
      userId: userId ?? this.userId,
      totalScore: totalScore ?? this.totalScore,
      cardsMasteredCount: cardsMasteredCount ?? this.cardsMasteredCount,
      assignmentsCompleted: assignmentsCompleted ?? this.assignmentsCompleted,
      lastActiveInClass: lastActiveInClass ?? this.lastActiveInClass,
      user: user ?? this.user,
    );
  }
}
