import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/home/home_fsrs_stats_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/screens/home/widgets/memory_stat_row.dart';

/// Số thẻ cần ôn hôm nay + nút "Ôn ngay" + các chỉ số trí nhớ, nền màu chính.
class ReviewTodayCard extends StatelessWidget {
  final HomeFsrsStatsModel stats;

  const ReviewTodayCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final due = stats.dueTodayCount;
    final retention = stats.avgRetrievability;
    final onCard = colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home_due_title'.tr,
                      style: textTheme.titleMedium?.copyWith(color: onCard.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$due',
                            style: textTheme.displaySmall?.copyWith(
                              color: onCard,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' ${'home_cards_unit'.tr}',
                            style: textTheme.titleMedium?.copyWith(color: onCard),
                          ),
                        ],
                      ),
                    ),
                    if (due == 0)
                      Text(
                        'home_due_empty'.tr,
                        style: textTheme.bodyMedium?.copyWith(color: onCard.withValues(alpha: 0.9)),
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  disabledBackgroundColor: onCard.withValues(alpha: 0.25),
                  disabledForegroundColor: onCard.withValues(alpha: 0.7),
                  textStyle: textTheme.labelLarge,
                ),
                onPressed: due > 0 ? () => context.pushNamed(AppRoute.testSetup.name) : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('home_review_now'.tr),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MemoryStatRow(
            items: [
              MemoryStatItem(
                icon: Icons.verified_outlined,
                value: '${stats.masteredCount}',
                label: 'home_mastered'.tr,
                info: 'home_mastered_info'.tr,
              ),
              MemoryStatItem(
                icon: Icons.psychology_outlined,
                value: retention == null ? 'home_not_studied'.tr : '${(retention * 100).round()}%',
                label: 'home_avg_retention'.tr,
                info: 'home_avg_retention_info'.tr,
              ),
              MemoryStatItem(
                icon: Icons.trending_down_rounded,
                value: '${stats.atRiskCount}',
                label: 'home_at_risk'.tr,
                info: 'home_at_risk_info'.tr.replaceAll(
                  '{threshold}',
                  '${(stats.atRiskThreshold * 100).round()}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
