class UserDeviceModel {
  final String id;
  final String userId;
  final String fcmToken;
  final String? deviceName;
  final DateTime createdAt;
  final DateTime lastActive;

  UserDeviceModel({
    required this.id,
    required this.userId,
    required this.fcmToken,
    this.deviceName,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) {
    return UserDeviceModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      fcmToken:
          json['fcmToken'] as String? ?? json['fcm_token'] as String? ?? '',
      deviceName:
          json['deviceName'] as String? ?? json['device_name'] as String?,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      lastActive:
          DateTime.tryParse(
            json['lastActive']?.toString() ??
                json['last_active']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fcmToken': fcmToken,
      'deviceName': deviceName,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  UserDeviceModel copyWith({
    String? id,
    String? userId,
    String? fcmToken,
    String? deviceName,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserDeviceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceName: deviceName ?? this.deviceName,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
