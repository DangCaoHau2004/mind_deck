import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/services/ad_service.dart';

/// Banner thích ứng theo chiều rộng màn hình, đặt ở đáy màn (`Scaffold.bottomNavigationBar`).
/// Chưa tải được hoặc lỗi thì không chiếm chỗ.
class BannerAdSlot extends StatefulWidget {
  final AdUnit unit;

  const BannerAdSlot({super.key, required this.unit});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  final AdService _adService = DI().sl<AdService>();
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load(MediaQuery.sizeOf(context).width.truncate());
  }

  Future<void> _load(int width) async {
    final unit = widget.unit;
    if (!_adService.isEnabled(unit)) return;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    _ad = BannerAd(
      adUnitId: unit.id,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
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
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        height: ad.size.height.toDouble(),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
