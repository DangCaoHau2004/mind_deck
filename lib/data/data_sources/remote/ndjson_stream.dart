import 'dart:async';
import 'dart:convert';

/// Khoảng im lặng tối đa (kể cả `ping` 15 giây/lần của BE) trước khi coi là mất kết nối.
const Duration ndjsonIdleTimeout = Duration(seconds: 30);

/// Tách luồng byte NDJSON thành từng đối tượng JSON.
/// - Dòng rỗng và dòng không phải JSON object bị bỏ qua.
/// - Một dòng có thể bị cắt giữa các gói byte; `LineSplitter` ghép lại.
/// - Quá [idleTimeout] không có dòng nào thì phát lỗi [TimeoutException].
Stream<Map<String, dynamic>> parseNdjson(
  Stream<List<int>> bytes, {
  Duration idleTimeout = ndjsonIdleTimeout,
}) {
  return bytes
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .timeout(
        idleTimeout,
        onTimeout: (sink) {
          sink.addError(TimeoutException('Không nhận được dữ liệu từ máy chủ', idleTimeout));
          sink.close();
        },
      )
      .map(_decodeLine)
      .where((e) => e != null)
      .cast<Map<String, dynamic>>();
}

Map<String, dynamic>? _decodeLine(String line) {
  final text = line.trim();
  if (text.isEmpty) return null;
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    // Dòng hỏng: bỏ qua, các dòng sau vẫn dùng được.
  }
  return null;
}
