import 'package:equatable/equatable.dart';

abstract class LibraryDeckEvent extends Equatable {
  const LibraryDeckEvent();

  @override
  List<Object?> get props => [];
}

class LibraryDeckLoadStarted extends LibraryDeckEvent {}

class LibraryDeckRefreshed extends LibraryDeckEvent {}

class LibraryDeckLoadMore extends LibraryDeckEvent {}

class LibraryDeckFilterChanged extends LibraryDeckEvent {
  final String? search;
  final String? filter;
  final String? sort;
  final String? order; // Thêm order

  const LibraryDeckFilterChanged({
    this.search,
    this.filter,
    this.sort,
    this.order,
  });

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

class LibraryDecksSelectedDeleted extends LibraryDeckEvent {}
