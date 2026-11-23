import 'package:flutter_timezone/flutter_timezone.dart';

/// Tên múi giờ IANA của máy (vd. `Asia/Ho_Chi_Minh`); lỗi hoặc rỗng thì trả `null` để BE tự chọn mặc định.
Future<String?> localTimezone() async {
  try {
    final id = (await FlutterTimezone.getLocalTimezone()).identifier;
    return id.isEmpty ? null : id;
  } catch (_) {
    return null;
  }
}
