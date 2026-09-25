import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class ICrashlyticsService {
  Future<void> initialize();
  Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal});
  Future<void> recordFlutterError(FlutterErrorDetails details, {bool fatal});
  Future<void> setUserId(String userId);
  Future<void> log(String message);
}

class CrashlyticsService implements ICrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  @override
  Future<void> initialize() async {
    // Chỉ bật Crashlytics thu thập log ở bản Release/Production
    if (kDebugMode) {
      await _crashlytics.setCrashlyticsCollectionEnabled(false);
    } else {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
    }
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details, {bool fatal = false}) async {
    await _crashlytics.recordFlutterError(details, fatal: fatal);
  }

  @override
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  // TODO: Cái này nó sẽ là chi tiết từng bước thao tác của user mà chỉ khi đẩy err lên thì nó mới đẩy cùng thôi
  @override
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }
}
