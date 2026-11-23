import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/utils/text_match.dart';
import 'package:mind_deck/data/models/image_search_model.dart';

class TestQuestionModel {
  /// Định danh câu trong đề (string ≤ 64). Đề auto: `q1..qN` do server gán cho từng phiên;
  /// đề manual: giữ nguyên qid giảng viên đặt. Submit / lưu nháp ghép câu trả lời theo `qid`.
  final String? qid;

  /// Thẻ BẢN SAO của lớp mà câu kiểm tra (để tính FSRS); null = chỉ chấm điểm.
  final String? cardId;
  final List<String>? cardIds;
  final TestQuestionType questionType;
  final Map<String, dynamic> questionData;

  TestQuestionModel({
    this.qid,
    this.cardId,
    this.cardIds,
    required this.questionType,
    required this.questionData,
  });

  factory TestQuestionModel.fromJson(Map<String, dynamic> json) {
    return TestQuestionModel(
      qid: json['qid']?.toString(),
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
      'qid': ?qid,
      'card_id': cardId,
      if (cardIds != null) 'cardIds': cardIds,
      'question_type': questionType.value,
      'question_data': questionData,
    };
  }

  /// Dạng chuẩn gửi lên BE khi tạo / sửa đề manual (`questions` của `POST /tests/generate`).
  Map<String, dynamic> toApiJson() {
    return {
      'qid': ?qid,
      'cardId': cardId,
      if (cardIds != null) 'cardIds': cardIds,
      'questionType': questionType.value,
      'questionData': questionData,
    };
  }

  TestQuestionModel copyWith({
    String? qid,
    String? cardId,
    List<String>? cardIds,
    TestQuestionType? questionType,
    Map<String, dynamic>? questionData,
  }) {
    return TestQuestionModel(
      qid: qid ?? this.qid,
      cardId: cardId ?? this.cardId,
      cardIds: cardIds ?? this.cardIds,
      questionType: questionType ?? this.questionType,
      questionData: questionData ?? this.questionData,
    );
  }

  // --- Convenience Getters ---
  String get prompt =>
      questionData['promptText']?.toString() ??
      questionData['prompt_text']?.toString() ??
      frontText;

  String? get promptImageUrl =>
      questionData['promptImageUrl']?.toString() ?? questionData['prompt_image_url']?.toString();

  ImageCredit? get promptImageCredit => ImageCredit.tryParse(
    questionData['promptImageCredit'] ?? questionData['prompt_image_credit'],
  );

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

  ImageCredit? get frontImageCredit =>
      ImageCredit.tryParse(questionData['frontImageCredit'] ?? questionData['front_image_credit']);

  bool get isTrueFalseExpected =>
      questionData['isCorrect'] as bool? ??
      questionData['is_correct'] as bool? ??
      questionData['is_true'] as bool? ??
      false;

  List<dynamic> get options => questionData['options'] as List<dynamic>? ?? const [];

  /// Id đáp án đúng của câu trắc nghiệm (đề auto: id thẻ; manual: id do giảng viên đặt).
  String? get correctOptionId =>
      (questionData['correctOptionId'] ?? questionData['correct_option_id'])?.toString();

  List<dynamic> get leftColumn =>
      questionData['leftColumn'] as List<dynamic>? ??
      questionData['left_column'] as List<dynamic>? ??
      const [];

  List<dynamic> get rightColumn =>
      questionData['rightColumn'] as List<dynamic>? ??
      questionData['right_column'] as List<dynamic>? ??
      const [];

  // --- Encapsulated Answer Checker ---
  /// Chấm cục bộ để hiện đúng/sai tức thì. Điểm chính thức luôn do server chấm lại khi nộp.
  bool checkAnswer(dynamic userAnswer) {
    switch (questionType) {
      case TestQuestionType.multipleChoice:
        final opts = options;
        if (userAnswer is int && userAnswer >= 0 && userAnswer < opts.length) {
          final optionId = opts[userAnswer]['id']?.toString() ?? '';
          // Đề cũ không có correctOptionId: id option chính là id thẻ.
          return optionId == (correctOptionId ?? cardId ?? '');
        }
        return false;

      case TestQuestionType.trueFalse:
        return (userAnswer as bool?) == isTrueFalseExpected;

      case TestQuestionType.fillInTheBlank:
      case TestQuestionType.dictation:
        // Server chấm gần đúng (lệch ≤ 1 ký tự hoặc ≤ 20% độ dài): FE khớp cùng quy tắc.
        return TextMatch.isNearMatch(userAnswer?.toString() ?? '', expectedText);

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
