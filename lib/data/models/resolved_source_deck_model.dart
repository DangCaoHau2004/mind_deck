import 'package:mind_deck/data/models/flashcard_model.dart';

class ResolvedSourceDeck {
  final String deckId;
  final String deckName;
  final String? icon;
  final String? color;
  final int cardCount;
  final int dueCount;
  final List<FlashcardModel> cards;

  ResolvedSourceDeck({
    required this.deckId,
    required this.deckName,
    this.icon,
    this.color,
    this.cardCount = 0,
    this.dueCount = 0,
    required this.cards,
  });

  factory ResolvedSourceDeck.fromJson(Map<String, dynamic> json) {
    final deckId = json['deckId'] as String? ?? json['deck_id'] as String? ?? '';
    final deckName = json['deckName'] as String? ?? json['deck_name'] as String? ?? '';
    final icon = json['icon'] as String?;
    final color = json['color'] as String?;
    final cardCount = json['cardCount'] as int? ?? json['card_count'] as int? ?? 0;
    final dueCount = json['dueCount'] as int? ?? json['due_count'] as int? ?? 0;
    final cardsList = json['cards'] as List<dynamic>? ?? [];
    return ResolvedSourceDeck(
      deckId: deckId,
      deckName: deckName,
      icon: icon,
      color: color,
      cardCount: cardCount > 0 ? cardCount : cardsList.length,
      dueCount: dueCount,
      cards: cardsList.map((c) {
        final map = Map<String, dynamic>.from(c as Map);
        map['deckId'] = deckId;
        return FlashcardModel.fromJson(map);
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deckId': deckId,
      'deckName': deckName,
      'icon': icon,
      'color': color,
      'cardCount': cardCount,
      'dueCount': dueCount,
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }
}
