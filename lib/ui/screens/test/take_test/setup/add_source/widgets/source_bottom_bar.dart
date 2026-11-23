import 'package:flutter/material.dart';

class SourceBottomBar extends StatelessWidget {
  final int selectedFoldersCount;
  final int selectedDecksCount;
  final int selectedClassesCount;
  final int totalCards;
  final int totalDueCards;
  final VoidCallback onConfirm;
  final VoidCallback onClearAll;

  const SourceBottomBar({
    super.key,
    required this.selectedFoldersCount,
    required this.selectedDecksCount,
    this.selectedClassesCount = 0,
    required this.totalCards,
    required this.totalDueCards,
    required this.onConfirm,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasSelection =
        selectedFoldersCount > 0 || selectedDecksCount > 0 || selectedClassesCount > 0;

    // Build human-readable selection summary text
    final List<String> parts = [];
    if (selectedClassesCount > 0) {
      parts.add('$selectedClassesCount Lớp');
    }
    if (selectedFoldersCount > 0) {
      parts.add('$selectedFoldersCount Thư mục');
    }
    if (selectedDecksCount > 0) {
      parts.add('$selectedDecksCount Bộ thẻ');
    }
    final selectionSummary = hasSelection
        ? 'Đã chọn: ${parts.join(', ')}'
        : 'Chưa chọn tài nguyên nào';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Summary Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectionSummary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasSelection ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (totalDueCards > 0) ...[
                          Icon(Icons.bolt_rounded, color: Colors.amber.shade700, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '$totalDueCards đến hạn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(fontSize: 12, color: colorScheme.outlineVariant),
                          ),
                        ],
                        Text(
                          '$totalCards thẻ được ôn',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Confirm Button
              ElevatedButton(
                onPressed: hasSelection ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                  disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: hasSelection ? 2 : 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xác nhận chọn',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
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
