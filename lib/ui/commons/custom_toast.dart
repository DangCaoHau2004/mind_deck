import 'dart:async';

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

  static const Duration defaultDuration = Duration(seconds: 4);
  static OverlayEntry? _currentEntry;
  static Timer? _hideTimer;

  /// Hiện toast ở đáy màn hình (trên lớp overlay gốc), toast mới thay toast đang hiện.
  /// [duration] là thời gian toast tồn tại trước khi tự tắt (mặc định [defaultDuration]).
  static void show(
    BuildContext context,
    CustomToast customToast, {
    Duration duration = defaultDuration,
  }) {
    showOnOverlay(Overlay.maybeOf(context, rootOverlay: true), customToast, duration: duration);
  }

  /// Hiện toast trực tiếp trên [overlay], dùng cho sự kiện cấp app khi không có `context` trong cây
  /// màn hình (ví dụ overlay của `rootNavigatorKey`). Không làm gì nếu [overlay] là null.
  static void showOnOverlay(
    OverlayState? overlay,
    CustomToast customToast, {
    Duration duration = defaultDuration,
  }) {
    if (overlay == null) return;

    dismiss();
    final entry = OverlayEntry(
      builder: (_) => _ToastPositioner(
        child: CustomToast(
          type: customToast.type,
          message: customToast.message,
          actionLabel: customToast.actionLabel,
          onAction: customToast.onAction,
          onClose: customToast.onClose ?? dismiss,
        ),
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
    _hideTimer = Timer(duration, dismiss);
  }

  /// Ẩn toast đang hiện (nếu có).
  static void dismiss() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
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

/// Đặt toast cố định ở đáy màn hình (nằm trên bàn phím khi mở), trượt lên và hiện dần.
class _ToastPositioner extends StatelessWidget {
  final Widget child;

  const _ToastPositioner({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.viewInsetsOf(context).bottom,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}
