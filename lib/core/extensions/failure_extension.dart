import 'package:intl/intl.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/constants/support_contact.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';

extension FailureDisplay on Failure {
  /// Tài khoản bị khóa: HTTP 423 hoặc mã `AUTH_ACCOUNT_LOCKED_*`.
  bool get isAccountLocked =>
      statusCode == 423 ||
      errorCode == AppErrorCodes.authAccountLockedPermanently ||
      errorCode == AppErrorCodes.authAccountLockedTemporarily;

  /// Câu hiển thị cho người dùng.
  /// - Lỗi kiểm tra dữ liệu nhập tại chỗ: dùng `message` có sẵn.
  /// - Khóa tài khoản: câu riêng có lý do và thời hạn.
  /// - Còn lại: `errorCode` là key trong `vi.json`; chưa có bản dịch thì `.tr` trả về chính mã lỗi.
  ///   Các `params` là chuỗi hoặc số được thế vào chỗ giữ `{tên}` trong câu (vd `{max}`, `{total}`).
  String get displayMessage {
    if (errorCode == AppErrorCodes.validationError) return message;
    var text = _accountLockMessage ?? errorCode.tr;
    params?.forEach((key, value) {
      if (value is String || value is num) text = text.replaceAll('{$key}', '$value');
    });
    return text;
  }

  /// Câu thông báo khóa tài khoản từ `params.reason`, `params.time`; null nếu không phải khóa tài khoản.
  String? get _accountLockMessage {
    if (!isAccountLocked) return null;

    final rawReason = params?['reason'];
    final reason = rawReason is String && rawReason.trim().isNotEmpty ? rawReason.trim() : null;
    final time = DateTime.tryParse(params?['time']?.toString() ?? '')?.toLocal();

    // Không có lý do và không có thời hạn: câu chung kèm địa chỉ hỗ trợ.
    if (reason == null && time == null) {
      return 'auth_locked_generic'.tr.replaceAll('{email}', SupportContact.email);
    }

    final permanent = errorCode == AppErrorCodes.authAccountLockedPermanently;
    final base = permanent
        ? 'auth_locked_permanent'.tr
        : time != null
        ? 'auth_locked_until'.tr.replaceAll('{time}', DateFormat('HH:mm dd/MM/yyyy').format(time))
        : 'auth_account_locked'.tr;
    return reason == null
        ? base
        : '$base\n${'auth_locked_reason'.tr.replaceAll('{reason}', reason)}';
  }
}
