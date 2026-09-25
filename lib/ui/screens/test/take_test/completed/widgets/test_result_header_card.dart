import 'package:flutter/material.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';

class TestResultHeaderCard extends StatelessWidget {
  final TestSetupCompletedState state;

  const TestResultHeaderCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final percent = state.totalQuestions > 0
        ? (state.correctCount / state.totalQuestions * 100)
        : 0.0;
    final isPass = percent >= 50.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPass
              ? [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)]
              : [colorScheme.error, colorScheme.error.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isPass ? colorScheme.primary : colorScheme.error).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPass
                ? Icons.emoji_events_rounded
                : Icons.sentiment_very_dissatisfied_rounded,
            size: 72,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isPass ? 'HOÀN THÀNH XUẤT SẮC!' : 'CẦN CỐ GẮNG HƠN!',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.testModel.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
