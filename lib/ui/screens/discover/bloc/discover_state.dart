import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/discovery/discovery_response_model.dart';
import 'package:mind_deck/data/models/global_search_model.dart';
import 'package:mind_deck/data/models/search_suggestion_model.dart';

enum DiscoverStatus { initial, loading, success, failure }

enum SearchStatus { initial, loading, success, failure }

enum SuggestStatus { initial, loading, success, failure }

class DiscoverState extends Equatable {
  static const String defaultSort = 'relevance';

  final DiscoverStatus status;
  final DiscoveryResponseModel? discoveryData;
  final String? errorMessage;
  final bool isRefreshing;

  final SearchStatus searchStatus;
  final List<GlobalSearchModel> searchResults;
  final List<GlobalSearchSectionModel> searchSections;
  final String? searchErrorMessage;
  final String searchQuery;
  final String searchType;
  final String searchSort;
  final int searchPage;
  final bool searchHasMore;
  final bool isLoadingMore;

  final SuggestStatus suggestStatus;
  final SearchSuggestionResponseModel? suggestions;

  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.discoveryData,
    this.errorMessage,
    this.isRefreshing = false,
    this.searchStatus = SearchStatus.initial,
    this.searchResults = const [],
    this.searchSections = const [],
    this.searchErrorMessage,
    this.searchQuery = '',
    this.searchType = 'all',
    this.searchSort = defaultSort,
    this.searchPage = 1,
    this.searchHasMore = false,
    this.isLoadingMore = false,
    this.suggestStatus = SuggestStatus.initial,
    this.suggestions,
  });

  DiscoverState copyWith({
    DiscoverStatus? status,
    DiscoveryResponseModel? discoveryData,
    String? errorMessage,
    bool? isRefreshing,
    SearchStatus? searchStatus,
    List<GlobalSearchModel>? searchResults,
    List<GlobalSearchSectionModel>? searchSections,
    String? searchErrorMessage,
    String? searchQuery,
    String? searchType,
    String? searchSort,
    int? searchPage,
    bool? searchHasMore,
    bool? isLoadingMore,
    SuggestStatus? suggestStatus,
    SearchSuggestionResponseModel? Function()? suggestions,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      discoveryData: discoveryData ?? this.discoveryData,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchStatus: searchStatus ?? this.searchStatus,
      searchResults: searchResults ?? this.searchResults,
      searchSections: searchSections ?? this.searchSections,
      searchErrorMessage: searchErrorMessage ?? this.searchErrorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      searchType: searchType ?? this.searchType,
      searchSort: searchSort ?? this.searchSort,
      searchPage: searchPage ?? this.searchPage,
      searchHasMore: searchHasMore ?? this.searchHasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      suggestStatus: suggestStatus ?? this.suggestStatus,
      suggestions: suggestions != null ? suggestions() : this.suggestions,
    );
  }

  @override
  List<Object?> get props => [
    status,
    discoveryData,
    errorMessage,
    isRefreshing,
    searchStatus,
    searchResults,
    searchSections,
    searchErrorMessage,
    searchQuery,
    searchType,
    searchSort,
    searchPage,
    searchHasMore,
    isLoadingMore,
    suggestStatus,
    suggestions,
  ];
}
