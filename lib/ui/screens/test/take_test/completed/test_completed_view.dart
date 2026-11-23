import 'package:flutter/material.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/completed/widgets/test_result_header_card.dart';
import 'package:mind_deck/ui/screens/test/take_test/completed/widgets/test_result_stats_row.dart';
import 'package:mind_deck/ui/screens/test/take_test/completed/widgets/test_result_answer_review_card.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/services/ad_service.dart';

class TestCompletedView extends StatelessWidget {
  final TestSetupCompletedState state;

  const TestCompletedView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kết quả ôn tập',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                children: [
                  // 1. Congratulations Header Card
                  TestResultHeaderCard(state: state),
                  const SizedBox(height: 28),

                  // 2. Metrics Row & Duration Card
                  TestResultStatsRow(state: state),

                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),
                  Text(
                    'CHI TIẾT CÂU HỎI',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Detailed Questions List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.questions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final q = state.questions[idx];
                      final isCorrect = state.answersCorrectnessMap[idx] ?? false;

                      return TestResultAnswerReviewCard(
                        index: idx,
                        question: q,
                        userAnswer: state.answersMap[idx],
                        isCorrect: isCorrect,
                      );
                    },
                  ),
                ],
              ),
            ),

            // 4. Bottom bar (Done action)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.08))),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await DI().sl<AdService>().showInterstitial(AdUnit.interstitialTestResult);
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'HOÀN THÀNH',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
