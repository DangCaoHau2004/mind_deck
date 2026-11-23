import 'test_question_model.dart';
import 'test_settings_model.dart';

/// Đề kiểm tra. Dùng cho: danh sách / chi tiết / tạo đề, và phiên làm bài (Start / Resume).
/// Đề lớp có `classId`; đề cá nhân `classId == null`.
class CustomTestModel {
  final String id;
  final String userId;
  final String name;
  final Map<String, dynamic>? sourceFilters;
  final List<String> questionTypes;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int timeLimitSeconds;
  final bool showAnswerImmediately;
  final List<TestQuestionModel> questions;

  // --- Đề (kho đề / chi tiết) ---
  final String? classId;

  /// auto | manual
  final String kind;

  /// Đã có học viên bắt đầu / nộp -> chỉ đổi được tên.
  final bool locked;
  final List<String> cardIds;
  final int? questionCount;
  final int? cardCount;
  final int assignmentCount;

  // --- Phiên làm bài (Start / Resume) ---
  final String? sessionId;
  final String? assignmentId;

  /// Hạn cứng của phiên; null = không giới hạn (đề cá nhân không bật giới hạn giờ).
  final DateTime? expiresAt;
  final bool resumed;
  final int attemptNo;

  /// null = không giới hạn lượt (đề cá nhân).
  final int? attemptsAllowed;
  final int elapsedSeconds;
  final int currentQuestionIndex;
  final TestVisibility visibility;

  /// Bản nháp đã lưu (`answers[]` khi resume), mỗi phần tử `{qid, userAnswer, pairs?, durationMs}`.
  final List<Map<String, dynamic>> drafts;

  CustomTestModel({
    required this.id,
    this.userId = '',
    required this.name,
    this.sourceFilters,
    required this.questionTypes,
    this.settings,
    required this.createdAt,
    this.updatedAt,
    this.timeLimitSeconds = 0,
    this.showAnswerImmediately = false,
    required this.questions,
    this.classId,
    this.kind = 'auto',
    this.locked = false,
    this.cardIds = const [],
    this.questionCount,
    this.cardCount,
    this.assignmentCount = 0,
    this.sessionId,
    this.assignmentId,
    this.expiresAt,
    this.resumed = false,
    this.attemptNo = 1,
    this.attemptsAllowed,
    this.elapsedSeconds = 0,
    this.currentQuestionIndex = 0,
    this.visibility = const TestVisibility(),
    this.drafts = const [],
  });

  /// Cài đặt đã parse (phiên bản 2).
  TestSettings get testSettings => TestSettings.fromJson(settings);

  bool get isManual => kind == 'manual';
  bool get isPersonal => classId == null;

  factory CustomTestModel.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];
    final rawDrafts = json['answers'];
    return CustomTestModel(
      id: json['id']?.toString() ?? json['testId']?.toString() ?? json['test_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name'] as String? ?? json['testName'] as String? ?? '',
      sourceFilters:
          json['sourceFilters'] as Map<String, dynamic>? ??
          json['source_filters'] as Map<String, dynamic>?,
      questionTypes: json['questionTypes'] != null
          ? strings(json['questionTypes'])
          : strings(json['question_types']),
      settings: json['settings'] as Map<String, dynamic>?,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      timeLimitSeconds:
          (json['timeLimitSeconds'] as num?)?.toInt() ??
          (json['time_limit_seconds'] as num?)?.toInt() ??
          0,
      showAnswerImmediately:
          json['showAnswerImmediately'] as bool? ??
          json['show_answer_immediately'] as bool? ??
          false,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => TestQuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      classId: json['classId'] as String?,
      kind: json['kind'] as String? ?? 'auto',
      locked: json['locked'] as bool? ?? false,
      cardIds: strings(json['cardIds']),
      questionCount: (json['questionCount'] as num?)?.toInt(),
      cardCount: (json['cardCount'] as num?)?.toInt(),
      assignmentCount: (json['assignmentCount'] as num?)?.toInt() ?? 0,
      sessionId: json['sessionId'] as String?,
      assignmentId: json['assignmentId'] as String?,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      resumed: json['resumed'] as bool? ?? false,
      attemptNo: (json['attemptNo'] as num?)?.toInt() ?? 1,
      attemptsAllowed: (json['attemptsAllowed'] as num?)?.toInt(),
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      currentQuestionIndex: (json['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      visibility: TestVisibility.fromJson(json['visibility']),
      drafts: rawDrafts is List
          ? [
              for (final e in rawDrafts)
                if (e is Map<String, dynamic>) e,
            ]
          : const [],
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
      if (classId != null) 'classId': classId,
      'kind': kind,
      'locked': locked,
      'cardIds': cardIds,
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
    bool? locked,
  }) {
    return CustomTestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sourceFilters: sourceFilters ?? this.sourceFilters,
      questionTypes: questionTypes ?? this.questionTypes,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      showAnswerImmediately: showAnswerImmediately ?? this.showAnswerImmediately,
      questions: questions ?? this.questions,
      classId: classId,
      kind: kind,
      locked: locked ?? this.locked,
      cardIds: cardIds,
      questionCount: questionCount,
      cardCount: cardCount,
      assignmentCount: assignmentCount,
      sessionId: sessionId,
      assignmentId: assignmentId,
      expiresAt: expiresAt,
      resumed: resumed,
      attemptNo: attemptNo,
      attemptsAllowed: attemptsAllowed,
      elapsedSeconds: elapsedSeconds,
      currentQuestionIndex: currentQuestionIndex,
      visibility: visibility,
      drafts: drafts,
    );
  }
}
