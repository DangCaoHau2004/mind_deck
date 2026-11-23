import 'folder_model.dart';
import 'deck_model.dart';
import 'flashcard_model.dart';

class SyncDownResponseModel {
  final DateTime timestamp;
  final List<FolderModel> updatedFolders;
  final List<DeckModel> updatedDecks;
  final List<FlashcardModel> updatedFlashcards;

  SyncDownResponseModel({
    required this.timestamp,
    required this.updatedFolders,
    required this.updatedDecks,
    required this.updatedFlashcards,
  });

  factory SyncDownResponseModel.fromJson(Map<String, dynamic> json) {
    return SyncDownResponseModel(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      updatedFolders:
          (json['updatedFolders'] as List<dynamic>?)
              ?.map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['updated_folders'] as List<dynamic>?)
              ?.map((e) => FolderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedDecks:
          (json['updatedDecks'] as List<dynamic>?)
              ?.map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['updated_decks'] as List<dynamic>?)
              ?.map((e) => DeckModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedFlashcards:
          (json['updatedFlashcards'] as List<dynamic>?)
              ?.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['updated_flashcards'] as List<dynamic>?)
              ?.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'updatedFolders': updatedFolders.map((e) => e.toJson()).toList(),
      'updatedDecks': updatedDecks.map((e) => e.toJson()).toList(),
      'updatedFlashcards': updatedFlashcards.map((e) => e.toJson()).toList(),
    };
  }
}

class SyncUpResponseModel {
  final String message;
  final String jobId;

  SyncUpResponseModel({required this.message, required this.jobId});

  factory SyncUpResponseModel.fromJson(Map<String, dynamic> json) {
    return SyncUpResponseModel(
      message: json['message'] as String? ?? '',
      jobId: json['jobId'] as String? ?? json['job_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'jobId': jobId};
  }
}
