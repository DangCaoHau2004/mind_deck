import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/coin_models.dart';
import 'package:mind_deck/data/repositories/coin_repository.dart';
import 'package:mind_deck/services/ad_service.dart';

enum CoinEarnStatus {
  /// Số dư đã tăng.
  earned,

  /// Xem xong nhưng hết số lần hỏi lại mà số dư chưa tăng (AdMob báo chậm).
  pending,

  /// Không có video để phát (không có xu).
  noVideo,

  /// Tự đóng video giữa chừng.
  skipped,

  /// Hôm nay đã nhận đủ xu.
  capReached,

  notSignedIn,

  /// Không kiểm tra được số dư trước khi phát video.
  failed,
}

class CoinEarnResult {
  final CoinEarnStatus status;

  /// Số dư và hạn mức mới nhất đọc được, có thể null.
  final CoinInfo? info;

  const CoinEarnResult(this.status, [this.info]);
}

/// Xem video thưởng để nhận xu. App không tự cộng xu: AdMob báo về BE, BE cộng, app hỏi lại số dư.
class CoinRewardService {
  final CoinRepository repository;
  final String? Function() userId;
  final Future<RewardedResult> Function(String userId, String placement) playVideo;

  /// AdMob có thể báo chậm vài giây. Con số do BE gợi ý (mỗi 2 giây, tối đa 5 lần).
  final Duration pollInterval;
  final int maxPolls;

  CoinRewardService({
    required this.repository,
    required this.userId,
    required this.playVideo,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 5,
  });

  /// [placement] là màn đang xem, chỉ để thống kê.
  Future<CoinEarnResult> watchVideo({required String placement}) async {
    final uid = userId();
    if (uid == null) return const CoinEarnResult(CoinEarnStatus.notSignedIn);

    final CoinInfo before;
    try {
      before = await repository.getCoins();
    } on Failure {
      return const CoinEarnResult(CoinEarnStatus.failed);
    }
    if (before.earn.capReached) return CoinEarnResult(CoinEarnStatus.capReached, before);

    switch (await playVideo(uid, placement)) {
      case RewardedResult.noVideo:
        return CoinEarnResult(CoinEarnStatus.noVideo, before);
      case RewardedResult.skipped:
        return CoinEarnResult(CoinEarnStatus.skipped, before);
      case RewardedResult.watched:
        break;
    }

    var latest = before;
    for (var i = 0; i < maxPolls; i++) {
      await Future<void>.delayed(pollInterval);
      try {
        latest = await repository.getCoins();
      } on Failure {
        continue;
      }
      if (latest.balance > before.balance) return CoinEarnResult(CoinEarnStatus.earned, latest);
    }
    return CoinEarnResult(CoinEarnStatus.pending, latest);
  }
}
