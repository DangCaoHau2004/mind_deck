import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';

enum ClassMaterialsStatus { initial, loading, success, failure }

class ClassMaterialsState extends Equatable {
  final ClassMaterialsStatus status;
  final List<DeckModel> decks;
  final List<FolderModel> folders;
  final String? errorMessage;

  final int currentPage;
  final bool hasReachedMax;
  final String searchQuery;

  final bool isProcessing;
  final bool isRefreshing;
  final String? processErrorMessage;

  final bool isSelectionMode;
  final List<String> selectedDecks;
  final List<String> selectedFolders;

  const ClassMaterialsState({
    this.status = ClassMaterialsStatus.initial,
    this.decks = const [],
    this.folders = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.searchQuery = '',
    this.isProcessing = false,
    this.isRefreshing = false,
    this.processErrorMessage,
    this.isSelectionMode = false,
    this.selectedDecks = const [],
    this.selectedFolders = const [],
  });

  ClassMaterialsState copyWith({
    ClassMaterialsStatus? status,
    List<DeckModel>? decks,
    List<FolderModel>? folders,
    String? errorMessage,
    int? currentPage,
    bool? hasReachedMax,
    String? searchQuery,
    bool? isProcessing,
    bool? isRefreshing,
    String? processErrorMessage,
    bool? isSelectionMode,
    List<String>? selectedDecks,
    List<String>? selectedFolders,
  }) {
    return ClassMaterialsState(
      status: status ?? this.status,
      decks: decks ?? this.decks,
      folders: folders ?? this.folders,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
      isProcessing: isProcessing ?? this.isProcessing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      processErrorMessage: processErrorMessage,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedDecks: selectedDecks ?? this.selectedDecks,
      selectedFolders: selectedFolders ?? this.selectedFolders,
    );
  }

  @override
  List<Object?> get props => [
    status,
    decks,
    folders,
    errorMessage,
    currentPage,
    hasReachedMax,
    searchQuery,
    isProcessing,
    isRefreshing,
    processErrorMessage,
    isSelectionMode,
    selectedDecks,
    selectedFolders,
  ];
}
