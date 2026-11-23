import 'image_search_model.dart';

class TestAttemptDetailModel {
  final String attemptId;
  final String testName;
  final int totalQuestions;

  /// 0 khi đề tắt `showScore` (kiểm tra [showScore] trước khi hiển thị).
  final int correctAnswers;
  final num scorePercentage;
  final int durationMs;
  final DateTime? completedAt;
  final Map<String, dynamic>? settings;
  final List<TestAttemptAnswerModel> answers;

  // Lượt làm của đề lớp: có thông tin lớp / bài giao; đề cá nhân thì null.
  final String? classId;
  final String? assignmentId;
  final int attemptNo;

  /// false = đề tắt xem điểm: không hiện điểm / số câu đúng.
  final bool showScore;

  /// false = đề tắt xem đáp án: không hiện đúng/sai và đáp án chi tiết.
  final bool showAnswers;

  TestAttemptDetailModel({
    required this.attemptId,
    required this.testName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.durationMs,
    this.completedAt,
    this.settings,
    required this.answers,
    this.classId,
    this.assignmentId,
    this.attemptNo = 1,
    this.showScore = true,
    this.showAnswers = true,
  });

  factory TestAttemptDetailModel.fromJson(Map<String, dynamic> json) {
    final visibility = json['visibility'];
    return TestAttemptDetailModel(
      attemptId: json['attemptId'] as String? ?? json['attempt_id'] as String? ?? '',
      testName: json['testName'] as String? ?? json['test_name'] as String? ?? '',
      totalQuestions:
          (json['totalQuestions'] as num?)?.toInt() ??
          (json['total_questions'] as num?)?.toInt() ??
          0,
      correctAnswers:
          (json['correctAnswers'] as num?)?.toInt() ??
          (json['correct_answers'] as num?)?.toInt() ??
          0,
      scorePercentage: json['scorePercentage'] as num? ?? json['score_percentage'] as num? ?? 0,
      durationMs:
          (json['durationMs'] as num?)?.toInt() ?? (json['duration_ms'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? json['completed_at']?.toString() ?? '',
      ),
      settings: json['settings'] as Map<String, dynamic>?,
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => TestAttemptAnswerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      classId: json['classId'] as String?,
      assignmentId: json['assignmentId'] as String?,
      attemptNo: (json['attemptNo'] as num?)?.toInt() ?? 1,
      showScore: visibility is Map ? (visibility['showScore'] as bool? ?? true) : true,
      showAnswers: visibility is Map ? (visibility['showAnswers'] as bool? ?? true) : true,
    );
  }
}

class TestAttemptAnswerModel {
  final String answerId;
  final String? qid;
  final String cardId;
  final String questionType;

  /// false khi sai HOẶC khi đề ẩn đáp án (xem [isCorrectKnown]).
  final bool isCorrect;

  /// false = BE ẩn đúng/sai (đề tắt `showAnswers`): đừng coi câu này là sai.
  final bool isCorrectKnown;
  final int durationMs;
  final Map<String, dynamic> userAnswerDetails;
  final FlashcardInfoModel? flashcardInfo;

  TestAttemptAnswerModel({
    required this.answerId,
    this.qid,
    required this.cardId,
    required this.questionType,
    required this.isCorrect,
    this.isCorrectKnown = true,
    required this.durationMs,
    required this.userAnswerDetails,
    this.flashcardInfo,
  });

  factory TestAttemptAnswerModel.fromJson(Map<String, dynamic> json) {
    final rawCorrect = json['isCorrect'] ?? json['is_correct'];
    return TestAttemptAnswerModel(
      answerId: json['answerId'] as String? ?? json['answer_id'] as String? ?? '',
      qid: json['qid']?.toString(),
      cardId: json['cardId'] as String? ?? json['card_id'] as String? ?? '',
      questionType: json['questionType'] as String? ?? json['question_type'] as String? ?? '',
      isCorrect: rawCorrect is bool ? rawCorrect : false,
      isCorrectKnown: rawCorrect is bool,
      durationMs:
          (json['durationMs'] as num?)?.toInt() ?? (json['duration_ms'] as num?)?.toInt() ?? 0,
      userAnswerDetails:
          json['userAnswerDetails'] as Map<String, dynamic>? ??
          json['user_answer_details'] as Map<String, dynamic>? ??
          {},
      flashcardInfo: json['flashcardInfo'] != null
          ? FlashcardInfoModel.fromJson(json['flashcardInfo'] as Map<String, dynamic>)
          : (json['flashcard_info'] != null
                ? FlashcardInfoModel.fromJson(json['flashcard_info'] as Map<String, dynamic>)
                : null),
    );
  }
}

class FlashcardInfoModel {
  final String frontText;
  final String backText;
  final String? frontImageUrl;
  final ImageCredit? frontImageCredit;

  FlashcardInfoModel({
    required this.frontText,
    required this.backText,
    this.frontImageUrl,
    this.frontImageCredit,
  });

  factory FlashcardInfoModel.fromJson(Map<String, dynamic> json) {
    return FlashcardInfoModel(
      frontText: json['frontText'] as String? ?? json['front_text'] as String? ?? '',
      backText: json['backText'] as String? ?? json['back_text'] as String? ?? '',
      frontImageUrl: json['frontImageUrl'] as String? ?? json['front_image_url'] as String?,
      frontImageCredit: ImageCredit.tryParse(
        json['frontImageCredit'] ?? json['front_image_credit'],
      ),
    );
  }
}
