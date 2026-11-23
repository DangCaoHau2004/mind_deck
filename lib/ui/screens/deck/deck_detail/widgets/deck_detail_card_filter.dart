import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/card_state_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/enums.dart';

/// Ô tìm thẻ (mặt trước hoặc mặt sau) và các chip lọc theo trạng thái học kèm số lượng. Tìm và lọc chạy
/// trên máy vì BE trả đủ mọi thẻ của bộ thẻ.
class DeckDetailCardFilter extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  /// Số thẻ theo từng trạng thái (thiếu = 0) và tổng số thẻ.
  final Map<CardState, int> counts;
  final int total;

  /// null = tất cả.
  final CardState? selected;
  final ValueChanged<CardState?> onSelected;

  /// Thứ tự chip: đến hạn lên đầu rồi tới các trạng thái còn lại.
  static const _order = [
    CardState.review,
    CardState.newCard,
    CardState.learning,
    CardState.relearning,
    CardState.mastered,
  ];

  const DeckDetailCardFilter({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.counts,
    required this.total,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget chip({
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
      Color? dot,
    }) {
      final fg = isSelected ? colorScheme.surface : colorScheme.onSurface;
      return Material(
        color: isSelected ? colorScheme.onSurface : colorScheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? Colors.transparent : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'deck_cards_search_hint'.tr,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip(
              label: '${'library_filter_all'.tr} · $total',
              isSelected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final state in _order)
              chip(
                label: '${state.label} · ${counts[state] ?? 0}',
                dot: state.color,
                isSelected: selected == state,
                onTap: () => onSelected(selected == state ? null : state),
              ),
          ],
        ),
      ],
    );
  }
}
