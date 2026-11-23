import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

class DeckKeywordSuggestionModel extends Equatable {
  final String query;
  final String displayText;
  final List<TagModel> tags;

  const DeckKeywordSuggestionModel({this.query = '', this.displayText = '', this.tags = const []});

  factory DeckKeywordSuggestionModel.fromJson(dynamic json) {
    if (json is String) {
      return DeckKeywordSuggestionModel(query: json, displayText: json, tags: const []);
    }
    if (json is Map<String, dynamic>) {
      return DeckKeywordSuggestionModel(
        query: json['query'] as String? ?? json['text'] as String? ?? '',
        displayText:
            json['displayText'] as String? ??
            json['display_text'] as String? ??
            json['name'] as String? ??
            json['query'] as String? ??
            '',
        tags:
            (json['tags'] as List<dynamic>?)
                ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
    }
    return const DeckKeywordSuggestionModel();
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

class DeckSuggestionModel extends Equatable {
  final List<DeckKeywordSuggestionModel> keywords;
  final List<TagModel> tags;
  final List<DeckModel> decks;

  const DeckSuggestionModel({
    this.keywords = const [],
    this.tags = const [],
    this.decks = const [],
  });

  factory DeckSuggestionModel.fromJson(Map<String, dynamic> json) {
    return DeckSuggestionModel(
      keywords:
          (json['keywords'] as List<dynamic>?)
              ?.map((e) => DeckKeywordSuggestionModel.fromJson(e))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      decks:
          (json['decks'] as List<dynamic>?)
              ?.map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keywords': keywords.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'decks': decks.map((e) => e.toJson()).toList(),
    };
  }

  DeckSuggestionModel copyWith({
    List<DeckKeywordSuggestionModel>? keywords,
    List<TagModel>? tags,
    List<DeckModel>? decks,
  }) {
    return DeckSuggestionModel(
      keywords: keywords ?? this.keywords,
      tags: tags ?? this.tags,
      decks: decks ?? this.decks,
    );
  }

  @override
  List<Object?> get props => [keywords, tags, decks];
}
