import 'test_question_model.dart';

class CustomTestModel {
  final String id;
  final String userId;
  final String name;
  final Map<String, dynamic>? sourceFilters;
  final List<String> questionTypes;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final int timeLimitSeconds;
  final bool showAnswerImmediately;
  final List<TestQuestionModel> questions;

  CustomTestModel({
    required this.id,
    required this.userId,
    required this.name,
    this.sourceFilters,
    required this.questionTypes,
    this.settings,
    required this.createdAt,
    this.timeLimitSeconds = 0,
    this.showAnswerImmediately = false,
    required this.questions,
  });

  factory CustomTestModel.fromJson(Map<String, dynamic> json) {
    return CustomTestModel(
      id:
          json['id']?.toString() ??
          json['testId']?.toString() ??
          json['test_id']?.toString() ??
          '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      sourceFilters:
          json['sourceFilters'] as Map<String, dynamic>? ??
          json['source_filters'] as Map<String, dynamic>?,
      questionTypes:
          (json['questionTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['question_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      settings: json['settings'] as Map<String, dynamic>?,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      timeLimitSeconds:
          json['timeLimitSeconds'] as int? ??
          json['time_limit_seconds'] as int? ??
          0,
      showAnswerImmediately:
          json['showAnswerImmediately'] as bool? ??
          json['show_answer_immediately'] as bool? ??
          false,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map(
                (e) => TestQuestionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      if (sourceFilters != null) 'sourceFilters': sourceFilters,
      'questionTypes': questionTypes,
      if (settings != null) 'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'timeLimitSeconds': timeLimitSeconds,
      'showAnswerImmediately': showAnswerImmediately,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }

  CustomTestModel copyWith({
    String? id,
    String? userId,
    String? name,
    Map<String, dynamic>? sourceFilters,
    List<String>? questionTypes,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    int? timeLimitSeconds,
    bool? showAnswerImmediately,
    List<TestQuestionModel>? questions,
  }) {
    return CustomTestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sourceFilters: sourceFilters ?? this.sourceFilters,
      questionTypes: questionTypes ?? this.questionTypes,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      showAnswerImmediately:
          showAnswerImmediately ?? this.showAnswerImmediately,
      questions: questions ?? this.questions,
    );
  }
}
