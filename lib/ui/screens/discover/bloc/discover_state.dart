import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/discovery/discovery_response_model.dart';
import 'package:mind_deck/data/models/global_search_model.dart';

enum DiscoverStatus { initial, loading, success, failure }

enum SearchStatus { initial, loading, success, failure }

class DiscoverState extends Equatable {
  final DiscoverStatus status;
  final DiscoveryResponseModel? discoveryData;
  final String? errorMessage;
  final bool isRefreshing;

  final SearchStatus searchStatus;
  final List<GlobalSearchModel> searchResults;
  final String? searchErrorMessage;

  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.discoveryData,
    this.errorMessage,
    this.isRefreshing = false,
    this.searchStatus = SearchStatus.initial,
    this.searchResults = const [],
    this.searchErrorMessage,
  });

  DiscoverState copyWith({
    DiscoverStatus? status,
    DiscoveryResponseModel? discoveryData,
    String? errorMessage,
    bool? isRefreshing,
    SearchStatus? searchStatus,
    List<GlobalSearchModel>? searchResults,
    String? searchErrorMessage,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      discoveryData: discoveryData ?? this.discoveryData,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchStatus: searchStatus ?? this.searchStatus,
      searchResults: searchResults ?? this.searchResults,
      searchErrorMessage: searchErrorMessage ?? this.searchErrorMessage,
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
    searchErrorMessage,
  ];
}
