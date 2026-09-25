import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final Widget Function(T item, bool isSelected)? itemBuilder;
  final void Function(T) onChanged;

  final bool isExpanded;
  final String? label;
  final bool isRequired;

  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool hasBorder;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    this.itemBuilder,
    required this.onChanged,
    this.isExpanded = false,
    this.label,
    this.isRequired = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ), // Sửa padding cho bằng CustomTextField
    this.backgroundColor,
    this.hasBorder = true,
  });

  double _calculateMaxWidth(TextStyle? style) {
    double maxWidth = 0.0;
    for (var item in items) {
      final textPainter = TextPainter(
        text: TextSpan(text: itemLabelBuilder(item), style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      final itemWidth = textPainter.width + (itemBuilder != null ? 30.0 : 0.0);
      if (itemWidth > maxWidth) {
        maxWidth = itemWidth;
      }
    }
    return maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final measureStyle = textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);
    final maxTextWidth = _calculateMaxWidth(measureStyle);

    // Tính toán width
    final totalWidth = maxTextWidth + 4 + 20 + 32;

    Widget dropdownWidget = LayoutBuilder(
      builder: (context, constraints) {
        final double finalWidth = isExpanded ? constraints.maxWidth : totalWidth;

        return Theme(
          data: theme.copyWith(
            popupMenuTheme: theme.popupMenuTheme.copyWith(menuPadding: EdgeInsets.zero),
          ),
          child: PopupMenuButton<T>(
            initialValue: value,
            onSelected: onChanged,
            clipBehavior: Clip.hardEdge,
            constraints: BoxConstraints(minWidth: finalWidth, maxWidth: finalWidth),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5), width: 1),
            ),
            offset: const Offset(0, 48), // Đẩy offset xuống một chút vì padding to ra
            color: colorScheme.surface,
            elevation: 3,
            itemBuilder: (BuildContext context) {
              return items.map((T item) {
                final isSelected = item == value;
                return PopupMenuItem<T>(
                  value: item,
                  padding: EdgeInsets.zero,
                  height: 44,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    child: itemBuilder != null
                        ? itemBuilder!(item, isSelected)
                        : Text(
                            itemLabelBuilder(item),
                            style: textTheme.bodyMedium?.copyWith(
                              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                  ),
                );
              }).toList();
            },
            // DƯỚI NÀY LÀ KHUNG HIỂN THỊ LÚC CHƯA MỞ MENU
            child: Container(
              width: finalWidth,
              padding: padding, // Dùng padding truyền vào (đã set lại 16)
              decoration: BoxDecoration(
                color: backgroundColor ?? colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                // ĐÃ FIX BORDER: Copy y hệt outline của CustomTextField
                border: hasBorder
                    ? Border.all(color: colorScheme.outline.withValues(alpha: 0.5), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: itemBuilder != null
                        ? itemBuilder!(value, true)
                        : Text(
                            itemLabelBuilder(value),
                            style: textTheme.bodyMedium?.copyWith(
                              color: value == null
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                  : colorScheme.onSurface,
                            ),
                          ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 20, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (label == null || label!.isEmpty) {
      return dropdownWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: colorScheme.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        dropdownWidget,
      ],
    );
  }
}
