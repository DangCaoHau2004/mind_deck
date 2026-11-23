import 'custom_test_model.dart';
import 'test_settings_model.dart';

class TestAttemptModel {
  final String id;
  final String? testId;
  final String testName;
  final String userId;
  final int totalQuestions;

  /// 0 khi đề tắt `showScore` (xem [showScore]).
  final int correctAnswers;
  final int? durationMs;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? source;
  final List<String> questionTypes;

  // Lượt làm của đề lớp có thêm thông tin lớp / bài giao; đề cá nhân thì các trường này null.
  final String? classId;
  final String? assignmentId;
  final String? assignmentTitle;
  final int attemptNo;

  /// Điểm % của lượt này; null khi đề tắt `showScore`.
  final double? scorePercentage;

  /// false = đề tắt xem điểm: KHÔNG hiện điểm / số câu đúng.
  final bool showScore;

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
    this.classId,
    this.assignmentId,
    this.assignmentTitle,
    this.attemptNo = 1,
    this.scorePercentage,
    this.showScore = true,
    this.test,
  });

  /// Tỉ lệ đúng tính cục bộ (chỉ dùng khi [showScore] = true).
  double get computedPercentage => totalQuestions <= 0 ? 0 : correctAnswers / totalQuestions * 100;

  factory TestAttemptModel.fromJson(Map<String, dynamic> json) {
    return TestAttemptModel(
      id: json['id'] as String? ?? json['attemptId'] as String? ?? '',
      testId: json['testId'] as String? ?? json['test_id'] as String?,
      testName: json['testName'] as String? ?? json['test_name'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      totalQuestions:
          (json['totalQuestions'] as num?)?.toInt() ??
          (json['total_questions'] as num?)?.toInt() ??
          0,
      // Đề tắt `showScore` -> BE trả null cho correctAnswers / scorePercentage.
      correctAnswers:
          (json['correctAnswers'] as num?)?.toInt() ??
          (json['correct_answers'] as num?)?.toInt() ??
          0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? (json['duration_ms'] as num?)?.toInt(),
      startedAt:
          DateTime.tryParse(
            json['startedAt']?.toString() ?? json['started_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? json['completed_at']?.toString() ?? '',
      ),
      source: json['source'] as Map<String, dynamic>?,
      questionTypes:
          (json['questionTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['question_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      classId: json['classId'] as String?,
      assignmentId: json['assignmentId'] as String?,
      assignmentTitle: json['assignmentTitle'] as String?,
      attemptNo: (json['attemptNo'] as num?)?.toInt() ?? 1,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble(),
      showScore: json['showScore'] as bool? ?? true,
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
      if (classId != null) 'classId': classId,
      if (assignmentId != null) 'assignmentId': assignmentId,
      if (assignmentTitle != null) 'assignmentTitle': assignmentTitle,
      'attemptNo': attemptNo,
      if (scorePercentage != null) 'scorePercentage': scorePercentage,
      'showScore': showScore,
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
      classId: classId,
      assignmentId: assignmentId,
      assignmentTitle: assignmentTitle,
      attemptNo: attemptNo,
      scorePercentage: scorePercentage,
      showScore: showScore,
      test: test ?? this.test,
    );
  }
}

/// Kết quả CHẤM LẠI của server khi nộp bài (điểm chính thức).
class SubmittedAnswerResult {
  final String? qid;
  final String? questionType;
  final bool isCorrect;
  final String? userAnswer;
  final String? expectedAnswer;

  /// Câu ghép cặp: `[{id, left, expectedAnswer, userAnswer, isCorrect}]`.
  final List<Map<String, dynamic>> pairs;

  const SubmittedAnswerResult({
    this.qid,
    this.questionType,
    this.isCorrect = false,
    this.userAnswer,
    this.expectedAnswer,
    this.pairs = const [],
  });

  factory SubmittedAnswerResult.fromJson(Map<String, dynamic> json) {
    final rawPairs = json['pairs'];
    return SubmittedAnswerResult(
      qid: json['qid']?.toString(),
      questionType: json['questionType'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      userAnswer: json['userAnswer']?.toString(),
      expectedAnswer: json['expectedAnswer']?.toString(),
      pairs: rawPairs is List
          ? [
              for (final p in rawPairs)
                if (p is Map<String, dynamic>) p,
            ]
          : const [],
    );
  }
}

class TestSubmitResponseModel {
  final String attemptId;
  final int attemptNo;

  /// null = không giới hạn lượt (đề cá nhân).
  final int? attemptsAllowed;
  final int? attemptsLeft;
  final int totalQuestions;

  /// 0 khi đề tắt `showScore` (đọc [visibility].showScore trước khi hiển thị).
  final int correctAnswers;

  /// Điểm % của lượt này; null khi đề tắt `showScore`.
  final double? scorePercentage;

  /// Điểm CHÍNH THỨC của bài giao (đã gộp theo `scorePolicy`); null khi đề tắt `showScore`.
  final double? officialScorePercentage;
  final int processedCards;
  final TestVisibility visibility;

  /// Chỉ có khi đề cho xem đáp án (`visibility.showAnswers`).
  final List<SubmittedAnswerResult>? answers;

  TestSubmitResponseModel({
    required this.attemptId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.processedCards,
    this.attemptNo = 1,
    this.attemptsAllowed,
    this.attemptsLeft,
    this.scorePercentage,
    this.officialScorePercentage,
    this.visibility = const TestVisibility(),
    this.answers,
  });

  /// Còn lượt làm lại (đề cá nhân: luôn làm lại được).
  bool get canRetry => attemptsAllowed == null || (attemptsLeft ?? 0) > 0;

  factory TestSubmitResponseModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    return TestSubmitResponseModel(
      attemptId: json['attemptId'] as String? ?? json['attempt_id'] as String? ?? '',
      totalQuestions:
          (json['totalQuestions'] as num?)?.toInt() ??
          (json['total_questions'] as num?)?.toInt() ??
          0,
      correctAnswers:
          (json['correctAnswers'] as num?)?.toInt() ??
          (json['correct_answers'] as num?)?.toInt() ??
          0,
      processedCards:
          (json['processedCards'] as num?)?.toInt() ??
          (json['processed_cards'] as num?)?.toInt() ??
          0,
      attemptNo: (json['attemptNo'] as num?)?.toInt() ?? 1,
      attemptsAllowed: (json['attemptsAllowed'] as num?)?.toInt(),
      attemptsLeft: (json['attemptsLeft'] as num?)?.toInt(),
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble(),
      officialScorePercentage: (json['officialScorePercentage'] as num?)?.toDouble(),
      visibility: TestVisibility.fromJson(json['visibility']),
      answers: rawAnswers is List
          ? [
              for (final a in rawAnswers)
                if (a is Map<String, dynamic>) SubmittedAnswerResult.fromJson(a),
            ]
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'attemptNo': attemptNo,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'processedCards': processedCards,
    };
  }
}
