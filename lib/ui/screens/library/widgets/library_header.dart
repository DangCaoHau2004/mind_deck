import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/theme/app_styles.dart';

/// Tiêu đề "Thư viện" + thanh chuyển Thư mục / Học phần, đặt làm sliver đầu tiên của từng tab
/// để cuộn đi cùng danh sách. [selectedIndex] là chỉ số của tab đang chứa header này.
class LibraryHeader extends StatelessWidget {
  final int selectedIndex;

  const LibraryHeader({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labels = ['library_tab_folders'.tr, 'library_tab_decks'.tr];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'library_title'.tr,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Thanh chuyển tab dạng segmented: nền xanh nhạt, tab đang chọn là ô trắng
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => StatefulNavigationShell.of(
                        context,
                      ).goBranch(i, initialLocation: i == selectedIndex),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: i == selectedIndex
                            ? BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppStyles.cardShadow(colorScheme),
                              )
                            : null,
                        child: Text(
                          labels[i],
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w400,
                            color: i == selectedIndex
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
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
