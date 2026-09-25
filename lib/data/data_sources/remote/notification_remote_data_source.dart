import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class NotificationRemoteDataSource {
  Future<Response> registerDevice({required String fcmToken, String? deviceName});
  Future<Response> getNotifications({int page = 1, int limit = 20});
  Future<Response> markAllAsRead();
  Future<Response> updateNotificationSettings(Map<String, dynamic> settings);
  Future<Response> markAsRead(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> registerDevice({required String fcmToken, String? deviceName}) {
    return dio.post(
      ApiEndpoints.notificationDevices,
      data: {'fcmToken': fcmToken, 'deviceName': ?deviceName},
    );
  }

  @override
  Future<Response> getNotifications({int page = 1, int limit = 20}) {
    return dio.get(ApiEndpoints.notifications, queryParameters: {'page': page, 'limit': limit});
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
