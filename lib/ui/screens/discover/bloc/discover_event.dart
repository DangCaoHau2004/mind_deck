import 'package:equatable/equatable.dart';

abstract class DiscoverEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscoverLoaded extends DiscoverEvent {}

class DiscoverRefreshed extends DiscoverEvent {}

/// Bắt đầu một lượt tìm kiếm mới (trang 1). `query` có thể chứa `#tag`.
class DiscoverSearched extends DiscoverEvent {
  final String query;
  final String type;
  final String sort;

  DiscoverSearched(this.query, {this.type = 'all', this.sort = 'relevance'});

  @override
  List<Object?> get props => [query, type, sort];
}

class DiscoverSearchLoadMore extends DiscoverEvent {}

/// Xin gợi ý khi đang gõ. Bloc tự debounce và huỷ yêu cầu cũ.
class DiscoverSuggestRequested extends DiscoverEvent {
  final String query;
  final String type;

  DiscoverSuggestRequested(this.query, {this.type = 'all'});

  @override
  List<Object?> get props => [query, type];
}

class DiscoverSuggestionsCleared extends DiscoverEvent {}

/// Thoát chế độ tìm kiếm: xoá kết quả + gợi ý.
class DiscoverSearchReset extends DiscoverEvent {}
