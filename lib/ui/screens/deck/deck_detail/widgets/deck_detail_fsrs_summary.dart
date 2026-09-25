import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/utils/extensions/card_state_extension.dart';

class DeckDetailFsrsSummary extends StatelessWidget {
  final DeckModel deck;

  const DeckDetailFsrsSummary({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    int newCount = 0;
    int learningCount = 0;
    int reviewCount = 0;
    int relearningCount = 0;
    int masteredCount = 0;

    if (deck.flashcards != null) {
      for (final card in deck.flashcards!) {
        final state = card.progress?.state ?? CardState.newCard;
        switch (state) {
          case CardState.newCard:
            newCount++;
            break;
          case CardState.learning:
            learningCount++;
            break;
          case CardState.review:
            reviewCount++;
            break;
          case CardState.relearning:
            relearningCount++;
            break;
          case CardState.mastered:
            masteredCount++;
            break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trạng thái học tập (FSRS)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressIndicatorItem(CardState.newCard, newCount, theme),
              _buildProgressIndicatorItem(CardState.learning, learningCount, theme),
              _buildProgressIndicatorItem(CardState.review, reviewCount, theme),
              _buildProgressIndicatorItem(CardState.relearning, relearningCount, theme),
              _buildProgressIndicatorItem(CardState.mastered, masteredCount, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicatorItem(CardState state, int count, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              color: state.color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: state.color,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
