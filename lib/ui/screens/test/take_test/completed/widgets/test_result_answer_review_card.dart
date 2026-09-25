import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/test_question_model.dart';

class TestResultAnswerReviewCard extends StatelessWidget {
  final int index;
  final TestQuestionModel question;
  final dynamic userAnswer;
  final bool isCorrect;

  const TestResultAnswerReviewCard({
    super.key,
    required this.index,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });

  String _formatCompletedUserAnswer(TestQuestionModel q, dynamic userAns) {
    if (userAns == null) return 'Không có câu trả lời';

    switch (q.questionType) {
      case TestQuestionType.multipleChoice:
        if (userAns is int) {
          final options = q.options;
          if (userAns >= 0 && userAns < options.length) {
            return options[userAns]['text']?.toString() ?? 'Lựa chọn ${userAns + 1}';
          }
        }
        return userAns.toString();

      case TestQuestionType.trueFalse:
        if (userAns is bool) {
          return userAns ? 'Đúng' : 'Sai';
        }
        return userAns.toString();

      case TestQuestionType.matching:
        return 'Đã trả lời câu ghép cặp';

      default:
        return userAns.toString();
    }
  }

  Widget _buildUserAnswerContent(
    BuildContext context,
    TestQuestionModel q,
    dynamic userAns,
    bool isCorrectOverall,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (q.questionType == TestQuestionType.matching) {
      if (userAns is! Map) return const SizedBox.shrink();

      final leftCol = q.leftColumn;
      final rightCol = q.rightColumn;

      final List<Widget> pairWidgets = [];
      for (final l in leftCol) {
        final lId = l['id']?.toString() ?? '';
        final lText = l['text']?.toString() ?? '';
        if (lId.isNotEmpty && userAns.containsKey(lId)) {
          final rId = userAns[lId]?.toString() ?? '';
          final rItem = rightCol.cast<Map<String, dynamic>>().firstWhere(
            (r) => r['id']?.toString() == rId,
            orElse: () => <String, dynamic>{},
          );
          final rText = rItem.isNotEmpty ? (rItem['text']?.toString() ?? '') : '???';

          final isPairCorrect = (lId == rId);

          pairWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isPairCorrect ? Icons.check_rounded : Icons.close_rounded,
                    color: isPairCorrect ? Colors.green.shade600 : colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$lText ➔ $rText',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isPairCorrect ? Colors.green.shade700 : colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu trả lời của bạn',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (pairWidgets.isEmpty)
            Text(
              'Chưa ghép cặp nào',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
            )
          else
            ...pairWidgets,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Câu trả lời của bạn',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCorrectOverall ? Icons.check_rounded : Icons.close_rounded,
              color: isCorrectOverall ? Colors.green.shade600 : colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _formatCompletedUserAnswer(q, userAns),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isCorrectOverall ? Colors.green.shade700 : colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPromptText() {
    switch (question.questionType) {
      case TestQuestionType.flashcard:
        return question.frontText.isNotEmpty ? question.frontText : question.prompt;
      case TestQuestionType.dictation:
        return 'Nghe chính tả: ${question.expectedText}';
      case TestQuestionType.matching:
        return 'Ghép các cặp từ tương ứng';
      default:
        return question.prompt.isNotEmpty ? question.prompt : 'Câu hỏi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final typeLabel = question.questionType.title;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect ? Colors.green.shade200 : colorScheme.error.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCorrect
                  ? Colors.green.shade50
                  : colorScheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isCorrect ? Colors.green.shade800 : colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getPromptText(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (userAnswer != null && question.questionType != TestQuestionType.flashcard)
                  _buildUserAnswerContent(context, question, userAnswer, isCorrect),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? Colors.green.shade600 : colorScheme.error,
            size: 24,
          ),
        ],
      ),
    );
  }
}
