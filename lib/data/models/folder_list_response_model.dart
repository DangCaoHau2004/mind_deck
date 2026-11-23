import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/folder_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

/// Kết quả `GET /folders`: danh sách folder kèm gợi ý tìm kiếm và các tag đang lọc.
class FolderListResponseModel {
  final List<FolderModel> data;
  final FolderSuggestionModel suggestions;
  final List<TagModel> activeTags;

  const FolderListResponseModel({
    this.data = const [],
    this.suggestions = const FolderSuggestionModel(),
    this.activeTags = const [],
  });

  factory FolderListResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final suggestions = data['suggestions'];
    return FolderListResponseModel(
      data: (data['folders'] as List<dynamic>? ?? const [])
          .map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestions: suggestions is Map<String, dynamic>
          ? FolderSuggestionModel.fromJson(suggestions)
          : const FolderSuggestionModel(),
      activeTags: (data['activeTags'] as List<dynamic>? ?? const [])
          .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
