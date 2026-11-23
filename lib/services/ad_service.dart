import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mind_deck/constants/ad_units.dart';

enum RewardedResult {
  /// Xem hết video.
  watched,

  /// Không có video (lỗi tải, hết thời gian chờ, không hiện được). Không có xác nhận từ AdMob
  /// nên không có phần thưởng.
  noVideo,

  /// Người dùng tự đóng giữa chừng.
  skipped,
}

/// Quản lý quảng cáo AdMob: bật/tắt theo đơn vị, tải sẵn và hiện quảng cáo toàn màn hình.
class AdService {
  // Đang căn chỉnh giao diện nên bật hết. Trước khi phát hành hạ xuống mức ít quảng cáo
  // (sau này đọc từ Remote Config `ads_config`).
  static const bool _adsEnabled = true;
  static const Set<AdUnit> _disabledUnits = {};

  // Khoảng cách tối thiểu giữa hai interstitial. Để 0 khi thử; con số khi phát hành do thiết kế chọn.
  static const Duration _minInterstitialGap = Duration.zero;

  // Thời gian chờ tải video có thưởng, con số do thiết kế chọn, chưa đo.
  static const Duration _rewardedLoadTimeout = Duration(seconds: 8);

  final FirebaseAnalytics _analytics;
  final Map<AdUnit, InterstitialAd> _interstitials = {};
  final Set<AdUnit> _loadingInterstitials = {};
  final Map<AdUnit, RewardedAd> _rewardedAds = {};
  final Map<AdUnit, Future<RewardedAd?>> _loadingRewarded = {};
  DateTime? _lastFullscreenAt;
  bool _fullscreenShowing = false;
  Future<void>? _initFuture;

  AdService({FirebaseAnalytics? analytics}) : _analytics = analytics ?? FirebaseAnalytics.instance;

  bool isEnabled(AdUnit unit) => _adsEnabled && !_disabledUnits.contains(unit);

  Future<void> initialize() => _initFuture ??= _initialize();

  Future<void> _initialize() async {
    await MobileAds.instance.initialize();
    for (final unit in AdUnit.values) {
      if (unit.format == AdFormat.interstitial) preloadInterstitial(unit);
    }
  }

  void logEvent(AdUnit unit, String event, {String? placement}) {
    // Tiền tố `app_` để tránh trùng tên sự kiện dành riêng của Firebase (ad_impression, ad_click...).
    unawaited(
      _analytics
          .logEvent(
            name: 'app_ad_$event',
            parameters: {
              'ad_unit': unit.unitName,
              'ad_format': unit.format.name,
              'placement': ?placement,
            },
          )
          .catchError((Object e) => debugPrint('Ghi sự kiện quảng cáo lỗi: $e')),
    );
  }

  void preloadInterstitial(AdUnit unit) {
    if (!isEnabled(unit) || _interstitials.containsKey(unit)) return;
    if (!_loadingInterstitials.add(unit)) return;
    InterstitialAd.load(
      adUnitId: unit.id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitials.remove(unit);
          _interstitials[unit] = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitials.remove(unit);
          logEvent(unit, 'failed');
          debugPrint('Tải ${unit.unitName} lỗi: ${error.message}');
        },
      ),
    );
  }

  /// Hiện interstitial nếu đã tải sẵn và chờ người dùng đóng. Chưa tải xong thì bỏ qua lần này.
  Future<void> showInterstitial(AdUnit unit) async {
    final ad = _interstitials[unit];
    final last = _lastFullscreenAt;
    final tooSoon = last != null && DateTime.now().difference(last) < _minInterstitialGap;
    if (ad == null || !isEnabled(unit) || _fullscreenShowing || tooSoon) {
      preloadInterstitial(unit);
      return;
    }
    _interstitials.remove(unit);
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = _fullscreenCallback<InterstitialAd>(unit, closed);
    _fullscreenShowing = true;
    await ad.show();
    await closed.future;
    preloadInterstitial(unit);
  }

  /// Tải sẵn video có thưởng, gọi khi vào màn có nút xem video.
  void preloadRewarded(AdUnit unit) {
    if (isEnabled(unit)) unawaited(_loadRewarded(unit));
  }

  Future<RewardedAd?> _loadRewarded(AdUnit unit) {
    final cached = _rewardedAds[unit];
    if (cached != null) return Future.value(cached);
    return _loadingRewarded[unit] ??= _requestRewarded(unit);
  }

  Future<RewardedAd?> _requestRewarded(AdUnit unit) {
    final loaded = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: unit.id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded.remove(unit);
          _rewardedAds[unit] = ad;
          loaded.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded.remove(unit);
          logEvent(unit, 'failed');
          debugPrint('Tải ${unit.unitName} lỗi: ${error.message}');
          loaded.complete(null);
        },
      ),
    );
    return loaded.future;
  }

  /// Phát video có thưởng. Video đã tải sẵn thì phát ngay, chưa có thì chờ tối đa [_rewardedLoadTimeout].
  /// [userId] được gắn vào xác minh phía máy chủ để BE biết cộng xu cho ai; [placement] là màn xem.
  Future<RewardedResult> showRewarded(AdUnit unit, {String? userId, String? placement}) async {
    if (_fullscreenShowing) return RewardedResult.skipped;
    final ad = isEnabled(unit)
        ? await _loadRewarded(unit).timeout(_rewardedLoadTimeout, onTimeout: () => null)
        : null;
    if (ad == null) {
      logEvent(unit, 'no_video', placement: placement);
      return RewardedResult.noVideo;
    }
    if (_fullscreenShowing) return RewardedResult.skipped;
    _rewardedAds.remove(unit);

    if (userId != null) {
      try {
        await ad.setServerSideOptions(ServerSideVerificationOptions(userId: userId));
      } catch (e) {
        // Thiếu userId thì BE không cộng được xu, nên không phát.
        debugPrint('Gắn userId cho ${unit.unitName} lỗi: $e');
        await ad.dispose();
        return RewardedResult.noVideo;
      }
    }

    var earned = false;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = _fullscreenCallback<RewardedAd>(unit, closed);
    _fullscreenShowing = true;
    await ad.show(
      onUserEarnedReward: (_, _) {
        earned = true;
        logEvent(unit, 'reward', placement: placement);
      },
    );
    final shown = await closed.future;
    preloadRewarded(unit);
    if (earned) return RewardedResult.watched;
    if (shown) return RewardedResult.skipped;
    logEvent(unit, 'no_video', placement: placement);
    return RewardedResult.noVideo;
  }

  FullScreenContentCallback<T> _fullscreenCallback<T extends Ad>(
    AdUnit unit,
    Completer<bool> closed,
  ) {
    void finish(Ad ad, {required bool shown}) {
      ad.dispose();
      _fullscreenShowing = false;
      _lastFullscreenAt = DateTime.now();
      if (!closed.isCompleted) closed.complete(shown);
    }

    return FullScreenContentCallback<T>(
      onAdImpression: (_) => logEvent(unit, 'impression'),
      onAdClicked: (_) => logEvent(unit, 'click'),
      onAdDismissedFullScreenContent: (ad) => finish(ad, shown: true),
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Hiện ${unit.unitName} lỗi: ${error.message}');
        finish(ad, shown: false);
      },
    );
  }
}
