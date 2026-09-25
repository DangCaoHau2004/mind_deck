import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';

class DiscoverRecommendedCard extends StatelessWidget {
  final DeckModel item;

  const DiscoverRecommendedCard({super.key, required this.item});

  Color _hexToColor(String? code) {
    if (code == null || code.isEmpty) return Colors.grey;
    if (code.startsWith('#')) {
      code = code.substring(1);
    }
    if (code.length == 6) {
      code = 'FF$code';
    }
    try {
      return Color(int.parse(code, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final cardColor = _hexToColor(item.color);

    return InkWell(
      onTap: () {
        context.pushNamed(
          AppRoute.deckDetail.name,
          pathParameters: {'id': item.id},
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 220 / 255),
              cardColor.withValues(alpha: 1.0),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 70 / 255),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.style_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 20 / 255),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white.withValues(
                                alpha: 60 / 255,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.authorName ?? 'Ẩn danh',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(
                                  alpha: 230 / 255,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 50 / 255),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.goalType == GoalType.longTerm
                                ? 'Dài hạn'
                                : 'Ngắn hạn',
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description!,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 200 / 255),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(
                      color: Colors.white.withValues(alpha: 40 / 255),
                      height: 1,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (item.tags != null)
                          ...List.generate(
                            item.tags!.take(2).length,
                            (index) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: 80 / 255,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "#${item.tags![index].name}",
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          Icons.style_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 200 / 255),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.cardCount ?? 0}',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.bookmark_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 200 / 255),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.savedCount}',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
