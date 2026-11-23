import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/home/home_recent_deck_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/core/theme/app_styles.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Danh sách ngang các bộ thẻ học gần đây.
class RecentLearningList extends StatelessWidget {
  final List<HomeRecentDeckModel> items;

  const RecentLearningList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'home_recent_empty'.tr,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
      );
    }

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _RecentDeckCard(item: items[index]),
      ),
    );
  }
}

class _RecentDeckCard extends StatelessWidget {
  final HomeRecentDeckModel item;

  const _RecentDeckCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = ColorUtils.parseHex(item.color);
    final started = item.studiedCards > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyles.cardShadow(colorScheme),
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.pushNamed(AppRoute.deckDetail.name, pathParameters: {'id': item.id}),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(AppIcons.getIconFromKey(item.icon), color: accent, size: 22),
                    ),
                    const Spacer(),
                    Icon(Icons.play_circle_fill_rounded, color: accent, size: 28),
                  ],
                ),
                const Spacer(),
                Text(
                  item.name,
                  style: textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Cùng một bố cục cho mọi thẻ (chưa học thì thanh ở 0) để các thẻ thẳng hàng.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        started
                            ? 'home_deck_progress'.tr
                                  .replaceAll('{studied}', '${item.studiedCards}')
                                  .replaceAll('{total}', '${item.totalCards}')
                            : 'home_not_studied'.tr,
                        style: textTheme.bodyMedium?.copyWith(
                          color: started ? colorScheme.onSurfaceVariant : colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (started)
                      Text(
                        '${(item.progress * 100).round()}%',
                        style: textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 6,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
