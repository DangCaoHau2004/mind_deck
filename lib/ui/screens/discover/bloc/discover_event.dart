import 'package:equatable/equatable.dart';

abstract class DiscoverEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscoverLoaded extends DiscoverEvent {}

class DiscoverRefreshed extends DiscoverEvent {}

class DiscoverSearched extends DiscoverEvent {
  final String query;
  final String type;

  DiscoverSearched(this.query, {this.type = 'all'});

  @override
  List<Object?> get props => [query, type];
}
