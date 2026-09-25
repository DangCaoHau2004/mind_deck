import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';

class ClassMaterialResponseModel {
  final List<DeckModel> decks;
  final List<FolderModel> folders;

  ClassMaterialResponseModel({required this.decks, required this.folders});

  factory ClassMaterialResponseModel.fromJson(Map<String, dynamic> json) {
    return ClassMaterialResponseModel(
      decks:
          (json['decks'] as List?)
              ?.map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      folders:
          (json['folders'] as List?)
              ?.map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'decks': decks.map((e) => e.toJson()).toList(),
      'folders': folders.map((e) => e.toJson()).toList(),
    };
  }
}
