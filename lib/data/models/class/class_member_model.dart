import '../enums.dart';
import '../user_model.dart';

class ClassMemberModel {
  final String classId;
  final String userId;
  final ClassRole role;
  final DateTime joinedAt;

  /// `null` với học viên khi lớp không bật `showMemberEmails`.
  final String? email;

  /// ≠ null chỉ cho biết người này từng được mời (không phải trạng thái hiện tại).
  final DateTime? invitedAt;

  // UI optimized fields
  final UserModel? user;

  ClassMemberModel({
    required this.classId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.email,
    this.invitedAt,
    this.user,
  });

  String get fullName => user?.fullName ?? '';

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      classId: json['classId'] as String? ?? json['class_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      role: ClassRole.fromString(json['role'] as String?),
      joinedAt:
          DateTime.tryParse(json['joinedAt']?.toString() ?? json['joined_at']?.toString() ?? '') ??
          DateTime.now(),
      email: json['email'] as String?,
      invitedAt: DateTime.tryParse(json['invitedAt']?.toString() ?? ''),

      // Relation
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : UserModel(
              email: json["email"] ?? "",
              fullName: json["fullName"] ?? "",
              id: json["id"] ?? "",
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
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'userId': userId,
      'role': role.toJson(),
      'joinedAt': joinedAt.toIso8601String(),
      if (email != null) 'email': email,
      if (invitedAt != null) 'invitedAt': invitedAt!.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  ClassMemberModel copyWith({
    String? classId,
    String? userId,
    ClassRole? role,
    DateTime? joinedAt,
    String? email,
    DateTime? invitedAt,
    UserModel? user,
  }) {
    return ClassMemberModel(
      classId: classId ?? this.classId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      email: email ?? this.email,
      invitedAt: invitedAt ?? this.invitedAt,
      user: user ?? this.user,
    );
  }
}

/// Kết quả `DELETE /classes/:id/members/:userId` (từ chối / thu hồi lời mời / đuổi).
class RemoveMemberResult {
  final bool removed;
  final bool kicked;
  final bool wasApproved;

  /// pending | invited | approved
  final String? previousStatus;

  const RemoveMemberResult({
    this.removed = false,
    this.kicked = false,
    this.wasApproved = false,
    this.previousStatus,
  });

  factory RemoveMemberResult.fromJson(Map<String, dynamic> json) {
    return RemoveMemberResult(
      removed: json['removed'] as bool? ?? false,
      kicked: json['kicked'] as bool? ?? false,
      wasApproved: json['wasApproved'] as bool? ?? false,
      previousStatus: json['previousStatus'] as String?,
    );
  }
}
