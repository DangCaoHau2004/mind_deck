import 'custom_test_model.dart';

class TestAttemptModel {
  final String id;
  final String? testId;
  final String testName;
  final String userId;
  final int totalQuestions;
  final int correctAnswers;
  final int? durationMs;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? source;
  final List<String> questionTypes;

  // Optional relations
  final CustomTestModel? test;

  TestAttemptModel({
    required this.id,
    this.testId,
    this.testName = '',
    this.userId = '',
    required this.totalQuestions,
    required this.correctAnswers,
    this.durationMs,
    required this.startedAt,
    this.completedAt,
    this.source,
    this.questionTypes = const [],
    this.test,
  });

  factory TestAttemptModel.fromJson(Map<String, dynamic> json) {
    return TestAttemptModel(
      id: json['id'] as String? ?? json['attemptId'] as String? ?? '',
      testId: json['testId'] as String? ?? json['test_id'] as String?,
      testName:
          json['testName'] as String? ?? json['test_name'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      totalQuestions:
          json['totalQuestions'] as int? ??
          json['total_questions'] as int? ??
          0,
      correctAnswers:
          json['correctAnswers'] as int? ??
          json['correct_answers'] as int? ??
          0,
      durationMs: json['durationMs'] as int? ?? json['duration_ms'] as int?,
      startedAt:
          DateTime.tryParse(
            json['startedAt']?.toString() ??
                json['started_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ??
            json['completed_at']?.toString() ??
            '',
      ),
      source: json['source'] as Map<String, dynamic>?,
      questionTypes:
          (json['questionTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['question_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      test: json['test'] != null
          ? CustomTestModel.fromJson(json['test'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (testId != null) 'testId': testId,
      'testName': testName,
      'userId': userId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      if (durationMs != null) 'durationMs': durationMs,
      'startedAt': startedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (source != null) 'source': source,
      'questionTypes': questionTypes,
      if (test != null) 'test': test!.toJson(),
    };
  }

  TestAttemptModel copyWith({
    String? id,
    String? testId,
    String? testName,
    String? userId,
    int? totalQuestions,
    int? correctAnswers,
    int? durationMs,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? source,
    List<String>? questionTypes,
    CustomTestModel? test,
  }) {
    return TestAttemptModel(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      testName: testName ?? this.testName,
      userId: userId ?? this.userId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      durationMs: durationMs ?? this.durationMs,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      source: source ?? this.source,
      questionTypes: questionTypes ?? this.questionTypes,
      test: test ?? this.test,
    );
  }
}

class TestSubmitResponseModel {
  final String attemptId;
  final int totalQuestions;
  final int correctAnswers;
  final int processedCards;

  TestSubmitResponseModel({
    required this.attemptId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.processedCards,
  });

  factory TestSubmitResponseModel.fromJson(Map<String, dynamic> json) {
    return TestSubmitResponseModel(
      attemptId:
          json['attemptId'] as String? ?? json['attempt_id'] as String? ?? '',
      totalQuestions:
          json['totalQuestions'] as int? ??
          json['total_questions'] as int? ??
          0,
      correctAnswers:
          json['correctAnswers'] as int? ??
          json['correct_answers'] as int? ??
          0,
      processedCards:
          json['processedCards'] as int? ??
          json['processed_cards'] as int? ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'processedCards': processedCards,
    };
  }
}
