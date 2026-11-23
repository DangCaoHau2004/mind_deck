import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/test_setup_view.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/test_in_progress_view.dart';
import 'package:mind_deck/ui/screens/test/take_test/completed/test_completed_view.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/study/active_study_session_model.dart';
import 'package:mind_deck/data/models/test_session_summary_model.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/utils/study_flow_helper.dart';

class TakeTestScreen extends StatefulWidget {
  const TakeTestScreen({super.key});

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  /// Phiên dở gần nhất (server): đề cá nhân hoặc phiên flashcard nhiều nguồn; chỉ một trong hai.
  TestSessionSummary? _pendingTest;
  ActiveStudySession? _pendingStudy;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  /// Banner chỉ là gợi ý nên lỗi mạng thì bỏ qua, không báo.
  Future<void> _loadPending() async {
    TestSessionSummary? test;
    ActiveStudySession? study;
    try {
      final response = await DI().sl<TestRepository>().getSessions(type: 'personal', limit: 1);
      test = response.data?.firstOrNull;
    } catch (_) {}
    try {
      final response = await DI().sl<StudyRepository>().getActiveSessions(type: 'cards', limit: 1);
      study = response.data?.firstOrNull;
    } catch (_) {}
    if (!mounted) return;

    final testAt = test?.updatedAt;
    final studyAt = study?.updatedAt;
    final useTest =
        test != null &&
        (study == null || (testAt != null && studyAt != null ? testAt.isAfter(studyAt) : true));
    setState(() {
      _pendingTest = useTest ? test : null;
      _pendingStudy = useTest ? null : study;
    });
  }

  void _hidePending() => setState(() {
    _pendingTest = null;
    _pendingStudy = null;
  });

  void _resumeTest() {
    final t = _pendingTest;
    if (t == null) return;
    _hidePending();
    context.read<TestSetupBloc>().add(
      TestSetupResumeRequested(sessionId: t.sessionId, testId: t.testId),
    );
  }

  void _restartTest() {
    final t = _pendingTest;
    if (t == null) return;
    _hidePending();
    context.read<TestSetupBloc>().add(TestSetupRestartRequested(testId: t.testId));
  }

  void _resumeStudy() {
    final s = _pendingStudy;
    if (s == null) return;
    _hidePending();
    StudyFlowHelper.start(context: context, sessionId: s.sessionId, replace: true);
  }

  Widget? _buildPendingBanner() {
    final test = _pendingTest;
    final study = _pendingStudy;
    if (test != null) {
      return _PendingBanner(
        title: 'Bạn có bài kiểm tra đang làm dở',
        subtitle:
            '${test.displayName} · ${'home_continue_test_progress'.tr.replaceAll('{answered}', '${test.answeredCount}').replaceAll('{total}', '${test.totalQuestions}')}',
        actions: [
          TextButton(onPressed: _hidePending, child: const Text('Bỏ qua')),
          TextButton(onPressed: _restartTest, child: Text('test_pending_new_test'.tr)),
          FilledButton(onPressed: _resumeTest, child: const Text('Làm tiếp')),
        ],
      );
    }
    if (study != null) {
      return _PendingBanner(
        title: 'test_pending_study_title'.tr,
        subtitle:
            '${'home_continue_review_cards'.tr.replaceAll('{count}', '${study.totalCards}')} · ${'home_continue_flashcard_progress'.tr.replaceAll('{learned}', '${study.learnedCount}').replaceAll('{total}', '${study.totalCards}')}',
        actions: [
          TextButton(onPressed: _hidePending, child: const Text('Bỏ qua')),
          FilledButton(onPressed: _resumeStudy, child: Text('test_pending_study_resume'.tr)),
        ],
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestSetupBloc, TestSetupState>(
      listenWhen: (prev, curr) {
        // `errorMessage` của phiên làm bài là "dính": chỉ báo khi có lỗi MỚI (vd nộp bài thất bại).
        if (curr is TestSetupInProgressState && curr.errorMessage != null) {
          return prev is! TestSetupInProgressState ||
              prev.errorMessage != curr.errorMessage ||
              (prev.isSubmitting && !curr.isSubmitting);
        }
        // `errorMessage` của màn thiết lập cũng "dính" qua copyWith: chỉ báo khi đổi.
        if (curr is TestSetupConfigState && curr.errorMessage != null) {
          return prev is! TestSetupConfigState || prev.errorMessage != curr.errorMessage;
        }
        return true;
      },
      listener: (context, state) {
        if (state is TestSetupInProgressState && state.errorMessage != null) {
          CustomToast.show(context, CustomToast.danger(message: state.errorMessage!));
        }
        if (state is TestSetupConfigState && state.errorMessage != null) {
          CustomToast.show(context, CustomToast.danger(message: state.errorMessage!));
        }
        if (state is TestSetupInProgressState) {
          final questions = state.testModel.questions;
          final isOnlyFlashcard =
              questions.isNotEmpty &&
              questions.every((q) => q.questionType == TestQuestionType.flashcard);

          if (isOnlyFlashcard) {
            final cardIds = questions
                .map((q) => q.cardId ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
            StudyFlowHelper.start(context: context, cardIds: cardIds, replace: true);
          }
        }
      },
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildViewForState(context, state),
        );
      },
    );
  }

  Widget _buildViewForState(BuildContext context, TestSetupState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is TestSetupConfigState) {
      return Scaffold(
        key: const ValueKey('config_view'),
        backgroundColor: colorScheme.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Thiết lập ôn tập',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                ?_buildPendingBanner(),
                Expanded(child: TestSetupView(state: state)),
              ],
            ),
            if (state.isGenerating)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: Card(
                    elevation: 4,
                    shape: StadiumBorder(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 3),
                          SizedBox(width: 16),
                          Text(
                            'Đang tạo bài ôn tập...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (state is TestSetupInProgressState) {
      final questions = state.testModel.questions;
      final isOnlyFlashcard =
          questions.isNotEmpty &&
          questions.every((q) => q.questionType == TestQuestionType.flashcard);

      if (isOnlyFlashcard) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return TestInProgressView(key: const ValueKey('in_progress_view'), state: state);
    }

    if (state is TestSetupCompletedState) {
      return TestCompletedView(key: const ValueKey('completed_view'), state: state);
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Nhắc phiên đang dở (đã thoát hoặc tắt app giữa chừng).
class _PendingBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const _PendingBanner({required this.title, required this.subtitle, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: cs.onPrimaryContainer, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer),
            ),
          ],
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      ),
    );
  }
}
