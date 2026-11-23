import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

/// Bottom sheet chọn cách sắp xếp kết quả. Trả về `relevance` hoặc `saved` (null nếu đóng).
class DiscoverSortSheet extends StatelessWidget {
  final String current;

  const DiscoverSortSheet({super.key, required this.current});

  static Future<String?> show(BuildContext context, {required String current}) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => DiscoverSortSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final options = {
      'relevance': 'discover_sort_relevance'.tr,
      'saved': 'discover_sort_popular'.tr,
    };

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'discover_sort_title'.tr,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final entry in options.entries)
            ListTile(
              title: Text(
                entry.value,
                style: TextStyle(
                  fontWeight: entry.key == current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: entry.key == current
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(entry.key),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
