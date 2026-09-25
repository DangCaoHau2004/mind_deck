import 'enums.dart';

class GlobalSearchModel {
  final String id;
  final String objectId;
  final SearchType type;
  final String searchContent;
  final Map<String, dynamic> data;

  GlobalSearchModel({
    required this.id,
    required this.objectId,
    required this.type,
    required this.searchContent,
    required this.data,
  });

  factory GlobalSearchModel.fromJson(Map<String, dynamic> json) {
    return GlobalSearchModel(
      id: json['id'] as String? ?? '',
      objectId:
          json['objectId'] as String? ?? json['object_id'] as String? ?? '',
      type: SearchType.fromString(
        json['type'] as String? ?? json['search_type'] as String?,
      ),
      searchContent:
          json['searchContent'] as String? ??
          json['search_content'] as String? ??
          '',
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'objectId': objectId,
      'type': type.toJson(),
      'searchContent': searchContent,
      'data': data,
    };
  }

  GlobalSearchModel copyWith({
    String? id,
    String? objectId,
    SearchType? type,
    String? searchContent,
    Map<String, dynamic>? data,
  }) {
    return GlobalSearchModel(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      type: type ?? this.type,
      searchContent: searchContent ?? this.searchContent,
      data: data ?? this.data,
    );
  }
}
