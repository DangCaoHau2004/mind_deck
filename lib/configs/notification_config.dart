import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationConfig {
  final FirebaseMessaging fcm;
  final SharedPreferences prefs;

  NotificationConfig({required this.prefs, required this.fcm});

  static Future<void> initialize() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Người dùng đã cấp quyền nhận thông báo.');
    }
  }

  void setupMessageHandlers(Function(String) onNavigate) {
    // 1. App đang mở trên màn hình (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('--- APP ĐANG MỞ (FOREGROUND) ---');
      debugPrint('Nhận được thông báo: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('--- APP CHẠY NGẦM VÀ ĐƯỢC BẤM VÀO ---');

      // Lấy cái path từ Backend (Nằm trong data payload)
      final path = message.data['path'];
      if (path != null && path.isNotEmpty) {
        debugPrint('Điều hướng tới: $path');
        onNavigate(path); // Gọi hàm chuyển màn hình
      }
    });

    fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('--- APP MỞ TỪ TRẠNG THÁI TẮT HẲN ---');
        final path = message.data['path'];
        if (path != null && path.isNotEmpty) {
          debugPrint('Điều hướng tới: $path');
          onNavigate(path);
        }
      }
    });
  }
}
