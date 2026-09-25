import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/folder_suggestion_model.dart';

enum LibraryFolderStatus { initial, loading, success, failure }

class LibraryFolderState extends Equatable {
  final LibraryFolderStatus status;
  final bool isRefreshing;
  final List<FolderModel> folders;
  final FolderSuggestionModel? suggestions;
  final int currentPage;
  final bool hasReachedMax;
  final Set<String> selectedIds;
  final String search;
  final String sort;
  final String order;
  final bool? isStarred;
  final String? toastMessage;
  final DateTime? toastTriggerTime;
  final bool isToastError;

  const LibraryFolderState({
    this.status = LibraryFolderStatus.initial,
    this.isRefreshing = false,
    this.folders = const [],
    this.suggestions,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.selectedIds = const {},
    this.search = "",
    this.sort = "recent",
    this.order = "desc",
    this.isStarred,
    this.toastMessage,
    this.toastTriggerTime,
    this.isToastError = true,
  });

  LibraryFolderState copyWith({
    LibraryFolderStatus? status,
    bool? isRefreshing,
    List<FolderModel>? folders,
    FolderSuggestionModel? suggestions,
    int? currentPage,
    bool? hasReachedMax,
    Set<String>? selectedIds,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    bool clearIsStarred = false,
    String? toastMessage,
    DateTime? toastTriggerTime,
    bool? isToastError,
  }) {
    return LibraryFolderState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      folders: folders ?? this.folders,
      suggestions: suggestions ?? this.suggestions,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedIds: selectedIds ?? this.selectedIds,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      isStarred: clearIsStarred ? null : (isStarred ?? this.isStarred),
      toastMessage: toastMessage,
      toastTriggerTime: toastTriggerTime,
      isToastError: isToastError ?? this.isToastError,
    );
  }

  bool get isSelectionMode => selectedIds.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    isRefreshing,
    folders,
    suggestions,
    currentPage,
    hasReachedMax,
    selectedIds,
    search,
    sort,
    order,
    isStarred,
    toastMessage,
    toastTriggerTime,
    isToastError,
  ];
}

