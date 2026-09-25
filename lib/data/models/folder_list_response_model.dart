import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/folder_suggestion_model.dart';

class FolderListDataModel {
  final List<FolderModel> folders;
  final FolderSuggestionModel suggestions;

  const FolderListDataModel({
    this.folders = const [],
    this.suggestions = const FolderSuggestionModel(),
  });

  factory FolderListDataModel.fromJson(Map<String, dynamic> json) {
    return FolderListDataModel(
      folders: (json['folders'] as List<dynamic>?)
              ?.map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      suggestions: json['suggestions'] != null &&
              json['suggestions'] is Map<String, dynamic>
          ? FolderSuggestionModel.fromJson(
              json['suggestions'] as Map<String, dynamic>,
            )
          : const FolderSuggestionModel(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folders': folders.map((e) => e.toJson()).toList(),
      'suggestions': suggestions.toJson(),
    };
  }
}

class FolderListResponseModel extends ApiListResponse<FolderModel> {
  final FolderSuggestionModel suggestions;
  final FolderListDataModel listData;

  FolderListResponseModel({
    required super.success,
    super.code,
    required super.message,
    required super.data,
    required super.total,
    super.stats,
    super.meta,
    super.pagination,
    this.suggestions = const FolderSuggestionModel(),
    required this.listData,
  });

  factory FolderListResponseModel.fromJson(Map<String, dynamic> json) {
    final metaMap = json['meta'] as Map<String, dynamic>?;
    final paginationMap = (metaMap?['pagination'] as Map<String, dynamic>?) ??
        (json['pagination'] as Map<String, dynamic>?);
    final totalCount = paginationMap?['total'] as int? ??
        metaMap?['total'] as int? ??
        0;

    final dataJson = json['data'];
    FolderListDataModel listData;
    if (dataJson is Map<String, dynamic>) {
      listData = FolderListDataModel.fromJson(dataJson);
    } else if (dataJson is List<dynamic>) {
      listData = FolderListDataModel(
        folders: dataJson
            .map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else {
      listData = const FolderListDataModel();
    }

    return FolderListResponseModel(
      success: json['success'] as bool? ?? false,
      code: json['code'] as String?,
      message: json['message'] as String? ?? '',
      total: totalCount,
      data: listData.folders,
      suggestions: listData.suggestions,
      listData: listData,
      meta: metaMap ?? paginationMap,
      pagination: paginationMap,
    );
  }
}
