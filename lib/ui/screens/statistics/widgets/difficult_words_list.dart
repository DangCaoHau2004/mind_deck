import 'package:flutter/material.dart';

class DifficultWordsList extends StatelessWidget {
  const DifficultWordsList({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Dữ liệu mô phỏng các thẻ bị kẹt ở Grade 1/2 làm D tăng cao
    final List<Map<String, dynamic>> difficultCards = [
      {'front': 'Phenomenon', 'back': 'Hiện tượng', 'D': 8.5},
      {'front': 'Serendipity', 'back': 'Sự tình cờ may mắn', 'D': 8.2},
      {'front': 'Ephemeral', 'back': 'Phù du, chóng vánh', 'D': 7.6},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Từ vựng khó nhằn', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Chỉ số Difficulty (D) > 7.0',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: difficultCards.length,
            separatorBuilder: (_, _) =>
                Divider(color: colorScheme.outline.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final card = difficultCards[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(card['front'], style: textTheme.titleMedium),
                subtitle: Text(
                  card['back'],
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'D: ${card['D']}',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.error),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
