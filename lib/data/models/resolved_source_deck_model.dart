import 'package:mind_deck/data/models/flashcard_model.dart';

class ResolvedSourceDeck {
  final String deckId;
  final String deckName;
  final List<FlashcardModel> cards;

  ResolvedSourceDeck({
    required this.deckId,
    required this.deckName,
    required this.cards,
  });

  factory ResolvedSourceDeck.fromJson(Map<String, dynamic> json) {
    final deckId =
        json['deckId'] as String? ?? json['deck_id'] as String? ?? '';
    final deckName =
        json['deckName'] as String? ?? json['deck_name'] as String? ?? '';
    final cardsList = json['cards'] as List<dynamic>? ?? [];
    return ResolvedSourceDeck(
      deckId: deckId,
      deckName: deckName,
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
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }
}
