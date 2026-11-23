import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';

// ---- Events ----
abstract class ClassTestsEvent extends Equatable {
  const ClassTestsEvent();

  @override
  List<Object?> get props => [];
}

class ClassTestsLoaded extends ClassTestsEvent {
  final String classId;

  const ClassTestsLoaded(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassTestsLoadMore extends ClassTestsEvent {
  final String classId;

  const ClassTestsLoadMore(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassTestsSearchChanged extends ClassTestsEvent {
  final String classId;
  final String query;

  const ClassTestsSearchChanged(this.classId, this.query);

  @override
  List<Object?> get props => [classId, query];
}

// ---- State ----
enum ClassTestsStatus { initial, loading, success, failure }

class ClassTestsState extends Equatable {
  final ClassTestsStatus status;
  final List<CustomTestModel> items;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String query;

  /// Không còn là giảng viên / lớp không còn: màn hình nên đóng.
  final bool isForbidden;

  const ClassTestsState({
    this.status = ClassTestsStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.query = '',
    this.isForbidden = false,
  });

  ClassTestsState copyWith({
    ClassTestsStatus? status,
    List<CustomTestModel>? items,
    String? errorMessage,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? query,
    bool? isForbidden,
  }) {
    return ClassTestsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      query: query ?? this.query,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    errorMessage,
    page,
    hasMore,
    isLoadingMore,
    query,
    isForbidden,
  ];
}

// ---- Bloc ----
/// Kho đề của lớp (`GET /tests?classId=`), chỉ giảng viên. Phân trang theo `meta.pagination`.
class ClassTestsBloc extends Bloc<ClassTestsEvent, ClassTestsState> {
  final TestRepository repository;

  static const int pageSize = 20;

  ClassTestsBloc({required this.repository}) : super(const ClassTestsState()) {
    on<ClassTestsLoaded>(_onLoaded);
    on<ClassTestsLoadMore>(_onLoadMore);
    on<ClassTestsSearchChanged>(_onSearch);
  }

  bool _hasMore(ApiListResponse<CustomTestModel> res, int page) {
    final totalPages = (res.pagination?['totalPages'] as num?)?.toInt();
    if (totalPages != null) return page < totalPages;
    return res.hasMore ?? res.data.length >= pageSize;
  }

  Future<void> _loadFirst(String classId, Emitter<ClassTestsState> emit) async {
    try {
      final res = await repository.getTests(
        classId: classId,
        page: 1,
        limit: pageSize,
        search: state.query,
      );
      emit(
        state.copyWith(
          status: ClassTestsStatus.success,
          items: res.data,
          page: 1,
          hasMore: _hasMore(res, 1),
          isLoadingMore: false,
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          status: ClassTestsStatus.failure,
          errorMessage: ClassErrorMessages.of(f),
          isForbidden: ClassErrorMessages.isClassGone(f),
        ),
      );
    }
  }

  Future<void> _onLoaded(ClassTestsLoaded event, Emitter<ClassTestsState> emit) async {
    emit(state.copyWith(status: ClassTestsStatus.loading));
    await _loadFirst(event.classId, emit);
  }

  Future<void> _onSearch(ClassTestsSearchChanged event, Emitter<ClassTestsState> emit) async {
    emit(state.copyWith(status: ClassTestsStatus.loading, query: event.query));
    await _loadFirst(event.classId, emit);
  }

  Future<void> _onLoadMore(ClassTestsLoadMore event, Emitter<ClassTestsState> emit) async {
    if (!state.hasMore || state.isLoadingMore || state.status != ClassTestsStatus.success) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = state.page + 1;
      final res = await repository.getTests(
        classId: event.classId,
        page: next,
        limit: pageSize,
        search: state.query,
      );
      final known = {for (final t in state.items) t.id};
      emit(
        state.copyWith(
          items: [...state.items, ...res.data.where((t) => !known.contains(t.id))],
          page: next,
          hasMore: _hasMore(res, next),
          isLoadingMore: false,
        ),
      );
    } on Failure {
      emit(state.copyWith(isLoadingMore: false));
    }
  }
}
