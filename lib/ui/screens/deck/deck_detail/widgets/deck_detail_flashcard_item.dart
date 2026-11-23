import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/card_state_extension.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/ui/commons/image_screens/image_credit_line.dart';
import 'package:mind_deck/utils/image_url_utils.dart';

/// Một thẻ trong danh sách của chi tiết bộ thẻ. Không bấm được; hiện đầy đủ ảnh, mặt trước, mặt sau (không
/// cắt dòng, không cắt ảnh) và viên trạng thái học.
class DeckDetailFlashcardItem extends StatelessWidget {
  final FlashcardModel cardData;

  const DeckDetailFlashcardItem({super.key, required this.cardData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = cardData.progress?.state ?? CardState.newCard;
    final stateColor = state == CardState.newCard ? colorScheme.onSurface : state.color;
    final imageUrl = cardData.frontImageUrl;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // Vừa chiều ngang, chiều cao theo tỉ lệ ảnh nên không bị cắt
              child: Image.network(
                getImageUrl(imageUrl),
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 4),
            ImageCreditLine(credit: cardData.frontImageCredit),
            const SizedBox(height: 10),
          ],
          Text(
            cardData.frontText,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            cardData.backText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: state.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: state.color),
                const SizedBox(width: 6),
                Text(
                  state.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: stateColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
