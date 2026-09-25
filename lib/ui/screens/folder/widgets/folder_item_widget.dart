import 'package:flutter/material.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

class FolderItemWidget extends StatelessWidget {
  final FolderModel folder;
  final bool isSelected;
  final bool isSelectionMode;

  // Bổ sung 3 callback để đẩy logic ra ngoài Screen/BLoC
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStarTap;

  const FolderItemWidget({
    super.key,
    required this.folder,
    required this.isSelected,
    required this.isSelectionMode,
    this.onTap,
    this.onLongPress,
    this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tự động tính toán màu sắc tương phản (Giữ nguyên code gốc của bạn)
    final themeColor = ColorUtils.parseHex(folder.color);
    final bool isLight = ColorUtils.isLightColor(themeColor);
    final Color contentColor = ColorUtils.getContrastColor(themeColor);
    final Color subTextColor = isLight
        ? Colors.black54
        : Colors.white.withValues(alpha: 0.85);

    return GestureDetector(
      // GỌI CALLBACK ĐƯỢC TRUYỀN TỪ NGOÀI VÀO
      onLongPress: onLongPress,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Stack(
          children: [
            // "Tai" thư mục
            Positioned(
              top: 0,
              left: 16,
              child: Container(
                width: 90,
                height: 20,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  border: isLight
                      ? Border.all(color: Colors.grey.shade300, width: 1)
                      : null,
                ),
              ),
            ),

            // Khung thư mục chính
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeColor.withValues(alpha: 0.8)
                    : themeColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: contentColor, width: 2)
                    : (isLight
                          ? Border.all(color: Colors.grey.shade300, width: 1)
                          : null),
                boxShadow: [
                  BoxShadow(
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.05)
                        : themeColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppIcons.getIconFromKey(folder.icon),
                      color: contentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: contentColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (folder.description != null &&
                            folder.description!.isNotEmpty)
                          Text(
                            folder.description!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: subTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isSelectionMode)
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? contentColor : subTextColor,
                      size: 26,
                    )
                  else ...[
                    if (onStarTap != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onStarTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            folder.isStarred
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: folder.isStarred
                                ? Colors.amberAccent
                                : subTextColor,
                            size: 22,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: subTextColor,
                      size: 26,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
