import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/coin_models.dart';
import 'package:mind_deck/data/repositories/coin_repository.dart';

class CoinState extends Equatable {
  final CoinInfo? info;
  final List<CoinTransaction> history;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const CoinState({
    this.info,
    this.history = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  CoinState copyWith({
    CoinInfo? info,
    List<CoinTransaction>? history,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return CoinState(
      info: info ?? this.info,
      history: history ?? this.history,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    info?.balance,
    info?.earn.earnedToday,
    info?.earn.remainingToday,
    history,
    page,
    hasMore,
    isLoading,
    isLoadingMore,
    error,
  ];
}

/// Số dư xu và lịch sử giao dịch.
class CoinCubit extends Cubit<CoinState> {
  final CoinRepository repository;

  CoinCubit({required this.repository}) : super(const CoinState());

  String _messageOf(Object e) => e is Failure ? e.message : 'common_error_occurred'.tr;

  /// Tải lại số dư và trang đầu của lịch sử.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final results = await Future.wait([repository.getCoins(), repository.getHistory()]);
      final page = results[1] as CoinHistoryPage;
      emit(
        CoinState(
          info: results[0] as CoinInfo,
          history: page.items,
          page: 1,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: _messageOf(e)));
    }
  }

  /// Chỉ cập nhật số dư (sau khi xem video), giữ nguyên danh sách.
  Future<void> refreshBalance() async {
    try {
      emit(state.copyWith(info: await repository.getCoins()));
    } catch (_) {
      // Giữ số cũ, lần mở sau sẽ tải lại.
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await repository.getHistory(page: state.page + 1);
      emit(
        state.copyWith(
          history: [...state.history, ...page.items],
          page: state.page + 1,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, error: _messageOf(e)));
    }
  }
}
