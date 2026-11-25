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

class ImageSearchState extends Equatable {
  final String query;
  final List<ImageSearchResult> results;
  final bool isLoading;
  final String? error;

  const ImageSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [query, results, isLoading, error];
}

/// Chỉ lấy trang đầu: người dùng muốn ảnh khác thì đổi từ khóa, đỡ tốn lượt gọi kho ảnh.
class ImageSearchBloc extends Bloc<ImageSearchEvent, ImageSearchState> {
  final ImageRepository repository;

  ImageSearchBloc({required this.repository}) : super(const ImageSearchState()) {
    on<ImageSearchQueryChanged>(_onQueryChanged, transformer: restartable());
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
      emit(ImageSearchState(query: query, results: page.results));
    } on Failure catch (e) {
      emit(ImageSearchState(query: query, error: ImageSearchErrorMessages.of(e)));
    }
  }

  String _fallbackError(String? message) => message ?? 'common_error_occurred'.tr;
}
