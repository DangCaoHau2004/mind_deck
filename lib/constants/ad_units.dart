import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mind_deck/configs/app_config.dart';

enum AdFormat { native, banner, interstitial, rewarded }

/// Đơn vị quảng cáo AdMob. `unitName` trùng tên đơn vị đã tạo trên AdMob.
/// Mã thật chỉ dùng ở flavor prod bản release trên Android. Bản debug, dev, staging và iOS (chưa tạo
/// đơn vị) luôn dùng mã test của Google để tránh bị khóa tài khoản.
enum AdUnit {
  nativeDiscover(
    'android_native_discover',
    AdFormat.native,
    'ca-app-pub-5061961566441627/9731100417',
  ),
  nativeDiscoverPopular(
    'android_native_discover_popular',
    AdFormat.native,
    'ca-app-pub-5061961566441627/4745980000',
  ),
  nativeLibrary(
    'android_native_library',
    AdFormat.native,
    'ca-app-pub-5061961566441627/1104624603',
  ),
  nativeFolderDetail(
    'android_native_folder_detail',
    AdFormat.native,
    'ca-app-pub-5061961566441627/8791542938',
  ),
  nativeDeckDetail(
    'android_native_deck_detail',
    AdFormat.native,
    'ca-app-pub-5061961566441627/6165379590',
  ),
  // TODO: điền mã thật sau khi tạo đơn vị 'android_native_home' trên AdMob. Để trống thì bản prod release
  // tải lỗi và ô quảng cáo tự ẩn; debug, dev, staging vẫn dùng mã test.
  nativeHome('android_native_home', AdFormat.native, ''),
  bannerTestHistory(
    'android_banner_test_history',
    AdFormat.banner,
    'ca-app-pub-5061961566441627/9765713259',
  ),
  bannerStats('android_banner_stats', AdFormat.banner, 'ca-app-pub-5061961566441627/6294865393'),
  bannerNotificationList(
    'android_banner_notification_list',
    AdFormat.banner,
    'ca-app-pub-5061961566441627/4986487303',
  ),
  bannerImportList(
    'android_banner_import_list',
    AdFormat.banner,
    'ca-app-pub-5061961566441627/9522170673',
  ),
  bannerImportWaiting(
    'android_banner_import_waiting',
    AdFormat.banner,
    'ca-app-pub-5061961566441627/7180571659',
  ),
  interstitialStudyComplete(
    'android_interstitial_study_complete',
    AdFormat.interstitial,
    'ca-app-pub-5061961566441627/8418018745',
  ),
  interstitialTestResult(
    'android_interstitial_test_result',
    AdFormat.interstitial,
    'ca-app-pub-5061961566441627/4846052351',
  ),
  rewardedCoin(
    'android_rewarded_coin',
    AdFormat.rewarded,
    'ca-app-pub-5061961566441627/7104937076',
    rewardItem: 'coin',
  );

  final String unitName;
  final AdFormat format;
  final String androidId;

  /// Tên phần thưởng khai báo trên AdMob (chỉ loại rewarded).
  final String? rewardItem;

  const AdUnit(this.unitName, this.format, this.androidId, {this.rewardItem});

  /// Mã dùng khi tải quảng cáo.
  String get id => idFor(
    isDebug: kDebugMode,
    useRealAds: AppConfig.current.useRealAds,
    isAndroid: Platform.isAndroid,
    isIOS: Platform.isIOS,
  );

  @visibleForTesting
  String idFor({
    required bool isDebug,
    required bool useRealAds,
    required bool isAndroid,
    required bool isIOS,
  }) {
    if (isDebug || !useRealAds || !isAndroid) {
      return (isIOS ? _iosTestIds : _androidTestIds)[format]!;
    }
    return androidId;
  }

  static const Map<AdFormat, String> _androidTestIds = {
    AdFormat.native: 'ca-app-pub-3940256099942544/2247696110',
    AdFormat.banner: 'ca-app-pub-3940256099942544/9214589741',
    AdFormat.interstitial: 'ca-app-pub-3940256099942544/1033173712',
    AdFormat.rewarded: 'ca-app-pub-3940256099942544/5224354917',
  };

  static const Map<AdFormat, String> _iosTestIds = {
    AdFormat.native: 'ca-app-pub-3940256099942544/3986624511',
    AdFormat.banner: 'ca-app-pub-3940256099942544/2435281174',
    AdFormat.interstitial: 'ca-app-pub-3940256099942544/4411468910',
    AdFormat.rewarded: 'ca-app-pub-3940256099942544/1712485313',
  };
}
