import 'package:mind_deck/core/failures.dart';

// TODO: [i18n] Tạm thời để tiếng Việt cứng tại MỘT chỗ; chuyển sang vi.json khi chuỗi được chốt.
class DocumentImportErrorMessages {
  DocumentImportErrorMessages._();

  static const String _p = 'DOCUMENT_IMPORT_';

  static const Map<String, String> _messages = {
    '${_p}FILE_REQUIRED': 'Vui lòng chọn một tệp.',
    '${_p}FILE_CORRUPTED':
        'Tệp hoặc ảnh bị hỏng, không đọc được, hoặc nội dung không khớp với đuôi tệp.',
    '${_p}FILE_TOO_COMPLEX': 'Tệp quá phức tạp để xử lý. Hãy thử tệp nhỏ hơn.',
    '${_p}TEXT_EMPTY': 'Tài liệu có quá ít chữ để tạo thẻ.',
    '${_p}PDF_NO_TEXT':
        'Không đọc được chữ trong PDF này. Hãy thử chụp ảnh các trang hoặc dùng tệp khác.',
    '${_p}MULTIPLE_FILES_NOT_IMAGES': 'Chỉ có thể gửi nhiều tệp khi tất cả đều là ảnh.',
    '${_p}SHEET_NOT_FOUND': 'Không tìm thấy sheet trong tệp Excel.',
    '${_p}NOT_ENOUGH_CARDS': 'Không tạo đủ thẻ (cần ít nhất 2 thẻ hợp lệ).',
    '${_p}FEATURE_DISABLED': 'Tính năng này đang tạm tắt.',
    '${_p}IN_PROGRESS': 'Bạn đang có một lượt xử lý khác. Hãy chờ lượt đó xong hoặc hủy nó.',
    '${_p}DAILY_LIMIT_REACHED':
        'Bạn đã dùng hết lượt AI hôm nay (gói AI miễn phí có giới hạn). Tệp csv/xlsx vẫn dùng được, hoặc thử lại sau 00:00.',
    '${_p}DAILY_ATTEMPTS_REACHED':
        'Hôm nay bạn đã thử quá nhiều lần. Vui lòng quay lại vào ngày mai.',
    '${_p}SYSTEM_BUSY': 'Hệ thống AI đang bận. Bạn không mất lượt, hãy thử lại sau ít phút.',
    '${_p}AI_NOT_CONFIGURED': 'Máy chủ chưa bật AI. Chỉ tệp csv/xlsx dùng được lúc này.',
    '${_p}AI_RATE_LIMITED': 'Hệ thống AI đang bận. Bạn không mất lượt, hãy thử lại sau ít phút.',
    '${_p}AI_UNAVAILABLE':
        'Dịch vụ AI tạm thời không khả dụng. Bạn không mất lượt, hãy thử lại sau.',
    '${_p}AI_TIMEOUT': 'Dịch vụ AI phản hồi quá lâu. Hãy thử lại.',
    '${_p}AI_BAD_RESPONSE': 'AI trả về kết quả không đọc được. Hãy thử lại.',
    '${_p}INTERRUPTED': 'Máy chủ khởi động lại giữa chừng nên lượt này bị lỗi. Hãy tải lại tệp.',
    '${_p}NOT_FOUND': 'Không tìm thấy bản nháp (có thể đã bị xóa hoặc hết hạn).',
    '${_p}FOLDER_NOT_FOUND': 'Không tìm thấy thư mục đã chọn.',
    '${_p}NOT_READY': 'Bản nháp chưa xử lý xong.',
    '${_p}ALREADY_COMMITTED': 'Bản nháp này đã được lưu thành bộ thẻ.',
    '${_p}CONTENT_EXPIRED': 'Nội dung bản nháp đã hết hạn và bị xóa.',
  };

  static String of(Failure failure) => ofCode(failure.errorCode, failure.message, failure.params);

  /// Dùng chung cho sự kiện `error` / `chunk_failed` của luồng (chỉ có `errorCode` và `message`).
  static String ofCode(String? errorCode, String? message, [Map<String, dynamic>? params]) {
    switch (errorCode) {
      case '${_p}FILE_TOO_LARGE':
        return 'Tệp quá lớn (tối đa ${params?['maxMb'] ?? 10} MB).';
      case '${_p}FILE_TYPE_INVALID':
        final types = params?['types'];
        return types is List && types.isNotEmpty
            ? 'Chỉ hỗ trợ tệp: ${types.join(', ')}.'
            : 'Loại tệp này chưa được hỗ trợ.';
      case '${_p}FILES_TOO_MANY':
        return 'Chỉ được gửi tối đa ${params?['maxFiles'] ?? 8} ảnh mỗi lần.';
      case '${_p}PDF_TOO_MANY_PAGES':
        return 'PDF quá nhiều trang (tối đa ${params?['maxPages'] ?? 50} trang mỗi lượt). Hãy chọn một khoảng trang.';
      case '${_p}PDF_PAGE_RANGE_INVALID':
        final total = params?['totalPages'];
        return total == null
            ? 'Khoảng trang không hợp lệ.'
            : 'Khoảng trang không hợp lệ (PDF có $total trang).';
      case '${_p}OPTIONS_INVALID':
      case '${_p}DRAFT_INVALID':
        final details = params?['details'];
        final extra = details is List && details.isNotEmpty ? ' ${details.join('; ')}' : '';
        return errorCode == '${_p}OPTIONS_INVALID'
            ? 'Cài đặt không hợp lệ.$extra'
            : 'Bản nháp chưa hợp lệ.$extra';
      case 'COIN_INSUFFICIENT':
        final price = params?['price'];
        final balance = params?['balance'];
        return price == null || balance == null
            ? 'Bạn không đủ xu. Hãy xem video để nhận xu.'
            : 'Cần $price xu, bạn có $balance xu. Hãy xem video để nhận xu.';
      case '${_p}DAILY_LIMIT_REACHED':
        final limit = params?['limit'];
        return limit == null
            ? _messages[errorCode]!
            : 'Bạn đã dùng hết $limit lượt AI hôm nay (gói AI miễn phí có giới hạn). '
                  'Tệp csv/xlsx vẫn dùng được, hoặc thử lại sau 00:00.';
    }
    final known = _messages[errorCode];
    if (known != null) return known;
    return (message != null && message.isNotEmpty) ? message : 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  /// Lỗi do hệ thống/AI, người dùng không bị trừ lượt.
  static bool isBusy(String? errorCode) =>
      errorCode == '${_p}SYSTEM_BUSY' ||
      errorCode == '${_p}AI_RATE_LIMITED' ||
      errorCode == '${_p}AI_UNAVAILABLE';
}
