import 'package:equatable/equatable.dart';

class HomeFsrsStatsModel extends Equatable {
  final int dueTodayCount;
  final int masteredCount;

  /// Độ chính xác 7 ngày (cùng cửa sổ với `chart`, BE tính theo số lần ôn). Null khi 7 ngày qua chưa ôn (khác 0%).
  final double? accuracy;
  final double? avgRetrievability;
  final int atRiskCount;
  final double atRiskThreshold;
  final List<HomeChartModel> chart;

  const HomeFsrsStatsModel({
    required this.dueTodayCount,
    required this.masteredCount,
    this.accuracy,
    this.avgRetrievability,
    this.atRiskCount = 0,
    this.atRiskThreshold = 0.7,
    required this.chart,
  });

  factory HomeFsrsStatsModel.fromJson(Map<String, dynamic> json) {
    return HomeFsrsStatsModel(
      dueTodayCount: json['dueTodayCount'] ?? json['due_today_count'] ?? 0,
      masteredCount: json['masteredCount'] ?? json['mastered_count'] ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      avgRetrievability: (json['avgRetrievability'] as num?)?.toDouble(),
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
      atRiskThreshold: (json['atRiskThreshold'] as num?)?.toDouble() ?? 0.7,
      chart:
          (json['chart'] as List<dynamic>?)?.map((e) => HomeChartModel.fromJson(e)).toList() ?? [],
    );
  }

  /// 7 ngày gần nhất (hôm nay + 6 ngày trước, giờ máy). BE bỏ ngày không ôn nên để `accuracy` null.
  List<HomeChartModel> filledChart([DateTime? now]) {
    final today = now ?? DateTime.now();
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final byDay = {for (final c in chart) key(c.date): c.accuracy};
    return [
      for (int i = 6; i >= 0; i--)
        () {
          final d = DateTime(today.year, today.month, today.day - i);
          return HomeChartModel(date: d, accuracy: byDay[key(d)]);
        }(),
    ];
  }

  @override
  List<Object?> get props => [
    dueTodayCount,
    masteredCount,
    accuracy,
    avgRetrievability,
    atRiskCount,
    atRiskThreshold,
    chart,
  ];
}

class HomeChartModel extends Equatable {
  final DateTime date;

  /// Null khi ngày đó chưa học.
  final double? accuracy;

  const HomeChartModel({required this.date, this.accuracy});

  factory HomeChartModel.fromJson(Map<String, dynamic> json) {
    return HomeChartModel(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      accuracy: double.tryParse(json['accuracy']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [date, accuracy];
}
