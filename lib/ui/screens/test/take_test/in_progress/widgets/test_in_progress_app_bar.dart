import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';

class TestInProgressAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TestSetupInProgressState state;

  const TestInProgressAppBar({super.key, required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatTimer(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    final minsStr = mins.toString().padLeft(2, '0');
    final secsStr = secs.toString().padLeft(2, '0');
    return '$minsStr:$secsStr';
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final index = state.currentQuestionIndex;
    final total = state.questions.length;

    final hasTimeLimit =
        state.timeRemainingSeconds > 0 || state.testModel.settings?['timeLimitEnabled'] == true;
    final isLowTime = hasTimeLimit && state.timeRemainingSeconds <= 60;
    final progress = (index + 1) / total;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: colorScheme.onSurface, size: 28),
        onPressed: () async {
          final shouldPop = await _showExitConfirmationDialog(context);
          if (shouldPop && context.mounted) {
            context.read<TestSetupBloc>().add(const TestSetupReset());
          }
        },
      ),
      title: Column(
        children: [
          Text(
            'Câu ${index + 1} / $total',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          // Thin linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 140,
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (hasTimeLimit)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLowTime
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLowTime ? colorScheme.error : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isLowTime ? colorScheme.error : colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimer(state.timeRemainingSeconds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLowTime ? colorScheme.error : colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
