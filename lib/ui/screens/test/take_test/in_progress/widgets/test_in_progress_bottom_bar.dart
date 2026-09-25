import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';

class TestInProgressBottomBar extends StatelessWidget {
  final bool showAnswerInstantly;
  final bool isAnswerChecked;
  final bool isValid;
  final int index;
  final int total;
  final dynamic localAnswer;

  const TestInProgressBottomBar({
    super.key,
    required this.showAnswerInstantly,
    required this.isAnswerChecked,
    required this.isValid,
    required this.index,
    required this.total,
    required this.localAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLast = index == total - 1;

    Widget actionButton;

    if (showAnswerInstantly) {
      if (!isAnswerChecked) {
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            foregroundColor: isValid ? Colors.white : colorScheme.outline,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size(double.infinity, 56),
            elevation: 0,
          ),
          onPressed: isValid
              ? () {
                  context.read<TestSetupBloc>().add(TestSetupAnswerSubmitted(localAnswer));
                }
              : null,
          child: Text(
            'KIỂM TRA',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isValid ? Colors.white : colorScheme.outline,
            ),
          ),
        );
      } else {
        actionButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size(double.infinity, 56),
            elevation: 0,
          ),
          onPressed: () {
            if (isLast) {
              context.read<TestSetupBloc>().add(const TestSetupSubmitRequested());
            } else {
              context.read<TestSetupBloc>().add(const TestSetupNextQuestionRequested());
            }
          },
          child: Text(
            isLast ? 'NỘP BÀI' : 'TIẾP TỤC',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      }
    } else {
      // Direct progression, submit then next
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          foregroundColor: isValid ? Colors.white : colorScheme.outline,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
        ),
        onPressed: isValid
            ? () {
                context.read<TestSetupBloc>().add(TestSetupAnswerSubmitted(localAnswer));
                if (isLast) {
                  context.read<TestSetupBloc>().add(const TestSetupSubmitRequested());
                } else {
                  context.read<TestSetupBloc>().add(const TestSetupNextQuestionRequested());
                }
              }
            : null,
        child: Text(
          isLast ? 'NỘP BÀI' : 'TIẾP TỤC',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isValid ? Colors.white : colorScheme.outline,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.08))),
      ),
      child: actionButton,
    );
  }
}
