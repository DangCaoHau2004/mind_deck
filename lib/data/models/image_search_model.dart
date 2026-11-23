/// Ghi nguồn ảnh từ kho ảnh, bắt buộc gửi kèm `frontImageUrl` khi lưu thẻ dùng ảnh kho.
class ImageCredit {
  final String source;
  final String authorName;
  final String authorUrl;
  final String photoUrl;

  const ImageCredit({
    required this.source,
    required this.authorName,
    required this.authorUrl,
    required this.photoUrl,
  });

  /// Tên kho ảnh để hiển thị, BE đổi nhà cung cấp thì `source` đổi theo.
  String get sourceLabel =>
      source.isEmpty ? '' : '${source[0].toUpperCase()}${source.substring(1)}';

  factory ImageCredit.fromJson(Map<String, dynamic> json) {
    return ImageCredit(
      source: json['source'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorUrl: json['authorUrl'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
    );
  }

  /// Đọc trường ghi nguồn có thể null hoặc sai kiểu.
  static ImageCredit? tryParse(Object? json) =>
      json is Map<String, dynamic> ? ImageCredit.fromJson(json) : null;

  Map<String, dynamic> toJson() => {
    'source': source,
    'authorName': authorName,
    'authorUrl': authorUrl,
    'photoUrl': photoUrl,
  };
}

class ImageSearchResult {
  final String id;
  final String url;
  final String thumbUrl;
  final int width;
  final int height;
  final String? description;
  final ImageCredit credit;
  final String trackingUrl;

  const ImageSearchResult({
    required this.id,
    required this.url,
    required this.thumbUrl,
    required this.width,
    required this.height,
    this.description,
    required this.credit,
    required this.trackingUrl,
  });

  factory ImageSearchResult.fromJson(Map<String, dynamic> json) {
    return ImageSearchResult(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      thumbUrl: json['thumbUrl'] as String? ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      credit: ImageCredit.fromJson(json['credit'] as Map<String, dynamic>? ?? const {}),
      trackingUrl: json['trackingUrl'] as String? ?? '',
    );
  }
}

class ImageSearchPage {
  final int total;
  final int totalPages;
  final int page;
  final int perPage;
  final List<ImageSearchResult> results;

  const ImageSearchPage({
    required this.total,
    required this.totalPages,
    required this.page,
    required this.perPage,
    required this.results,
  });

  bool get hasMore => page < totalPages;

  factory ImageSearchPage.fromJson(Map<String, dynamic> json) {
    return ImageSearchPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['perPage'] as num?)?.toInt() ?? 0,
      results: (json['results'] as List<dynamic>? ?? const [])
          .map((e) => ImageSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
