import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'common_question_widgets.dart';

class MultipleChoiceBody extends StatelessWidget {
  final TestQuestionModel question;
  final int? selectedIndex;
  final bool isChecked;
  final ValueChanged<int> onSelected;

  const MultipleChoiceBody({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.isChecked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final prompt = question.prompt;
    final imageUrl = question.promptImageUrl;
    final options = question.options;
    final correctId = question.cardId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHỌN ĐÁP ÁN ĐÚNG',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        buildPromptContainer(context, prompt, imageUrl, question.promptImageCredit),
        const SizedBox(height: 32),
        ...List.generate(options.length, (index) {
          final option = options[index];
          final optionId = option['id']?.toString() ?? '';
          final optionText = option['text']?.toString() ?? '';

          final isSelected = selectedIndex == index;
          final isCorrectOption = optionId == correctId;

          Color borderColor = colorScheme.outline.withValues(alpha: 0.25);
          Color bgColor = colorScheme.surface;
          Color textColor = colorScheme.onSurface;

          if (isChecked) {
            if (isCorrectOption) {
              borderColor = Colors.green.shade600;
              bgColor = Colors.green.shade50;
              textColor = Colors.green.shade900;
            } else if (isSelected) {
              borderColor = colorScheme.error;
              bgColor = colorScheme.errorContainer.withValues(alpha: 0.3);
              textColor = colorScheme.error;
            }
          } else if (isSelected) {
            borderColor = colorScheme.primary;
            bgColor = colorScheme.primaryContainer.withValues(alpha: 0.15);
            textColor = colorScheme.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: isChecked ? null : () => onSelected(index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (isChecked && isCorrectOption) ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    optionText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: isSelected || (isChecked && isCorrectOption)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
