import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/coin_models.dart';
import 'package:mind_deck/services/ad_service.dart';
import 'package:mind_deck/services/coin_reward_service.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';

/// Nút "Xem video nhận 1 xu". Nhãn ghi rõ phần thưởng trước khi phát (theo chính sách AdMob).
class WatchVideoForCoinButton extends StatefulWidget {
  /// Màn đang đặt nút, chỉ để thống kê.
  final String placement;

  /// Gọi khi số dư đã tăng hoặc đang chờ BE xác nhận, để màn tải lại dữ liệu của nó.
  final void Function(CoinInfo? info)? onRewarded;
  final bool filled;

  const WatchVideoForCoinButton({
    super.key,
    required this.placement,
    this.onRewarded,
    this.filled = false,
  });

  @override
  State<WatchVideoForCoinButton> createState() => _WatchVideoForCoinButtonState();
}

class _WatchVideoForCoinButtonState extends State<WatchVideoForCoinButton> {
  bool _playing = false;
  bool _capReached = false;

  @override
  void initState() {
    super.initState();
    DI().sl<AdService>().preloadRewarded(AdUnit.rewardedCoin);
  }

  static String messageKeyOf(CoinEarnStatus status) {
    return switch (status) {
      CoinEarnStatus.earned => 'coin_earned',
      CoinEarnStatus.pending => 'coin_pending',
      CoinEarnStatus.noVideo => 'coin_no_video',
      CoinEarnStatus.skipped => 'coin_skipped',
      CoinEarnStatus.capReached => 'coin_cap_reached',
      CoinEarnStatus.notSignedIn => 'coin_not_signed_in',
      CoinEarnStatus.failed => 'coin_failed',
    };
  }

  Future<void> _onPressed() async {
    setState(() => _playing = true);
    final result = await DI().sl<CoinRewardService>().watchVideo(placement: widget.placement);
    if (!mounted) return;
    final info = result.info;
    setState(() {
      _playing = false;
      _capReached = result.status == CoinEarnStatus.capReached || (info?.earn.capReached ?? false);
    });
    CustomToast.show(context, CustomToast.general(message: messageKeyOf(result.status).tr));
    if (result.status == CoinEarnStatus.earned || result.status == CoinEarnStatus.pending) {
      widget.onRewarded?.call(info);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DI().sl<AdService>().isEnabled(AdUnit.rewardedCoin)) return const SizedBox.shrink();

    final onPressed = _playing || _capReached ? null : _onPressed;
    final label = Text(_capReached ? 'coin_cap_reached_short'.tr : 'coin_watch_video'.tr);
    final icon = _playing
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.ondemand_video_rounded);

    if (widget.filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: label,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      );
    }
    return TextButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}
