import 'user_card_progress_model.dart';

class FlashcardModel {
  final String id;
  final String deckId;
  final int sortOrder;
  final String frontText;
  final String? frontImageUrl;
  final String backText;
  final DateTime createdAt;
  final DateTime updatedAt;

  final UserCardProgressModel? progress;

  FlashcardModel({
    required this.id,
    required this.deckId,
    this.sortOrder = 0,
    required this.frontText,
    this.frontImageUrl,
    required this.backText,
    required this.createdAt,
    required this.updatedAt,
    this.progress,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String? ?? '',
      deckId: json['deckId'] as String? ?? json['deck_id'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
      frontText: json['frontText'] as String? ?? json['front_text'] as String? ?? '',
      frontImageUrl: json['frontImageUrl'] as String? ?? json['front_image_url'] as String?,
      backText: json['backText'] as String? ?? json['back_text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '',
          ) ??
          DateTime.now(),

      // Relation
      progress: json['progress'] != null
          ? UserCardProgressModel.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'sortOrder': sortOrder,
      'frontText': frontText,
      'frontImageUrl': frontImageUrl,
      'backText': backText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'progress': progress?.toJson(),
    };
  }

  FlashcardModel copyWith({
    String? id,
    String? deckId,
    int? sortOrder,
    String? frontText,
    String? frontImageUrl,
    String? backText,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserCardProgressModel? progress,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      sortOrder: sortOrder ?? this.sortOrder,
      frontText: frontText ?? this.frontText,
      frontImageUrl: frontImageUrl ?? this.frontImageUrl,
      backText: backText ?? this.backText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
    );
  }
}
