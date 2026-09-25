import 'enums.dart';
import 'tag_model.dart';
import 'flashcard_model.dart';

class DeckModel {
  final String id;
  final String? folderId;
  final String userId;
  final String? clonedFromId;
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
  final int? dueCardCount;
  final String? folderName;
  final String? authorName;

  DeckModel({
    required this.id,
    this.folderId,
    required this.userId,
    this.clonedFromId,
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
    this.dueCardCount,
    this.folderName,
    this.authorName,
  });

  factory DeckModel.fromJson(Map<String, dynamic> json) {
    return DeckModel(
      id: json['id'] as String? ?? '',
      folderId: json['folderId'] as String? ?? json['folder_id'] as String?,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      clonedFromId: json['clonedFromId'] as String? ?? json['cloned_from_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'default_deck',
      color: json['color'] as String? ?? '#FFFFFF',
      goalType: GoalType.fromString(json['goalType'] as String? ?? json['goal_type'] as String?),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      isPublic: json['isPublic'] as bool? ?? json['is_public'] as bool? ?? false,
      shareMode: json['accessLevel'] as String? ?? json['access_level'] as String? ?? 'private',
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
        return TagModel(id: '', name: 'Unknown');
      }).toList(),
      flashcards: ((json['flashcards'] ?? json['cards']) as List<dynamic>?)
          ?.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      cardCount: json['cardCount'] as int? ?? json['card_count'] as int?,
      dueCardCount: json['dueCardCount'] as int? ?? json['due_card_count'] as int?,
      folderName: json['folderName'] as String? ?? json['folder_name'] as String?,
      authorName: json['authorName'] as String? ?? json['author_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (folderId != null) 'folderId': folderId,
      'userId': userId,
      if (clonedFromId != null) 'clonedFromId': clonedFromId,
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
      if (dueCardCount != null) 'dueCardCount': dueCardCount,
      if (folderName != null) 'folderName': folderName,
      if (authorName != null) 'authorName': authorName,
    };
  }

  DeckModel copyWith({
    String? id,
    String? folderId,
    String? userId,
    String? clonedFromId,
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
    int? dueCardCount,
    String? folderName,
    String? authorName,
  }) {
    return DeckModel(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      userId: userId ?? this.userId,
      clonedFromId: clonedFromId ?? this.clonedFromId,
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
      dueCardCount: dueCardCount ?? this.dueCardCount,
      folderName: folderName ?? this.folderName,
      authorName: authorName ?? this.authorName,
    );
  }
}
