import 'package:equatable/equatable.dart';

abstract class DiscoverPopularEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscoverPopularLoaded extends DiscoverPopularEvent {
  final int page;
  final int limit;
  DiscoverPopularLoaded({this.page = 1, this.limit = 20});
}

class DiscoverPopularRefreshed extends DiscoverPopularEvent {}
