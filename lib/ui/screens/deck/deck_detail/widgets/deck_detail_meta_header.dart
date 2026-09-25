import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';

class DeckDetailMetaHeader extends StatelessWidget {
  final DeckModel deck;
  final Color mainThemeColor;

  const DeckDetailMetaHeader({
    super.key,
    required this.deck,
    required this.mainThemeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              deck.isPublic ? Icons.public_rounded : Icons.lock_rounded,
              size: 20,
              color: colorScheme.outline,
            ),
            const SizedBox(width: 6),
            Text(
              deck.isPublic
                  ? 'Công khai • ${deck.savedCount} lượt lưu'
                  : 'Riêng tư',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const Spacer(),
            Text(
              'Tổng: ${deck.cardCount} Thẻ',
              style: theme.textTheme.titleSmall?.copyWith(
                color: mainThemeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: deck.goalType == GoalType.shortTerm
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: deck.goalType == GoalType.shortTerm
                  ? const Color(0xFFFFB74D)
                  : const Color(0xFF81C784),
            ),
          ),
          child: Row(
            children: [
              Icon(
                deck.goalType == GoalType.shortTerm
                    ? Icons.timer_rounded
                    : Icons.all_inclusive_rounded,
                color: deck.goalType == GoalType.shortTerm
                    ? const Color(0xFFF57C00)
                    : const Color(0xFF388E3C),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.goalType == GoalType.shortTerm
                        ? 'Trí nhớ ngắn hạn (Ôn thi)'
                        : 'Trí nhớ vĩnh cửu',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: deck.goalType == GoalType.shortTerm
                          ? const Color(0xFFF57C00)
                          : const Color(0xFF388E3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (deck.goalType == GoalType.shortTerm && deck.deadline != null)
                    Text(
                      'Hoàn thành trước: ${DateFormat('dd/MM/yyyy').format(deck.deadline!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFE65100),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        if (deck.authorName != null && deck.authorName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.person, size: 16, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tác giả: ${deck.authorName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
