import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/test_attempt_detail_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _formatDateTime(DateTime? d) {
  if (d == null) return '--';
  final l = d.toLocal();
  return '${_two(l.day)}/${_two(l.month)} ${_two(l.hour)}:${_two(l.minute)}';
}

String _formatDuration(int ms) {
  final s = (ms / 1000).round();
  return '${_two(s ~/ 60)}:${_two(s % 60)}';
}

String _formatScore(num v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Danh sách các lượt làm bài của một học viên trong một bài kiểm tra (giảng viên xem).
Future<void> showStudentAttemptsSheet(
  BuildContext context, {
  required String classId,
  required String assignmentId,
  required String userId,
  required String studentName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttemptsSheet(
      classId: classId,
      assignmentId: assignmentId,
      userId: userId,
      studentName: studentName,
    ),
  );
}

/// Chi tiết một lượt làm bài (luôn đầy đủ điểm + đáp án với giảng viên).
Future<void> showAttemptDetailSheet(
  BuildContext context, {
  required String classId,
  required String attemptId,
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttemptDetailSheet(classId: classId, attemptId: attemptId, title: title),
  );
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget Function(ScrollController controller) builder;

  const _SheetFrame({required this.title, this.subtitle, required this.builder});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              Expanded(child: builder(controller)),
            ],
          ),
        );
      },
    );
  }
}

class _AttemptsSheet extends StatefulWidget {
  final String classId;
  final String assignmentId;
  final String userId;
  final String studentName;

  const _AttemptsSheet({
    required this.classId,
    required this.assignmentId,
    required this.userId,
    required this.studentName,
  });

  @override
  State<_AttemptsSheet> createState() => _AttemptsSheetState();
}

class _AttemptsSheetState extends State<_AttemptsSheet> {
  bool _loading = true;
  String? _error;
  List<StudentAttemptModel> _attempts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await DI().sl<ClassRepository>().getStudentAttempts(
        widget.classId,
        widget.assignmentId,
        widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _attempts = resp.data;
      });
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ClassErrorMessages.of(f);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SheetFrame(
      title: 'Các lượt làm bài',
      subtitle: widget.studentName,
      builder: (controller) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) {
          return Center(
            child: Text(_error!, style: TextStyle(color: colorScheme.error)),
          );
        }
        if (_attempts.isEmpty) {
          return Center(
            child: Text('Học viên chưa nộp lượt nào', style: TextStyle(color: colorScheme.outline)),
          );
        }
        return ListView.separated(
          controller: controller,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _attempts.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          itemBuilder: (context, i) {
            final a = _attempts[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  '${a.attemptNo}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(
                'Lượt ${a.attemptNo} · ${_formatScore(a.scorePercentage)}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${a.correctAnswers}/${a.totalQuestions} câu đúng · ${_formatDuration(a.durationMs)} · ${_formatDateTime(a.completedAt)}',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showAttemptDetailSheet(
                context,
                classId: widget.classId,
                attemptId: a.attemptId,
                title: 'Lượt ${a.attemptNo} – ${widget.studentName}',
              ),
            );
          },
        );
      },
    );
  }
}

class _AttemptDetailSheet extends StatefulWidget {
  final String classId;
  final String attemptId;
  final String title;

  const _AttemptDetailSheet({required this.classId, required this.attemptId, required this.title});

  @override
  State<_AttemptDetailSheet> createState() => _AttemptDetailSheetState();
}

class _AttemptDetailSheetState extends State<_AttemptDetailSheet> {
  bool _loading = true;
  String? _error;
  TestAttemptDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await DI().sl<ClassRepository>().getAttemptDetail(
        widget.classId,
        widget.attemptId,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _detail = resp.data;
      });
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ClassErrorMessages.of(f);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SheetFrame(
      title: widget.title,
      subtitle: _detail?.testName,
      builder: (controller) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        final detail = _detail;
        if (_error != null || detail == null) {
          return Center(
            child: Text(
              _error ?? 'Không tải được bài làm',
              style: TextStyle(color: colorScheme.error),
            ),
          );
        }
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summary('Điểm', '${_formatScore(detail.scorePercentage)}%'),
                  _summary('Đúng', '${detail.correctAnswers}/${detail.totalQuestions}'),
                  _summary('Thời gian', _formatDuration(detail.durationMs)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < detail.answers.length; i++)
              _answerTile(colorScheme, i, detail.answers[i]),
          ],
        );
      },
    );
  }

  Widget _summary(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _answerTile(ColorScheme colorScheme, int index, TestAttemptAnswerModel a) {
    final d = a.userAnswerDetails;
    final color = a.isCorrect ? Colors.green.shade600 : Colors.red.shade500;
    final pairs = d['pairs'];
    final prompt = (d['prompt'] ?? a.flashcardInfo?.frontText ?? '').toString();

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
              const Spacer(),
              Text(
                _formatDuration(a.durationMs),
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          if (prompt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(prompt, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 8),
          if (pairs is List)
            for (final p in pairs.whereType<Map>())
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${p['left'] ?? ''} → ${p['userAnswer'] ?? '(bỏ trống)'}'
                  '${p['isCorrect'] == false ? '  (đúng: ${p['expectedAnswer'] ?? ''})' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: p['isCorrect'] == false ? Colors.red.shade600 : colorScheme.onSurface,
                  ),
                ),
              )
          else ...[
            Text(
              'Trả lời: ${(d['userAnswer'] ?? '').toString().isEmpty ? '(bỏ trống)' : d['userAnswer']}',
              style: const TextStyle(fontSize: 13),
            ),
            if (!a.isCorrect && d['expectedAnswer'] != null)
              Text(
                'Đáp án: ${d['expectedAnswer']}',
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
