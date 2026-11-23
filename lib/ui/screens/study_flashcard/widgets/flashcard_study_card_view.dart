import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/utils/image_url_utils.dart';
import 'package:mind_deck/ui/commons/image_screens/image_credit_line.dart';

class FlashcardStudyCardView extends StatelessWidget {
  final FlashcardModel card;
  final bool isFront;
  final bool isDragging;
  final Offset dragPosition;
  final bool isMock;

  const FlashcardStudyCardView({
    super.key,
    required this.card,
    required this.isFront,
    this.isDragging = false,
    this.dragPosition = Offset.zero,
    this.isMock = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double dragOpacity = (dragPosition.dx.abs() / 150).clamp(0.0, 1.0);
    final double contentOpacity = (1.0 - (dragPosition.dx.abs() / 250)).clamp(0.0, 1.0);
    final Color overlayColor = dragPosition.dx > 0 ? Colors.green : Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: isDragging && !isMock ? contentOpacity : 1.0,
            child: Column(
              children: [
                if (isFront && card.frontImageUrl != null)
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          getImageUrl(card.frontImageUrl),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: theme.colorScheme.outline,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    color: theme.colorScheme.outlineVariant,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Lỗi hiển thị ảnh',
                                    style: TextStyle(
                                      color: theme.colorScheme.outline,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (card.frontImageCredit != null)
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ImageCreditLine(
                                  credit: card.frontImageCredit,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  flex: isFront && card.frontImageUrl != null ? 5 : 10,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        isFront ? card.frontText : card.backText,
                        style: isFront
                            ? theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              )
                            : theme.textTheme.titleLarge?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface,
                              ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isMock && isDragging)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: overlayColor.withValues(alpha: dragOpacity), width: 4),
              ),
              child: Center(
                child: Opacity(
                  opacity: dragOpacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: overlayColor, width: 4),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    child: Text(
                      dragPosition.dx > 0 ? 'ĐÃ HỌC' : 'CHƯA HỌC',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: overlayColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
