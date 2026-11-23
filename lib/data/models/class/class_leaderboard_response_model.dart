import 'package:mind_deck/core/server_clock.dart';

/// Một dòng của bảng xếp hạng lớp (`GET /classes/:id/leaderboard`).
class LeaderboardEntryModel {
  /// `null` khi học viên chưa được xếp hạng (điểm ≤ 0) – chỉ gặp ở `me`.
  final int? rank;
  final String userId;
  final String fullName;

  /// Điểm xếp hạng 0–100 gộp điểm kiểm tra và mức chăm chỉ (tỷ trọng ở `weights`).
  final double value;

  /// Điểm kiểm tra trung bình trong tháng; `null` = không có bài áp dụng
  /// (khác `0` = có bài nhưng chưa nộp).
  final double? testScore;
  final int testCount;
  final int submittedCount;

  /// Số thẻ KHÁC NHAU của lớp đã ôn trong tháng.
  final int cardsReviewed;

  const LeaderboardEntryModel({
    this.rank,
    required this.userId,
    required this.fullName,
    required this.value,
    this.testScore,
    this.testCount = 0,
    this.submittedCount = 0,
    this.cardsReviewed = 0,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt(),
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Người dùng',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      testScore: (json['testScore'] as num?)?.toDouble(),
      testCount: (json['testCount'] as num?)?.toInt() ?? 0,
      submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
      cardsReviewed: (json['cardsReviewed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Tỷ trọng đang dùng để gộp điểm. Đọc từ server, không hardcode (BE có thể đổi).
class LeaderboardWeights {
  final double test;
  final double diligence;

  const LeaderboardWeights({this.test = 0.5, this.diligence = 0.5});

  factory LeaderboardWeights.fromJson(Object? json) {
    if (json is! Map) return const LeaderboardWeights();
    return LeaderboardWeights(
      test: (json['test'] as num?)?.toDouble() ?? 0.5,
      diligence: (json['diligence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  int get testPercent => (test * 100).round();
  int get diligencePercent => (diligence * 100).round();
}

class ClassLeaderboardResponseModel {
  /// Tháng được tính, `YYYY-MM` (giờ Việt Nam). Hiển thị nhãn từ đây, KHÔNG suy ra từ [from].
  final String month;

  /// Khoảng nửa mở `[from, to)`, UTC.
  final DateTime? from;
  final DateTime? to;
  final LeaderboardWeights weights;
  final int totalRanked;
  final List<LeaderboardEntryModel> items;

  /// Vị trí của tôi; `null` với giảng viên.
  final LeaderboardEntryModel? me;

  const ClassLeaderboardResponseModel({
    this.month = '',
    this.from,
    this.to,
    this.weights = const LeaderboardWeights(),
    this.totalRanked = 0,
    this.items = const [],
    this.me,
  });

  /// Chỉ hiện top `limit` (tối đa 50) trong tổng số người có hạng.
  bool get hasMore => totalRanked > items.length;

  factory ClassLeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    final rawMe = json['me'];
    return ClassLeaderboardResponseModel(
      month: json['month'] as String? ?? '',
      from: DateTime.tryParse(json['from']?.toString() ?? ''),
      to: DateTime.tryParse(json['to']?.toString() ?? ''),
      weights: LeaderboardWeights.fromJson(json['weights']),
      totalRanked: (json['totalRanked'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      me: rawMe is Map<String, dynamic> ? LeaderboardEntryModel.fromJson(rawMe) : null,
    );
  }
}

/// Tháng xếp hạng dạng `YYYY-MM`, tính theo giờ Việt Nam (UTC+7 cố định) như BE.
class LeaderboardMonth {
  LeaderboardMonth._();

  /// Tháng sớm nhất BE nhận.
  static const String earliest = '2000-01';

  static String format(int year, int month) => '$year-${month.toString().padLeft(2, '0')}';

  /// Tháng hiện tại theo giờ VN (dùng giờ server nếu đã biết, không dùng múi giờ máy).
  static String current([DateTime? now]) {
    final vn = (now ?? ServerClock.now()).toUtc().add(const Duration(hours: 7));
    return format(vn.year, vn.month);
  }

  static String previous(String month) => shift(month, -1);

  /// Cộng/trừ [delta] tháng.
  static String shift(String month, int delta) {
    final (y, m) = parse(month);
    final index = y * 12 + (m - 1) + delta;
    return format(index ~/ 12, index % 12 + 1);
  }

  static (int, int) parse(String month) {
    final parts = month.split('-');
    return (
      int.tryParse(parts.first) ?? 2000,
      int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1,
    );
  }

  /// `2026-10` -> `Tháng 10/2026`.
  static String label(String month) {
    if (month.isEmpty) return '';
    final (y, m) = parse(month);
    return 'Tháng $m/$y';
  }

  /// Danh sách tháng từ [from] lùi về [earliest] (mới nhất trước).
  static int countBack(String from) {
    final (y, m) = parse(from);
    final (ey, em) = parse(earliest);
    return (y * 12 + m) - (ey * 12 + em) + 1;
  }
}
