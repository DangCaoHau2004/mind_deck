import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/test_question_model.dart';

/// Chuyển đáp án trên UI <-> định dạng BE dùng cho `PATCH /tests/sessions/:id/progress` và
/// `POST /tests/:testId/submit` (và `/classes/:id/assignments/:aid/submit`).
///
/// Giá trị trên UI theo từng dạng câu:
/// - trắc nghiệm: `int` (chỉ số option); - đúng/sai: `bool` ("phát biểu là ĐÚNG?");
/// - điền từ / chính tả: `String`; - ghép cặp: `Map<String, String>` (id mục trái -> id mục phải).
///
/// Quy ước BE: trắc nghiệm gửi TEXT đáp án (hoặc id option) — KHÔNG gửi chỉ số hay chữ A/B/C;
/// đúng/sai gửi "true"/"false"; ghép cặp gửi `pairs: [{cardId: <id mục trái>, userAnswer}]`.
class TestAnswerBuilder {
  TestAnswerBuilder._();

  /// Một phần tử của `answers[]` cho MỘT câu. Câu bỏ trống: `userAnswer: ""`.
  static Map<String, dynamic> build(
    TestQuestionModel q,
    dynamic localAnswer,
    int durationMs, {
    bool isMarked = false,
  }) {
    final base = <String, dynamic>{
      'qid': ?q.qid,
      'cardId': ?q.cardId,
      'questionType': q.questionType.value,
      'durationMs': durationMs,
      if (isMarked) 'isMarked': true,
    };

    switch (q.questionType) {
      case TestQuestionType.multipleChoice:
        final opts = q.options;
        var text = '';
        if (localAnswer is int && localAnswer >= 0 && localAnswer < opts.length) {
          final opt = opts[localAnswer];
          text = (opt is Map ? (opt['text'] ?? opt['id']) : opt)?.toString() ?? '';
        }
        return {...base, 'userAnswer': text};

      case TestQuestionType.trueFalse:
        return {...base, 'userAnswer': localAnswer is bool ? localAnswer.toString() : ''};

      case TestQuestionType.matching:
        final matches = localAnswer is Map ? localAnswer : const {};
        return {
          ...base,
          'pairs': [
            for (final e in matches.entries)
              {'cardId': e.key.toString(), 'userAnswer': e.value.toString(), 'durationMs': 0},
          ],
        };

      case TestQuestionType.fillInTheBlank:
      case TestQuestionType.dictation:
      case TestQuestionType.flashcard:
        return {...base, 'userAnswer': localAnswer?.toString() ?? ''};
    }
  }

  /// Khôi phục đáp án trên UI từ bản nháp của server (`answers[]` khi resume).
  static dynamic restore(TestQuestionModel q, Map<String, dynamic> draft) {
    final userAnswer = draft['userAnswer']?.toString() ?? '';
    switch (q.questionType) {
      case TestQuestionType.multipleChoice:
        if (userAnswer.isEmpty) return null;
        final opts = q.options;
        for (var i = 0; i < opts.length; i++) {
          final opt = opts[i];
          if (opt is Map &&
              (opt['text']?.toString() == userAnswer || opt['id']?.toString() == userAnswer)) {
            return i;
          }
        }
        return null;

      case TestQuestionType.trueFalse:
        if (userAnswer == 'true') return true;
        if (userAnswer == 'false') return false;
        return null;

      case TestQuestionType.matching:
        final pairs = draft['pairs'];
        if (pairs is! List || pairs.isEmpty) return null;
        final rightByText = <String, String>{
          for (final r in q.rightColumn)
            if (r is Map) r['text'].toString(): r['id'].toString(),
        };
        return <String, String>{
          for (final p in pairs.whereType<Map>())
            p['cardId'].toString():
                rightByText[p['userAnswer'].toString()] ?? p['userAnswer'].toString(),
        };

      case TestQuestionType.fillInTheBlank:
      case TestQuestionType.dictation:
      case TestQuestionType.flashcard:
        return userAnswer.isEmpty ? null : userAnswer;
    }
  }
}
