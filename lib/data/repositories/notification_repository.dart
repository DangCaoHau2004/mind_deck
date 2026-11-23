import 'package:mind_deck/data/data_sources/remote/notification_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/notification_model.dart';
import 'package:mind_deck/data/models/user_notification_settings_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class NotificationRepository {
  Future<ApiResponse<void>> registerDevice({
    required String fcmToken,
    String? deviceName,
    String? timezone,
  });
  Future<ApiListResponse<NotificationModel>> getNotifications({int offset = 0, int limit = 20});
  Future<ApiResponse<UserNotificationSettingsModel>> getNotificationSettings();
  Future<ApiResponse<void>> deleteNotification(String notificationId);

  /// Xóa mọi thông báo đã đọc; trả số thông báo đã xóa.
  Future<int> deleteAllRead();
  Future<ApiResponse<void>> markAllAsRead();
  Future<ApiResponse<UserNotificationSettingsModel>> updateNotificationSettings(
    Map<String, dynamic> settings,
  );
  Future<ApiResponse<void>> markAsRead(String notificationId);
}

class NotificationRepositoryImpl with ApiHandler implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<void>> registerDevice({
    required String fcmToken,
    String? deviceName,
    String? timezone,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.registerDevice(
        fcmToken: fcmToken,
        deviceName: deviceName,
        timezone: timezone,
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiListResponse<NotificationModel>> getNotifications({
    int offset = 0,
    int limit = 20,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getNotifications(offset: offset, limit: limit);
      return ApiListResponse<NotificationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => NotificationModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> markAllAsRead() async {
    return executeApi(() async {
      final response = await remoteDataSource.markAllAsRead();
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<UserNotificationSettingsModel>> updateNotificationSettings(
    Map<String, dynamic> settings,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.updateNotificationSettings(settings);
      return ApiResponse<UserNotificationSettingsModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserNotificationSettingsModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<UserNotificationSettingsModel>> getNotificationSettings() async {
    return executeApi(() async {
      final response = await remoteDataSource.getNotificationSettings();
      return ApiResponse<UserNotificationSettingsModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserNotificationSettingsModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> deleteNotification(String notificationId) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteNotification(notificationId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<int> deleteAllRead() async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteAllRead();
      final res = ApiResponse<int>.fromJsonAny(
        response.data as Map<String, dynamic>,
        (d) => d is Map ? (d['deletedCount'] as num?)?.toInt() ?? 0 : 0,
      );
      return res.data ?? 0;
    });
  }

  @override
  Future<ApiResponse<void>> markAsRead(String notificationId) async {
    return executeApi(() async {
      final response = await remoteDataSource.markAsRead(notificationId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }
}
