import 'package:equatable/equatable.dart';

abstract class ClassMaterialsEvent extends Equatable {
  const ClassMaterialsEvent();

  @override
  List<Object?> get props => [];
}

class ClassMaterialsLoaded extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsLoaded(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassMaterialsLoadMore extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsLoadMore(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassMaterialsSearchChanged extends ClassMaterialsEvent {
  final String classId;
  final String query;

  const ClassMaterialsSearchChanged(this.classId, this.query);

  @override
  List<Object?> get props => [classId, query];
}

class ClassMaterialsRefreshed extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsRefreshed(this.classId);

  @override
  List<Object?> get props => [classId];
}

class ClassMaterialAdded extends ClassMaterialsEvent {
  final String classId;
  final List<String> folderIds;
  final List<String> deckIds;

  const ClassMaterialAdded({
    required this.classId,
    required this.folderIds,
    required this.deckIds,
  });

  @override
  List<Object?> get props => [classId, folderIds, deckIds];
}

class ClassMaterialCloned extends ClassMaterialsEvent {
  final String classId;
  final String folderId;
  final String deckId;

  const ClassMaterialCloned({
    required this.classId,
    required this.folderId,
    required this.deckId,
  });

  @override
  List<Object?> get props => [classId, folderId, deckId];
}

class ClassMaterialsSelectionModeToggled extends ClassMaterialsEvent {
  final bool? isSelectionMode;
  const ClassMaterialsSelectionModeToggled([this.isSelectionMode]);
  @override
  List<Object?> get props => [isSelectionMode];
}

class ClassMaterialDeckSelectionToggled extends ClassMaterialsEvent {
  final String deckId;
  const ClassMaterialDeckSelectionToggled(this.deckId);
  @override
  List<Object?> get props => [deckId];
}

class ClassMaterialFolderSelectionToggled extends ClassMaterialsEvent {
  final String folderId;
  const ClassMaterialFolderSelectionToggled(this.folderId);
  @override
  List<Object?> get props => [folderId];
}

class ClassMaterialsSelectionCleared extends ClassMaterialsEvent {}

class ClassMaterialsDeleted extends ClassMaterialsEvent {
  final String classId;

  const ClassMaterialsDeleted(this.classId);

  @override
  List<Object?> get props => [classId];
}
