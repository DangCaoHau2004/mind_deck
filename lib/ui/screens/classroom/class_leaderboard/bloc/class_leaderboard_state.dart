import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_leaderboard_response_model.dart';

enum ClassLeaderboardStatus { initial, loading, success, failure }

class ClassLeaderboardState extends Equatable {
  final ClassLeaderboardStatus status;
  final ClassLeaderboardResponseModel? leaderboard;
  final String? errorMessage;
  final bool isRefreshing;

  const ClassLeaderboardState({
    this.status = ClassLeaderboardStatus.initial,
    this.leaderboard,
    this.errorMessage,
    this.isRefreshing = false,
  });

  ClassLeaderboardState copyWith({
    ClassLeaderboardStatus? status,
    ClassLeaderboardResponseModel? leaderboard,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return ClassLeaderboardState(
      status: status ?? this.status,
      leaderboard: leaderboard ?? this.leaderboard,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, leaderboard, errorMessage, isRefreshing];
}
