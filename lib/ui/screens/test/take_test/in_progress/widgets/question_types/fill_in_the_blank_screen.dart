import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'common_question_widgets.dart';

class FillInTheBlankBody extends StatefulWidget {
  final TestQuestionModel question;
  final String? enteredText;
  final bool isChecked;
  final ValueChanged<String> onChanged;

  const FillInTheBlankBody({
    super.key,
    required this.question,
    required this.enteredText,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  State<FillInTheBlankBody> createState() => _FillInTheBlankBodyState();
}

class _FillInTheBlankBodyState extends State<FillInTheBlankBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.enteredText ?? '');
  }

  @override
  void didUpdateWidget(covariant FillInTheBlankBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enteredText != _controller.text) {
      _controller.text = widget.enteredText ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final prompt = widget.question.prompt;
    final imageUrl = widget.question.promptImageUrl;
    final expected = widget.question.expectedText;

    final isCorrect = widget.question.checkAnswer(widget.enteredText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ĐIỀN TỪ CÒN THIẾU',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        buildPromptContainer(context, prompt, imageUrl, widget.question.promptImageCredit),
        const SizedBox(height: 32),
        TextField(
          controller: _controller,
          enabled: !widget.isChecked,
          onChanged: widget.onChanged,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Nhập câu trả lời...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            filled: true,
            fillColor: widget.isChecked
                ? (isCorrect
                      ? Colors.green.shade50
                      : colorScheme.errorContainer.withValues(alpha: 0.2))
                : colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorText: widget.isChecked && !isCorrect ? 'Đáp án đúng: $expected' : null,
            errorStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
            suffixIcon: widget.isChecked
                ? Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? Colors.green.shade600 : colorScheme.error,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
