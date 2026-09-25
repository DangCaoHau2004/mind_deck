import 'package:equatable/equatable.dart';

abstract class LibraryFolderEvent extends Equatable {
  const LibraryFolderEvent();

  @override
  List<Object?> get props => [];
}

class LibraryFolderLoadStarted extends LibraryFolderEvent {}

class LibraryFolderRefreshed extends LibraryFolderEvent {}

class LibraryFolderLoadMore extends LibraryFolderEvent {}

class LibraryFolderFilterChanged extends LibraryFolderEvent {
  final String? search;
  final String? sort;
  final String? order;
  final bool? isStarred;
  final bool clearIsStarred;

  const LibraryFolderFilterChanged({
    this.search,
    this.sort,
    this.order,
    this.isStarred,
    this.clearIsStarred = false,
  });

  @override
  List<Object?> get props => [search, sort, order, isStarred, clearIsStarred];
}

class LibraryFolderSelectionToggled extends LibraryFolderEvent {
  final String id;

  const LibraryFolderSelectionToggled(this.id);

  @override
  List<Object?> get props => [id];
}

class LibraryFolderSelectionCleared extends LibraryFolderEvent {}

class LibraryFolderStarToggled extends LibraryFolderEvent {
  final String id;

  const LibraryFolderStarToggled(this.id);

  @override
  List<Object?> get props => [id];
}

class LibraryFoldersSelectedDeleted extends LibraryFolderEvent {}
