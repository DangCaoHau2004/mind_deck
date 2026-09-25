import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_state.dart';

class ClassTestCompletedView extends StatelessWidget {
  final ClassTestInProgressState state;

  const ClassTestCompletedView({super.key, required this.state});

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 giây';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins phút $secs giây';
    }
    return '$secs giây';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalQuestions = state.questions.length;
    final correctCount = state.answersCorrectnessMap.values.where((c) => c == true).length;
    final timeSpentSeconds = DateTime.now().difference(state.startedAt).inSeconds;

    final percent = totalQuestions > 0 ? (correctCount / totalQuestions * 100) : 0.0;
    final isPass = percent >= 50.0;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kết quả ôn tập',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                children: [
                  // Congratulations Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPass
                            ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)]
                            : [colorScheme.error, colorScheme.error.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: (isPass ? colorScheme.primary : colorScheme.error).withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isPass
                              ? Icons.emoji_events_rounded
                              : Icons.sentiment_very_dissatisfied_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPass ? 'HOÀN THÀNH XUẤT SẮC!' : 'CẦN CỐ GẮNG HƠN!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.testModel.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          value: '$correctCount/$totalQuestions',
                          label: 'Số câu đúng',
                          icon: Icons.check_circle_rounded,
                          iconColor: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          value: '${percent.toStringAsFixed(1)}%',
                          label: 'Độ chính xác',
                          icon: Icons.offline_bolt_rounded,
                          iconColor: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMetricCard(
                    context: context,
                    value: _formatDuration(timeSpentSeconds),
                    label: 'Thời gian làm bài',
                    icon: Icons.timer_outlined,
                    iconColor: colorScheme.primary,
                    isWide: true,
                  ),

                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),
                  Text(
                    'CHI TIẾT CÂU HỎI',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detailed Questions List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final q = state.questions[idx];
                      final isCorrect = state.answersCorrectnessMap[idx] ?? false;
                      final typeLabel = q.questionType.title;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCorrect
                                ? Colors.green.shade200
                                : colorScheme.error.withValues(alpha: 0.2),
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
                                '${idx + 1}',
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
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getQuestionPrompt(q),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (state.answersMap[idx] != null &&
                                      q.questionType != TestQuestionType.flashcard)
                                    _buildUserAnswer(context, q, state.answersMap[idx], isCorrect),
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
                    },
                  ),
                ],
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.08))),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: Text(
                  'HOÀN THÀNH',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool isWide = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Row(
      mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: content,
    );
  }

  String _getQuestionPrompt(TestQuestionModel q) {
    switch (q.questionType) {
      case TestQuestionType.flashcard:
        return q.frontText.isNotEmpty ? q.frontText : q.prompt;
      case TestQuestionType.dictation:
        return 'Nghe chính tả: ${q.expectedText}';
      case TestQuestionType.matching:
        return 'Ghép các cặp từ tương ứng';
      default:
        return q.prompt.isNotEmpty ? q.prompt : 'Câu hỏi';
    }
  }

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

  Widget _buildUserAnswer(
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
}
