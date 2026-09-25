import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/utils/color_utils.dart';

class DeckItemWidget extends StatelessWidget {
  final DeckModel deck;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStarTap;

  const DeckItemWidget({
    super.key,
    required this.deck,
    required this.isSelected,
    required this.isSelectionMode,
    this.onTap,
    this.onLongPress,
    this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColor = ColorUtils.parseHex(deck.color);
    final bool isLight = ColorUtils.isLightColor(themeColor);
    final Color contentColor = ColorUtils.getContrastColor(themeColor);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 12, left: 24, right: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isSelected ? themeColor.withValues(alpha: 0.8) : themeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(30),
                ),
                border: isSelected
                    ? Border.all(color: contentColor, width: 2)
                    : (isLight ? Border.all(color: Colors.grey.shade300, width: 1) : null),
                boxShadow: [
                  BoxShadow(
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.05)
                        : themeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 50.0),
                    child: Text(
                      deck.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${deck.cardCount ?? deck.flashcards?.length ?? 0} thẻ',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: contentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (deck.goalType == GoalType.longTerm)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Dài hạn',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: contentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (deck.goalType == GoalType.shortTerm)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ngắn hạn',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: contentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (deck.tags != null && deck.tags!.isNotEmpty)
                        ...deck.tags!
                            .take(2)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? Colors.black.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#${tag.name}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: contentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                      if (deck.tags != null && deck.tags!.length > 2)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${deck.tags!.length - 2}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: contentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -12,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4CAF50) : themeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (isLight ? Colors.grey.shade300 : Colors.white),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isSelected ? Icons.check_rounded : AppIcons.getIconFromKey(deck.icon),
                      color: contentColor,
                      size: 24,
                    ),
                  ),
                  if (onStarTap != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onStarTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          deck.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amberAccent,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
