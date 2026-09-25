import 'package:mind_deck/data/models/flashcard_model.dart';

abstract class FlashcardStudyEvent {}

class InitStudyEvent extends FlashcardStudyEvent {
  final String sessionId;
  final List<FlashcardModel> cards;
  final List<Map<String, dynamic>> reviewLogs;

  InitStudyEvent({required this.sessionId, required this.cards, required this.reviewLogs});
}

class SwipeCardEvent extends FlashcardStudyEvent {
  final int direction; // 1: Thuộc (phải), -1: Chưa thuộc (trái)
  SwipeCardEvent(this.direction);
}

class UndoSwipeEvent extends FlashcardStudyEvent {}

class ToggleShuffleEvent extends FlashcardStudyEvent {
  final bool isShuffle;
  ToggleShuffleEvent(this.isShuffle);
}

class ToggleShowBackFirstEvent extends FlashcardStudyEvent {
  final bool showBackFirst;
  ToggleShowBackFirstEvent(this.showBackFirst);
}

class ResetCardsEvent extends FlashcardStudyEvent {}

class ForceSubmitEvent extends FlashcardStudyEvent {}

class SyncProgressEvent extends FlashcardStudyEvent {
  final bool immediate;
  SyncProgressEvent({this.immediate = false});
}
