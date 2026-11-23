import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/image_search_error_messages.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/image_search_model.dart';
import 'package:mind_deck/data/repositories/image_repository.dart';

abstract class ImageSearchEvent extends Equatable {
  const ImageSearchEvent();

  @override
  List<Object?> get props => [];
}

class ImageSearchQueryChanged extends ImageSearchEvent {
  final String query;
  const ImageSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ImageSearchNextPageRequested extends ImageSearchEvent {
  const ImageSearchNextPageRequested();
}

class ImageSearchState extends Equatable {
  final String query;
  final List<ImageSearchResult> results;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const ImageSearchState({
    this.query = '',
    this.results = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  @override
  List<Object?> get props => [query, results, page, hasMore, isLoading, isLoadingMore, error];
}

class ImageSearchBloc extends Bloc<ImageSearchEvent, ImageSearchState> {
  final ImageRepository repository;

  ImageSearchBloc({required this.repository}) : super(const ImageSearchState()) {
    on<ImageSearchQueryChanged>(_onQueryChanged, transformer: restartable());
    on<ImageSearchNextPageRequested>(_onNextPage, transformer: droppable());
  }

  Future<void> _onQueryChanged(
    ImageSearchQueryChanged event,
    Emitter<ImageSearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const ImageSearchState());
      return;
    }
    emit(ImageSearchState(query: query, isLoading: true));
    try {
      final response = await repository.searchImages(query: query);
      final page = response.data;
      if (!response.success || page == null) {
        emit(ImageSearchState(query: query, error: _fallbackError(response.message)));
        return;
      }
      emit(
        ImageSearchState(
          query: query,
          results: page.results,
          page: page.page,
          hasMore: page.hasMore,
        ),
      );
    } on Failure catch (e) {
      emit(ImageSearchState(query: query, error: ImageSearchErrorMessages.of(e)));
    }
  }

  Future<void> _onNextPage(
    ImageSearchNextPageRequested event,
    Emitter<ImageSearchState> emit,
  ) async {
    final current = state;
    if (!current.hasMore || current.isLoading || current.isLoadingMore) return;
    emit(_copy(current, isLoadingMore: true));
    try {
      final response = await repository.searchImages(query: current.query, page: current.page + 1);
      final page = response.data;
      // Từ khóa đã đổi trong lúc tải thì bỏ kết quả cũ.
      if (state.query != current.query) return;
      if (!response.success || page == null) {
        emit(_copy(current, error: _fallbackError(response.message)));
        return;
      }
      emit(
        ImageSearchState(
          query: current.query,
          results: [...current.results, ...page.results],
          page: page.page,
          hasMore: page.hasMore,
        ),
      );
    } on Failure catch (e) {
      if (state.query == current.query) {
        emit(_copy(current, error: ImageSearchErrorMessages.of(e)));
      }
    }
  }

  String _fallbackError(String? message) => message ?? 'common_error_occurred'.tr;

  ImageSearchState _copy(ImageSearchState s, {bool isLoadingMore = false, String? error}) {
    return ImageSearchState(
      query: s.query,
      results: s.results,
      page: s.page,
      hasMore: s.hasMore,
      isLoadingMore: isLoadingMore,
      error: error,
    );
  }
}
