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
      code: json['code'] as String?,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data'] as Map<String, dynamic>) : null, //data
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

  ApiListResponse({
    required this.success,
    this.code,
    required this.message,
    required this.data,
    required this.total,
    this.stats,
    this.meta,
    this.pagination,
  });

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final paginationMap = json['pagination'] as Map<String, dynamic>?;
    final metaMap = json['meta'] as Map<String, dynamic>?;
    final totalCount = metaMap?['total'] as int? ?? paginationMap?['total'] as int? ?? 0;

    return ApiListResponse(
      success: json['success'] as bool? ?? false,
      code: json['code'] as String?,
      message: json['message'] as String? ?? '',
      total: totalCount,
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
