import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/test_in_progress_app_bar.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/test_in_progress_bottom_bar.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/multiple_choice_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/true_false_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/fill_in_the_blank_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/matching_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/dictation_screen.dart';

class TestInProgressView extends StatefulWidget {
  final TestSetupInProgressState state;

  const TestInProgressView({super.key, required this.state});

  @override
  State<TestInProgressView> createState() => _TestInProgressViewState();
}

class _TestInProgressViewState extends State<TestInProgressView> {
  dynamic _localAnswer;

  @override
  void initState() {
    super.initState();
    _resetLocalAnswer();
  }

  @override
  void didUpdateWidget(covariant TestInProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentQuestionIndex != widget.state.currentQuestionIndex) {
      _resetLocalAnswer();
    }
  }

  void _resetLocalAnswer() {
    final state = widget.state;
    final idx = state.currentQuestionIndex;
    _localAnswer = state.answersMap[idx];
  }

  void _onAnswerSelected(dynamic value) {
    setState(() {
      _localAnswer = value;
    });
  }

  bool _isAnswerInputValid() {
    if (_localAnswer == null) return false;
    final question = widget.state.questions[widget.state.currentQuestionIndex];
    if (question.questionType == TestQuestionType.fillInTheBlank ||
        question.questionType == TestQuestionType.dictation) {
      final s = _localAnswer as String?;
      return s != null && s.trim().isNotEmpty;
    }
    if (question.questionType == TestQuestionType.matching) {
      final m = _localAnswer as Map<String, String>?;
      final leftList = question.leftColumn;
      return m != null && m.length == leftList.length;
    }
    return true;
  }

  Future<bool> _showExitConfirmationDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Thoát bài ôn tập?'),
        content: const Text(
          'Tiến trình ôn tập hiện tại của bạn sẽ bị hủy bỏ và không được lưu lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Tiếp tục làm',
              style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = widget.state;

    final index = state.currentQuestionIndex;
    final total = state.questions.length;
    final question = state.questions[index];

    final isAnswerChecked = state.isAnswerCheckedMap[index] ?? false;
    final showAnswerInstantly = state.testModel.settings?['showAnswerInstantly'] == true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && context.mounted) {
          context.read<TestSetupBloc>().add(const TestSetupReset());
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        appBar: TestInProgressAppBar(state: state),
        body: SafeArea(
          child: Column(
            children: [
              // Main content scroll area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: KeyedSubtree(
                    key: ValueKey<int>(index),
                    child: _buildQuestionBody(question, isAnswerChecked),
                  ),
                ),
              ),
              // Bottom persistent action bar
              TestInProgressBottomBar(
                showAnswerInstantly: showAnswerInstantly,
                isAnswerChecked: isAnswerChecked,
                isValid: _isAnswerInputValid(),
                index: index,
                total: total,
                localAnswer: _localAnswer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionBody(TestQuestionModel question, bool isAnswerChecked) {
    switch (question.questionType) {
      case TestQuestionType.multipleChoice:
        return MultipleChoiceBody(
          question: question,
          selectedIndex: _localAnswer as int?,
          isChecked: isAnswerChecked,
          onSelected: _onAnswerSelected,
        );
      case TestQuestionType.trueFalse:
        return TrueFalseBody(
          question: question,
          selectedValue: _localAnswer as bool?,
          isChecked: isAnswerChecked,
          onSelected: _onAnswerSelected,
        );
      case TestQuestionType.fillInTheBlank:
        return FillInTheBlankBody(
          question: question,
          enteredText: _localAnswer as String?,
          isChecked: isAnswerChecked,
          onChanged: _onAnswerSelected,
        );
      case TestQuestionType.dictation:
        return DictationBody(
          question: question,
          enteredText: _localAnswer as String?,
          isChecked: isAnswerChecked,
          onChanged: _onAnswerSelected,
        );
      case TestQuestionType.matching:
        return MatchingBody(
          question: question,
          currentMatches: _localAnswer as Map<String, String>?,
          isChecked: isAnswerChecked,
          onMatchesChanged: _onAnswerSelected,
        );
      case TestQuestionType.flashcard:
        return const Center(child: Text('Loại câu hỏi Flashcard'));
    }
  }
}
