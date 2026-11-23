// TODO: [i18n] Cái phần đa ngôn ngữ sẽ được xử lý ở đây căn bản là:
// cái message nó không có giá trị vì nó sẽ chỉ hiển thị tiếng việt mà thôi
// nên cứ thay nó là đẹp nhất
class ApiResponse<T> {
  final bool success;
  final String? code;
  final String? message;
  final T? data;

  ApiResponse({required this.success, this.code, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      code: (json['errorCode'] ?? json['code']) as String?,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data'] as Map<String, dynamic>) : null, //data
    );
  }

  /// Dùng khi `data` không phải Map (List, số...) hoặc cần tự parse phần `data` thô.
  factory ApiResponse.fromJsonAny(Map<String, dynamic> json, T Function(dynamic data) parse) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      code: (json['errorCode'] ?? json['code']) as String?,
      message: json['message'] as String?,
      data: json['data'] != null ? parse(json['data']) : null,
    );
  }
}

class ApiListResponse<T> {
  final bool success;
  final String? code;
  final String message;
  final List<T> data;
  final int total;
  final Map<String, dynamic>? stats;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? pagination;

  /// `hasMore` do BE trả trong `pagination` (vd `meta.pagination.hasMore`); null nếu BE không trả.
  final bool? hasMore;

  ApiListResponse({
    required this.success,
    this.code,
    required this.message,
    required this.data,
    required this.total,
    this.stats,
    this.meta,
    this.pagination,
    this.hasMore,
  });

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final metaMap = json['meta'] as Map<String, dynamic>?;
    // Có BE trả `pagination` ở cấp ngoài, có BE lồng trong `meta.pagination`.
    final paginationMap =
        json['pagination'] as Map<String, dynamic>? ??
        metaMap?['pagination'] as Map<String, dynamic>?;
    int? asInt(Object? v) => (v as num?)?.toInt();
    // `/history/tests` dùng `totalItems`, các route khác dùng `total`.
    final totalCount =
        asInt(metaMap?['total']) ??
        asInt(paginationMap?['total']) ??
        asInt(paginationMap?['totalItems']) ??
        0;

    return ApiListResponse(
      success: json['success'] as bool? ?? false,
      code: json['code'] as String?,
      message: json['message'] as String? ?? '',
      total: totalCount,
      hasMore: paginationMap?['hasMore'] as bool? ?? metaMap?['hasMore'] as bool?,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [], // data
      stats: json['stats'] as Map<String, dynamic>?,
      meta: metaMap ?? paginationMap,
      pagination: paginationMap,
    );
  }
}
