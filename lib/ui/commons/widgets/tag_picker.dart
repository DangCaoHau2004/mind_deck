import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Chọn tag trong form: tiêu đề kèm "Đã chọn N", chip theo màu tag (chọn rồi thì nền đặc kèm dấu tích),
/// gọn còn [collapsedCount] chip + "+N" để mở rộng/thu gọn, và chip "+ Tag mới" ở cuối.
/// Tag đã chọn luôn được hiện dù đang thu gọn. [isLoading] (chưa có danh sách) thì hiện chip giữ chỗ.
class TagPicker extends StatefulWidget {
  final List<TagModel> availableTags;
  final List<TagModel> selectedTags;
  final bool isLoading;
  final ValueChanged<TagModel> onToggle;
  final VoidCallback onAddNew;

  static const int collapsedCount = 3;

  const TagPicker({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onToggle,
    required this.onAddNew,
    this.isLoading = false,
  });

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  bool _expanded = false;

  // Chip giả để skeleton có hình dáng thật (tên dài ngắn khác nhau cho tự nhiên)
  static const _placeholders = [
    TagModel(id: 'p1', name: 'lap-trinh', color: '#9E9E9E'),
    TagModel(id: 'p2', name: 'backend', color: '#9E9E9E'),
    TagModel(id: 'p3', name: 'co-so-du-lieu', color: '#9E9E9E'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.selectedTags;

    final all = widget.availableTags;
    final visible = _expanded || all.length <= TagPicker.collapsedCount
        ? all
        : [
            for (var i = 0; i < all.length; i++)
              if (i < TagPicker.collapsedCount || selected.any((t) => t.id == all[i].id)) all[i],
          ];
    final hidden = all.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'form_tags_title'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            if (selected.isNotEmpty)
              Text(
                'form_tags_selected'.tr.replaceAll('{count}', '${selected.length}'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.isLoading && all.isEmpty)
          Skeletonizer(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _placeholders)
                  _TagChip(tag: tag, isSelected: false, onTap: () {}),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in visible)
                _TagChip(
                  tag: tag,
                  isSelected: selected.any((t) => t.id == tag.id),
                  onTap: () => widget.onToggle(tag),
                ),
              if (hidden > 0)
                _ActionChip(
                  icon: Icons.add_rounded,
                  label: '$hidden',
                  onTap: () => setState(() => _expanded = true),
                )
              else if (_expanded && all.length > TagPicker.collapsedCount)
                _ActionChip(
                  icon: Icons.remove_rounded,
                  label: 'deck_folders_collapse'.tr,
                  onTap: () => setState(() => _expanded = false),
                ),
              _ActionChip(
                icon: Icons.add_rounded,
                label: 'form_tag_new'.tr,
                onTap: widget.onAddNew,
                outlined: true,
              ),
            ],
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// true: chip viền (thêm tag mới); false: nền nhạt (+N / thu gọn).
  final bool outlined;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? null : primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: outlined ? Border.all(color: primary.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final TagModel tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tagColor = ColorUtils.parseHex(tag.color ?? '#8B5CF6');
    final fg = isSelected ? ColorUtils.getContrastColor(tagColor) : tagColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? tagColor : tagColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? tagColor : tagColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? Icons.check_rounded : Icons.tag_rounded, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(
              tag.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
