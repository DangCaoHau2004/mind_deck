import 'dart:io';

/// Giờ theo server, suy từ header `Date` của các response gần nhất.
///
/// Dùng khi so sánh với mốc thời gian do server cấp (vd. `expiresAt` của phiên làm bài):
/// máy người dùng có thể chỉnh lệch giờ, còn server mới là nơi quyết định hết hạn.
class ServerClock {
  ServerClock._();

  /// `giờ server − giờ máy`. 0 khi chưa nhận được response nào có header `Date`.
  static Duration _offset = Duration.zero;

  static Duration get offset => _offset;

  static DateTime now() => DateTime.now().add(_offset);

  /// Cập nhật độ lệch từ giá trị header `Date` (RFC 7231, độ chính xác 1 giây).
  static void syncFromHttpDate(String? httpDate) {
    if (httpDate == null || httpDate.isEmpty) return;
    try {
      final serverNow = HttpDate.parse(httpDate);
      _offset = serverNow.difference(DateTime.now());
    } catch (_) {
      // Header không hợp lệ: giữ độ lệch cũ.
    }
  }

  /// Chỉ dùng trong test.
  static void debugSetOffset(Duration offset) => _offset = offset;
}
