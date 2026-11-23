import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/tag_model.dart';

class SearchKeywordSuggestionModel extends Equatable {
  final String query;
  final String displayText;
  final String? type;
  final List<TagModel> tags;

  const SearchKeywordSuggestionModel({
    this.query = '',
    this.displayText = '',
    this.type,
    this.tags = const [],
  });

  factory SearchKeywordSuggestionModel.fromJson(Map<String, dynamic> json) {
    return SearchKeywordSuggestionModel(
      query: json['query'] as String? ?? '',
      displayText:
          json['displayText'] as String? ??
          json['display_text'] as String? ??
          json['query'] as String? ??
          '',
      type: json['type'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'displayText': displayText,
      'type': type,
      'tags': tags.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [query, displayText, type, tags];
}

class SearchSuggestionResponseModel extends Equatable {
  final List<SearchKeywordSuggestionModel> keywords;
  final List<TagModel> tags;

  const SearchSuggestionResponseModel({this.keywords = const [], this.tags = const []});

  factory SearchSuggestionResponseModel.fromJson(Map<String, dynamic> json) {
    final suggestions = json['suggestions'] as Map<String, dynamic>? ?? json;
    return SearchSuggestionResponseModel(
      keywords:
          (suggestions['keywords'] as List<dynamic>?)
              ?.map((e) => SearchKeywordSuggestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (suggestions['tags'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keywords': keywords.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [keywords, tags];
}
