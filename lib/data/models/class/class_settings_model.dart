/// Các loại thông báo của lớp (khóa snake_case đúng như BE trả về).
class ClassNotifyTypes {
  ClassNotifyTypes._();

  static const String assignment = 'assignment';
  static const String test = 'test';
  static const String announcement = 'announcement';
  static const String materialAdded = 'material_added';
  static const String joinRequest = 'join_request';
  static const String submission = 'submission';
  static const String memberLeft = 'member_left';

  static const List<String> all = [
    assignment,
    test,
    announcement,
    materialAdded,
    joinRequest,
    submission,
    memberLeft,
  ];
}

bool _asBool(Object? v, {required bool fallback}) => v is bool ? v : fallback;

/// Cài đặt cấp lớp (chỉ owner/admin sửa được).
class ClassSettings {
  final bool allowMemberAdd;
  final bool allowMemberClone;
  final bool showLeaderboard;
  final bool showMemberEmails;

  /// Công tắc cấp lớp cho từng loại thông báo; khóa thiếu = bật.
  final Map<String, bool> notifications;

  const ClassSettings({
    this.allowMemberAdd = false,
    this.allowMemberClone = true,
    this.showLeaderboard = true,
    this.showMemberEmails = false,
    this.notifications = const {},
  });

  factory ClassSettings.fromJson(Map<String, dynamic> json) {
    final rawNotifications = json['notifications'];
    return ClassSettings(
      allowMemberAdd: _asBool(json['allowMemberAdd'], fallback: false),
      allowMemberClone: _asBool(json['allowMemberClone'], fallback: true),
      showLeaderboard: _asBool(json['showLeaderboard'], fallback: true),
      showMemberEmails: _asBool(json['showMemberEmails'], fallback: false),
      notifications: rawNotifications is Map
          ? {
              for (final e in rawNotifications.entries)
                if (e.value is bool) e.key.toString(): e.value as bool,
            }
          : const {},
    );
  }

  bool notifyEnabled(String type) => notifications[type] ?? true;

  Map<String, dynamic> toJson() => {
    'allowMemberAdd': allowMemberAdd,
    'allowMemberClone': allowMemberClone,
    'showLeaderboard': showLeaderboard,
    'showMemberEmails': showMemberEmails,
    'notifications': notifications,
  };

  ClassSettings copyWith({
    bool? allowMemberAdd,
    bool? allowMemberClone,
    bool? showLeaderboard,
    bool? showMemberEmails,
    Map<String, bool>? notifications,
  }) {
    return ClassSettings(
      allowMemberAdd: allowMemberAdd ?? this.allowMemberAdd,
      allowMemberClone: allowMemberClone ?? this.allowMemberClone,
      showLeaderboard: showLeaderboard ?? this.showLeaderboard,
      showMemberEmails: showMemberEmails ?? this.showMemberEmails,
      notifications: notifications ?? this.notifications,
    );
  }
}

/// Cài đặt thông báo CỦA TÔI trong lớp (`muted` + 7 loại, thiếu = bật).
class MyNotifySettings {
  final bool muted;
  final Map<String, bool> types;

  const MyNotifySettings({this.muted = false, this.types = const {}});

  factory MyNotifySettings.fromJson(Map<String, dynamic> json) {
    return MyNotifySettings(
      muted: _asBool(json['muted'], fallback: false),
      types: {
        for (final type in ClassNotifyTypes.all)
          if (json[type] is bool) type: json[type] as bool,
      },
    );
  }

  bool enabled(String type) => types[type] ?? true;

  MyNotifySettings copyWith({bool? muted, Map<String, bool>? types}) =>
      MyNotifySettings(muted: muted ?? this.muted, types: types ?? this.types);
}

/// Gợi ý quyền cho UI (server vẫn kiểm tra lại). Giảng viên luôn true.
class ClassPermissions {
  final bool canInviteMembers;
  final bool canCloneMaterials;
  final bool canViewLeaderboard;

  const ClassPermissions({
    this.canInviteMembers = false,
    this.canCloneMaterials = true,
    this.canViewLeaderboard = true,
  });

  factory ClassPermissions.fromJson(Map<String, dynamic> json) {
    return ClassPermissions(
      canInviteMembers: _asBool(json['canInviteMembers'], fallback: false),
      canCloneMaterials: _asBool(json['canCloneMaterials'], fallback: true),
      canViewLeaderboard: _asBool(json['canViewLeaderboard'], fallback: true),
    );
  }
}
