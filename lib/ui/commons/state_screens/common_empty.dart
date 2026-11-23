import 'package:flutter/material.dart';
import 'package:mind_deck/constants/app_assets.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

class CommonEmpty extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const CommonEmpty({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.actionText,
    this.onActionPressed,
  });

  CommonEmpty.notFound({
    super.key,
    String? title,
    String? subtitle,
    this.icon = Icons.location_off_outlined,
    this.iconColor,
    this.actionText,
    this.onActionPressed,
  }) : title = title ?? 'common_data_not_found'.tr,
       subtitle = subtitle ?? 'common_path_or_id_not_found'.tr;

  CommonEmpty.search({
    super.key,
    String? title,
    String? subtitle,
    this.icon = Icons.search_off_rounded,
    this.iconColor,
    this.actionText,
    this.onActionPressed,
  }) : title = title ?? 'common_no_results'.tr,
       subtitle = subtitle ?? 'common_try_again_with_other_keywords'.tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon != null
                  ? Icon(icon, color: iconColor ?? colorScheme.onPrimary, size: 64)
                  : Image.asset(
                      AppAssets.emptyBox,
                      width: 64,
                      height: 64,
                      color: colorScheme.onPrimary,
                    ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title ?? 'common_empty_data'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle ?? 'common_list_is_currently_empty'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            if (onActionPressed != null) ...[
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: onActionPressed,
                child: Text(actionText ?? 'common_reload_page'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
