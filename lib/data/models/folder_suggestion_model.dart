import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

class FolderSuggestionModel extends Equatable {
  final List<FolderModel> folders;
  final List<TagModel> tags;

  const FolderSuggestionModel({
    this.folders = const [],
    this.tags = const [],
  });

  factory FolderSuggestionModel.fromJson(Map<String, dynamic> json) {
    return FolderSuggestionModel(
      folders: (json['folders'] as List<dynamic>?)
              ?.map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folders': folders.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
    };
  }

  FolderSuggestionModel copyWith({
    List<FolderModel>? folders,
    List<TagModel>? tags,
  }) {
    return FolderSuggestionModel(
      folders: folders ?? this.folders,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [folders, tags];
}
