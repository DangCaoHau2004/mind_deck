import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/folder_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

enum LibraryFolderStatus { initial, loading, success, failure }

class LibraryFolderState extends Equatable {
  final LibraryFolderStatus status;
  final bool isRefreshing;

  /// Đang tìm/lọc/sắp xếp khi đã có danh sách (danh sách cũ vẫn hiển thị).
  final bool isSearching;
  final bool isLoadingMore;
  final List<FolderModel> folders;
  final FolderSuggestionModel? suggestions;
  final List<TagModel> activeTags;
  final int currentPage;
  final bool hasReachedMax;

  /// Các mục đã chọn theo thứ tự chọn (giữ cả khi tìm/lọc làm chúng không còn trong danh sách đang hiện).
  final Map<String, FolderModel> selected;
  final String search;
  final String sort;
  final String order;
  final bool? isStarred;

  /// Tăng mỗi khi kết quả tìm/lọc mới thay danh sách, để màn cuộn về đầu.
  final int listVersion;
  final String? toastMessage;
  final DateTime? toastTriggerTime;
  final bool isToastError;

  const LibraryFolderState({
    this.status = LibraryFolderStatus.initial,
    this.isRefreshing = false,
    this.isSearching = false,
    this.isLoadingMore = false,
    this.folders = const [],
    this.suggestions,
    this.activeTags = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.selected = const {},
    this.search = "",
    this.sort = "recent",
    this.order = "desc",
    this.isStarred,
    this.listVersion = 0,
    this.toastMessage,
    this.toastTriggerTime,
    this.isToastError = true,
  });

  LibraryFolderState copyWith({
    LibraryFolderStatus? status,
    bool? isRefreshing,
    bool? isSearching,
    bool? isLoadingMore,
    List<FolderModel>? folders,
    FolderSuggestionModel? suggestions,
    List<TagModel>? activeTags,
    int? currentPage,
    bool? hasReachedMax,
    Map<String, FolderModel>? selected,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    bool clearIsStarred = false,
    int? listVersion,
    String? toastMessage,
    DateTime? toastTriggerTime,
    bool? isToastError,
  }) {
    return LibraryFolderState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      folders: folders ?? this.folders,
      suggestions: suggestions ?? this.suggestions,
      activeTags: activeTags ?? this.activeTags,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selected: selected ?? this.selected,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      isStarred: clearIsStarred ? null : (isStarred ?? this.isStarred),
      listVersion: listVersion ?? this.listVersion,
      toastMessage: toastMessage,
      toastTriggerTime: toastTriggerTime,
      isToastError: isToastError ?? this.isToastError,
    );
  }

  bool get isSelectionMode => selected.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    isRefreshing,
    isSearching,
    isLoadingMore,
    folders,
    suggestions,
    activeTags,
    currentPage,
    hasReachedMax,
    selected,
    search,
    sort,
    order,
    isStarred,
    listVersion,
    toastMessage,
    toastTriggerTime,
    isToastError,
  ];
}
