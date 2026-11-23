/// Tên tính năng trong `features` của `GET /coins`.
class CoinFeatureKeys {
  CoinFeatureKeys._();

  static const String aiImport = 'ai_import';

  /// Chưa có trong BE; có giá thì app tự hỏi xu trước khi tạo đề tự soạn.
  static const String customTest = 'custom_test';
}

/// Giá xu của một tính năng (`features.<tên>.coinPrice` của `GET /coins`).
class CoinPrice {
  /// `fixed` (giá cố định) hoặc `per_unit` (theo đơn vị, vd cứ 20 ảnh một xu).
  final String type;
  final int coins;
  final int unit;
  final int coinsPerUnit;
  final int? max;

  const CoinPrice({
    this.type = 'fixed',
    this.coins = 0,
    this.unit = 0,
    this.coinsPerUnit = 0,
    this.max,
  });

  factory CoinPrice.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return CoinPrice(
      type: json['type'] as String? ?? 'fixed',
      coins: asInt(json['coins']),
      unit: asInt(json['unit']),
      coinsPerUnit: asInt(json['coinsPerUnit']),
      max: (json['max'] as num?)?.toInt(),
    );
  }

  /// Giá cho [units] đơn vị (làm tròn lên, không vượt `max`). Giá cố định bỏ qua [units].
  int priceFor(int units) {
    if (type != 'per_unit' || unit <= 0) return coins;
    final price = (units / unit).ceil() * coinsPerUnit;
    final cap = max;
    return cap != null && price > cap ? cap : price;
  }
}

class CoinFeature {
  final bool allowed;
  final int freePerDay;

  /// null: tính năng không dùng xu.
  final CoinPrice? price;

  const CoinFeature({this.allowed = true, this.freePerDay = 0, this.price});

  factory CoinFeature.fromJson(Map<String, dynamic> json) {
    final price = json['coinPrice'];
    return CoinFeature(
      allowed: json['allowed'] as bool? ?? true,
      freePerDay: (json['freePerDay'] as num?)?.toInt() ?? 0,
      price: price is Map<String, dynamic> ? CoinPrice.fromJson(price) : null,
    );
  }
}

/// Hạn mức kiếm xu bằng video trong ngày.
class CoinEarn {
  final int perVideo;
  final int dailyCap;
  final int earnedToday;
  final int remainingToday;
  final DateTime? resetsAt;

  const CoinEarn({
    this.perVideo = 1,
    this.dailyCap = 0,
    this.earnedToday = 0,
    this.remainingToday = 0,
    this.resetsAt,
  });

  factory CoinEarn.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return CoinEarn(
      perVideo: (json['perVideo'] as num?)?.toInt() ?? 1,
      dailyCap: asInt(json['dailyCap']),
      earnedToday: asInt(json['earnedToday']),
      remainingToday: asInt(json['remainingToday']),
      resetsAt: DateTime.tryParse(json['resetsAt']?.toString() ?? '')?.toLocal(),
    );
  }

  bool get capReached => remainingToday <= 0;
}

/// `GET /coins`.
class CoinInfo {
  final int balance;
  final String plan;
  final CoinEarn earn;
  final Map<String, CoinFeature> features;

  const CoinInfo({
    this.balance = 0,
    this.plan = 'free',
    this.earn = const CoinEarn(),
    this.features = const {},
  });

  factory CoinInfo.fromJson(Map<String, dynamic> json) {
    final features = json['features'];
    return CoinInfo(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      plan: json['plan'] as String? ?? 'free',
      earn: CoinEarn.fromJson(json['earn'] as Map<String, dynamic>? ?? const {}),
      features: features is Map<String, dynamic>
          ? {
              for (final e in features.entries)
                if (e.value is Map<String, dynamic>)
                  e.key: CoinFeature.fromJson(e.value as Map<String, dynamic>),
            }
          : const {},
    );
  }
}

/// Một dòng của `GET /coins/history`.
class CoinTransaction {
  final String id;

  /// Dương là cộng, âm là trừ.
  final int amount;
  final int balanceAfter;

  /// `ad_video`, `ai_import`, `refund`, `admin_adjust` (có thể thêm loại mới).
  final String reason;
  final String? refId;
  final DateTime? createdAt;

  const CoinTransaction({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.reason,
    this.refId,
    this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      refId: json['refId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }
}

class CoinHistoryPage {
  final List<CoinTransaction> items;
  final bool hasMore;

  const CoinHistoryPage({required this.items, required this.hasMore});
}
