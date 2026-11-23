import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/document_import_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';
import 'package:mind_deck/data/repositories/document_import_repository.dart';

abstract class DocumentImportListEvent extends Equatable {
  const DocumentImportListEvent();

  @override
  List<Object?> get props => [];
}

class DocumentImportListLoaded extends DocumentImportListEvent {
  const DocumentImportListLoaded();
}

class DocumentImportListMore extends DocumentImportListEvent {
  const DocumentImportListMore();
}

class DocumentImportListDeleted extends DocumentImportListEvent {
  final String id;
  const DocumentImportListDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

enum DocumentImportListStatus { loading, success, failure }

class DocumentImportListState extends Equatable {
  final DocumentImportListStatus status;
  final List<DocumentImportListItem> items;
  final int page;
  final bool hasMore;
  final String? errorMessage;
  final String? notice;
  final int noticeId;

  const DocumentImportListState({
    this.status = DocumentImportListStatus.loading,
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.errorMessage,
    this.notice,
    this.noticeId = 0,
  });

  DocumentImportListState copyWith({
    DocumentImportListStatus? status,
    List<DocumentImportListItem>? items,
    int? page,
    bool? hasMore,
    String? errorMessage,
    String? notice,
    int? noticeId,
  }) {
    return DocumentImportListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items.map((e) => e.id).join(','),
    page,
    hasMore,
    errorMessage,
    noticeId,
  ];
}

class DocumentImportListBloc extends Bloc<DocumentImportListEvent, DocumentImportListState> {
  static const int _pageSize = 20;

  final DocumentImportRepository repository;
  bool _loadingMore = false;

  DocumentImportListBloc({required this.repository}) : super(const DocumentImportListState()) {
    on<DocumentImportListLoaded>(_onLoaded);
    on<DocumentImportListMore>(_onMore);
    on<DocumentImportListDeleted>(_onDeleted);
  }

  String _messageOf(Object e, String fallback) {
    if (e is Failure) return DocumentImportErrorMessages.of(e);
    return fallback;
  }

  bool _hasMore(int page, int total, int fetched) {
    // BE trả `meta.pagination.totalPages`; dự phòng theo số đã tải so với tổng.
    return page * _pageSize < total && fetched >= _pageSize;
  }

  Future<void> _onLoaded(
    DocumentImportListLoaded event,
    Emitter<DocumentImportListState> emit,
  ) async {
    emit(const DocumentImportListState());
    try {
      final res = await repository.list(page: 1, limit: _pageSize);
      emit(
        state.copyWith(
          status: DocumentImportListStatus.success,
          items: res.data,
          page: 1,
          hasMore: _hasMore(1, res.total, res.data.length),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DocumentImportListStatus.failure,
          errorMessage: _messageOf(e, 'Không thể tải danh sách bản nháp'),
        ),
      );
    }
  }

  Future<void> _onMore(DocumentImportListMore event, Emitter<DocumentImportListState> emit) async {
    if (!state.hasMore || _loadingMore || state.status != DocumentImportListStatus.success) return;
    _loadingMore = true;
    try {
      final next = state.page + 1;
      final res = await repository.list(page: next, limit: _pageSize);
      final known = state.items.map((e) => e.id).toSet();
      final merged = [...state.items, ...res.data.where((e) => !known.contains(e.id))];
      emit(
        state.copyWith(
          items: merged,
          page: next,
          hasMore: res.data.isNotEmpty && _hasMore(next, res.total, res.data.length),
        ),
      );
    } catch (_) {
      // Lỗi tải thêm: giữ nguyên danh sách, lần cuộn sau thử lại.
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _onDeleted(
    DocumentImportListDeleted event,
    Emitter<DocumentImportListState> emit,
  ) async {
    final before = state.items;
    emit(state.copyWith(items: before.where((e) => e.id != event.id).toList()));
    try {
      await repository.delete(event.id);
    } on Failure catch (f) {
      if (f.errorCode == 'DOCUMENT_IMPORT_NOT_FOUND') return; // đã bị xóa ở nơi khác
      emit(
        state.copyWith(
          items: before,
          notice: DocumentImportErrorMessages.of(f),
          noticeId: state.noticeId + 1,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          items: before,
          notice: 'Không thể xóa bản nháp',
          noticeId: state.noticeId + 1,
        ),
      );
    }
  }
}
