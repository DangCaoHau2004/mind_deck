import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/discovery_repository.dart';
import 'package:mind_deck/data/repositories/search_repository.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final DiscoveryRepository discoveryRepository;
  final SearchRepository searchRepository;

  DiscoverBloc({
    required this.discoveryRepository,
    required this.searchRepository,
  }) : super(const DiscoverState()) {
    on<DiscoverLoaded>(_onLoaded);
    on<DiscoverRefreshed>(_onRefreshed);
    on<DiscoverSearched>(_onSearched);
  }

  Future<void> _onLoaded(
    DiscoverLoaded event,
    Emitter<DiscoverState> emit,
  ) async {
    emit(state.copyWith(status: DiscoverStatus.loading));
    try {
      final response = await discoveryRepository.getDiscoveryFeed();
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: DiscoverStatus.success,
            discoveryData: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscoverStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    DiscoverRefreshed event,
    Emitter<DiscoverState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final response = await discoveryRepository.getDiscoveryFeed();
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: DiscoverStatus.success,
            discoveryData: response.data,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscoverStatus.failure,
            errorMessage: response.message,
            isRefreshing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onSearched(
    DiscoverSearched event,
    Emitter<DiscoverState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(
        state.copyWith(searchStatus: SearchStatus.initial, searchResults: []),
      );
      return;
    }

    emit(state.copyWith(searchStatus: SearchStatus.loading));
    try {
      final response = await searchRepository.search(query: event.query, type: event.type);
      if (response.success) {
        emit(
          state.copyWith(
            searchStatus: SearchStatus.success,
            searchResults: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            searchStatus: SearchStatus.failure,
            searchErrorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          searchStatus: SearchStatus.failure,
          searchErrorMessage: e.toString(),
        ),
      );
    }
  }
}
