import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/stats_model.dart';

abstract class StatsOverviewState extends Equatable {
  const StatsOverviewState();

  @override
  List<Object?> get props => [];
}

class StatsOverviewInitial extends StatsOverviewState {}

class StatsOverviewLoading extends StatsOverviewState {}

class StatsOverviewSuccess extends StatsOverviewState {
  final StatsOverviewModel stats;

  const StatsOverviewSuccess(this.stats);

  @override
  List<Object?> get props => [stats];
}

class StatsOverviewFailure extends StatsOverviewState {
  final String errorMessage;

  const StatsOverviewFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
