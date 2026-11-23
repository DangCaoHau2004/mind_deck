import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/stats_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/screens/profile/stats_overview/widgets/stats_widgets.dart';

/// Độ nhớ trung bình (R, S) và số thẻ nguy cơ quên.
class MemorySection extends StatelessWidget {
  final MemoryStats memory;
  const MemorySection({super.key, required this.memory});

  String _percent(double? v) => v == null ? '--' : '${(v * 100).round()}%';

  String _days(double? v) {
    if (v == null) return '--';
    final text = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '$text ngày';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final thresholdPercent = (memory.atRiskThreshold * 100).round();

    return buildCardContainer(
      context,
      'Độ nhớ',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Khả năng nhớ TB (R)',
                  value: _percent(memory.avgRetrievability),
                ),
              ),
              Expanded(
                child: _MiniStat(label: 'Độ bền TB (S)', value: _days(memory.avgStabilityDays)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: memory.atRiskCount > 0
                  ? colorScheme.errorContainer.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              memory.reviewedCards == 0
                  ? 'Chưa học thẻ nào nên chưa có độ nhớ.'
                  : 'Nguy cơ quên (R < $thresholdPercent%): ${memory.atRiskCount} / '
                        '${memory.reviewedCards} thẻ đã học',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: memory.atRiskCount > 0
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Phân bố trạng thái thẻ: thanh xếp chồng + chú thích số lượng.
class CardStatesSection extends StatelessWidget {
  final FSRSStatsModel cardStates;
  const CardStatesSection({super.key, required this.cardStates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final segments = <(String, int, Color)>[
      ('Mới', cardStates.newCards, Colors.blue),
      ('Đang học', cardStates.learning, Colors.orange),
      ('Ôn lại', cardStates.review, Colors.green),
      ('Học lại', cardStates.relearning, Colors.red),
      ('Đã thuộc', cardStates.mastered, Colors.purple),
    ];
    final total = cardStates.total;

    return buildCardContainer(
      context,
      'Trạng thái thẻ',
      total == 0
          ? Text(
              'Bạn chưa có thẻ nào.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        for (final s in segments)
                          if (s.$2 > 0)
                            Expanded(
                              flex: s.$2,
                              child: ColoredBox(color: s.$3),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    for (final s in segments)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('${s.$1}: ${s.$2}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng: $total thẻ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Thẻ đến hạn (hôm nay + quá hạn) và số thẻ đã ôn hôm nay.
class DueNowSection extends StatelessWidget {
  final DueNowStats dueNow;
  final int studiedToday;
  const DueNowSection({super.key, required this.dueNow, required this.studiedToday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _tile(
            theme,
            title: 'Đến hạn',
            value: '${dueNow.total}',
            caption: dueNow.overdue > 0
                ? 'Hôm nay ${dueNow.dueToday} · quá hạn ${dueNow.overdue}'
                : 'Hôm nay ${dueNow.dueToday}',
            color: dueNow.total > 0 ? colorScheme.error : colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _tile(
            theme,
            title: 'Đã ôn hôm nay',
            value: '$studiedToday',
            caption: 'thẻ khác nhau',
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _tile(
    ThemeData theme, {
    required String title,
    required String value,
    required String caption,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Bài giao chưa xong trong 7 ngày tới. Bấm một bài hoặc dòng "còn N bài" → danh sách lớp.
class AssignmentsSection extends StatelessWidget {
  final AssignmentsOverview overview;
  const AssignmentsSection({super.key, required this.overview});

  void _openClasses(BuildContext context) => context.pushNamed(AppRoute.classrooms.name);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return buildCardContainer(
      context,
      'Bài giao sắp hết hạn',
      overview.items.isEmpty
          ? Text(
              'Không có bài giao nào trong 7 ngày tới.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overview.dueTodayCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Hết hạn hôm nay: ${overview.dueTodayCount} bài',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final a in overview.items) ...[
                  _AssignmentRow(item: a, onTap: () => _openClasses(context)),
                  Divider(color: colorScheme.surfaceContainerHigh, height: 1),
                ],
                if (overview.hiddenCount > 0)
                  InkWell(
                    onTap: () => _openClasses(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Còn ${overview.hiddenCount} bài khác trong 7 ngày tới · xem trong danh sách lớp',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final OpenAssignmentModel item;
  final VoidCallback onTap;
  const _AssignmentRow({required this.item, required this.onTap});

  String _typeLabel() => item.isTest ? 'Kiểm tra' : 'Bài học';

  String _endText() {
    final d = item.endAt;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return item.endsToday ? 'Hôm nay $hh:$mm' : '$dd/$mo $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = item.progress;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.className} · ${_typeLabel()}'
                    '${progress != null ? ' · ${progress.done}/${progress.target} thẻ' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _endText(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: item.endsToday ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
