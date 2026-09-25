import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_content_model.dart';

enum DiscoverPopularStatus { initial, loading, success, failure }

class DiscoverPopularState extends Equatable {
  final DiscoverPopularStatus status;
  final List<DiscoverySuggestedContentModel> items;
  final String? errorMessage;
  final bool isRefreshing;
  final bool hasReachedMax;
  final int currentPage;

  const DiscoverPopularState({
    this.status = DiscoverPopularStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.isRefreshing = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  DiscoverPopularState copyWith({
    DiscoverPopularStatus? status,
    List<DiscoverySuggestedContentModel>? items,
    String? errorMessage,
    bool? isRefreshing,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return DiscoverPopularState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    errorMessage,
    isRefreshing,
    hasReachedMax,
    currentPage,
  ];
}
