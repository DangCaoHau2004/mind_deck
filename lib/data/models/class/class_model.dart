import '../user_model.dart';
import 'class_member_model.dart';
import '../deck_model.dart';

class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String joinCode;
  final int memberCount;
  final bool requireApproval;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  // UI optimized fields
  final String? myRole;
  final String? myStatus;
  final bool isOwner;
  final String? ownerName;

  // UI optimized fields
  final UserModel? owner;
  final List<ClassMemberModel>? members;
  final List<DeckModel>? decks;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.joinCode,
    this.memberCount = 0,
    this.requireApproval = false,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
    this.myRole,
    this.myStatus,
    this.isOwner = false,
    this.ownerName,
    this.owner,
    this.members,
    this.decks,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String? ?? json['classId'] as String? ?? json['class_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String? ?? json['owner_id'] as String? ?? '',
      joinCode: json['joinCode'] as String? ?? json['join_code'] as String? ?? '',
      memberCount: json['memberCount'] as int? ?? json['member_count'] as int? ?? 0,
      requireApproval:
          json['requireApproval'] as bool? ?? json['require_approval'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? json['is_public'] as bool? ?? false,
      myRole: json['myRole'] as String? ?? json['my_role'] as String?,
      myStatus: json['myStatus'] as String? ?? json['my_status'] as String?,
      isOwner: json['isOwner'] as bool? ?? json['is_owner'] as bool? ?? false,
      ownerName: json['ownerName'] as String? ?? json['owner_name'] as String?,
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
      'joinCode': joinCode,
      'memberCount': memberCount,
      'requireApproval': requireApproval,
      'isPublic': isPublic,
      if (myRole != null) 'myRole': myRole,
      if (myStatus != null) 'myStatus': myStatus,
      'isOwner': isOwner,
      if (ownerName != null) 'ownerName': ownerName,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      members: members ?? this.members,
      decks: decks ?? this.decks,
    );
  }
}
