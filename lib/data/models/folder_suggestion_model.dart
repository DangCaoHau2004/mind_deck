import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

class FolderKeywordSuggestionModel extends Equatable {
  final String query;
  final String displayText;
  final List<TagModel> tags;

  const FolderKeywordSuggestionModel({
    this.query = '',
    this.displayText = '',
    this.tags = const [],
  });

  factory FolderKeywordSuggestionModel.fromJson(dynamic json) {
    if (json is String) {
      return FolderKeywordSuggestionModel(query: json, displayText: json, tags: const []);
    }
    if (json is Map<String, dynamic>) {
      return FolderKeywordSuggestionModel(
        query: json['query'] as String? ?? json['text'] as String? ?? '',
        displayText:
            json['displayText'] as String? ??
            json['display_text'] as String? ??
            json['query'] as String? ??
            '',
        tags:
            (json['tags'] as List<dynamic>?)
                ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
    }
    return const FolderKeywordSuggestionModel();
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'displayText': displayText,
      'tags': tags.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [query, displayText, tags];
}

class FolderSuggestionModel extends Equatable {
  final List<FolderKeywordSuggestionModel> keywords;
  final List<TagModel> tags;
  final List<FolderModel> folders;

  const FolderSuggestionModel({
    this.keywords = const [],
    this.tags = const [],
    this.folders = const [],
  });

  factory FolderSuggestionModel.fromJson(Map<String, dynamic> json) {
    return FolderSuggestionModel(
      keywords:
          (json['keywords'] as List<dynamic>?)
              ?.map((e) => FolderKeywordSuggestionModel.fromJson(e))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      folders:
          (json['folders'] as List<dynamic>?)
              ?.map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keywords': keywords.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'folders': folders.map((e) => e.toJson()).toList(),
    };
  }

  FolderSuggestionModel copyWith({
    List<FolderKeywordSuggestionModel>? keywords,
    List<TagModel>? tags,
    List<FolderModel>? folders,
  }) {
    return FolderSuggestionModel(
      keywords: keywords ?? this.keywords,
      tags: tags ?? this.tags,
      folders: folders ?? this.folders,
    );
  }

  @override
  List<Object?> get props => [keywords, tags, folders];
}
