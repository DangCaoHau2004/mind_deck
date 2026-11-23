import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;

/// Phần khác nhau giữa các môi trường (flavor `dev`, `staging`, `prod`).
///
/// Flavor lấy từ `flutter run --flavor <tên>`; không có flavor (ví dụ khi chạy `flutter test`) thì dùng dev.
/// Id ứng dụng, tên app, App ID AdMob và cấu hình Firebase nằm ở `android/app/src/<flavor>/`.
class AppConfig {
  final String name;

  /// Gốc server, dùng để ghép địa chỉ ảnh tự tải (`/images/...`).
  final String url;

  /// Địa chỉ API.
  final String baseUrl;

  /// Chỉ prod mới dùng mã đơn vị quảng cáo thật (và chỉ ở bản release, xem `AdUnit.id`).
  final bool useRealAds;

  const AppConfig({
    required this.name,
    required this.url,
    required this.baseUrl,
    required this.useRealAds,
  });

  // TODO: cả ba tạm trỏ vào backend chạy local trên máy ảo; đổi khi có server riêng.
  static const String _localUrl = 'http://10.0.2.2:3000';

  static const AppConfig dev = AppConfig(
    name: 'dev',
    url: _localUrl,
    baseUrl: '$_localUrl/api/v1',
    useRealAds: false,
  );

  static const AppConfig staging = AppConfig(
    name: 'staging',
    url: _localUrl,
    baseUrl: '$_localUrl/api/v1',
    useRealAds: false,
  );

  static const AppConfig prod = AppConfig(
    name: 'prod',
    url: _localUrl,
    baseUrl: '$_localUrl/api/v1',
    useRealAds: true,
  );

  /// Cấu hình của flavor [flavor]; null hoặc tên lạ thì dùng dev.
  static AppConfig of(String? flavor) {
    switch (flavor) {
      case 'prod':
        return prod;
      case 'staging':
        return staging;
      case 'dev':
      case null:
        return dev;
      default:
        debugPrint('Flavor lạ "$flavor", dùng cấu hình dev.');
        return dev;
    }
  }

  static final AppConfig current = of(appFlavor);
}
