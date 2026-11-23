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
  final List<String>? tagIds;

  /// Bộ thẻ đưa luôn vào thư mục khi tạo (một lần gọi, BE hủy cả lô nếu có bộ thẻ lỗi).
  final List<String>? deckIds;

  const FolderFormCreate({
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.isPublic,
    this.tagIds,
    this.deckIds,
  });

  @override
  List<Object?> get props => [name, description, color, icon, isPublic, tagIds, deckIds];
}

class FolderFormUpdate extends FolderFormEvent {
  final String id;
  final String name;
  final String description;
  final String color;
  final String icon;

  /// null: không đổi quyền riêng tư (BE giữ nguyên).
  final bool? isPublic;
  final List<String>? tagIds;

  const FolderFormUpdate({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    this.isPublic,
    this.tagIds,
  });

  @override
  List<Object?> get props => [id, name, description, color, icon, isPublic, tagIds];
}

class FolderFormLoadTags extends FolderFormEvent {
  const FolderFormLoadTags();
}

class FolderFormAddTag extends FolderFormEvent {
  final String name;
  final String? color;

  const FolderFormAddTag({required this.name, this.color});

  @override
  List<Object?> get props => [name, color];
}
