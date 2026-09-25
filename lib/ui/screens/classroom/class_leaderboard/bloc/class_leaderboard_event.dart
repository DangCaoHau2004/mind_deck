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
