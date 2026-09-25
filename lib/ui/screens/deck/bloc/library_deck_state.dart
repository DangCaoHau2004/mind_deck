import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';

enum LibraryDeckStatus { initial, loading, success, failure }

class LibraryDeckState extends Equatable {
  final LibraryDeckStatus status;
  final bool isRefreshing;
  final List<DeckModel> decks;
  final int currentPage;
  final bool hasReachedMax;
  final Set<String> selectedIds;
  final String search;
  final String? filter;
  final String? sort;
  final String? order;
  final String? toastMessage;
  final DateTime? toastTriggerTime;
  final bool isToastError;

  const LibraryDeckState({
    this.status = LibraryDeckStatus.initial,
    this.isRefreshing = false,
    this.decks = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.selectedIds = const {},
    this.search = "",
    this.filter = "all", // Mặc định theo API
    this.sort = "created", // Mặc định theo API
    this.order = "desc", // Mặc định theo API
    this.toastMessage,
    this.toastTriggerTime,
    this.isToastError = true,
  });

  LibraryDeckState copyWith({
    LibraryDeckStatus? status,
    bool? isRefreshing,
    List<DeckModel>? decks,
    int? currentPage,
    bool? hasReachedMax,
    Set<String>? selectedIds,
    String? search,
    String? filter,
    String? sort,
    String? order,
    String? toastMessage,
    DateTime? toastTriggerTime,
    bool? isToastError,
  }) {
    return LibraryDeckState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      decks: decks ?? this.decks,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedIds: selectedIds ?? this.selectedIds,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      order: order ?? this.order,
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
    decks,
    currentPage,
    hasReachedMax,
    selectedIds,
    search,
    filter,
    sort,
    order,
    toastMessage,
    toastTriggerTime,
    isToastError,
  ];
}
