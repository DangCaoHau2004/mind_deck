import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/test_setup_view.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/test_in_progress_view.dart';
import 'package:mind_deck/ui/screens/test/take_test/completed/test_completed_view.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/utils/study_flow_helper.dart';

class TakeTestScreen extends StatefulWidget {
  const TakeTestScreen({super.key});

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestSetupBloc, TestSetupState>(
      listener: (context, state) {
        if (state is TestSetupConfigState && state.errorMessage != null) {
          CustomToast.show(
            context,
            CustomToast.danger(message: state.errorMessage!),
          );
        }
        if (state is TestSetupInProgressState) {
          final questions = state.testModel.questions;
          final isOnlyFlashcard =
              questions.isNotEmpty && questions.every((q) => q.questionType == TestQuestionType.flashcard);

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
            TestSetupView(state: state),
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
          questions.isNotEmpty && questions.every((q) => q.questionType == TestQuestionType.flashcard);

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
