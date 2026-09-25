import 'package:equatable/equatable.dart';

abstract class DeckDetailEvent extends Equatable {
  const DeckDetailEvent();
  @override
  List<Object?> get props => [];
}

class DeckDetailLoaded extends DeckDetailEvent {
  final String id;
  final String? token;
  const DeckDetailLoaded(this.id, {this.token});
  @override
  List<Object?> get props => [id, token];
}

class DeckDetailRefreshed extends DeckDetailEvent {
  final String id;
  final String? token;
  const DeckDetailRefreshed(this.id, {this.token});
  @override
  List<Object?> get props => [id, token];
}

class DeckDeleted extends DeckDetailEvent {
  final String id;
  const DeckDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class DeckDetailStarToggled extends DeckDetailEvent {
  final String id;
  const DeckDetailStarToggled(this.id);
  @override
  List<Object?> get props => [id];
}

class DeckShareUpdated extends DeckDetailEvent {
  final String id;
  final String? accessLevel;
  final bool isPublic;
  final bool generateLink;
  final bool isSilent;

  const DeckShareUpdated({
    required this.id,
    this.accessLevel,
    required this.isPublic,
    required this.generateLink,
    this.isSilent = false,
  });

  @override
  List<Object?> get props => [id, accessLevel, isPublic, generateLink, isSilent];
}

class DeckDetailCloned extends DeckDetailEvent {
  final String id;
  final String? token;
  const DeckDetailCloned(this.id, {this.token});
  @override
  List<Object?> get props => [id, token];
}
