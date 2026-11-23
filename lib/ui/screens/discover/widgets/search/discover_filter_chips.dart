import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

/// 4 chip phẳng lọc loại kết quả: Tất cả / Bộ thẻ / Thư mục / Lớp học.
class DiscoverFilterChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const DiscoverFilterChips({super.key, required this.value, required this.onChanged});

  static const scopes = ['all', 'deck', 'folder', 'class'];

  String _label(String scope) => switch (scope) {
    'deck' => 'discover_scope_deck'.tr,
    'folder' => 'discover_scope_folder'.tr,
    'class' => 'discover_scope_class'.tr,
    _ => 'discover_scope_all'.tr,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final scope in scopes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                selected: scope == value,
                onSelected: (_) => onChanged(scope),
                label: Text(_label(scope)),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scope == value ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                side: BorderSide(
                  color: scope == value ? colorScheme.primary : colorScheme.outlineVariant,
                ),
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }
}
