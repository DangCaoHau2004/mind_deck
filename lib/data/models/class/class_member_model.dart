import '../enums.dart';
import '../user_model.dart';

class ClassMemberModel {
  final String classId;
  final String userId;
  final ClassRole role;
  final DateTime joinedAt;

  // UI optimized fields
  final UserModel? user;

  ClassMemberModel({
    required this.classId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.user,
  });

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassMemberModel(
      classId: json['classId'] as String? ?? json['class_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      role: ClassRole.fromString(json['role'] as String?),
      joinedAt:
          DateTime.tryParse(json['joinedAt']?.toString() ?? json['joined_at']?.toString() ?? '') ??
          DateTime.now(),

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
      if (user != null) 'user': user!.toJson(),
    };
  }

  ClassMemberModel copyWith({
    String? classId,
    String? userId,
    ClassRole? role,
    DateTime? joinedAt,
    UserModel? user,
  }) {
    return ClassMemberModel(
      classId: classId ?? this.classId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      user: user ?? this.user,
    );
  }
}
