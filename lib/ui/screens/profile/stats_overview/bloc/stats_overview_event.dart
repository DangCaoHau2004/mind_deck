import 'package:equatable/equatable.dart';

abstract class StatsOverviewEvent extends Equatable {
  const StatsOverviewEvent();

  @override
  List<Object?> get props => [];
}

class StatsOverviewLoadStarted extends StatsOverviewEvent {
  const StatsOverviewLoadStarted();
}
