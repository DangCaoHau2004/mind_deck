import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'common_question_widgets.dart';

class TrueFalseBody extends StatelessWidget {
  final TestQuestionModel question;
  final bool? selectedValue;
  final bool isChecked;
  final ValueChanged<bool> onSelected;

  const TrueFalseBody({
    super.key,
    required this.question,
    required this.selectedValue,
    required this.isChecked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final prompt = question.prompt;
    final statement = question.statement;
    final imageUrl = question.promptImageUrl;
    final expected = question.isTrueFalseExpected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ĐÚNG HAY SAI?',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        buildPromptContainer(context, prompt, imageUrl),
        if (statement.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              statement,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: _buildTFButton(
                context: context,
                value: true,
                label: 'ĐÚNG',
                icon: Icons.check_circle_outline_rounded,
                expected: expected,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTFButton(
                context: context,
                value: false,
                label: 'SAI',
                icon: Icons.cancel_outlined,
                expected: expected,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTFButton({
    required BuildContext context,
    required bool value,
    required String label,
    required IconData icon,
    required bool expected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSelected = selectedValue == value;
    final isCorrect = value == expected;

    Color borderColor = colorScheme.outline.withValues(alpha: 0.25);
    Color bgColor = colorScheme.surface;
    Color iconColor = colorScheme.outline;
    Color textColor = colorScheme.onSurface;

    if (isChecked) {
      if (isCorrect) {
        borderColor = Colors.green.shade600;
        bgColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        textColor = Colors.green.shade900;
      } else if (isSelected) {
        borderColor = colorScheme.error;
        bgColor = colorScheme.errorContainer.withValues(alpha: 0.3);
        iconColor = colorScheme.error;
        textColor = colorScheme.error;
      }
    } else if (isSelected) {
      borderColor = colorScheme.primary;
      bgColor = colorScheme.primaryContainer.withValues(alpha: 0.15);
      iconColor = colorScheme.primary;
      textColor = colorScheme.primary;
    }

    return InkWell(
      onTap: isChecked ? null : () => onSelected(value),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: isSelected || (isChecked && isCorrect) ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
