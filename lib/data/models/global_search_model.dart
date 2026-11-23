import 'package:mind_deck/data/models/tag_model.dart';
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
      objectId: json['objectId'] as String? ?? json['object_id'] as String? ?? '',
      type: SearchType.fromString(json['type'] as String? ?? json['search_type'] as String?),
      searchContent: json['searchContent'] as String? ?? json['search_content'] as String? ?? '',
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

  /// Id thực thể (deck/folder) để điều hướng.
  String get entityId => data['id'] as String? ?? objectId;

  String get name => data['name'] as String? ?? searchContent;

  String? get description {
    final value = (data['description'] as String?)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String get colorHex => data['color'] as String? ?? '#673AB7';

  String get iconKey =>
      data['icon'] as String? ?? (type == SearchType.folder ? 'default_folder' : 'default_deck');

  String? get ownerName => data['ownerName'] as String?;

  int get savedCount => (data['savedCount'] as num?)?.toInt() ?? 0;

  int? get cardCount => (data['cardCount'] as num?)?.toInt();

  int? get deckCount => (data['deckCount'] as num?)?.toInt();

  // --- Lớp học (type == class) ---
  int get memberCount => (data['memberCount'] as num?)?.toInt() ?? 0;

  bool get isJoined => data['isJoined'] as bool? ?? false;

  bool get isPending => data['isPending'] as bool? ?? false;

  String get joinCode => data['joinCode'] as String? ?? '';

  List<TagModel> get tags =>
      (data['tags'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(TagModel.fromJson)
          .toList() ??
      const [];
}

/// Một nhóm kết quả của `GET /search?type=all` (tối đa 5 mục, có thể rỗng).
class GlobalSearchSectionModel {
  final SearchType type;
  final List<GlobalSearchModel> items;
  final bool hasMore;

  const GlobalSearchSectionModel({required this.type, this.items = const [], this.hasMore = false});

  factory GlobalSearchSectionModel.fromJson(Map<String, dynamic> json) {
    return GlobalSearchSectionModel(
      type: SearchType.fromString(json['type'] as String?),
      items: GlobalSearchResponseModel._parseItems(json['data']),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// Response của `GET /search`.
/// - `type=all`: có [sections] (`page/limit` không có), `data` phẳng ở cấp ngoài bị bỏ qua.
/// - `type=deck|folder|class`: [items] phẳng + `page/limit/hasMore`.
class GlobalSearchResponseModel {
  final List<GlobalSearchSectionModel>? sections;
  final List<GlobalSearchModel> items;
  final int page;
  final int limit;
  final bool hasMore;

  const GlobalSearchResponseModel({
    this.sections,
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.hasMore = false,
  });

  bool get isSectioned => sections != null;

  factory GlobalSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>?;
    if (rawSections != null) {
      return GlobalSearchResponseModel(
        sections: rawSections
            .whereType<Map<String, dynamic>>()
            .map(GlobalSearchSectionModel.fromJson)
            .toList(),
      );
    }
    return GlobalSearchResponseModel(
      items: _parseItems(json['data']),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  static List<GlobalSearchModel> _parseItems(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(GlobalSearchModel.fromJson).toList();
  }
}
