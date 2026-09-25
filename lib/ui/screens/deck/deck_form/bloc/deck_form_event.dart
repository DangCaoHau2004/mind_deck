import 'package:equatable/equatable.dart';

abstract class DeckFormEvent extends Equatable {
  const DeckFormEvent();
  @override
  List<Object?> get props => [];
}

class DeckFormCreate extends DeckFormEvent {
  final Map<String, dynamic> data;
  const DeckFormCreate(this.data);
  @override
  List<Object?> get props => [data];
}

class DeckFormUpdate extends DeckFormEvent {
  final String id;
  final Map<String, dynamic> data;
  const DeckFormUpdate(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeckFormLoadTags extends DeckFormEvent {
  const DeckFormLoadTags();
}

class DeckFormAddTag extends DeckFormEvent {
  final String name;
  final String? color;
  const DeckFormAddTag({required this.name, this.color});
  @override
  List<Object?> get props => [name, color];
}
