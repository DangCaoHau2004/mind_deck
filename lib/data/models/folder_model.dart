import 'deck_model.dart';
import 'tag_model.dart';

class FolderModel {
  final String id;
  final String userId;

  /// Khác null = bản sao học liệu của lớp; `clonedFromId` = folder nguồn.
  final String? classId;
  final String? clonedFromId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final String shareMode;
  final int savedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOwner;
  final bool isPublic;
  final String? shareToken;
  final bool canClone;

  /// Có quyền sửa/xóa thư mục (BE trả ở chi tiết thư mục).
  final bool canEdit;
  final bool isStarred;

  // UI optimized fields
  final List<DeckModel>? decks;
  final int? deckCount;

  /// Số thẻ cần ôn hôm nay (chỉ có ở danh sách và chi tiết folder).
  final int? dueCount;
  final String? authorName;
  final List<TagModel>? tags;

  FolderModel({
    required this.id,
    required this.userId,
    this.classId,
    this.clonedFromId,
    required this.name,
    this.description,
    this.icon = 'default_icon',
    this.color = '#FFFFFF',
    this.shareMode = 'private',
    this.savedCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isOwner = false,
    this.isPublic = false,
    this.shareToken,
    this.canClone = false,
    this.canEdit = false,
    this.isStarred = false,
    this.decks,
    this.deckCount,
    this.dueCount,
    this.authorName,
    this.tags,
  });

  /// Dữ liệu giữ chỗ cho skeleton (chữ không quan trọng, chỉ cần đủ dài để bố cục giống thật).
  factory FolderModel.placeholder() => FolderModel(
    id: '',
    userId: '',
    name: 'Tên thư mục mẫu',
    color: '#1565C0',
    isPublic: true,
    deckCount: 3,
    dueCount: 5,
    tags: [
      const TagModel(id: '', name: 'tag-mau'),
      const TagModel(id: '', name: 'hoc-tap'),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  bool get isClassCopy => classId != null && classId!.isNotEmpty;

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    final folderJson = json['folder'] as Map<String, dynamic>? ?? json;
    return FolderModel(
      id: folderJson['id'] as String? ?? '',
      userId: folderJson['userId'] as String? ?? folderJson['user_id'] as String? ?? '',
      classId: folderJson['classId'] as String? ?? folderJson['class_id'] as String?,
      clonedFromId:
          folderJson['clonedFromId'] as String? ?? folderJson['cloned_from_id'] as String?,
      name: folderJson['name'] as String? ?? '',
      description: folderJson['description'] as String?,
      icon: folderJson['icon'] as String? ?? 'default_icon',
      color:
          (folderJson['color'] as String?)?.isNotEmpty == true && folderJson['color'] != '#FFFFFF'
          ? folderJson['color'] as String
          : (json['color'] as String? ?? '#1565C0'),
      shareMode:
          folderJson['accessLevel'] as String? ??
          folderJson['access_level'] as String? ??
          folderJson['shareMode'] as String? ??
          folderJson['share_mode'] as String? ??
          'private',
      savedCount: folderJson['savedCount'] as int? ?? folderJson['saved_count'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(
            folderJson['createdAt']?.toString() ?? folderJson['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            folderJson['updatedAt']?.toString() ?? folderJson['updated_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      isOwner: folderJson['isOwner'] as bool? ?? folderJson['is_owner'] as bool? ?? false,
      isPublic: folderJson['isPublic'] as bool? ?? folderJson['is_public'] as bool? ?? false,
      shareToken: folderJson['shareToken'] as String? ?? folderJson['share_token'] as String?,
      canClone: folderJson['canClone'] as bool? ?? folderJson['can_clone'] as bool? ?? false,
      canEdit: folderJson['canEdit'] as bool? ?? folderJson['can_edit'] as bool? ?? false,
      isStarred: folderJson['isStarred'] as bool? ?? folderJson['is_starred'] as bool? ?? false,

      // Relations & UI properties
      decks: (folderJson['decks'] as List<dynamic>?)
          ?.map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      deckCount: folderJson['deckCount'] as int? ?? folderJson['deck_count'] as int?,
      dueCount: (folderJson['dueCount'] as num?)?.toInt(),
      authorName: folderJson['authorName'] as String? ?? folderJson['author_name'] as String?,
      tags: (folderJson['tags'] as List<dynamic>? ?? json['tags'] as List<dynamic>?)
          ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      if (classId != null) 'classId': classId,
      if (clonedFromId != null) 'clonedFromId': clonedFromId,
      'name': name,
      if (description != null) 'description': description,
      'icon': icon,
      'color': color,
      'shareMode': shareMode,
      'savedCount': savedCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isOwner': isOwner,
      'isPublic': isPublic,
      if (shareToken != null) 'shareToken': shareToken,
      'canClone': canClone,
      'canEdit': canEdit,
      'isStarred': isStarred,
      if (decks != null) 'decks': decks!.map((e) => e.toJson()).toList(),
      if (deckCount != null) 'deckCount': deckCount,
      if (dueCount != null) 'dueCount': dueCount,
      if (authorName != null) 'authorName': authorName,
      if (tags != null) 'tags': tags!.map((e) => e.toJson()).toList(),
    };
  }

  FolderModel copyWith({
    String? id,
    String? userId,
    String? classId,
    String? clonedFromId,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? shareMode,
    int? savedCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOwner,
    bool? isPublic,
    String? shareToken,
    bool? canClone,
    bool? canEdit,
    bool? isStarred,
    List<DeckModel>? decks,
    int? deckCount,
    int? dueCount,
    String? authorName,
    List<TagModel>? tags,
  }) {
    return FolderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      classId: classId ?? this.classId,
      clonedFromId: clonedFromId ?? this.clonedFromId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      shareMode: shareMode ?? this.shareMode,
      savedCount: savedCount ?? this.savedCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOwner: isOwner ?? this.isOwner,
      isPublic: isPublic ?? this.isPublic,
      shareToken: shareToken ?? this.shareToken,
      canClone: canClone ?? this.canClone,
      canEdit: canEdit ?? this.canEdit,
      isStarred: isStarred ?? this.isStarred,
      decks: decks ?? this.decks,
      deckCount: deckCount ?? this.deckCount,
      dueCount: dueCount ?? this.dueCount,
      authorName: authorName ?? this.authorName,
      tags: tags ?? this.tags,
    );
  }
}
