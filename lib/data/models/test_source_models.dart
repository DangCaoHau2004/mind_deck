import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/deck_suggestion_model.dart';

class SourceDeckModel {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final bool isStarred;
  final String? folderId;
  final String? folderName;
  final String? classId;
  final String? classFolderId;
  final int cardCount;
  final int dueCount;
  final int newCount;
  final List<TagModel> tags;
  final String? createdAt;
  final String? updatedAt;

  SourceDeckModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.isStarred = false,
    this.folderId,
    this.folderName,
    this.classId,
    this.classFolderId,
    this.cardCount = 0,
    this.dueCount = 0,
    this.newCount = 0,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  DeckModel toDeckModel() {
    return DeckModel(
      id: id,
      name: name,
      icon: icon ?? 'default_deck',
      color: color ?? '#1565C0',
      isStarred: isStarred,
      folderId: folderId,
      cardCount: cardCount,
      dueCount: dueCount,
      tags: tags,
      classId: classId,
      goalType: GoalType.longTerm,
      userId: '',
      createdAt: createdAt != null
          ? (DateTime.tryParse(createdAt!) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: updatedAt != null
          ? (DateTime.tryParse(updatedAt!) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  factory SourceDeckModel.fromJson(Map<String, dynamic> json) {
    var rawTags = json['tags'];
    List<TagModel> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags
          .whereType<Map<String, dynamic>>()
          .map((t) => TagModel.fromJson(t))
          .toList();
    }

    return SourceDeckModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isStarred: json['isStarred'] as bool? ?? json['is_starred'] as bool? ?? false,
      folderId: json['folderId'] as String? ?? json['folder_id'] as String?,
      folderName: json['folderName'] as String? ?? json['folder_name'] as String?,
      classId: json['classId'] as String? ?? json['class_id'] as String?,
      classFolderId: json['classFolderId'] as String? ?? json['class_folder_id'] as String?,
      cardCount: (json['cardCount'] as num?)?.toInt() ?? (json['card_count'] as num?)?.toInt() ?? 0,
      dueCount: (json['dueCount'] as num?)?.toInt() ?? (json['due_count'] as num?)?.toInt() ?? 0,
      newCount: (json['newCount'] as num?)?.toInt() ?? (json['new_count'] as num?)?.toInt() ?? 0,
      tags: parsedTags,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'isStarred': isStarred,
    'folderId': folderId,
    'folderName': folderName,
    'classId': classId,
    'classFolderId': classFolderId,
    'cardCount': cardCount,
    'dueCount': dueCount,
    'newCount': newCount,
    'tags': tags.map((t) => t.toJson()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class SourceFolderModel {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final bool isStarred;
  final int cardCount;
  final int dueCount;
  final int newCount;
  final int deckCount;
  final List<TagModel> tags;
  final List<SourceDeckModel> decks;

  /// Khác null = folder bản sao của lớp (BE không trả trên folder; gán từ lớp chứa nó).
  final String? classId;
  final String? createdAt;
  final String? updatedAt;

  SourceFolderModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.isStarred = false,
    this.cardCount = 0,
    this.dueCount = 0,
    this.newCount = 0,
    this.deckCount = 0,
    this.tags = const [],
    this.decks = const [],
    this.classId,
    this.createdAt,
    this.updatedAt,
  });

  SourceFolderModel withClassId(String? id) => SourceFolderModel(
    id: this.id,
    name: name,
    icon: icon,
    color: color,
    isStarred: isStarred,
    cardCount: cardCount,
    dueCount: dueCount,
    newCount: newCount,
    deckCount: deckCount,
    tags: tags,
    decks: decks,
    classId: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  FolderModel toFolderModel() {
    return FolderModel(
      id: id,
      name: name,
      icon: icon ?? 'default_icon',
      color: color ?? '#1565C0',
      isStarred: isStarred,
      deckCount: deckCount,
      decks: decks.map((d) => d.toDeckModel()).toList(),
      tags: tags,
      classId: classId ?? decks.map((d) => d.classId).whereType<String>().firstOrNull,
      userId: '',
      createdAt: createdAt != null
          ? (DateTime.tryParse(createdAt!) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: updatedAt != null
          ? (DateTime.tryParse(updatedAt!) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  factory SourceFolderModel.fromJson(Map<String, dynamic> json) {
    var rawTags = json['tags'];
    List<TagModel> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags
          .whereType<Map<String, dynamic>>()
          .map((t) => TagModel.fromJson(t))
          .toList();
    }

    var rawDecks = json['decks'];
    List<SourceDeckModel> parsedDecks = [];
    if (rawDecks is List) {
      parsedDecks = rawDecks
          .whereType<Map<String, dynamic>>()
          .map((d) => SourceDeckModel.fromJson(d))
          .toList();
    }

    return SourceFolderModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isStarred: json['isStarred'] as bool? ?? json['is_starred'] as bool? ?? false,
      cardCount: (json['cardCount'] as num?)?.toInt() ?? (json['card_count'] as num?)?.toInt() ?? 0,
      dueCount: (json['dueCount'] as num?)?.toInt() ?? (json['due_count'] as num?)?.toInt() ?? 0,
      newCount: (json['newCount'] as num?)?.toInt() ?? (json['new_count'] as num?)?.toInt() ?? 0,
      deckCount:
          (json['deckCount'] as num?)?.toInt() ??
          (json['deck_count'] as num?)?.toInt() ??
          parsedDecks.length,
      tags: parsedTags,
      decks: parsedDecks,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'isStarred': isStarred,
    'cardCount': cardCount,
    'dueCount': dueCount,
    'newCount': newCount,
    'deckCount': deckCount,
    'tags': tags.map((t) => t.toJson()).toList(),
    'decks': decks.map((d) => d.toJson()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class SourceClassModel {
  final String classId;
  final String className;
  final String? description;
  final String? role;
  final int totalCards;
  final int dueCount;
  final int newCount;
  final List<dynamic> items;
  final List<SourceFolderModel> folders;
  final List<SourceDeckModel> standaloneDecks;

  SourceClassModel({
    required this.classId,
    required this.className,
    this.description,
    this.role,
    this.totalCards = 0,
    this.dueCount = 0,
    this.newCount = 0,
    this.items = const [],
    this.folders = const [],
    this.standaloneDecks = const [],
  });

  factory SourceClassModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> parsedItems = [];
    List<SourceFolderModel> parsedFolders = [];
    List<SourceDeckModel> parsedStandalone = [];
    final ownerClassId =
        json['classId'] as String? ?? json['class_id'] as String? ?? json['id'] as String?;

    var rawItems = json['items'];
    if (rawItems is List && rawItems.isNotEmpty) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          final type = item['type'] as String? ?? (item.containsKey('decks') ? 'folder' : 'deck');
          if (type == 'folder') {
            final folder = SourceFolderModel.fromJson(item).withClassId(ownerClassId);
            parsedItems.add(folder);
            parsedFolders.add(folder);
          } else {
            final deck = SourceDeckModel.fromJson(item);
            parsedItems.add(deck);
            parsedStandalone.add(deck);
          }
        }
      }
    } else {
      var rawFolders = json['folders'];
      if (rawFolders is List) {
        parsedFolders = rawFolders
            .whereType<Map<String, dynamic>>()
            .map((f) => SourceFolderModel.fromJson(f).withClassId(ownerClassId))
            .toList();
        parsedItems.addAll(parsedFolders);
      }

      var rawStandalone = json['standaloneDecks'] ?? json['standalone_decks'] ?? json['decks'];
      if (rawStandalone is List) {
        parsedStandalone = rawStandalone
            .whereType<Map<String, dynamic>>()
            .map((d) => SourceDeckModel.fromJson(d))
            .toList();
        parsedItems.addAll(parsedStandalone);
      }
    }

    int totalCards =
        (json['totalCards'] as num?)?.toInt() ??
        (json['total_cards'] as num?)?.toInt() ??
        (json['cardCount'] as num?)?.toInt() ??
        (json['card_count'] as num?)?.toInt() ??
        0;

    int dueCount =
        (json['dueCount'] as num?)?.toInt() ??
        (json['due_count'] as num?)?.toInt() ??
        (json['dueCardCount'] as num?)?.toInt() ??
        (json['due_card_count'] as num?)?.toInt() ??
        0;

    if (totalCards == 0) {
      for (final f in parsedFolders) {
        totalCards += f.cardCount;
      }
      for (final d in parsedStandalone) {
        totalCards += d.cardCount;
      }
    }

    if (dueCount == 0) {
      for (final f in parsedFolders) {
        dueCount += f.dueCount;
      }
      for (final d in parsedStandalone) {
        dueCount += d.dueCount;
      }
    }

    return SourceClassModel(
      classId:
          json['classId'] as String? ?? json['class_id'] as String? ?? json['id'] as String? ?? '',
      className:
          json['className'] as String? ??
          json['class_name'] as String? ??
          json['name'] as String? ??
          '',
      description: json['description'] as String?,
      role: json['role'] as String?,
      totalCards: totalCards,
      dueCount: dueCount,
      newCount: (json['newCount'] as num?)?.toInt() ?? (json['new_count'] as num?)?.toInt() ?? 0,
      items: parsedItems,
      folders: parsedFolders,
      standaloneDecks: parsedStandalone,
    );
  }

  Map<String, dynamic> toJson() => {
    'classId': classId,
    'className': className,
    'description': description,
    'role': role,
    'totalCards': totalCards,
    'dueCount': dueCount,
    'newCount': newCount,
    'items': items.map((i) => i.toJson()).toList(),
    'folders': folders.map((f) => f.toJson()).toList(),
    'standaloneDecks': standaloneDecks.map((d) => d.toJson()).toList(),
  };
}

class PersonalSourcesData {
  final List<TagModel> activeTags;
  final DeckSuggestionModel? suggestions;
  final List<dynamic> items;
  final List<SourceFolderModel> folders;
  final List<SourceDeckModel> standaloneDecks;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;

  PersonalSourcesData({
    this.activeTags = const [],
    this.suggestions,
    this.items = const [],
    this.folders = const [],
    this.standaloneDecks = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
    this.hasMore = false,
  });

  factory PersonalSourcesData.fromJson(Map<String, dynamic> json) {
    var rawTags = json['activeTags'] ?? json['active_tags'];
    List<TagModel> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags
          .whereType<Map<String, dynamic>>()
          .map((t) => TagModel.fromJson(t))
          .toList();
    }

    DeckSuggestionModel? parsedSuggestions;
    if (json['suggestions'] is Map<String, dynamic>) {
      parsedSuggestions = DeckSuggestionModel.fromJson(json['suggestions'] as Map<String, dynamic>);
    }

    List<dynamic> parsedItems = [];
    List<SourceFolderModel> parsedFolders = [];
    List<SourceDeckModel> parsedDecks = [];

    var rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          final type = item['type'] as String? ?? (item.containsKey('decks') ? 'folder' : 'deck');
          if (type == 'folder') {
            final folder = SourceFolderModel.fromJson(item);
            parsedItems.add(folder);
            parsedFolders.add(folder);
          } else {
            final deck = SourceDeckModel.fromJson(item);
            parsedItems.add(deck);
            parsedDecks.add(deck);
          }
        }
      }
    } else {
      var rawFolders = json['folders'];
      if (rawFolders is List) {
        parsedFolders = rawFolders
            .whereType<Map<String, dynamic>>()
            .map((f) => SourceFolderModel.fromJson(f))
            .toList();
        parsedItems.addAll(parsedFolders);
      }

      var rawDecks = json['standaloneDecks'] ?? json['standalone_decks'] ?? json['decks'];
      if (rawDecks is List) {
        parsedDecks = rawDecks
            .whereType<Map<String, dynamic>>()
            .map((d) => SourceDeckModel.fromJson(d))
            .toList();
        parsedItems.addAll(parsedDecks);
      }
    }

    final meta =
        json['meta'] as Map<String, dynamic>? ?? json['pagination'] as Map<String, dynamic>?;
    final pagination = meta?['pagination'] as Map<String, dynamic>? ?? meta;

    final page = (pagination?['page'] as num?)?.toInt() ?? (json['page'] as num?)?.toInt() ?? 1;
    final limit = (pagination?['limit'] as num?)?.toInt() ?? (json['limit'] as num?)?.toInt() ?? 20;
    final total =
        (pagination?['total'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        parsedItems.length;
    final totalPages =
        (pagination?['totalPages'] as num?)?.toInt() ??
        (pagination?['total_pages'] as num?)?.toInt() ??
        (json['totalPages'] as num?)?.toInt() ??
        ((total / (limit > 0 ? limit : 20)).ceil());
    final hasMore =
        (pagination?['hasMore'] as bool?) ??
        (pagination?['has_more'] as bool?) ??
        (json['hasMore'] as bool?) ??
        (page < totalPages);

    return PersonalSourcesData(
      activeTags: parsedTags,
      suggestions: parsedSuggestions,
      items: parsedItems,
      folders: parsedFolders,
      standaloneDecks: parsedDecks,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }
}

class ClassSourcesData {
  final List<TagModel> activeTags;
  final DeckSuggestionModel? suggestions;
  final List<SourceClassModel> classes;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;

  ClassSourcesData({
    this.activeTags = const [],
    this.suggestions,
    this.classes = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
    this.hasMore = false,
  });

  factory ClassSourcesData.fromJson(Map<String, dynamic> json) {
    var rawTags = json['activeTags'] ?? json['active_tags'];
    List<TagModel> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags
          .whereType<Map<String, dynamic>>()
          .map((t) => TagModel.fromJson(t))
          .toList();
    }

    DeckSuggestionModel? parsedSuggestions;
    if (json['suggestions'] is Map<String, dynamic>) {
      parsedSuggestions = DeckSuggestionModel.fromJson(json['suggestions'] as Map<String, dynamic>);
    }

    var rawClasses = json['classes'];
    List<SourceClassModel> parsedClasses = [];
    if (rawClasses is List) {
      parsedClasses = rawClasses
          .whereType<Map<String, dynamic>>()
          .map((c) => SourceClassModel.fromJson(c))
          .toList();
    }

    final meta =
        json['meta'] as Map<String, dynamic>? ?? json['pagination'] as Map<String, dynamic>?;
    final page = (meta?['page'] as num?)?.toInt() ?? (json['page'] as num?)?.toInt() ?? 1;
    final limit = (meta?['limit'] as num?)?.toInt() ?? (json['limit'] as num?)?.toInt() ?? 20;
    final total =
        (meta?['total'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        parsedClasses.length;
    final totalPages =
        (meta?['totalPages'] as num?)?.toInt() ??
        (meta?['total_pages'] as num?)?.toInt() ??
        (json['totalPages'] as num?)?.toInt() ??
        ((total / (limit > 0 ? limit : 20)).ceil());
    final hasMore =
        (meta?['hasMore'] as bool?) ??
        (meta?['has_more'] as bool?) ??
        (json['hasMore'] as bool?) ??
        (page < totalPages);

    return ClassSourcesData(
      activeTags: parsedTags,
      suggestions: parsedSuggestions,
      classes: parsedClasses,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }
}
