import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/deck_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

/// Kết quả `GET /decks`: danh sách deck kèm gợi ý tìm kiếm và các tag đang lọc.
class DeckListResponseModel {
  final List<DeckModel> data;
  final DeckSuggestionModel suggestions;
  final List<TagModel> activeTags;

  const DeckListResponseModel({
    this.data = const [],
    this.suggestions = const DeckSuggestionModel(),
    this.activeTags = const [],
  });

  factory DeckListResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final suggestions = data['suggestions'];
    return DeckListResponseModel(
      data: (data['decks'] as List<dynamic>? ?? const [])
          .map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestions: suggestions is Map<String, dynamic>
          ? DeckSuggestionModel.fromJson(suggestions)
          : const DeckSuggestionModel(),
      activeTags: (data['activeTags'] as List<dynamic>? ?? const [])
          .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
