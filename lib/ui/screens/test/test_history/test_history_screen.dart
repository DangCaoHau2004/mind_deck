import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/ui/screens/test/test_history/bloc/test_history_bloc.dart';
import 'package:mind_deck/ui/screens/test/test_history/bloc/test_history_event.dart';
import 'package:mind_deck/ui/screens/test/test_history/bloc/test_history_state.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TestHistoryBloc>().add(const TestHistoryInitialized());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Lịch sử ôn tập',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<TestHistoryBloc, TestHistoryState>(
        builder: (context, state) {
          if (state.status == TestHistoryStatus.loading ||
              state.status == TestHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TestHistoryStatus.failure && state.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  state.errorMessage!,
                  style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state.historyAttempts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TestHistoryBloc>().add(const TestHistoryRefreshed());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có lịch sử làm bài ôn tập.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Các bài kiểm tra đã làm sẽ hiển thị ở đây.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TestHistoryBloc>().add(const TestHistoryRefreshed());
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: state.historyAttempts.length,
              itemBuilder: (context, idx) {
                final attempt = state.historyAttempts[idx];
                final test = attempt.test;
                if (test == null) return const SizedBox.shrink();

                final total = attempt.totalQuestions;
                final correct = attempt.correctAnswers;
                final pct = total > 0 ? (correct / total) * 100 : 0.0;

                Color scoreColor = Colors.red.shade600;
                if (pct >= 80) {
                  scoreColor = Colors.green.shade600;
                } else if (pct >= 50) {
                  scoreColor = Colors.orange.shade600;
                }

                final durationMs = attempt.durationMs;
                String durationText = 'N/A';
                if (durationMs != null) {
                  final seconds = (durationMs / 1000).round();
                  if (seconds >= 60) {
                    durationText = '${seconds ~/ 60}m ${seconds % 60}s';
                  } else {
                    durationText = '${seconds}s';
                  }
                }

                final date = attempt.completedAt ?? attempt.startedAt;
                final formattedDate =
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                test.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: scoreColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$correct / $total',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: scoreColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              durationText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Điểm số: ${pct.toStringAsFixed(1)}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // Will navigate and pass data to test_setup in the router later.
                              },
                              icon: const Icon(Icons.replay_rounded, size: 16),
                              label: const Text('Ôn lại bài này'),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
