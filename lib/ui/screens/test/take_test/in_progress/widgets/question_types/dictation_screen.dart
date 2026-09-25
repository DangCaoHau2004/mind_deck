import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/services/tts_service.dart';

class DictationBody extends StatefulWidget {
  final TestQuestionModel question;
  final String? enteredText;
  final bool isChecked;
  final ValueChanged<String> onChanged;

  const DictationBody({
    super.key,
    required this.question,
    required this.enteredText,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  State<DictationBody> createState() => _DictationBodyState();
}

class _DictationBodyState extends State<DictationBody> with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late AnimationController _waveController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.enteredText ?? '');
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(covariant DictationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enteredText != _controller.text) {
      _controller.text = widget.enteredText ?? '';
    }
    // Ngắt audio ngay khi ấn "Kiểm tra"
    if (widget.isChecked && !oldWidget.isChecked) {
      _stopAudio();
    }
  }

  @override
  void dispose() {
    // Ngắt hoàn toàn khi widget bị huỷ (ấn "Tiếp tục" chuyển câu)
    DI().sl<TTSService>().stop();
    _controller.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _stopAudio() {
    DI().sl<TTSService>().stop();
    if (mounted && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      _waveController.stop();
    }
  }

  void _playAudio() async {
    final tts = DI().sl<TTSService>();

    if (_isPlaying) {
      _stopAudio();
      return;
    }

    setState(() {
      _isPlaying = true;
    });
    _waveController.repeat(reverse: true);

    final expected = widget.question.expectedText;

    try {
      await tts.speak(expected);
    } catch (e) {
      // Ignore if TTS fails, just fallback to stopping the animation
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
      _waveController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final expected = widget.question.expectedText;
    final isCorrect = widget.question.checkAnswer(widget.enteredText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NGHE VÀ VIẾT LẠI',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _playAudio,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? colorScheme.primary
                        : colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: _isPlaying ? 0.3 : 0.1),
                        blurRadius: _isPlaying ? 20 : 10,
                        spreadRadius: _isPlaying ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                    size: 44,
                    color: _isPlaying ? Colors.white : colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Simple animated sound waves simulation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      double height = 4.0;
                      if (_isPlaying) {
                        final factor = (index == 0 || index == 4) ? 0.4 : (index == 2 ? 1.0 : 0.7);
                        height = 4 + (_waveController.value * 20 * factor);
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 4,
                        height: height,
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        TextField(
          controller: _controller,
          enabled: !widget.isChecked,
          onChanged: widget.onChanged,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Nhập những gì bạn nghe được...',
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
