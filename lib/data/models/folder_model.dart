import 'deck_model.dart';
import 'tag_model.dart';

class FolderModel {
  final String id;
  final String userId;
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
  final bool isStarred;

  // UI optimized fields
  final List<DeckModel>? decks;
  final int? deckCount;
  final String? authorName;
  final List<TagModel>? tags;

  FolderModel({
    required this.id,
    required this.userId,
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
    this.isStarred = false,
    this.decks,
    this.deckCount,
    this.authorName,
    this.tags,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    final folderJson = json['folder'] as Map<String, dynamic>? ?? json;
    return FolderModel(
      id: folderJson['id'] as String? ?? '',
      userId: folderJson['userId'] as String? ?? folderJson['user_id'] as String? ?? '',
      name: folderJson['name'] as String? ?? '',
      description: folderJson['description'] as String?,
      icon: folderJson['icon'] as String? ?? 'default_icon',
      color: (folderJson['color'] as String?)?.isNotEmpty == true &&
              folderJson['color'] != '#FFFFFF'
          ? folderJson['color'] as String
          : (json['color'] as String? ?? '#1565C0'),
      shareMode: folderJson['accessLevel'] as String? ??
          folderJson['access_level'] as String? ??
          folderJson['shareMode'] as String? ??
          folderJson['share_mode'] as String? ??
          'private',
      savedCount:
          folderJson['savedCount'] as int? ?? folderJson['saved_count'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(
            folderJson['createdAt']?.toString() ??
                folderJson['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            folderJson['updatedAt']?.toString() ??
                folderJson['updated_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      isOwner: folderJson['isOwner'] as bool? ?? folderJson['is_owner'] as bool? ?? false,
      isPublic:
          folderJson['isPublic'] as bool? ?? folderJson['is_public'] as bool? ?? false,
      shareToken:
          folderJson['shareToken'] as String? ?? folderJson['share_token'] as String?,
      canClone:
          folderJson['canClone'] as bool? ?? folderJson['can_clone'] as bool? ?? false,
      isStarred:
          folderJson['isStarred'] as bool? ?? folderJson['is_starred'] as bool? ?? false,

      // Relations & UI properties
      decks: (folderJson['decks'] as List<dynamic>?)
          ?.map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      deckCount: folderJson['deckCount'] as int? ?? folderJson['deck_count'] as int?,
      authorName:
          folderJson['authorName'] as String? ?? folderJson['author_name'] as String?,
      tags: (folderJson['tags'] as List<dynamic>? ?? json['tags'] as List<dynamic>?)
          ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
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
      'isStarred': isStarred,
      if (decks != null) 'decks': decks!.map((e) => e.toJson()).toList(),
      if (deckCount != null) 'deckCount': deckCount,
      if (authorName != null) 'authorName': authorName,
      if (tags != null) 'tags': tags!.map((e) => e.toJson()).toList(),
    };
  }

  FolderModel copyWith({
    String? id,
    String? userId,
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
    bool? isStarred,
    List<DeckModel>? decks,
    int? deckCount,
    String? authorName,
    List<TagModel>? tags,
  }) {
    return FolderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      isStarred: isStarred ?? this.isStarred,
      decks: decks ?? this.decks,
      deckCount: deckCount ?? this.deckCount,
      authorName: authorName ?? this.authorName,
      tags: tags ?? this.tags,
    );
  }
}
