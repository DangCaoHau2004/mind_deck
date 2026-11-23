/// Công tắc thông báo lớp theo loại (áp cho mọi lớp).
class ClassNotificationTypes {
  final bool assignment;
  final bool announcement;
  final bool joinRequest;
  final bool joinApproved;

  const ClassNotificationTypes({
    this.assignment = true,
    this.announcement = true,
    this.joinRequest = true,
    this.joinApproved = true,
  });

  factory ClassNotificationTypes.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ClassNotificationTypes();
    return ClassNotificationTypes(
      assignment: json['assignment'] as bool? ?? true,
      announcement: json['announcement'] as bool? ?? true,
      joinRequest: json['joinRequest'] as bool? ?? true,
      joinApproved: json['joinApproved'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'assignment': assignment,
    'announcement': announcement,
    'joinRequest': joinRequest,
    'joinApproved': joinApproved,
  };

  ClassNotificationTypes copyWith({
    bool? assignment,
    bool? announcement,
    bool? joinRequest,
    bool? joinApproved,
  }) {
    return ClassNotificationTypes(
      assignment: assignment ?? this.assignment,
      announcement: announcement ?? this.announcement,
      joinRequest: joinRequest ?? this.joinRequest,
      joinApproved: joinApproved ?? this.joinApproved,
    );
  }
}

/// Cấu hình thông báo của người dùng (`GET/PUT /notifications/settings`).
/// Giờ là `HH:MM:SS`; thẻ đến hạn luôn nhắc cố định 20:00 giờ máy nên không có giờ riêng.
class UserNotificationSettingsModel {
  final bool isAllNotificationsEnabled;
  final bool isAllClassNotificationsEnabled;
  final bool isMorningMotivationEnabled;
  final String morningTime;
  final bool isSrsDueEnabled;
  final bool isStudyReminderEnabled;
  final String studyTime;
  final bool isStreakWarningEnabled;
  final ClassNotificationTypes classNotificationTypes;

  const UserNotificationSettingsModel({
    this.isAllNotificationsEnabled = true,
    this.isAllClassNotificationsEnabled = true,
    this.isMorningMotivationEnabled = true,
    this.morningTime = '07:00:00',
    this.isSrsDueEnabled = true,
    this.isStudyReminderEnabled = false,
    this.studyTime = '20:00:00',
    this.isStreakWarningEnabled = true,
    this.classNotificationTypes = const ClassNotificationTypes(),
  });

  factory UserNotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationSettingsModel(
      isAllNotificationsEnabled: json['isAllNotificationsEnabled'] as bool? ?? true,
      isAllClassNotificationsEnabled: json['isAllClassNotificationsEnabled'] as bool? ?? true,
      isMorningMotivationEnabled: json['isMorningMotivationEnabled'] as bool? ?? true,
      morningTime: json['morningTime'] as String? ?? '07:00:00',
      isSrsDueEnabled: json['isSrsDueEnabled'] as bool? ?? true,
      isStudyReminderEnabled: json['isStudyReminderEnabled'] as bool? ?? false,
      studyTime: json['studyTime'] as String? ?? '20:00:00',
      isStreakWarningEnabled: json['isStreakWarningEnabled'] as bool? ?? true,
      classNotificationTypes: ClassNotificationTypes.fromJson(
        json['classNotificationTypes'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAllNotificationsEnabled': isAllNotificationsEnabled,
      'isAllClassNotificationsEnabled': isAllClassNotificationsEnabled,
      'isMorningMotivationEnabled': isMorningMotivationEnabled,
      'morningTime': morningTime,
      'isSrsDueEnabled': isSrsDueEnabled,
      'isStudyReminderEnabled': isStudyReminderEnabled,
      'studyTime': studyTime,
      'isStreakWarningEnabled': isStreakWarningEnabled,
      'classNotificationTypes': classNotificationTypes.toJson(),
    };
  }

  UserNotificationSettingsModel copyWith({
    bool? isAllNotificationsEnabled,
    bool? isAllClassNotificationsEnabled,
    bool? isMorningMotivationEnabled,
    String? morningTime,
    bool? isSrsDueEnabled,
    bool? isStudyReminderEnabled,
    String? studyTime,
    bool? isStreakWarningEnabled,
    ClassNotificationTypes? classNotificationTypes,
  }) {
    return UserNotificationSettingsModel(
      isAllNotificationsEnabled: isAllNotificationsEnabled ?? this.isAllNotificationsEnabled,
      isAllClassNotificationsEnabled:
          isAllClassNotificationsEnabled ?? this.isAllClassNotificationsEnabled,
      isMorningMotivationEnabled: isMorningMotivationEnabled ?? this.isMorningMotivationEnabled,
      morningTime: morningTime ?? this.morningTime,
      isSrsDueEnabled: isSrsDueEnabled ?? this.isSrsDueEnabled,
      isStudyReminderEnabled: isStudyReminderEnabled ?? this.isStudyReminderEnabled,
      studyTime: studyTime ?? this.studyTime,
      isStreakWarningEnabled: isStreakWarningEnabled ?? this.isStreakWarningEnabled,
      classNotificationTypes: classNotificationTypes ?? this.classNotificationTypes,
    );
  }
}
