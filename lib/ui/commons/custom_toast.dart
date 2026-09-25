import 'package:flutter/material.dart';
import 'package:mind_deck/constants/custom_colors.dart';

enum CustomToastType { primary, success, danger, warning, general }

class CustomToast extends StatelessWidget {
  final CustomToastType type;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  const CustomToast({
    super.key,
    required this.type,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  factory CustomToast.primary({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onClose,
  }) => CustomToast(
    type: CustomToastType.primary,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    onClose: onClose,
  );

  factory CustomToast.success({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onClose,
  }) => CustomToast(
    type: CustomToastType.success,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    onClose: onClose,
  );

  factory CustomToast.danger({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onClose,
  }) => CustomToast(
    type: CustomToastType.danger,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    onClose: onClose,
  );

  factory CustomToast.warning({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onClose,
  }) => CustomToast(
    type: CustomToastType.warning,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    onClose: onClose,
  );

  factory CustomToast.general({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onClose,
  }) => CustomToast(
    type: CustomToastType.general,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    onClose: onClose,
  );

  static void show(BuildContext context, CustomToast customToast) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        content: CustomToast(
          type: customToast.type,
          message: customToast.message,
          actionLabel: customToast.actionLabel,
          onAction: customToast.onAction,
          onClose:
              customToast.onClose ??
              () {
                scaffoldMessenger.hideCurrentSnackBar();
              },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case CustomToastType.primary:
        backgroundColor = CustomColors.toastPrimary;
        iconData = Icons.info_outline;
        break;
      case CustomToastType.success:
        backgroundColor = CustomColors.toastSuccess;
        iconData = Icons.check;
        break;
      case CustomToastType.danger:
        backgroundColor = CustomColors.toastDanger;
        iconData = Icons.error_outline;
        break;
      case CustomToastType.warning:
        backgroundColor = CustomColors.toastWarning;
        iconData = Icons.warning_amber_rounded;
        break;
      case CustomToastType.general:
        backgroundColor = CustomColors.toastGeneral;
        iconData = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(iconData, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2, // Added for premium feel
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ],
        ],
      ),
    );
  }
}
