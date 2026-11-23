import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class NotificationRemoteDataSource {
  Future<Response> registerDevice({required String fcmToken, String? deviceName, String? timezone});
  Future<Response> getNotifications({int offset = 0, int limit = 20});
  Future<Response> getNotificationSettings();
  Future<Response> deleteNotification(String notificationId);
  Future<Response> deleteAllRead();
  Future<Response> markAllAsRead();
  Future<Response> updateNotificationSettings(Map<String, dynamic> settings);
  Future<Response> markAsRead(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> registerDevice({
    required String fcmToken,
    String? deviceName,
    String? timezone,
  }) {
    return dio.post(
      ApiEndpoints.notificationDevices,
      data: {'fcmToken': fcmToken, 'deviceName': ?deviceName, 'timezone': ?timezone},
    );
  }

  @override
  Future<Response> getNotifications({int offset = 0, int limit = 20}) {
    return dio.get(ApiEndpoints.notifications, queryParameters: {'offset': offset, 'limit': limit});
  }

  @override
  Future<Response> getNotificationSettings() {
    return dio.get(ApiEndpoints.notificationSettings);
  }

  @override
  Future<Response> deleteNotification(String notificationId) {
    return dio.delete('${ApiEndpoints.notificationRead}$notificationId');
  }

  @override
  Future<Response> deleteAllRead() {
    return dio.delete(ApiEndpoints.notifications);
  }

  @override
  Future<Response> markAllAsRead() {
    return dio.put(ApiEndpoints.notificationsReadAll);
  }

  @override
  Future<Response> updateNotificationSettings(Map<String, dynamic> settings) {
    return dio.put(ApiEndpoints.notificationSettings, data: settings);
  }

  @override
  Future<Response> markAsRead(String notificationId) {
    return dio.put('${ApiEndpoints.notificationRead}$notificationId/read');
  }
}
