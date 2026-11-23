int _asInt(Object? v) => (v as num?)?.toInt() ?? 0;

/// Một mục học liệu của lớp: FOLDER hoặc DECK lẻ. `id` là id BẢN SAO trong lớp (dùng để gỡ,
/// clone, làm nguồn bài giao, mở học) – KHÔNG phải id nguồn ở thư viện cá nhân.
class ClassMaterialItem {
  static const String typeFolder = 'folder';
  static const String typeDeck = 'deck';

  final String type;
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;

  /// Id nguồn gốc (thư viện cá nhân của giảng viên lúc thêm).
  final String? clonedFromId;

  /// Chỉ folder.
  final int? deckCount;

  /// Chỉ deck.
  final int? cardCount;

  /// true = bản được thêm SAU của cùng một nguồn -> hiện nhãn "Bản trùng".
  final bool isDuplicateCopy;

  /// Giảng viên luôn true; học viên theo `allowMemberClone`.
  final bool canClone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClassMaterialItem({
    required this.type,
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.clonedFromId,
    this.deckCount,
    this.cardCount,
    this.isDuplicateCopy = false,
    this.canClone = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isFolder => type == typeFolder;
  bool get isDeck => type == typeDeck;

  /// Số mục con để hiển thị: số deck (folder) hoặc số thẻ (deck).
  int get count => isFolder ? (deckCount ?? 0) : (cardCount ?? 0);

  factory ClassMaterialItem.fromJson(Map<String, dynamic> json, {String? fallbackType}) {
    return ClassMaterialItem(
      type: json['type'] as String? ?? fallbackType ?? typeDeck,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      clonedFromId: json['clonedFromId'] as String?,
      deckCount: (json['deckCount'] as num?)?.toInt(),
      cardCount: (json['cardCount'] as num?)?.toInt(),
      isDuplicateCopy: json['isDuplicateCopy'] as bool? ?? false,
      canClone: json['canClone'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

/// Phân trang của `GET /classes/:id/materials` và `.../materials/folders/:folderId/decks`.
class ClassMaterialsPage {
  final List<ClassMaterialItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  /// Chỉ có ở `.../materials/folders/:folderId/decks`: thông tin folder đang mở.
  final ClassMaterialItem? folder;

  const ClassMaterialsPage({
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
    this.hasMore = false,
    this.folder,
  });

  /// Parse toàn bộ body `{success, data:[...], meta:{pagination:{...}}, folder?}`.
  factory ClassMaterialsPage.fromBody(Map<String, dynamic> body, {String? itemFallbackType}) {
    final meta = body['meta'] as Map<String, dynamic>?;
    final pagination = (meta?['pagination'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final rawFolder = body['folder'];
    return ClassMaterialsPage(
      items:
          (body['data'] as List<dynamic>?)
              ?.map(
                (e) => ClassMaterialItem.fromJson(
                  e as Map<String, dynamic>,
                  fallbackType: itemFallbackType,
                ),
              )
              .toList() ??
          const [],
      page: _asInt(pagination['page']) == 0 ? 1 : _asInt(pagination['page']),
      limit: _asInt(pagination['limit']),
      total: _asInt(pagination['total']),
      totalPages: _asInt(pagination['totalPages']),
      hasMore: pagination['hasMore'] as bool? ?? false,
      folder: rawFolder is Map<String, dynamic>
          ? ClassMaterialItem.fromJson(rawFolder, fallbackType: ClassMaterialItem.typeFolder)
          : null,
    );
  }
}

/// Một học liệu đã có trong lớp (trùng với nguồn đang thêm) – từ 409 hoặc `/materials/check`.
class DuplicateInfo {
  /// deck | folder
  final String type;

  /// Thuộc NGUỒN: dùng để đánh dấu "Đã có trong lớp" ở màn chọn.
  final String sourceId;
  final String name;

  /// Folder nguồn đang thêm chứa deck này; null nếu thêm lẻ.
  final String? viaFolderId;

  /// Id bản sao đang có trong lớp.
  final String existingId;
  final String? existingFolderId;
  final String? existingFolderName;

  const DuplicateInfo({
    required this.type,
    required this.sourceId,
    required this.name,
    this.viaFolderId,
    required this.existingId,
    this.existingFolderId,
    this.existingFolderName,
  });

  /// Deck lẻ trong lớp mà nguồn đang thêm là FOLDER chứa nó -> `merge` mới có tác dụng.
  bool get canMerge =>
      type == ClassMaterialItem.typeDeck && viaFolderId != null && existingFolderId == null;

  factory DuplicateInfo.fromJson(Map<String, dynamic> json) {
    return DuplicateInfo(
      type: json['type'] as String? ?? ClassMaterialItem.typeDeck,
      sourceId: json['sourceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      viaFolderId: json['viaFolderId'] as String?,
      existingId: json['existingId'] as String? ?? '',
      existingFolderId: json['existingFolderId'] as String?,
      existingFolderName: json['existingFolderName'] as String?,
    );
  }

  /// Đọc `params.duplicates` của 409 `CLASS_MATERIAL_DUPLICATE` hoặc `data.duplicates` của check.
  static List<DuplicateInfo> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) DuplicateInfo.fromJson(e),
    ];
  }
}

class SkippedMaterial {
  final String type;
  final String sourceId;
  final String name;

  /// duplicate | in_requested_folder
  final String reason;

  const SkippedMaterial({
    required this.type,
    required this.sourceId,
    required this.name,
    required this.reason,
  });

  factory SkippedMaterial.fromJson(Map<String, dynamic> json) {
    return SkippedMaterial(
      type: json['type'] as String? ?? '',
      sourceId: json['sourceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }

  static List<SkippedMaterial> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) SkippedMaterial.fromJson(e),
    ];
  }
}

class AddedMaterial {
  final String id;
  final String name;
  final String sourceId;
  final int? deckCount;
  final int? cardCount;

  const AddedMaterial({
    required this.id,
    required this.name,
    required this.sourceId,
    this.deckCount,
    this.cardCount,
  });

  factory AddedMaterial.fromJson(Map<String, dynamic> json) {
    return AddedMaterial(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sourceId: json['sourceId'] as String? ?? '',
      deckCount: (json['deckCount'] as num?)?.toInt(),
      cardCount: (json['cardCount'] as num?)?.toInt(),
    );
  }
}

/// Kết quả `POST /classes/:id/materials`. 200 vẫn có thể là "không thêm gì" (mọi mục bị skip).
class AddMaterialsResult {
  final List<AddedMaterial> addedFolders;
  final List<AddedMaterial> addedDecks;
  final int mergedDecks;
  final List<SkippedMaterial> skipped;

  const AddMaterialsResult({
    this.addedFolders = const [],
    this.addedDecks = const [],
    this.mergedDecks = 0,
    this.skipped = const [],
  });

  bool get isNothingAdded => addedFolders.isEmpty && addedDecks.isEmpty && mergedDecks == 0;

  factory AddMaterialsResult.fromJson(Map<String, dynamic> json) {
    List<AddedMaterial> list(Object? raw) => raw is List
        ? [
            for (final e in raw)
              if (e is Map<String, dynamic>) AddedMaterial.fromJson(e),
          ]
        : const [];
    return AddMaterialsResult(
      addedFolders: list(json['addedFolders']),
      addedDecks: list(json['addedDecks']),
      mergedDecks: _asInt(json['mergedDecks']),
      skipped: SkippedMaterial.listFrom(json['skipped']),
    );
  }
}

/// Kết quả `POST /classes/:id/materials/check` (không bao giờ 409).
class CheckMaterialsResult {
  final List<DuplicateInfo> duplicates;
  final List<SkippedMaterial> skipped;

  const CheckMaterialsResult({this.duplicates = const [], this.skipped = const []});

  /// Id NGUỒN đã có trong lớp -> đánh dấu "Đã có trong lớp".
  Set<String> get duplicateSourceIds => {for (final d in duplicates) d.sourceId};

  factory CheckMaterialsResult.fromJson(Map<String, dynamic> json) {
    return CheckMaterialsResult(
      duplicates: DuplicateInfo.listFrom(json['duplicates']),
      skipped: SkippedMaterial.listFrom(json['skipped']),
    );
  }
}

class RemoveMaterialsResult {
  final int removedFolders;
  final int removedDecks;

  const RemoveMaterialsResult({this.removedFolders = 0, this.removedDecks = 0});

  factory RemoveMaterialsResult.fromJson(Map<String, dynamic> json) {
    return RemoveMaterialsResult(
      removedFolders: _asInt(json['removedFolders']),
      removedDecks: _asInt(json['removedDecks']),
    );
  }
}
