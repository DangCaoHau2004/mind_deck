import 'package:equatable/equatable.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/home/home_data_model.dart';

enum HomeStatus { initial, loading, success, failure }

/// Một state duy nhất (giống DiscoverState) để giữ được cả dữ liệu cũ lẫn lỗi:
/// làm mới bị lỗi thì vẫn còn [data] để hiện.
class HomeState extends Equatable {
  final HomeStatus status;
  final HomeDataModel? data;
  final bool isRefreshing;

  /// Lỗi gần nhất (để hiện toast).
  final Failure? failure;

  /// Tăng mỗi lần lỗi, để màn hiện toast cho từng lần kể cả khi lỗi giống lần trước.
  final int failureCount;

  const HomeState({
    this.status = HomeStatus.initial,
    this.data,
    this.isRefreshing = false,
    this.failure,
    this.failureCount = 0,
  });

  HomeState copyWith({
    HomeStatus? status,
    HomeDataModel? data,
    bool? isRefreshing,
    Failure? failure,
    int? failureCount,
  }) {
    return HomeState(
      status: status ?? this.status,
      data: data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failure: failure ?? this.failure,
      failureCount: failureCount ?? this.failureCount,
    );
  }

  @override
  List<Object?> get props => [status, data, isRefreshing, failure, failureCount];
}
