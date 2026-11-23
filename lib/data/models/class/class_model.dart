import '../user_model.dart';
import 'class_member_model.dart';
import 'class_settings_model.dart';
import '../deck_model.dart';

class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String ownerId;

  /// Chỉ giảng viên mới có; học viên (và người ngoài lớp) nhận `null`.
  final String? joinCode;
  final int memberCount;
  final bool requireApproval;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  // UI optimized fields
  /// owner | admin | tutor | student | none
  final String? myRole;

  /// approved | pending | invited | not_joined (null khi lấy từ danh sách lớp của tôi).
  final String? myStatus;
  final bool isOwner;
  final String? ownerName;

  /// Chỉ có ở `GET /classes/:id` khi mình là thành viên (vắng ở dạng xem trước).
  final ClassSettings? settings;
  final MyNotifySettings? myNotifySettings;
  final ClassPermissions? permissions;

  // UI optimized fields
  final UserModel? owner;
  final List<ClassMemberModel>? members;
  final List<DeckModel>? decks;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.joinCode,
    this.memberCount = 0,
    this.requireApproval = false,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
    this.myRole,
    this.myStatus,
    this.isOwner = false,
    this.ownerName,
    this.settings,
    this.myNotifySettings,
    this.permissions,
    this.owner,
    this.members,
    this.decks,
  });

  /// Giảng viên = owner | admin | tutor.
  bool get isTeacher => isOwner || myRole == 'owner' || myRole == 'admin' || myRole == 'tutor';

  bool get isAdminOrOwner => isOwner || myRole == 'owner' || myRole == 'admin';

  /// Thành viên đã duyệt (danh sách lớp của tôi không có `myStatus` nên coi là đã duyệt).
  bool get isMember => myStatus == null || myStatus == 'approved';

  /// Dạng xem trước của người chưa là thành viên đã duyệt (not_joined | pending | invited).
  bool get isPreview => !isMember;

  bool get canViewLeaderboard => isTeacher || (permissions?.canViewLeaderboard ?? true);
  bool get canInviteMembers => isTeacher || (permissions?.canInviteMembers ?? false);
  bool get canCloneMaterials => isTeacher || (permissions?.canCloneMaterials ?? true);

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    final rawNotify = json['myNotifySettings'];
    final rawPermissions = json['permissions'];
    return ClassModel(
      id: json['id'] as String? ?? json['classId'] as String? ?? json['class_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String? ?? json['owner_id'] as String? ?? '',
      joinCode: json['joinCode'] as String? ?? json['join_code'] as String?,
      memberCount: json['memberCount'] as int? ?? json['member_count'] as int? ?? 0,
      requireApproval:
          json['requireApproval'] as bool? ?? json['require_approval'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? json['is_public'] as bool? ?? false,
      myRole: json['myRole'] as String? ?? json['my_role'] as String?,
      myStatus: json['myStatus'] as String? ?? json['my_status'] as String?,
      isOwner: json['isOwner'] as bool? ?? json['is_owner'] as bool? ?? false,
      ownerName: json['ownerName'] as String? ?? json['owner_name'] as String?,
      settings: rawSettings is Map<String, dynamic> ? ClassSettings.fromJson(rawSettings) : null,
      myNotifySettings: rawNotify is Map<String, dynamic>
          ? MyNotifySettings.fromJson(rawNotify)
          : null,
      permissions: rawPermissions is Map<String, dynamic>
          ? ClassPermissions.fromJson(rawPermissions)
          : null,
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
      owner: json['owner'] != null
          ? UserModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => ClassMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      decks: (json['decks'] as List<dynamic>?)
          ?.map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'ownerId': ownerId,
      if (joinCode != null) 'joinCode': joinCode,
      'memberCount': memberCount,
      'requireApproval': requireApproval,
      'isPublic': isPublic,
      if (myRole != null) 'myRole': myRole,
      if (myStatus != null) 'myStatus': myStatus,
      'isOwner': isOwner,
      if (ownerName != null) 'ownerName': ownerName,
      if (settings != null) 'settings': settings!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (owner != null) 'owner': owner!.toJson(),
      if (members != null) 'members': members!.map((e) => e.toJson()).toList(),
      if (decks != null) 'decks': decks!.map((e) => e.toJson()).toList(),
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? joinCode,
    int? memberCount,
    bool? requireApproval,
    bool? isPublic,
    String? myRole,
    String? myStatus,
    bool? isOwner,
    String? ownerName,
    ClassSettings? settings,
    MyNotifySettings? myNotifySettings,
    ClassPermissions? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? owner,
    List<ClassMemberModel>? members,
    List<DeckModel>? decks,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      joinCode: joinCode ?? this.joinCode,
      memberCount: memberCount ?? this.memberCount,
      requireApproval: requireApproval ?? this.requireApproval,
      isPublic: isPublic ?? this.isPublic,
      myRole: myRole ?? this.myRole,
      myStatus: myStatus ?? this.myStatus,
      isOwner: isOwner ?? this.isOwner,
      ownerName: ownerName ?? this.ownerName,
      settings: settings ?? this.settings,
      myNotifySettings: myNotifySettings ?? this.myNotifySettings,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      members: members ?? this.members,
      decks: decks ?? this.decks,
    );
  }
}
