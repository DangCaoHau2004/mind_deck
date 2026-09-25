class UserNotificationSettingsModel {
  final String userId;
  final bool isMorningMotivationEnabled;
  final String morningTime;
  final bool isSrsDueEnabled;
  final String srsDueTime;
  final bool isStreakWarningEnabled;
  final bool isClassUpdateEnabled;
  final DateTime updatedAt;

  UserNotificationSettingsModel({
    required this.userId,
    required this.isMorningMotivationEnabled,
    required this.morningTime,
    required this.isSrsDueEnabled,
    required this.srsDueTime,
    required this.isStreakWarningEnabled,
    required this.isClassUpdateEnabled,
    required this.updatedAt,
  });

  factory UserNotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationSettingsModel(
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      isMorningMotivationEnabled:
          json['isMorningMotivationEnabled'] as bool? ??
          json['is_morning_motivation_enabled'] as bool? ??
          true,
      morningTime:
          json['morningTime'] as String? ??
          json['morning_time'] as String? ??
          '07:00:00',
      isSrsDueEnabled:
          json['isSrsDueEnabled'] as bool? ??
          json['is_srs_due_enabled'] as bool? ??
          true,
      srsDueTime:
          json['srsDueTime'] as String? ??
          json['srs_due_time'] as String? ??
          '20:00:00',
      isStreakWarningEnabled:
          json['isStreakWarningEnabled'] as bool? ??
          json['is_streak_warning_enabled'] as bool? ??
          true,
      isClassUpdateEnabled:
          json['isClassUpdateEnabled'] as bool? ??
          json['is_class_update_enabled'] as bool? ??
          true,
      updatedAt:
          DateTime.tryParse(
            json['updatedAt']?.toString() ??
                json['updated_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isMorningMotivationEnabled': isMorningMotivationEnabled,
      'morningTime': morningTime,
      'isSrsDueEnabled': isSrsDueEnabled,
      'srsDueTime': srsDueTime,
      'isStreakWarningEnabled': isStreakWarningEnabled,
      'isClassUpdateEnabled': isClassUpdateEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserNotificationSettingsModel copyWith({
    String? userId,
    bool? isMorningMotivationEnabled,
    String? morningTime,
    bool? isSrsDueEnabled,
    String? srsDueTime,
    bool? isStreakWarningEnabled,
    bool? isClassUpdateEnabled,
    DateTime? updatedAt,
  }) {
    return UserNotificationSettingsModel(
      userId: userId ?? this.userId,
      isMorningMotivationEnabled:
          isMorningMotivationEnabled ?? this.isMorningMotivationEnabled,
      morningTime: morningTime ?? this.morningTime,
      isSrsDueEnabled: isSrsDueEnabled ?? this.isSrsDueEnabled,
      srsDueTime: srsDueTime ?? this.srsDueTime,
      isStreakWarningEnabled:
          isStreakWarningEnabled ?? this.isStreakWarningEnabled,
      isClassUpdateEnabled: isClassUpdateEnabled ?? this.isClassUpdateEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
