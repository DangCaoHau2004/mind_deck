import 'package:equatable/equatable.dart';

abstract class ClassLeaderboardEvent extends Equatable {
  const ClassLeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class ClassLeaderboardLoaded extends ClassLeaderboardEvent {
  final String classId;

  const ClassLeaderboardLoaded(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassLeaderboardRefreshed extends ClassLeaderboardEvent {
  final String classId;

  const ClassLeaderboardRefreshed(this.classId);

  @override
  List<Object?> get props => [classId];
}

/// Đổi tháng xem. `month` dạng `YYYY-MM`; null = "Tháng này" (không gửi `month` lên BE).
class ClassLeaderboardMonthChanged extends ClassLeaderboardEvent {
  final String classId;
  final String? month;

  const ClassLeaderboardMonthChanged(this.classId, this.month);

  @override
  List<Object?> get props => [classId, month];
}
