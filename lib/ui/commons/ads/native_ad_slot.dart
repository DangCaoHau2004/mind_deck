import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/services/ad_service.dart';

/// Quảng cáo native dùng mẫu có sẵn của plugin, bọc trong thẻ bo góc giống các thẻ nội dung.
/// Chưa tải được hoặc lỗi thì không chiếm chỗ.
class NativeAdSlot extends StatefulWidget {
  final AdUnit unit;
  final TemplateType templateType;
  final EdgeInsetsGeometry margin;

  /// false: vẫn tải quảng cáo nhưng chưa hiện (vd. màn đang skeleton), để khi nội dung về
  /// thì quảng cáo thường đã sẵn và hiện cùng lúc, đỡ đẩy nội dung bên dưới.
  final bool visible;

  const NativeAdSlot({
    super.key,
    required this.unit,
    this.templateType = TemplateType.small,
    this.margin = const EdgeInsets.only(top: 18, bottom: 12, left: 24, right: 24),
    this.visible = true,
  });

  @override
  State<NativeAdSlot> createState() => _NativeAdSlotState();
}

class _NativeAdSlotState extends State<NativeAdSlot> with AutomaticKeepAliveClientMixin {
  final AdService _adService = DI().sl<AdService>();
  NativeAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  // Ô đã bị cuộn ra xa và tháo khỏi cây (chờ hủy) mà quảng cáo mới tải xong: `mounted` vẫn true
  // nên phải tự theo dõi, nếu không `updateKeepAlive()` sẽ tra cứu widget đã deactivate và báo lỗi.
  bool _active = true;

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  // Giữ ô (và quảng cáo đã tải) khi bị cuộn ra xa trong danh sách, để cuộn lại không phải tải lại.
  @override
  bool get wantKeepAlive => _loaded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load(Theme.of(context).colorScheme);
  }

  void _load(ColorScheme colorScheme) {
    final unit = widget.unit;
    if (!_adService.isEnabled(unit)) return;
    _ad = NativeAd(
      adUnitId: unit.id,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
          if (_active) updateKeepAlive();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
          _adService.logEvent(unit, 'failed');
          debugPrint('Tải ${unit.unitName} lỗi: ${error.message}');
        },
        onAdImpression: (_) => _adService.logEvent(unit, 'impression'),
        onAdClicked: (_) => _adService.logEvent(unit, 'click'),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: colorScheme.surface,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurface,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurface.withValues(alpha: 0.6),
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurface.withValues(alpha: 0.6),
          size: 12,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (!widget.visible || !_loaded || ad == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final height = widget.templateType == TemplateType.small ? 110.0 : 340.0;

    return Padding(
      padding: widget.margin,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                'ad_label'.tr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            SizedBox(
              height: height,
              child: AdWidget(ad: ad),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tính vị trí chèn quảng cáo native vào danh sách: sau mục thứ [first], rồi cứ [every] mục chèn một ô,
/// tối đa [maxAds] ô (null = không giới hạn). Danh sách ít hơn [first] mục hoặc [enabled] = false thì
/// không chèn. Các con số mặc định do thiết kế chọn, chưa đo.
class NativeAdPositions {
  final int itemCount;
  final bool enabled;
  final int first;
  final int every;
  final int? maxAds;

  const NativeAdPositions({
    required this.itemCount,
    this.enabled = true,
    this.first = 4,
    this.every = 10,
    this.maxAds,
  });

  int get adCount {
    if (!enabled || itemCount < first) return 0;
    final count = 1 + (itemCount - first) ~/ every;
    return maxAds == null ? count : math.min(count, maxAds!);
  }

  /// Tổng số ô (mục + quảng cáo).
  int get totalCount => itemCount + adCount;

  bool isAd(int index) {
    if (adCount == 0 || index >= totalCount || index < first) return false;
    final offset = index - first;
    return offset % (every + 1) == 0 && offset ~/ (every + 1) < adCount;
  }

  /// Vị trí của mục trong danh sách gốc ứng với ô [index] (ô không phải quảng cáo).
  /// Ô sau mục cuối cùng (ví dụ ô loading) trả về [itemCount].
  int itemIndex(int index) {
    if (adCount == 0 || index < first) return index;
    return index - math.min(adCount, (index - first - 1) ~/ (every + 1) + 1);
  }
}
