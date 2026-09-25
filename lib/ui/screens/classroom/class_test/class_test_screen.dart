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
          'Bạn đang làm bài thi. Thoát ra lúc này kết quả sẽ không được lưu. Chắc chắn thoát?',
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
                  if (state is ClassTestInProgressState) {
                    final remaining = state.timeRemainingSeconds;
                    if (remaining > 0) {
                      final minutes = (remaining / 60).floor().toString().padLeft(2, '0');
                      final seconds = (remaining % 60).toString().padLeft(2, '0');
                      return Text(
                        'Thời gian: $minutes:$seconds',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      );
                    }
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
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
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
                  // Hết câu hỏi và đang chờ xử lý nộp bài
                  return const Center(child: CircularProgressIndicator());
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
