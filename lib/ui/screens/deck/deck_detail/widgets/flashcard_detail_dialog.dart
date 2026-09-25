import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/utils/extensions/card_state_extension.dart';

class FlashcardDetailDialog extends StatelessWidget {
  final FlashcardModel cardData;

  const FlashcardDetailDialog({super.key, required this.cardData});

  static Future<void> show(BuildContext context, {required FlashcardModel cardData}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FlashcardDetailDialog(cardData: cardData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final progress = cardData.progress;
    final state = progress?.state ?? CardState.newCard;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle kéo sheet
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header bar
              Text(
                'Chi tiết Flashcard',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              // Nội dung có thể cuộn
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  children: [
                    // ==========================================
                    // 1. MẶT TRƯỚC (CÂU HỎI & ẢNH NẾU CÓ)
                    // ==========================================
                    _buildSectionHeader(
                      context,
                      title: 'Mặt trước',
                      icon: Icons.help_outline_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cardData.frontImageUrl != null &&
                              cardData.frontImageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                cardData.frontImageUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SelectableText(
                            cardData.frontText.isNotEmpty
                                ? cardData.frontText
                                : '(Chưa có nội dung)',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 2. MẶT SAU (ĐÁP ÁN - CHỈ TEXT)
                    // ==========================================
                    _buildSectionHeader(
                      context,
                      title: 'Mặt sau (Đáp án)',
                      icon: Icons.check_circle_outline_rounded,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
                      ),
                      child: SelectableText(
                        cardData.backText.isNotEmpty ? cardData.backText : '(Chưa có đáp án)',
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // 3. THÔNG TIN TIẾN ĐỘ & FSRS
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiến độ ghi nhớ (FSRS)',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: state.color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 3, backgroundColor: state.color),
                              const SizedBox(width: 6),
                              Text(
                                state.label,
                                style: textTheme.labelSmall?.copyWith(
                                  color: state.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (progress != null) ...[
                      // Grid 4 thông số FSRS
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              icon: Icons.shield_outlined,
                              label: 'Độ ổn định',
                              value: progress.stability != null
                                  ? '${progress.stability!.toStringAsFixed(1)} ngày'
                                  : '--',
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              icon: Icons.speed_rounded,
                              label: 'Độ khó',
                              value: progress.difficulty.toStringAsFixed(1),
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              icon: Icons.repeat_rounded,
                              label: 'Khoảng lặp',
                              value: progress.scheduledDays != null
                                  ? '${progress.scheduledDays!.toStringAsFixed(0)} ngày'
                                  : '--',
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              icon: Icons.event_available_rounded,
                              label: 'Hạn ôn tập',
                              value: progress.dueDate != null
                                  ? DateFormat('dd/MM/yyyy').format(progress.dueDate!)
                                  : '--',
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),

                      if (progress.lastReview != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ôn gần nhất:',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(progress.lastReview!),
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Thẻ chưa có tiến độ ôn tập',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
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
