import 'package:mind_deck/core/failures.dart';

// TODO: [i18n] Tạm thời để tiếng Việt cứng tại MỘT chỗ; chuyển sang vi.json khi chuỗi được chốt.
class ReportErrorMessages {
  ReportErrorMessages._();

  static const Map<String, String> _messages = {
    'REPORT_TYPE_INVALID': 'Loại báo cáo không hợp lệ.',
    'REPORT_TARGET_TYPE_INVALID': 'Đối tượng báo cáo không hợp lệ.',
    'REPORT_DESCRIPTION_EMPTY': 'Vui lòng nhập mô tả chi tiết.',
    'REPORT_ATTACHMENTS_INVALID': 'Ảnh đính kèm không hợp lệ.',
    'REPORT_TARGET_ID_REQUIRED': 'Thiếu đối tượng cần báo cáo.',
    'REPORT_TARGET_ID_INVALID': 'Đối tượng cần báo cáo không hợp lệ.',
    'REPORT_TARGET_ID_NOT_ALLOWED': 'Báo cáo hệ thống không đi kèm đối tượng cụ thể.',
    'REPORT_TYPE_TARGET_MISMATCH': 'Loại báo cáo không phù hợp với đối tượng đã chọn.',
    'REPORT_ATTACHMENT_ITEM_INVALID': 'Có ảnh đính kèm không hợp lệ.',
    'REPORT_SELF_REPORT': 'Bạn không thể báo cáo chính mình hoặc nội dung của mình.',
    'REPORT_TARGET_NOT_FOUND':
        'Không tìm thấy đối tượng cần báo cáo hoặc bạn không còn quyền xem nó.',
    'REPORT_DUPLICATE': 'Bạn đã báo cáo đối tượng này và báo cáo đang được xử lý.',
    'REPORT_NOT_FOUND_OR_ACCESS_DENIED': 'Không tìm thấy báo cáo.',
  };

  static String of(Failure failure) {
    final max = failure.params?['max'];
    switch (failure.errorCode) {
      case 'REPORT_DESCRIPTION_TOO_LONG':
        return 'Mô tả tối đa ${max ?? 2000} ký tự.';
      case 'REPORT_ATTACHMENTS_TOO_MANY':
        return 'Chỉ được đính kèm tối đa ${max ?? 5} ảnh.';
      case 'REPORT_TOO_MANY':
        return 'Bạn đã gửi tối đa ${max ?? 5} báo cáo trong 1 giờ. Vui lòng thử lại sau.';
    }
    return _messages[failure.errorCode] ??
        (failure.message.isNotEmpty ? failure.message : 'Có lỗi xảy ra');
  }

  /// Lỗi thuộc về lúc gửi báo cáo (dùng lại cho cả danh sách/chi tiết).
  static String of0(Object e, String fallback) {
    if (e is Failure) return of(e);
    return fallback;
  }
}
