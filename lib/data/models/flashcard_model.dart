import 'enums.dart';
import 'image_search_model.dart';
import 'user_card_progress_model.dart';

class FlashcardModel {
  final String id;
  final String deckId;
  final int sortOrder;
  final String frontText;
  final String? frontImageUrl;

  /// Ghi nguồn ảnh kho; ảnh tự tải là null.
  final ImageCredit? frontImageCredit;
  final String backText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isDue;

  final UserCardProgressModel? progress;

  FlashcardModel({
    required this.id,
    required this.deckId,
    this.sortOrder = 0,
    required this.frontText,
    this.frontImageUrl,
    this.frontImageCredit,
    required this.backText,
    required this.createdAt,
    required this.updatedAt,
    this.isDue,
    this.progress,
  });

  /// Thẻ giả để hiện skeleton khi chưa có dữ liệu.
  factory FlashcardModel.placeholder() => FlashcardModel(
    id: '',
    deckId: '',
    frontText: 'Mặt trước của thẻ ôn tập',
    backText: 'Mặt sau của thẻ, vài dòng nội dung ngắn gọn để giữ chỗ',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  bool get isDueCard {
    if (isDue != null) return isDue!;
    if (progress?.dueDate != null) {
      return !progress!.dueDate!.isAfter(DateTime.now());
    }
    if (progress != null) {
      return progress!.state == CardState.learning || progress!.state == CardState.relearning;
    }
    return false;
  }

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String? ?? '',
      deckId: json['deckId'] as String? ?? json['deck_id'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
      frontText: json['frontText'] as String? ?? json['front_text'] as String? ?? '',
      frontImageUrl: json['frontImageUrl'] as String? ?? json['front_image_url'] as String?,
      frontImageCredit: ImageCredit.tryParse(
        json['frontImageCredit'] ?? json['front_image_credit'],
      ),
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
      isDue: json['isDue'] as bool? ?? json['is_due'] as bool?,

      // Relation / Flat fields
      progress: json['progress'] != null
          ? UserCardProgressModel.fromJson(json['progress'] as Map<String, dynamic>)
          : (json['dueDate'] != null || json['due_date'] != null || json['state'] != null)
          ? UserCardProgressModel(
              id: '',
              userId: '',
              cardId: json['id'] as String? ?? '',
              state: CardState.fromString(json['state'] as String?),
              dueDate: json['dueDate'] != null
                  ? DateTime.tryParse(json['dueDate'].toString())
                  : (json['due_date'] != null
                        ? DateTime.tryParse(json['due_date'].toString())
                        : null),
            )
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
      'frontImageCredit': ?frontImageCredit?.toJson(),
      'backText': backText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (isDue != null) 'isDue': isDue,
      'progress': progress?.toJson(),
    };
  }

  FlashcardModel copyWith({
    String? id,
    String? deckId,
    int? sortOrder,
    String? frontText,
    String? frontImageUrl,
    ImageCredit? frontImageCredit,
    bool clearFrontImage = false,
    String? backText,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDue,
    UserCardProgressModel? progress,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      sortOrder: sortOrder ?? this.sortOrder,
      frontText: frontText ?? this.frontText,
      frontImageUrl: frontImageUrl ?? (clearFrontImage ? null : this.frontImageUrl),
      frontImageCredit: frontImageCredit ?? (clearFrontImage ? null : this.frontImageCredit),
      backText: backText ?? this.backText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDue: isDue ?? this.isDue,
      progress: progress ?? this.progress,
    );
  }
}
