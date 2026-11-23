import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';

abstract class LibraryDeckEvent extends Equatable {
  const LibraryDeckEvent();

  @override
  List<Object?> get props => [];
}

class LibraryDeckLoadStarted extends LibraryDeckEvent {}

class LibraryDeckRefreshed extends LibraryDeckEvent {}

class LibraryDeckLoadMore extends LibraryDeckEvent {}

/// Chi tiết bộ thẻ đã đổi (vd gắn sao): thay đúng mục đó tại chỗ, không gọi API.
class LibraryDeckItemUpdated extends LibraryDeckEvent {
  final DeckModel deck;

  const LibraryDeckItemUpdated(this.deck);

  @override
  List<Object?> get props => [deck];
}

class LibraryDeckFilterChanged extends LibraryDeckEvent {
  final String? search;
  final String? filter;
  final String? sort;
  final String? order; // Thêm order

  const LibraryDeckFilterChanged({this.search, this.filter, this.sort, this.order});

  @override
  List<Object?> get props => [search, filter, sort, order];
}

class LibraryDeckSelectionToggled extends LibraryDeckEvent {
  final String id;

  const LibraryDeckSelectionToggled(this.id);

  @override
  List<Object?> get props => [id];
}

class LibraryDeckStarToggled extends LibraryDeckEvent {
  final String id;

  const LibraryDeckStarToggled(this.id);

  @override
  List<Object?> get props => [id];
}

class LibraryDeckSelectionCleared extends LibraryDeckEvent {}

/// Gắn sao / bỏ sao hàng loạt các học phần đang chọn (tất cả đã gắn sao thì bỏ sao, ngược lại gắn sao).
class LibraryDeckSelectedStarToggled extends LibraryDeckEvent {}

class LibraryDecksSelectedDeleted extends LibraryDeckEvent {}
