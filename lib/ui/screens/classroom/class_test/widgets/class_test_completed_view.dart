import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/test_attempt_model.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_state.dart';

/// Kết quả sau khi nộp bài. Điểm / đáp án là kết quả CHẤM LẠI của server và chỉ hiện khi đề cho phép
/// (`visibility`); đề tắt thì KHÔNG tự hiện dù app đang giữ sẵn đáp án.
class ClassTestCompletedView extends StatelessWidget {
  final ClassTestInProgressState state;

  const ClassTestCompletedView({super.key, required this.state});

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 giây';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return mins > 0 ? '$mins phút $secs giây' : '$secs giây';
  }

  String _percent(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final result = state.result;

    final showScore = result?.visibility.showScore ?? false;
    final showAnswers = result?.visibility.showAnswers ?? false;
    final score = result?.scorePercentage;
    final total = result?.totalQuestions ?? state.questions.length;
    final correct = result?.correctAnswers ?? 0;
    final official = result?.officialScorePercentage;
    final hasScore = showScore && score != null;
    final isPass = hasScore && score >= 50;
    final timeSpentSeconds = DateTime.now().difference(state.startedAt).inSeconds;
    final accent = !hasScore ? cs.primary : (isPass ? cs.primary : cs.error);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kết quả bài kiểm tra',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.82)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          hasScore
                              ? (isPass
                                    ? Icons.emoji_events_rounded
                                    : Icons.sentiment_dissatisfied_rounded)
                              : Icons.task_alt_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasScore ? '${_percent(score)}%' : 'ĐÃ NỘP BÀI',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasScore ? '$correct/$total câu đúng' : 'Điểm sẽ do giảng viên công bố',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.testModel.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          context,
                          icon: Icons.replay_circle_filled_rounded,
                          label: 'Lượt làm',
                          value: result?.attemptsAllowed == null
                              ? '${result?.attemptNo ?? state.testModel.attemptNo}'
                              : '${result!.attemptNo}/${result.attemptsAllowed}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metric(
                          context,
                          icon: Icons.timer_outlined,
                          label: 'Thời gian',
                          value: _formatDuration(timeSpentSeconds),
                        ),
                      ),
                    ],
                  ),
                  if (hasScore && official != null && (official - score).abs() > 0.005) ...[
                    const SizedBox(height: 12),
                    _metric(
                      context,
                      icon: Icons.verified_rounded,
                      label: 'Điểm chính thức của bài',
                      value: '${_percent(official)}%',
                    ),
                  ],
                  if (result != null && result.attemptsAllowed != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      result.canRetry
                          ? 'Bạn còn ${result.attemptsLeft} lượt làm lại — vào lại bài ở danh sách bài tập.'
                          : 'Bạn đã dùng hết số lượt làm bài.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                  if (showAnswers && result?.answers != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Chi tiết từng câu',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < result!.answers!.length; i++)
                      _answerTile(context, i, result.answers![i]),
                  ] else if (!showAnswers) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Giảng viên không mở xem đáp án chi tiết cho bài kiểm tra này.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: () => context.pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Về danh sách bài tập'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị một câu: ghép theo `qid` với câu hỏi của đề để lấy nội dung câu hỏi.
  Widget _answerTile(BuildContext context, int index, SubmittedAnswerResult a) {
    final cs = Theme.of(context).colorScheme;
    final color = a.isCorrect ? Colors.green.shade600 : Colors.red.shade500;
    final TestQuestionModel? q = state.questions
        .where((e) => e.qid != null && e.qid == a.qid)
        .cast<TestQuestionModel?>()
        .firstOrNull;
    final prompt = q == null
        ? ''
        : (q.questionType == TestQuestionType.trueFalse && q.statement.isNotEmpty
              ? '${q.prompt}\n→ ${q.statement}'
              : q.prompt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                a.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Câu ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          if (prompt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(prompt, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 8),
          if (a.pairs.isNotEmpty)
            for (final p in a.pairs)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${p['left'] ?? ''} → ${p['userAnswer'] ?? '(bỏ trống)'}'
                  '${p['isCorrect'] == false ? '  (đúng: ${p['expectedAnswer'] ?? ''})' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: p['isCorrect'] == false ? Colors.red.shade600 : cs.onSurface,
                  ),
                ),
              )
          else ...[
            Text(
              'Trả lời: ${(a.userAnswer ?? '').isEmpty ? '(bỏ trống)' : a.userAnswer}',
              style: const TextStyle(fontSize: 13),
            ),
            if (!a.isCorrect && a.expectedAnswer != null)
              Text(
                'Đáp án: ${a.expectedAnswer}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
