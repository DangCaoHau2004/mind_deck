import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';

enum FolderDetailStatus { initial, loading, success, failure, deleted }

class FolderDetailState extends Equatable {
  final FolderDetailStatus status;
  final bool isRefreshing;
  final FolderModel? folder;

  /// Bộ thẻ trong thư mục (phân trang qua `GET /folders/:id/decks`, theo tìm kiếm và sắp xếp hiện tại).
  final List<DeckModel> decks;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;

  /// Đang tìm/đổi sắp xếp khi đã có danh sách (danh sách cũ vẫn hiển thị).
  final bool isSearching;
  final String search;
  final String sort;
  final String order;

  /// Tăng mỗi khi kết quả tìm/sắp xếp mới thay danh sách, để màn cuộn về đầu.
  final int listVersion;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? toastTriggerTime;
  final bool isSelectionMode;
  final List<String> selectedDeckIds;
  final String? clonedFolderId;

  const FolderDetailState({
    this.status = FolderDetailStatus.initial,
    this.isRefreshing = false,
    this.folder,
    this.decks = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.search = '',
    this.sort = 'due',
    this.order = 'asc',
    this.listVersion = 0,
    this.errorMessage,
    this.successMessage,
    this.toastTriggerTime,
    this.isSelectionMode = false,
    this.selectedDeckIds = const [],
    this.clonedFolderId,
  });

  FolderDetailState copyWith({
    FolderDetailStatus? status,
    bool? isRefreshing,
    FolderModel? folder,
    List<DeckModel>? decks,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isSearching,
    String? search,
    String? sort,
    String? order,
    int? listVersion,
    String? errorMessage,
    String? successMessage,
    DateTime? toastTriggerTime,
    bool? isSelectionMode,
    List<String>? selectedDeckIds,
    String? clonedFolderId,
  }) {
    return FolderDetailState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      folder: folder ?? this.folder,
      decks: decks ?? this.decks,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      listVersion: listVersion ?? this.listVersion,
      errorMessage: errorMessage,
      successMessage: successMessage,
      toastTriggerTime: toastTriggerTime,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedDeckIds: selectedDeckIds ?? this.selectedDeckIds,
      clonedFolderId: clonedFolderId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isRefreshing,
    folder,
    decks,
    currentPage,
    hasReachedMax,
    isLoadingMore,
    isSearching,
    search,
    sort,
    order,
    listVersion,
    errorMessage,
    successMessage,
    toastTriggerTime,
    isSelectionMode,
    selectedDeckIds,
    clonedFolderId,
  ];
}
