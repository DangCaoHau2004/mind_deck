import 'package:mind_deck/data/models/enums.dart';

class TestQuestionModel {
  final String? cardId;
  final List<String>? cardIds;
  final TestQuestionType questionType;
  final Map<String, dynamic> questionData;

  TestQuestionModel({
    this.cardId,
    this.cardIds,
    required this.questionType,
    required this.questionData,
  });

  factory TestQuestionModel.fromJson(Map<String, dynamic> json) {
    return TestQuestionModel(
      cardId: json['card_id'] as String? ?? json['cardId'] as String?,
      cardIds: (json['cardIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      questionType: TestQuestionType.fromString(
        json['question_type'] as String? ?? json['questionType'] as String?,
      ),
      questionData:
          json['question_data'] as Map<String, dynamic>? ??
          json['questionData'] as Map<String, dynamic>? ??
          const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      if (cardIds != null) 'cardIds': cardIds,
      'question_type': questionType.value,
      'question_data': questionData,
    };
  }

  // --- Convenience Getters ---
  String get prompt =>
      questionData['promptText']?.toString() ??
      questionData['prompt_text']?.toString() ??
      frontText;

  String? get promptImageUrl =>
      questionData['promptImageUrl']?.toString() ?? questionData['prompt_image_url']?.toString();

  String get statement =>
      questionData['statementText']?.toString() ?? questionData['statement_text']?.toString() ?? '';

  String get expectedText =>
      questionData['expectedText']?.toString() ?? questionData['expected_text']?.toString() ?? '';

  String get frontText =>
      questionData['frontText']?.toString() ?? questionData['front_text']?.toString() ?? '';

  String get backText =>
      questionData['backText']?.toString() ?? questionData['back_text']?.toString() ?? '';

  String? get frontImageUrl =>
      questionData['frontImageUrl']?.toString() ?? questionData['front_image_url']?.toString();

  bool get isTrueFalseExpected =>
      questionData['isCorrect'] as bool? ??
      questionData['is_correct'] as bool? ??
      questionData['is_true'] as bool? ??
      false;

  List<dynamic> get options => questionData['options'] as List<dynamic>? ?? const [];

  List<dynamic> get leftColumn =>
      questionData['leftColumn'] as List<dynamic>? ??
      questionData['left_column'] as List<dynamic>? ??
      const [];

  List<dynamic> get rightColumn =>
      questionData['rightColumn'] as List<dynamic>? ??
      questionData['right_column'] as List<dynamic>? ??
      const [];

  // --- Encapsulated Answer Checker ---
  bool checkAnswer(dynamic userAnswer) {
    switch (questionType) {
      case TestQuestionType.multipleChoice:
        final opts = options;
        if (userAnswer is int && userAnswer >= 0 && userAnswer < opts.length) {
          final optionId = opts[userAnswer]['id']?.toString() ?? '';
          return optionId == (cardId ?? '');
        }
        return false;

      case TestQuestionType.trueFalse:
        return (userAnswer as bool?) == isTrueFalseExpected;

      case TestQuestionType.fillInTheBlank:
      case TestQuestionType.dictation:
        return (userAnswer?.toString() ?? '').trim().toLowerCase() ==
            expectedText.trim().toLowerCase();

      case TestQuestionType.matching:
        final matches = userAnswer as Map<String, String>? ?? {};
        final left = leftColumn;
        if (left.isEmpty || matches.length != left.length) return false;
        int correctPairs = 0;
        for (final match in matches.entries) {
          if (match.key == match.value) {
            correctPairs++;
          }
        }
        return correctPairs == left.length;

      case TestQuestionType.flashcard:
        return userAnswer as bool? ?? false;
    }
  }
}
