import 'enums.dart';
import 'user_notification_settings_model.dart';
import 'social_account_model.dart';
import 'user_device_model.dart';

class UserModel {
  final String id;
  final String email;
  final String? password; // Null if signed in via Google / Social Login
  final String fullName;
  final UserRole role;
  final UserPlan plan;
  final bool isLocked;
  final DateTime? lockedUntil;
  final DateTime? lastStudyAt;
  final int currentStreak;
  final int maxStreak;
  final DateTime createdAt;
  final DateTime updatedAt;

  // UI optimized fields (Optional relationships)
  final UserNotificationSettingsModel? notificationSettings;
  final List<SocialAccountModel>? socialAccounts;
  final List<UserDeviceModel>? devices;

  UserModel({
    required this.id,
    required this.email,
    this.password,
    required this.fullName,
    this.role = UserRole.user,
    this.plan = UserPlan.free,
    this.isLocked = false,
    this.lockedUntil,
    this.lastStudyAt,
    this.currentStreak = 0,
    this.maxStreak = 0,
    required this.createdAt,
    required this.updatedAt,
    this.notificationSettings,
    this.socialAccounts,
    this.devices,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String?,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      plan: UserPlan.fromString(json['plan'] as String?),
      isLocked: json['isLocked'] as bool? ?? json['is_locked'] as bool? ?? false,
      lockedUntil: json['lockedUntil'] != null
          ? DateTime.tryParse(json['lockedUntil'].toString())
          : (json['locked_until'] != null
                ? DateTime.tryParse(json['locked_until'].toString())
                : null),
      lastStudyAt: json['lastStudyAt'] != null
          ? DateTime.tryParse(json['lastStudyAt'].toString())
          : (json['last_study_at'] != null
                ? DateTime.tryParse(json['last_study_at'].toString())
                : (json['lastStudyDate'] != null
                      ? DateTime.tryParse(json['lastStudyDate'].toString())
                      : (json['last_study_date'] != null
                            ? DateTime.tryParse(json['last_study_date'].toString())
                            : null))),
      currentStreak: json['currentStreak'] as int? ?? json['current_streak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? json['max_streak'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '',
          ) ??
          DateTime.now(),

      // Relations
      notificationSettings: json['notificationSettings'] != null
          ? UserNotificationSettingsModel.fromJson(
              json['notificationSettings'] as Map<String, dynamic>,
            )
          : (json['notification_settings'] != null
                ? UserNotificationSettingsModel.fromJson(
                    json['notification_settings'] as Map<String, dynamic>,
                  )
                : null),
      socialAccounts:
          (json['socialAccounts'] as List<dynamic>?)
              ?.map((e) => SocialAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['social_accounts'] as List<dynamic>?)
              ?.map((e) => SocialAccountModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      devices: (json['devices'] as List<dynamic>?)
          ?.map((e) => UserDeviceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (password != null) 'password': password,
      'fullName': fullName,
      'role': role.toJson(),
      'plan': plan.toJson(),
      'isLocked': isLocked,
      'lockedUntil': lockedUntil?.toIso8601String(),
      'lastStudyAt': lastStudyAt?.toIso8601String(),
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (notificationSettings != null) 'notificationSettings': notificationSettings!.toJson(),
      if (socialAccounts != null) 'socialAccounts': socialAccounts!.map((e) => e.toJson()).toList(),
      if (devices != null) 'devices': devices!.map((e) => e.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? fullName,
    UserRole? role,
    UserPlan? plan,
    bool? isLocked,
    DateTime? lockedUntil,
    DateTime? lastStudyAt,
    int? currentStreak,
    int? maxStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserNotificationSettingsModel? notificationSettings,
    List<SocialAccountModel>? socialAccounts,
    List<UserDeviceModel>? devices,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      isLocked: isLocked ?? this.isLocked,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      lastStudyAt: lastStudyAt ?? this.lastStudyAt,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      socialAccounts: socialAccounts ?? this.socialAccounts,
      devices: devices ?? this.devices,
    );
  }
}
