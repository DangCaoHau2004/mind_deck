import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

class CommonFailure extends StatelessWidget {
  final String? title;
  final String? errorMessage;
  final String? errorCode;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const CommonFailure({
    super.key,
    this.title,
    this.errorMessage,
    this.errorCode,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
  });

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
            // Icon Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? colorScheme.error,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                color: iconColor ?? colorScheme.onError,
                size: 48,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title ?? 'common_error_occurred'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),

            // Description (errorMessage)
            Text(
              errorMessage ?? 'common_unknown_error'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            // Error Code Box
            if (errorCode != null && errorCode!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'common_error_code'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorCode!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
