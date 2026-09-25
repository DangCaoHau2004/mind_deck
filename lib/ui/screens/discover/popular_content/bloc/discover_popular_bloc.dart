import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/discovery_repository.dart';
import 'discover_popular_event.dart';
import 'discover_popular_state.dart';

class DiscoverPopularBloc
    extends Bloc<DiscoverPopularEvent, DiscoverPopularState> {
  final DiscoveryRepository discoveryRepository;

  DiscoverPopularBloc({required this.discoveryRepository})
    : super(const DiscoverPopularState()) {
    on<DiscoverPopularLoaded>(_onLoaded);
    on<DiscoverPopularRefreshed>(_onRefreshed);
  }

  Future<void> _onLoaded(
    DiscoverPopularLoaded event,
    Emitter<DiscoverPopularState> emit,
  ) async {
    if (state.hasReachedMax && event.page > 1) return;

    if (event.page == 1) {
      emit(state.copyWith(status: DiscoverPopularStatus.loading));
    }

    try {
      final response = await discoveryRepository.getPopularContent(
        page: event.page,
        limit: event.limit,
      );
      if (response.success) {
        if (response.data.isEmpty) {
          emit(
            state.copyWith(
              hasReachedMax: true,
              status: DiscoverPopularStatus.success,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: DiscoverPopularStatus.success,
              items: event.page == 1 ? response.data : List.of(state.items)
                ..addAll(response.data),
              hasReachedMax: response.data.length < event.limit,
              currentPage: event.page,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: DiscoverPopularStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverPopularStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    DiscoverPopularRefreshed event,
    Emitter<DiscoverPopularState> emit,
  ) async {
    emit(
      state.copyWith(isRefreshing: true, hasReachedMax: false, currentPage: 1),
    );
    try {
      final response = await discoveryRepository.getPopularContent(
        page: 1,
        limit: 20,
      );
      if (response.success) {
        emit(
          state.copyWith(
            status: DiscoverPopularStatus.success,
            items: response.data,
            hasReachedMax: response.data.length < 20,
            isRefreshing: false,
            currentPage: 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DiscoverPopularStatus.failure,
            errorMessage: response.message,
            isRefreshing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoverPopularStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }
}
