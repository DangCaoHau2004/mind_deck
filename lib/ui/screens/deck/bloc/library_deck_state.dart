import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/deck_suggestion_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

enum LibraryDeckStatus { initial, loading, success, failure }

class LibraryDeckState extends Equatable {
  final LibraryDeckStatus status;
  final bool isRefreshing;

  /// Đang tìm/lọc/sắp xếp khi đã có danh sách (danh sách cũ vẫn hiển thị).
  final bool isSearching;
  final bool isLoadingMore;
  final List<DeckModel> decks;
  final DeckSuggestionModel? suggestions;
  final List<TagModel> activeTags;
  final int currentPage;
  final bool hasReachedMax;

  /// Các mục đã chọn theo thứ tự chọn (giữ cả khi tìm/lọc làm chúng không còn trong danh sách đang hiện).
  final Map<String, DeckModel> selected;
  final String search;
  final String? filter;
  final String? sort;
  final String? order;

  /// Tăng mỗi khi kết quả tìm/lọc mới thay danh sách, để màn cuộn về đầu.
  final int listVersion;
  final String? toastMessage;
  final DateTime? toastTriggerTime;
  final bool isToastError;

  const LibraryDeckState({
    this.status = LibraryDeckStatus.initial,
    this.isRefreshing = false,
    this.isSearching = false,
    this.isLoadingMore = false,
    this.decks = const [],
    this.suggestions,
    this.activeTags = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.selected = const {},
    this.search = "",
    this.filter = "all", // Mặc định theo API
    this.sort = "recent", // Mặc định theo API
    this.order = "desc", // Mặc định theo API
    this.listVersion = 0,
    this.toastMessage,
    this.toastTriggerTime,
    this.isToastError = true,
  });

  LibraryDeckState copyWith({
    LibraryDeckStatus? status,
    bool? isRefreshing,
    bool? isSearching,
    bool? isLoadingMore,
    List<DeckModel>? decks,
    DeckSuggestionModel? suggestions,
    List<TagModel>? activeTags,
    int? currentPage,
    bool? hasReachedMax,
    Map<String, DeckModel>? selected,
    String? search,
    String? filter,
    String? sort,
    String? order,
    int? listVersion,
    String? toastMessage,
    DateTime? toastTriggerTime,
    bool? isToastError,
  }) {
    return LibraryDeckState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      decks: decks ?? this.decks,
      suggestions: suggestions ?? this.suggestions,
      activeTags: activeTags ?? this.activeTags,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selected: selected ?? this.selected,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      order: order ?? this.order,
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
    decks,
    suggestions,
    activeTags,
    currentPage,
    hasReachedMax,
    selected,
    search,
    filter,
    sort,
    order,
    listVersion,
    toastMessage,
    toastTriggerTime,
    isToastError,
  ];
}
