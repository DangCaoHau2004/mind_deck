import 'package:flutter/material.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';

class TestResultStatsRow extends StatelessWidget {
  final TestSetupCompletedState state;

  const TestResultStatsRow({super.key, required this.state});

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 giây';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins phút $secs giây';
    }
    return '$secs giây';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = state.totalQuestions > 0
        ? (state.correctCount / state.totalQuestions * 100)
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context: context,
                value: '${state.correctCount}/${state.totalQuestions}',
                label: 'Số câu đúng',
                icon: Icons.check_circle_rounded,
                iconColor: Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                context: context,
                value: '${percent.toStringAsFixed(1)}%',
                label: 'Độ chính xác',
                icon: Icons.offline_bolt_rounded,
                iconColor: Colors.amber.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          context: context,
          value: _formatDuration(state.timeSpentSeconds),
          label: 'Thời gian làm bài',
          icon: Icons.timer_outlined,
          iconColor: colorScheme.primary,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool isWide = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Row(
      mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: content,
    );
  }
}
