import 'package:dio/dio.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/class_access_monitor.dart';

/// Bắt `CLASS_NOT_FOUND` / `CLASS_NOT_A_MEMBER` của mọi API dạng `/classes/:id/...` hoặc
/// `/analytics/classes/:id/...` và báo cho [ClassAccessMonitor]. Lỗi vẫn được chuyển tiếp như cũ.
class ClassAccessInterceptor extends Interceptor {
  static final RegExp _classPath = RegExp(r'/classes/([^/?#]+)');

  /// Các đoạn đường dẫn sau `/classes/` không phải id lớp.
  static const Set<String> _notIds = {'join', 'invitations'};

  static const Set<String> _goneCodes = {
    AppErrorCodes.classNotFound,
    AppErrorCodes.classNotAMember,
  };

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    if (data is Map) {
      final code = (data['errorCode'] ?? data['code'])?.toString();
      if (code != null && _goneCodes.contains(code)) {
        final match = _classPath.firstMatch(err.requestOptions.path);
        final classId = match?.group(1);
        if (classId != null && !_notIds.contains(classId)) {
          ClassAccessMonitor.instance.notify(
            ClassAccessLost(
              classId: classId,
              errorCode: code,
              message: data['message']?.toString(),
            ),
          );
        }
      }
    }
    handler.next(err);
  }
}
