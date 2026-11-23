import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/card_state_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';

/// Thẻ "Trạng thái ghi nhớ (FSRS)": một thanh chia đoạn theo tỉ lệ số thẻ ở từng trạng thái, bên dưới là
/// số lượng và tên trạng thái.
class DeckDetailFsrsSummary extends StatelessWidget {
  final DeckModel deck;

  const DeckDetailFsrsSummary({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final counts = {for (final s in CardState.values) s: 0};
    for (final card in deck.flashcards ?? const []) {
      final state = card.progress?.state ?? CardState.newCard;
      counts[state] = counts[state]! + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'deck_fsrs_title'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'FSRS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: total == 0
                  ? ColoredBox(color: CardState.newCard.color, child: const SizedBox.expand())
                  : Row(
                      children: [
                        for (final state in CardState.values)
                          if (counts[state]! > 0) ...[
                            Expanded(
                              flex: counts[state]!,
                              child: ColoredBox(color: state.color, child: const SizedBox.expand()),
                            ),
                            const SizedBox(width: 2),
                          ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final state in CardState.values)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${counts[state]}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: state == CardState.newCard
                              ? colorScheme.onSurface.withValues(alpha: 0.7)
                              : state.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
