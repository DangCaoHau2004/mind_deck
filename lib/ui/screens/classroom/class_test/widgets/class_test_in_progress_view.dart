import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_test/bloc/class_test_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/multiple_choice_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/true_false_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/fill_in_the_blank_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/matching_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/in_progress/widgets/question_types/dictation_screen.dart';

class ClassTestInProgressView extends StatefulWidget {
  final ClassTestInProgressState state;

  const ClassTestInProgressView({super.key, required this.state});

  @override
  State<ClassTestInProgressView> createState() => _ClassTestInProgressViewState();
}

class _ClassTestInProgressViewState extends State<ClassTestInProgressView> {
  dynamic _localAnswer;

  @override
  void initState() {
    super.initState();
    _resetLocalAnswer();
  }

  @override
  void didUpdateWidget(covariant ClassTestInProgressView oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final questions = state.questions;
    final index = state.currentQuestionIndex;

    if (index >= questions.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Bạn đã hoàn thành tất cả câu hỏi!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<ClassTestBloc>().add(const ClassTestSubmitRequested());
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: Colors.blue,
              ),
              child: const Text('Nộp Bài', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      );
    }

    final question = questions[index];
    final isAnswerChecked = state.answersMap.containsKey(index);

    Widget child;
    switch (question.questionType) {
      case TestQuestionType.multipleChoice:
        child = MultipleChoiceBody(
          question: question,
          selectedIndex: _localAnswer as int?,
          isChecked: isAnswerChecked,
          onSelected: _onAnswerSelected,
        );
        break;
      case TestQuestionType.trueFalse:
        child = TrueFalseBody(
          question: question,
          selectedValue: _localAnswer as bool?,
          isChecked: isAnswerChecked,
          onSelected: _onAnswerSelected,
        );
        break;
      case TestQuestionType.fillInTheBlank:
        child = FillInTheBlankBody(
          question: question,
          enteredText: _localAnswer as String?,
          isChecked: isAnswerChecked,
          onChanged: _onAnswerSelected,
        );
        break;
      case TestQuestionType.matching:
        child = MatchingBody(
          question: question,
          currentMatches: _localAnswer as Map<String, String>?,
          isChecked: isAnswerChecked,
          onMatchesChanged: _onAnswerSelected,
        );
        break;
      case TestQuestionType.dictation:
        child = DictationBody(
          question: question,
          enteredText: _localAnswer as String?,
          isChecked: isAnswerChecked,
          onChanged: _onAnswerSelected,
        );
        break;
      default:
        child = Center(
          child: Text('Loại câu hỏi chưa hỗ trợ: ${question.questionType.title}'),
        );
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: (index) / questions.length,
          backgroundColor: Colors.grey.shade200,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Câu ${index + 1} / ${questions.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: child),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAnswerInputValid()
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: _isAnswerInputValid()
                  ? Colors.white
                  : Theme.of(context).colorScheme.outline,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
            ),
            onPressed: _isAnswerInputValid()
                ? () {
                    final durationMs = DateTime.now()
                        .difference(state.currentQuestionStartedAt)
                        .inMilliseconds;
                    context.read<ClassTestBloc>().add(
                      ClassTestAnswerSelected(
                        questionIndex: index,
                        answer: _localAnswer,
                        isCorrect: question.checkAnswer(_localAnswer),
                        durationMs: durationMs,
                      ),
                    );
                  }
                : null,
            child: Text(
              index == questions.length - 1 ? 'NỘP BÀI' : 'TIẾP TỤC',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: _isAnswerInputValid()
                    ? Colors.white
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
