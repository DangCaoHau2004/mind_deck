import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/dashboard_data_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardSuccess extends DashboardState {
  final DashboardDataModel data;

  const DashboardSuccess({required this.data});

  @override
  List<Object?> get props => [data];
}

class DashboardFailure extends DashboardState {
  final String error;

  const DashboardFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
