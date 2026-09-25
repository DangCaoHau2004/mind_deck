class TestAttemptDetailModel {
  final String attemptId;
  final String testName;
  final int totalQuestions;
  final int correctAnswers;
  final num scorePercentage;
  final int durationMs;
  final DateTime? completedAt;
  final Map<String, dynamic>? settings;
  final List<TestAttemptAnswerModel> answers;

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
  });

  factory TestAttemptDetailModel.fromJson(Map<String, dynamic> json) {
    return TestAttemptDetailModel(
      attemptId:
          json['attemptId'] as String? ?? json['attempt_id'] as String? ?? '',
      testName:
          json['testName'] as String? ?? json['test_name'] as String? ?? '',
      totalQuestions:
          json['totalQuestions'] as int? ??
          json['total_questions'] as int? ??
          0,
      correctAnswers:
          json['correctAnswers'] as int? ??
          json['correct_answers'] as int? ??
          0,
      scorePercentage:
          json['scorePercentage'] as num? ??
          json['score_percentage'] as num? ??
          0,
      durationMs:
          json['durationMs'] as int? ?? json['duration_ms'] as int? ?? 0,
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ??
            json['completed_at']?.toString() ??
            '',
      ),
      settings: json['settings'] as Map<String, dynamic>?,
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map(
                (e) =>
                    TestAttemptAnswerModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class TestAttemptAnswerModel {
  final String answerId;
  final String cardId;
  final String questionType;
  final bool isCorrect;
  final int durationMs;
  final Map<String, dynamic> userAnswerDetails;
  final FlashcardInfoModel? flashcardInfo;

  TestAttemptAnswerModel({
    required this.answerId,
    required this.cardId,
    required this.questionType,
    required this.isCorrect,
    required this.durationMs,
    required this.userAnswerDetails,
    this.flashcardInfo,
  });

  factory TestAttemptAnswerModel.fromJson(Map<String, dynamic> json) {
    return TestAttemptAnswerModel(
      answerId:
          json['answerId'] as String? ?? json['answer_id'] as String? ?? '',
      cardId: json['cardId'] as String? ?? json['card_id'] as String? ?? '',
      questionType:
          json['questionType'] as String? ??
          json['question_type'] as String? ??
          '',
      isCorrect:
          json['isCorrect'] as bool? ?? json['is_correct'] as bool? ?? false,
      durationMs:
          json['durationMs'] as int? ?? json['duration_ms'] as int? ?? 0,
      userAnswerDetails:
          json['userAnswerDetails'] as Map<String, dynamic>? ??
          json['user_answer_details'] as Map<String, dynamic>? ??
          {},
      flashcardInfo: json['flashcardInfo'] != null
          ? FlashcardInfoModel.fromJson(
              json['flashcardInfo'] as Map<String, dynamic>,
            )
          : (json['flashcard_info'] != null
                ? FlashcardInfoModel.fromJson(
                    json['flashcard_info'] as Map<String, dynamic>,
                  )
                : null),
    );
  }
}

class FlashcardInfoModel {
  final String frontText;
  final String backText;
  final String? frontImageUrl;

  FlashcardInfoModel({
    required this.frontText,
    required this.backText,
    this.frontImageUrl,
  });

  factory FlashcardInfoModel.fromJson(Map<String, dynamic> json) {
    return FlashcardInfoModel(
      frontText:
          json['frontText'] as String? ?? json['front_text'] as String? ?? '',
      backText:
          json['backText'] as String? ?? json['back_text'] as String? ?? '',
      frontImageUrl:
          json['frontImageUrl'] as String? ??
          json['front_image_url'] as String?,
    );
  }
}
