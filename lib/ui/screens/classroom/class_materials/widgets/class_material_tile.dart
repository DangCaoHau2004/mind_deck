import 'package:flutter/material.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Một dòng học liệu của lớp (folder hoặc deck lẻ). `item.id` là id BẢN SAO trong lớp.
class ClassMaterialTile extends StatelessWidget {
  final ClassMaterialItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  /// Hiện nút sao chép về thư viện cá nhân (theo `canClone`).
  final VoidCallback? onClone;

  const ClassMaterialTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onClone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = ColorUtils.parseHex(item.color ?? '#1565C0');
    final isFolder = item.isFolder;

    final subtitle = isFolder ? '${item.deckCount ?? 0} bộ thẻ' : '${item.cardCount ?? 0} thẻ';

    return Material(
      color: isSelected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? cs.primary : cs.outline,
                ),
                const SizedBox(width: 12),
              ],
              // Folder có góc trên-trái nhọn như tab thư mục để phân biệt với deck.
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: isFolder
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        )
                      : BorderRadius.circular(16),
                ),
                child: Icon(
                  AppIcons.getIconFromKey(
                    item.icon ?? (isFolder ? 'default_folder' : 'default_deck'),
                  ),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isFolder ? Icons.folder_rounded : Icons.style_rounded,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (item.isDuplicateCopy) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bản trùng',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode && onClone != null)
                IconButton(
                  tooltip: 'Sao chép về thư viện của tôi',
                  icon: Icon(Icons.copy_rounded, color: cs.primary, size: 20),
                  onPressed: onClone,
                ),
              if (!isSelectionMode && isFolder)
                Icon(Icons.chevron_right_rounded, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
