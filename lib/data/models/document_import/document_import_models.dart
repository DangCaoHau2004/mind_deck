import 'dart:typed_data';

/// Đuôi ảnh được nhận (ảnh chụp camera cũng thuộc nhóm này). HEIC chưa được BE nhận.
const List<String> documentImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

const List<String> _defaultFileTypes = [
  'txt',
  'docx',
  'pdf',
  'csv',
  'xlsx',
  ...documentImageExtensions,
];

/// Một tệp gửi lên (nhiều ảnh = nhiều phần tử, đúng thứ tự trang).
class DocumentUploadFile {
  final Uint8List bytes;
  final String fileName;

  const DocumentUploadFile({required this.bytes, required this.fileName});
}

/// Giới hạn file lấy từ `GET /document-imports/quota`.
class DocumentImportLimits {
  final int maxFileMb;
  final int maxPdfPages;
  final int maxScanPdfPages;
  final int maxImages;
  final int maxCards;
  final List<String> fileTypes;

  const DocumentImportLimits({
    this.maxFileMb = 10,
    this.maxPdfPages = 50,
    this.maxScanPdfPages = 20,
    this.maxImages = 8,
    this.maxCards = 200,
    this.fileTypes = _defaultFileTypes,
  });

  factory DocumentImportLimits.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DocumentImportLimits();
    final types = (json['fileTypes'] as List?)?.map((e) => e.toString().toLowerCase()).toList();
    return DocumentImportLimits(
      maxFileMb: (json['maxFileMb'] as num?)?.toInt() ?? 10,
      maxPdfPages: (json['maxPdfPages'] as num?)?.toInt() ?? 50,
      maxScanPdfPages: (json['maxScanPdfPages'] as num?)?.toInt() ?? 20,
      maxImages: (json['maxImages'] as num?)?.toInt() ?? 8,
      maxCards: (json['maxCards'] as num?)?.toInt() ?? 200,
      fileTypes: types == null || types.isEmpty ? _defaultFileTypes : types,
    );
  }
}

/// Khối `coins` của `GET /document-imports/quota`.
class DocumentImportCoins {
  final int balance;

  /// Giá một lượt khi hết lượt miễn phí; null nếu tính năng không dùng xu.
  final int? price;

  /// `free` (còn lượt miễn phí), `coins` (hết lượt miễn phí, đủ xu nên sẽ bị trừ) hoặc `denied`.
  final String mode;
  final bool canUse;

  /// Hết lượt miễn phí và thiếu xu: cần xem video.
  final bool needsVideo;

  const DocumentImportCoins({
    this.balance = 0,
    this.price,
    this.mode = 'free',
    this.canUse = true,
    this.needsVideo = false,
  });

  factory DocumentImportCoins.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as String? ?? 'free';
    return DocumentImportCoins(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt(),
      mode: mode,
      canUse: json['canUse'] as bool? ?? mode != 'denied',
      needsVideo: json['needsVideo'] as bool? ?? false,
    );
  }

  /// Lượt này sẽ bị trừ xu.
  bool get isCharged => mode == 'coins';
}

/// Hạn mức hôm nay (`GET /document-imports/quota`).
class DocumentImportQuota {
  final int dailyLimit;
  final int usedToday;
  final int remainingToday;
  final int attemptsLimit;
  final int attemptsToday;
  final DateTime? resetsAt;
  final bool aiAvailable;
  final DocumentImportLimits limits;

  /// null khi BE cũ chưa trả khối `coins`.
  final DocumentImportCoins? coins;

  const DocumentImportQuota({
    this.dailyLimit = 0,
    this.usedToday = 0,
    this.remainingToday = 0,
    this.attemptsLimit = 0,
    this.attemptsToday = 0,
    this.resetsAt,
    this.aiAvailable = true,
    this.limits = const DocumentImportLimits(),
    this.coins,
  });

  factory DocumentImportQuota.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return DocumentImportQuota(
      dailyLimit: asInt(json['dailyLimit']),
      usedToday: asInt(json['usedToday']),
      remainingToday: asInt(json['remainingToday']),
      attemptsLimit: asInt(json['attemptsLimit']),
      attemptsToday: asInt(json['attemptsToday']),
      resetsAt: DateTime.tryParse(json['resetsAt']?.toString() ?? '')?.toLocal(),
      aiAvailable: json['aiAvailable'] as bool? ?? true,
      limits: DocumentImportLimits.fromJson(json['limits'] as Map<String, dynamic>?),
      coins: json['coins'] is Map<String, dynamic>
          ? DocumentImportCoins.fromJson(json['coins'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Dùng được AI: còn lượt miễn phí hoặc đủ xu, và server đã cấu hình AI.
  bool get canUseAi => aiAvailable && (coins?.canUse ?? remainingToday > 0);

  /// Hết số lần thử trong ngày (kể cả csv/xlsx cũng bị tính lần thử).
  bool get attemptsExhausted => attemptsLimit > 0 && attemptsToday >= attemptsLimit;
}

class DraftCard {
  final String frontText;
  final String backText;

  const DraftCard({this.frontText = '', this.backText = ''});

  factory DraftCard.fromJson(Map<String, dynamic> json) => DraftCard(
    frontText: json['frontText']?.toString() ?? '',
    backText: json['backText']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'frontText': frontText, 'backText': backText};

  DraftCard copyWith({String? frontText, String? backText}) =>
      DraftCard(frontText: frontText ?? this.frontText, backText: backText ?? this.backText);

  bool get isComplete => frontText.trim().isNotEmpty && backText.trim().isNotEmpty;
}

class DraftDeck {
  final String name;
  final List<DraftCard> cards;

  const DraftDeck({required this.name, this.cards = const []});

  factory DraftDeck.fromJson(Map<String, dynamic> json) => DraftDeck(
    name: json['name']?.toString() ?? '',
    cards:
        (json['cards'] as List?)
            ?.whereType<Map>()
            .map((e) => DraftCard.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {'name': name, 'cards': cards.map((c) => c.toJson()).toList()};

  DraftDeck copyWith({String? name, List<DraftCard>? cards}) =>
      DraftDeck(name: name ?? this.name, cards: cards ?? this.cards);
}

/// Một đoạn kết quả của luồng (`chunk`) hoặc của `chunks[]` trong bản nháp đang xử lý.
class DraftChunk {
  final int index;
  final String? section;
  final List<DraftCard> cards;
  final bool failed;
  final String? errorCode;

  const DraftChunk({
    required this.index,
    this.section,
    this.cards = const [],
    this.failed = false,
    this.errorCode,
  });

  factory DraftChunk.fromJson(Map<String, dynamic> json) => DraftChunk(
    index: (json['index'] as num?)?.toInt() ?? 0,
    section: json['section']?.toString(),
    cards:
        (json['cards'] as List?)
            ?.whereType<Map>()
            .map((e) => DraftCard.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
    failed: json['failed'] == true,
    errorCode: json['errorCode']?.toString(),
  );
}

enum DocumentImportStatus {
  processing,
  done,
  failed,
  committed;

  static DocumentImportStatus fromString(String? v) {
    switch (v) {
      case 'done':
        return DocumentImportStatus.done;
      case 'failed':
        return DocumentImportStatus.failed;
      case 'committed':
        return DocumentImportStatus.committed;
      case 'processing':
      default:
        return DocumentImportStatus.processing;
    }
  }
}

/// Bản nháp (`GET /document-imports/:id` và sự kiện `done`).
class DocumentImportDraft {
  final String id;
  final DocumentImportStatus status;
  final String fileName;
  final String fileType;
  final int fileSize;
  final bool usesAi;
  final Map<String, dynamic> options;
  final int totalChunks;
  final int doneChunks;
  final List<DraftChunk> chunks;
  final List<DraftDeck> decks;
  final int totalCards;
  final List<String> warnings;
  final String? errorCode;
  final String? errorMessage;
  final bool contentCleared;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? committedFolderId;
  final List<String> committedDeckIds;

  const DocumentImportDraft({
    required this.id,
    this.status = DocumentImportStatus.processing,
    this.fileName = '',
    this.fileType = '',
    this.fileSize = 0,
    this.usesAi = false,
    this.options = const {},
    this.totalChunks = 0,
    this.doneChunks = 0,
    this.chunks = const [],
    this.decks = const [],
    this.totalCards = 0,
    this.warnings = const [],
    this.errorCode,
    this.errorMessage,
    this.contentCleared = false,
    this.expiresAt,
    this.createdAt,
    this.committedFolderId,
    this.committedDeckIds = const [],
  });

  factory DocumentImportDraft.fromJson(Map<String, dynamic> json) {
    final draftMap = json['draft'] as Map?;
    final decks =
        (draftMap?['decks'] as List?)
            ?.whereType<Map>()
            .map((e) => DraftDeck.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <DraftDeck>[];
    return DocumentImportDraft(
      id: json['id']?.toString() ?? '',
      status: DocumentImportStatus.fromString(json['status']?.toString()),
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      usesAi: json['usesAi'] == true,
      options: json['options'] is Map
          ? Map<String, dynamic>.from(json['options'] as Map)
          : const {},
      totalChunks: (json['totalChunks'] as num?)?.toInt() ?? 0,
      doneChunks: (json['doneChunks'] as num?)?.toInt() ?? 0,
      chunks:
          (json['chunks'] as List?)
              ?.whereType<Map>()
              .map((e) => DraftChunk.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      decks: decks,
      totalCards:
          (draftMap?['totalCards'] as num?)?.toInt() ??
          decks.fold<int>(0, (s, d) => s + d.cards.length),
      warnings: (json['warnings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      errorCode: json['errorCode']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      contentCleared: json['contentCleared'] == true,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      committedFolderId: json['committedFolderId']?.toString(),
      committedDeckIds:
          (json['committedDeckIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// Số ngày còn lại trước khi nội dung bị xóa (làm tròn lên); null nếu không có hạn.
  int? daysUntilExpiry([DateTime? now]) {
    final e = expiresAt;
    if (e == null) return null;
    final diff = e.difference(now ?? DateTime.now());
    if (diff.isNegative) return 0;
    return (diff.inHours / 24).ceil();
  }
}

/// Một dòng trong danh sách bản nháp (`GET /document-imports`).
class DocumentImportListItem {
  final String id;
  final DocumentImportStatus status;
  final String fileName;
  final String fileType;
  final int fileSize;
  final bool usesAi;
  final int totalChunks;
  final int doneChunks;
  final int deckCount;
  final int cardCount;
  final String? errorCode;
  final List<String> warnings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentImportListItem({
    required this.id,
    this.status = DocumentImportStatus.done,
    this.fileName = '',
    this.fileType = '',
    this.fileSize = 0,
    this.usesAi = false,
    this.totalChunks = 0,
    this.doneChunks = 0,
    this.deckCount = 0,
    this.cardCount = 0,
    this.errorCode,
    this.warnings = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentImportListItem.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return DocumentImportListItem(
      id: json['id']?.toString() ?? '',
      status: DocumentImportStatus.fromString(json['status']?.toString()),
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileSize: asInt(json['fileSize']),
      usesAi: json['usesAi'] == true,
      totalChunks: asInt(json['totalChunks']),
      doneChunks: asInt(json['doneChunks']),
      deckCount: asInt(json['deckCount']),
      cardCount: asInt(json['cardCount']),
      errorCode: json['errorCode']?.toString(),
      warnings: (json['warnings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal(),
    );
  }
}

class CommitResult {
  final String? folderId;
  final String? folderName;
  final bool folderCreated;
  final List<CommittedDeck> decks;
  final int totalCards;

  const CommitResult({
    this.folderId,
    this.folderName,
    this.folderCreated = false,
    this.decks = const [],
    this.totalCards = 0,
  });

  factory CommitResult.fromJson(Map<String, dynamic> json) {
    final folder = json['folder'] as Map?;
    return CommitResult(
      folderId: folder?['id']?.toString(),
      folderName: folder?['name']?.toString(),
      folderCreated: folder?['created'] == true,
      decks:
          (json['decks'] as List?)
              ?.whereType<Map>()
              .map((e) => CommittedDeck.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      totalCards: (json['totalCards'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommittedDeck {
  final String id;
  final String name;
  final int cardCount;

  const CommittedDeck({required this.id, this.name = '', this.cardCount = 0});

  factory CommittedDeck.fromJson(Map<String, dynamic> json) => CommittedDeck(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
  );
}

enum DocumentImportEventType { started, progress, chunk, chunkFailed, done, error, ping, unknown }

/// Một dòng của luồng NDJSON. `type` lạ → [DocumentImportEventType.unknown] (phải bỏ qua).
class DocumentImportStreamEvent {
  final DocumentImportEventType type;
  final String? draftId;
  final String? fileName;
  final String? fileType;
  final bool usesAi;
  final bool resumed;
  final int totalChunks;
  final String? stage;
  final int done;
  final int total;
  final int index;
  final String? section;
  final List<DraftCard> cards;
  final String? errorCode;
  final String? message;
  final DocumentImportDraft? draft;

  const DocumentImportStreamEvent({
    required this.type,
    this.draftId,
    this.fileName,
    this.fileType,
    this.usesAi = false,
    this.resumed = false,
    this.totalChunks = 0,
    this.stage,
    this.done = 0,
    this.total = 0,
    this.index = 0,
    this.section,
    this.cards = const [],
    this.errorCode,
    this.message,
    this.draft,
  });

  factory DocumentImportStreamEvent.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    switch (json['type']) {
      case 'started':
        return DocumentImportStreamEvent(
          type: DocumentImportEventType.started,
          draftId: json['draftId']?.toString(),
          fileName: json['fileName']?.toString(),
          fileType: json['fileType']?.toString(),
          usesAi: json['usesAi'] == true,
          resumed: json['resumed'] == true,
          totalChunks: asInt(json['totalChunks']),
        );
      case 'progress':
        return DocumentImportStreamEvent(
          type: DocumentImportEventType.progress,
          stage: json['stage']?.toString(),
          done: asInt(json['done']),
          total: asInt(json['total']),
        );
      case 'chunk':
        return DocumentImportStreamEvent(
          type: DocumentImportEventType.chunk,
          index: asInt(json['index']),
          section: json['section']?.toString(),
          cards:
              (json['cards'] as List?)
                  ?.whereType<Map>()
                  .map((e) => DraftCard.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              const [],
        );
      case 'chunk_failed':
        return DocumentImportStreamEvent(
          type: DocumentImportEventType.chunkFailed,
          index: asInt(json['index']),
          errorCode: json['errorCode']?.toString(),
          message: json['message']?.toString(),
        );
      case 'done':
        final raw = json['draft'];
        return DocumentImportStreamEvent(
          type: DocumentImportEventType.done,
          draft: raw is Map ? DocumentImportDraft.fromJson(Map<String, dynamic>.from(raw)) : null,
        );
      case 'error':
        return DocumentImportStreamEvent(
          type: DocumentImportEventType.error,
          errorCode: json['errorCode']?.toString(),
          message: json['message']?.toString(),
        );
      case 'ping':
        return const DocumentImportStreamEvent(type: DocumentImportEventType.ping);
      default:
        return const DocumentImportStreamEvent(type: DocumentImportEventType.unknown);
    }
  }
}

/// Tùy chọn khi tải tài liệu lên; mọi trường đều gửi dạng chuỗi.
class DocumentImportOptions {
  final String splitMode; // single | deck_count | cards_per_deck
  final int deckCount;
  final int cardsPerDeck;
  final int? maxCards;
  final String detailLevel; // brief | balanced | detailed
  final int? pageFrom;
  final int? pageTo;
  final bool createFolder;
  final int frontColumn;
  final int backColumn;
  final bool hasHeader;
  final String? sheet;

  const DocumentImportOptions({
    this.splitMode = 'single',
    this.deckCount = 2,
    this.cardsPerDeck = 20,
    this.maxCards,
    this.detailLevel = 'balanced',
    this.pageFrom,
    this.pageTo,
    this.createFolder = false,
    this.frontColumn = 1,
    this.backColumn = 2,
    this.hasHeader = false,
    this.sheet,
  });

  DocumentImportOptions copyWith({
    String? splitMode,
    int? deckCount,
    int? cardsPerDeck,
    int? maxCards,
    String? detailLevel,
    int? pageFrom,
    int? pageTo,
    bool? createFolder,
    int? frontColumn,
    int? backColumn,
    bool? hasHeader,
    String? sheet,
    bool clearPages = false,
    bool clearPageFrom = false,
    bool clearPageTo = false,
    bool clearMaxCards = false,
    bool clearSheet = false,
  }) {
    return DocumentImportOptions(
      splitMode: splitMode ?? this.splitMode,
      deckCount: deckCount ?? this.deckCount,
      cardsPerDeck: cardsPerDeck ?? this.cardsPerDeck,
      maxCards: clearMaxCards ? null : (maxCards ?? this.maxCards),
      detailLevel: detailLevel ?? this.detailLevel,
      pageFrom: (clearPages || clearPageFrom) ? null : (pageFrom ?? this.pageFrom),
      pageTo: (clearPages || clearPageTo) ? null : (pageTo ?? this.pageTo),
      createFolder: createFolder ?? this.createFolder,
      frontColumn: frontColumn ?? this.frontColumn,
      backColumn: backColumn ?? this.backColumn,
      hasHeader: hasHeader ?? this.hasHeader,
      sheet: clearSheet ? null : (sheet ?? this.sheet),
    );
  }

  /// Các trường multipart theo loại file (`pdf`, `csv`, `xlsx`, `txt`, `docx`).
  Map<String, String> toFields(String fileType) {
    final type = fileType.toLowerCase();
    final isTable = type == 'csv' || type == 'xlsx';
    return {
      'splitMode': splitMode,
      if (splitMode == 'deck_count') 'deckCount': '$deckCount',
      if (splitMode == 'cards_per_deck') 'cardsPerDeck': '$cardsPerDeck',
      'maxCards': ?(maxCards == null ? null : '$maxCards'),
      if (!isTable) 'detailLevel': detailLevel,
      if (type == 'pdf' && pageFrom != null) 'pageFrom': '$pageFrom',
      if (type == 'pdf' && pageTo != null) 'pageTo': '$pageTo',
      'createFolder': '$createFolder',
      if (isTable) 'frontColumn': '$frontColumn',
      if (isTable) 'backColumn': '$backColumn',
      if (isTable) 'hasHeader': '$hasHeader',
      if (type == 'xlsx' && (sheet ?? '').trim().isNotEmpty) 'sheet': sheet!.trim(),
    };
  }
}
