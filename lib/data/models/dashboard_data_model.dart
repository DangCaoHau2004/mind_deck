import 'package:equatable/equatable.dart';

class DashboardDataModel extends Equatable {
  final DashboardUserModel user;
  final DashboardFsrsStatsModel fsrsStats;
  final List<DashboardRecentDeckModel> recentDecks;
  final List<DashboardClassModel> classes;

  const DashboardDataModel({
    required this.user,
    required this.fsrsStats,
    required this.recentDecks,
    required this.classes,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      user: DashboardUserModel.fromJson(json['user'] ?? {}),
      fsrsStats: DashboardFsrsStatsModel.fromJson(json['fsrs_stats'] ?? {}),
      recentDecks:
          (json['recent_decks'] as List<dynamic>?)
              ?.map((e) => DashboardRecentDeckModel.fromJson(e))
              .toList() ??
          [],
      classes:
          (json['classes'] as List<dynamic>?)
              ?.map((e) => DashboardClassModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [user, fsrsStats, recentDecks, classes];
}

class DashboardUserModel extends Equatable {
  final String fullName;
  final int currentStreak;
  final int unreadNotifications;

  const DashboardUserModel({
    required this.fullName,
    required this.currentStreak,
    required this.unreadNotifications,
  });

  factory DashboardUserModel.fromJson(Map<String, dynamic> json) {
    return DashboardUserModel(
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      currentStreak: json['currentStreak'] ?? json['current_streak'] ?? 0,
      unreadNotifications:
          json['unreadNotifications'] ?? json['unread_notifications'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [fullName, currentStreak, unreadNotifications];
}

class DashboardFsrsStatsModel extends Equatable {
  final int dueTodayCount;
  final int masteredCount;
  final double retentionRate;
  final List<DashboardChartModel> chart;

  const DashboardFsrsStatsModel({
    required this.dueTodayCount,
    required this.masteredCount,
    required this.retentionRate,
    required this.chart,
  });

  factory DashboardFsrsStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardFsrsStatsModel(
      dueTodayCount: json['dueTodayCount'] ?? json['due_today_count'] ?? 0,
      masteredCount: json['masteredCount'] ?? json['mastered_count'] ?? 0,
      retentionRate: (json['retentionRate'] ?? json['retention_rate'] ?? 0.0)
          .toDouble(),
      chart:
          (json['chart'] as List<dynamic>?)
              ?.map((e) => DashboardChartModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    dueTodayCount,
    masteredCount,
    retentionRate,
    chart,
  ];
}

class DashboardChartModel extends Equatable {
  final DateTime date;
  final double accuracy;

  const DashboardChartModel({required this.date, required this.accuracy});

  factory DashboardChartModel.fromJson(Map<String, dynamic> json) {
    return DashboardChartModel(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      accuracy: double.tryParse(json['accuracy']?.toString() ?? '0') ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [date, accuracy];
}

class DashboardRecentDeckModel extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String progressText;

  const DashboardRecentDeckModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.progressText,
  });

  factory DashboardRecentDeckModel.fromJson(Map<String, dynamic> json) {
    return DashboardRecentDeckModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'folder',
      color: json['color'] ?? '#02569B',
      progressText: json['progressText'] ?? json['progress_text'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, progressText];
}

class DashboardClassModel extends Equatable {
  final String id;
  final String name;
  final String activityText;

  const DashboardClassModel({
    required this.id,
    required this.name,
    required this.activityText,
  });

  factory DashboardClassModel.fromJson(Map<String, dynamic> json) {
    return DashboardClassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      activityText: json['activityText'] ?? json['activity_text'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, activityText];
}
