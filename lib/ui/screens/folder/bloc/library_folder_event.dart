import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/folder_model.dart';

abstract class LibraryFolderEvent extends Equatable {
  const LibraryFolderEvent();

  @override
  List<Object?> get props => [];
}

class LibraryFolderLoadStarted extends LibraryFolderEvent {}

class LibraryFolderRefreshed extends LibraryFolderEvent {}

class LibraryFolderLoadMore extends LibraryFolderEvent {}

/// Chi tiết thư mục đã đổi (tên, màu, sao, số bộ thẻ...): thay đúng mục đó tại chỗ, không gọi API.
class LibraryFolderItemUpdated extends LibraryFolderEvent {
  final FolderModel folder;

  const LibraryFolderItemUpdated(this.folder);

  @override
  List<Object?> get props => [folder];
}

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

/// Gắn sao / bỏ sao hàng loạt các thư mục đang chọn (tất cả đã gắn sao thì bỏ sao, ngược lại gắn sao).
class LibraryFolderSelectedStarToggled extends LibraryFolderEvent {}

class LibraryFolderStarToggled extends LibraryFolderEvent {
  final String id;

  const LibraryFolderStarToggled(this.id);

  @override
  List<Object?> get props => [id];
}

class LibraryFoldersSelectedDeleted extends LibraryFolderEvent {}
