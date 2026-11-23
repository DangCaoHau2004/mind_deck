import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_leaderboard_response_model.dart';

enum ClassLeaderboardStatus { initial, loading, success, failure }

class ClassLeaderboardState extends Equatable {
  final ClassLeaderboardStatus status;
  final ClassLeaderboardResponseModel? leaderboard;
  final String? errorMessage;
  final bool isRefreshing;

  /// Tháng đang xem (`YYYY-MM`); null = tháng hiện tại (mặc định của BE).
  final String? selectedMonth;

  /// Lớp đã tắt bảng xếp hạng với học viên (403 `CLASS_LEADERBOARD_DISABLED`).
  final bool isDisabled;

  const ClassLeaderboardState({
    this.status = ClassLeaderboardStatus.initial,
    this.leaderboard,
    this.errorMessage,
    this.isRefreshing = false,
    this.selectedMonth,
    this.isDisabled = false,
  });

  ClassLeaderboardState copyWith({
    ClassLeaderboardStatus? status,
    ClassLeaderboardResponseModel? leaderboard,
    bool clearLeaderboard = false,
    String? errorMessage,
    bool? isRefreshing,
    String? selectedMonth,
    bool clearSelectedMonth = false,
    bool? isDisabled,
  }) {
    return ClassLeaderboardState(
      status: status ?? this.status,
      leaderboard: clearLeaderboard ? null : (leaderboard ?? this.leaderboard),
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      selectedMonth: clearSelectedMonth ? null : (selectedMonth ?? this.selectedMonth),
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  @override
  List<Object?> get props => [
    status,
    leaderboard,
    errorMessage,
    isRefreshing,
    selectedMonth,
    isDisabled,
  ];
}
