import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_state.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/widgets/class_test_completed_view.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/widgets/class_test_in_progress_view.dart';

class ClassTestScreen extends StatelessWidget {
  final String classId;
  final String assignmentId;
  final String testId;

  const ClassTestScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
    required this.testId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<ClassTestBloc>()
            ..add(ClassTestStarted(classId: classId, assignmentId: assignmentId, testId: testId)),
      child: const _ClassTestView(),
    );
  }
}

class _ClassTestView extends StatelessWidget {
  const _ClassTestView();

  Future<bool> _onWillPop(BuildContext context) async {
    final state = context.read<ClassTestBloc>().state;
    // Nếu đang submtitting hoặc đã success thì được phép pop
    if (state is ClassTestInProgressState && state.isSubmitting) return false;
    if (state is ClassTestInProgressState && state.isSuccess) return true;
    if (state is! ClassTestInProgressState) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cảnh báo'),
        content: const Text(
          'Các câu bạn đã trả lời được lưu tạm. Bạn có thể vào lại để làm tiếp, nhưng đồng hồ vẫn chạy '
          'và bài tự kết thúc khi hết giờ. Thoát ra lúc này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục làm bài'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Thoát', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context);
        if (shouldPop) {
          if (context.mounted) {
            context.pop(false);
          }
        }
      },
      child: BlocConsumer<ClassTestBloc, ClassTestState>(
        listener: (context, state) {
          if (state is ClassTestInProgressState) {
            if (state.errorMessage != null) {
              CustomToast.show(context, CustomToast.danger(message: state.errorMessage!));
            }
          } else if (state is ClassTestFailure) {
            CustomToast.show(context, CustomToast.danger(message: state.errorMessage));
          }
        },
        builder: (context, state) {
          // Khi đã thành công, hiển thị toàn bộ màn hình kết quả mới (ClassTestCompletedView là 1 Scaffold độc lập)
          if (state is ClassTestInProgressState && state.isSuccess) {
            return ClassTestCompletedView(state: state);
          }

          return Scaffold(
            appBar: AppBar(
              title: BlocBuilder<ClassTestBloc, ClassTestState>(
                builder: (context, state) {
                  if (state is ClassTestInProgressState && state.hasTimer && !state.isSuccess) {
                    final remaining = state.timeRemainingSeconds;
                    final minutes = (remaining / 60).floor().toString().padLeft(2, '0');
                    final seconds = (remaining % 60).toString().padLeft(2, '0');
                    return Text(
                      'Thời gian: $minutes:$seconds',
                      style: TextStyle(
                        color: remaining <= 60 ? Colors.red : null,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return const Text('Làm Bài Tập');
                },
              ),
              centerTitle: true,
            ),
            body: () {
              if (state is ClassTestInitial || state is ClassTestLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ClassTestFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Về danh sách bài tập; trả `true` để danh sách tải lại (bài có thể đã đổi / bị xóa).
                        OutlinedButton(
                          onPressed: () => context.pop(true),
                          child: const Text('Về danh sách bài tập'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ClassTestInProgressState) {
                if (state.isSubmitting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang nộp bài...'),
                      ],
                    ),
                  );
                }

                final questions = state.questions;
                final index = state.currentQuestionIndex;

                if (index >= questions.length) {
                  // Đã trả lời hết nhưng nộp chưa thành công (lỗi mạng...): cho nộp lại.
                  return _SubmitRetryView(state: state);
                }

                return ClassTestInProgressView(state: state);
              }

              return const SizedBox.shrink();
            }(),
          );
        },
      ),
    );
  }
}

/// Nộp bài thất bại vì lỗi tạm thời: bài làm vẫn còn trong máy, phiên vẫn còn trên server
/// (đến `expiresAt` + 60 giây), nên cho người dùng bấm nộp lại.
class _SubmitRetryView extends StatelessWidget {
  final ClassTestInProgressState state;

  const _SubmitRetryView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = state.answersMap.length;
    final total = state.questions.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Chưa nộp được bài',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã làm $answered/$total câu. Bài làm vẫn được giữ trên máy, '
              'hãy kiểm tra kết nối rồi nộp lại trước khi hết hạn.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<ClassTestBloc>().add(const ClassTestSubmitRequested()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Nộp lại'),
            ),
          ],
        ),
      ),
    );
  }
}
