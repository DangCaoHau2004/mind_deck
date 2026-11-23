import 'deck_folder_ref_model.dart';
import 'enums.dart';
import 'tag_model.dart';
import 'flashcard_model.dart';

class DeckModel {
  final String id;
  final String? folderId;
  final String userId;
  final String? clonedFromId;

  /// Khác null = bản sao học liệu của lớp (không xóa/chia sẻ/gắn sao được).
  final String? classId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final GoalType goalType;
  final DateTime? deadline;
  final bool isPublic;
  final String shareMode;
  final int savedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isStarred;
  final DateTime? lastStudiedAt;
  final bool isOwner;
  final String? shareToken;
  final bool canClone;

  // UI optimized fields
  final List<TagModel>? tags;
  final List<FlashcardModel>? flashcards;
  final int? cardCount;
  final int? dueCount;
  final List<String> folderIds;

  /// Thư mục chứa bộ thẻ (chỉ chủ sở hữu mới có, người khác là rỗng).
  final List<DeckFolderRef> folders;
  final String? authorName;

  DeckModel({
    required this.id,
    this.folderId,
    required this.userId,
    this.clonedFromId,
    this.classId,
    required this.name,
    this.description,
    this.icon = 'default_deck',
    this.color = '#FFFFFF',
    required this.goalType,
    this.deadline,
    this.isPublic = false,
    this.shareMode = 'private',
    this.savedCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isStarred = false,
    this.lastStudiedAt,
    this.isOwner = false,
    this.shareToken,
    this.canClone = false,
    this.tags,
    this.flashcards,
    this.cardCount,
    this.dueCount,
    this.folderIds = const [],
    this.folders = const [],
    this.authorName,
  });

  /// Dữ liệu giữ chỗ cho skeleton (chữ chỉ cần đủ dài để bố cục giống thật).
  factory DeckModel.placeholder() => DeckModel(
    id: '',
    userId: '',
    name: 'Tên học phần mẫu',
    color: '#1565C0',
    goalType: GoalType.longTerm,
    cardCount: 12,
    dueCount: 3,
    folders: [const DeckFolderRef(id: '', name: 'Thư mục mẫu')],
    tags: [
      const TagModel(id: '', name: 'tag-mau'),
      const TagModel(id: '', name: 'hoc-tap'),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  bool get isClassCopy => classId != null && classId!.isNotEmpty;

  factory DeckModel.fromJson(Map<String, dynamic> json) {
    return DeckModel(
      id: json['id'] as String? ?? '',
      folderId: json['folderId'] as String? ?? json['folder_id'] as String?,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      clonedFromId: json['clonedFromId'] as String? ?? json['cloned_from_id'] as String?,
      classId: json['classId'] as String? ?? json['class_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'default_deck',
      color: json['color'] as String? ?? '#FFFFFF',
      goalType: GoalType.fromString(json['goalType'] as String? ?? json['goal_type'] as String?),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      isPublic: json['isPublic'] as bool? ?? json['is_public'] as bool? ?? false,
      shareMode:
          json['accessLevel'] as String? ??
          json['access_level'] as String? ??
          json['shareMode'] as String? ??
          'private',
      savedCount: json['savedCount'] as int? ?? json['saved_count'] as int? ?? 0,
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
      isStarred: json['isStarred'] as bool? ?? json['is_starred'] as bool? ?? false,
      lastStudiedAt: json['lastStudiedAt'] != null
          ? DateTime.tryParse(json['lastStudiedAt'].toString())
          : (json['last_studied_at'] != null
                ? DateTime.tryParse(json['last_studied_at'].toString())
                : null),
      isOwner: json['isOwner'] as bool? ?? json['is_owner'] as bool? ?? false,
      shareToken: json['shareToken'] as String? ?? json['share_token'] as String?,
      canClone: json['canClone'] as bool? ?? json['can_clone'] as bool? ?? false,

      // Relations & UI properties
      tags: (json['tags'] as List<dynamic>?)?.map((e) {
        if (e is String) {
          return TagModel(id: '', name: e, color: '#00BCD4');
        } else if (e is Map<String, dynamic>) {
          return TagModel.fromJson(e);
        }
        return const TagModel(id: '', name: 'Unknown');
      }).toList(),
      flashcards: ((json['flashcards'] ?? json['cards']) as List<dynamic>?)
          ?.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      cardCount: json['cardCount'] as int? ?? json['card_count'] as int?,
      dueCount: (json['dueCount'] as num?)?.toInt(),
      folderIds: (json['folderIds'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      folders: (json['folders'] as List<dynamic>? ?? const [])
          .map((e) => DeckFolderRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      authorName: json['authorName'] as String? ?? json['author_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (folderId != null) 'folderId': folderId,
      'userId': userId,
      if (clonedFromId != null) 'clonedFromId': clonedFromId,
      if (classId != null) 'classId': classId,
      'name': name,
      if (description != null) 'description': description,
      'icon': icon,
      'color': color,
      'goalType': goalType.toJson(),
      'deadline': deadline != null
          ? "${deadline!.year.toString().padLeft(4, '0')}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}"
          : null,
      'isPublic': isPublic,
      'shareMode': shareMode,
      'savedCount': savedCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isStarred': isStarred,
      if (lastStudiedAt != null) 'lastStudiedAt': lastStudiedAt!.toIso8601String(),
      'isOwner': isOwner,
      if (shareToken != null) 'shareToken': shareToken,
      'canClone': canClone,
      if (tags != null) 'tags': tags!.map((e) => e.toJson()).toList(),
      if (flashcards != null) 'flashcards': flashcards!.map((e) => e.toJson()).toList(),
      if (cardCount != null) 'cardCount': cardCount,
      if (dueCount != null) 'dueCount': dueCount,
      'folderIds': folderIds,
      'folders': folders.map((e) => e.toJson()).toList(),
      if (authorName != null) 'authorName': authorName,
    };
  }

  DeckModel copyWith({
    String? id,
    String? folderId,
    String? userId,
    String? clonedFromId,
    String? classId,
    String? name,
    String? description,
    String? icon,
    String? color,
    GoalType? goalType,
    DateTime? deadline,
    bool? isPublic,
    String? shareMode,
    int? savedCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarred,
    DateTime? lastStudiedAt,
    bool? isOwner,
    String? shareToken,
    bool? canClone,
    List<TagModel>? tags,
    List<FlashcardModel>? flashcards,
    int? cardCount,
    int? dueCount,
    List<String>? folderIds,
    List<DeckFolderRef>? folders,
    String? authorName,
  }) {
    return DeckModel(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      userId: userId ?? this.userId,
      clonedFromId: clonedFromId ?? this.clonedFromId,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      goalType: goalType ?? this.goalType,
      deadline: deadline ?? this.deadline,
      isPublic: isPublic ?? this.isPublic,
      shareMode: shareMode ?? this.shareMode,
      savedCount: savedCount ?? this.savedCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      isOwner: isOwner ?? this.isOwner,
      shareToken: shareToken ?? this.shareToken,
      canClone: canClone ?? this.canClone,
      tags: tags ?? this.tags,
      flashcards: flashcards ?? this.flashcards,
      cardCount: cardCount ?? this.cardCount,
      dueCount: dueCount ?? this.dueCount,
      folderIds: folderIds ?? this.folderIds,
      folders: folders ?? this.folders,
      authorName: authorName ?? this.authorName,
    );
  }
}
