import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

class CustomDialog extends StatelessWidget {
  final Widget? iconWidget;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? iconSize;

  final String? title;
  final Widget? titleWidget;
  final TextStyle? titleStyle;

  final String? description;
  final Widget? contentWidget;
  final TextStyle? descriptionStyle;

  final String? cancelText;
  final String? confirmText;

  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  final Color? confirmButtonColor;
  final Color? confirmTextColor;

  final Color? cancelButtonColor;
  final Color? cancelTextColor;

  final bool showCancelButton;

  const CustomDialog({
    super.key,
    this.iconWidget,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconSize,
    this.title,
    this.titleWidget,
    this.titleStyle,
    this.description,
    this.contentWidget,
    this.descriptionStyle,
    this.cancelText,
    this.confirmText,
    this.onCancel,
    this.onConfirm,
    this.confirmButtonColor,
    this.confirmTextColor,
    this.cancelButtonColor,
    this.cancelTextColor,
    this.showCancelButton = true,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    Widget? iconWidget,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    double? iconSize,
    String? title,
    Widget? titleWidget,
    TextStyle? titleStyle,
    String? description,
    Widget? contentWidget,
    TextStyle? descriptionStyle,
    String? cancelText,
    String? confirmText,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    Color? confirmButtonColor,
    Color? confirmTextColor,
    Color? cancelButtonColor,
    Color? cancelTextColor,
    bool showCancelButton = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        iconWidget: iconWidget,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        iconSize: iconSize,
        title: title,
        titleWidget: titleWidget,
        titleStyle: titleStyle,
        description: description,
        contentWidget: contentWidget,
        descriptionStyle: descriptionStyle,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: onCancel,
        onConfirm: onConfirm,
        confirmButtonColor: confirmButtonColor,
        confirmTextColor: confirmTextColor,
        cancelButtonColor: cancelButtonColor,
        cancelTextColor: cancelTextColor,
        showCancelButton: showCancelButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Icon ---
            if (iconWidget != null || icon != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color:
                        iconBackgroundColor ??
                        colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      iconWidget ??
                      Icon(
                        icon ?? Icons.warning_amber_rounded,
                        color: iconColor ?? colorScheme.error,
                        size: iconSize ?? 32,
                      ),
                ),
              ),
            if (iconWidget != null || icon != null) const SizedBox(height: 20),

            // --- Title ---
            if (titleWidget != null || title != null)
              Center(
                child:
                    titleWidget ??
                    Text(
                      title ?? '',
                      textAlign: TextAlign.center,
                      style:
                          titleStyle ??
                          textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
              ),
            if (titleWidget != null || title != null)
              const SizedBox(height: 12),

            // --- Content / Description ---
            if (contentWidget != null || description != null)
              Center(
                child:
                    contentWidget ??
                    Text(
                      description ?? '',
                      textAlign: TextAlign.center,
                      style:
                          descriptionStyle ??
                          textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
              ),
            if (contentWidget != null || description != null)
              const SizedBox(height: 32),

            // --- Actions ---
            Row(
              children: [
                if (showCancelButton) ...[
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor:
                            cancelButtonColor ?? colorScheme.surfaceContainer,
                        foregroundColor:
                            cancelTextColor ?? colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (onCancel != null) {
                          onCancel!();
                        } else {
                          context.pop(false);
                        }
                      },
                      child: Text(
                        cancelText ?? 'common_cancel'.tr,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cancelTextColor ?? colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          confirmButtonColor ?? colorScheme.primary,
                      foregroundColor:
                          confirmTextColor ?? colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (onConfirm != null) {
                        onConfirm!();
                      } else {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: Text(
                      confirmText ?? 'common_confirm'.tr,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: confirmTextColor ?? Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
