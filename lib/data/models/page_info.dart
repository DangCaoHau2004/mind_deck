import 'package:equatable/equatable.dart';

/// Tiến độ tải phân trang của một danh sách. BE các danh sách lớp học không trả tổng số hay `hasMore`:
/// danh sách hết khi một trang trả ít hơn `limit` dòng.
class PageInfo extends Equatable {
  /// Trang đã tải gần nhất (từ 1).
  final int page;

  /// Còn trang sau (trang vừa tải đầy `limit` dòng).
  final bool hasMore;
  final bool isLoadingMore;

  const PageInfo({this.page = 1, this.hasMore = false, this.isLoadingMore = false});

  /// Sau khi tải xong một trang có [loaded] dòng.
  factory PageInfo.loaded({required int page, required int loaded, required int limit}) =>
      PageInfo(page: page, hasMore: loaded >= limit);

  PageInfo copyWith({int? page, bool? hasMore, bool? isLoadingMore}) => PageInfo(
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  /// Có thể tải trang kế tiếp ngay bây giờ.
  bool get canLoadMore => hasMore && !isLoadingMore;

  @override
  List<Object?> get props => [page, hasMore, isLoadingMore];
}
