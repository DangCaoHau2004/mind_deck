class DiscoverySuggestedContentModel {
  final String type; // 'deck' or 'folder'
  final String id;
  final String name;
  final int savedCount;
  final int? cardCount;
  final int? deckCount;
  final String? ownerName;
  final bool? isPublic;
  final String? description;

  DiscoverySuggestedContentModel({
    required this.type,
    required this.id,
    required this.name,
    required this.savedCount,
    this.cardCount,
    this.deckCount,
    this.ownerName,
    this.isPublic,
    this.description,
  });

  factory DiscoverySuggestedContentModel.fromJson(Map<String, dynamic> json) {
    return DiscoverySuggestedContentModel(
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      savedCount:
          json['savedCount'] as int? ?? json['saved_count'] as int? ?? 0,
      cardCount: json['cardCount'] as int? ?? json['card_count'] as int?,
      deckCount: json['deckCount'] as int? ?? json['deck_count'] as int?,
      ownerName: json['ownerName'] as String? ?? json['owner_name'] as String?,
      isPublic: json['isPublic'] as bool? ?? json['is_public'] as bool?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'savedCount': savedCount,
      if (cardCount != null) 'cardCount': cardCount,
      if (deckCount != null) 'deckCount': deckCount,
      if (ownerName != null) 'ownerName': ownerName,
      if (isPublic != null) 'isPublic': isPublic,
      if (description != null) 'description': description,
    };
  }
}
