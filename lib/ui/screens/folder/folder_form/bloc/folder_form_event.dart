import 'package:equatable/equatable.dart';

abstract class FolderFormEvent extends Equatable {
  const FolderFormEvent();

  @override
  List<Object?> get props => [];
}

class FolderFormCreate extends FolderFormEvent {
  final String name;
  final String description;
  final String color;
  final String icon;
  final bool isPublic;

  const FolderFormCreate({
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.isPublic,
  });

  @override
  List<Object?> get props => [name, description, color, icon, isPublic];
}

class FolderFormUpdate extends FolderFormEvent {
  final String id;
  final String name;
  final String description;
  final String color;
  final String icon;
  final bool isPublic;

  const FolderFormUpdate({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.isPublic,
  });

  @override
  List<Object?> get props => [id, name, description, color, icon, isPublic];
}
