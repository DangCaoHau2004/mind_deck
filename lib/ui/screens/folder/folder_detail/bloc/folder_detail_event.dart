import 'package:equatable/equatable.dart';

abstract class FolderDetailEvent extends Equatable {
  const FolderDetailEvent();
  @override
  List<Object?> get props => [];
}

class FolderDetailLoaded extends FolderDetailEvent {
  final String id;
  final String? token;
  const FolderDetailLoaded(this.id, {this.token});
  @override
  List<Object?> get props => [id, token];
}

class FolderDetailRefreshed extends FolderDetailEvent {
  final String id;
  final String? token;
  const FolderDetailRefreshed(this.id, {this.token});
  @override
  List<Object?> get props => [id, token];
}

class FolderDeleted extends FolderDetailEvent {
  final String id;
  final bool keepDecks;
  const FolderDeleted({required this.id, required this.keepDecks});
  @override
  List<Object?> get props => [id, keepDecks];
}

class FolderShareUpdated extends FolderDetailEvent {
  final String id;
  final String accessLevel;
  final bool isSilent;

  const FolderShareUpdated({
    required this.id,
    required this.accessLevel,
    this.isSilent = false,
  });

  @override
  List<Object?> get props => [id, accessLevel, isSilent];
}

class FolderAddDecks extends FolderDetailEvent {
  final String folderId;
  final List<String> deckIds;

  const FolderAddDecks({required this.folderId, required this.deckIds});

  @override
  List<Object?> get props => [folderId, deckIds];
}

class FolderRemoveDecks extends FolderDetailEvent {
  final String folderId;
  final List<String> deckIds;

  const FolderRemoveDecks({required this.folderId, required this.deckIds});

  @override
  List<Object?> get props => [folderId, deckIds];
}

class FolderDetailSelectionToggled extends FolderDetailEvent {
  final String deckId;

  const FolderDetailSelectionToggled(this.deckId);

  @override
  List<Object?> get props => [deckId];
}

class FolderDetailSelectionCleared extends FolderDetailEvent {
  const FolderDetailSelectionCleared();
}

class FolderDetailCloned extends FolderDetailEvent {
  final String id;
  final String? token;
  const FolderDetailCloned(this.id, {this.token});
  @override
  List<Object?> get props => [id, token];
}
