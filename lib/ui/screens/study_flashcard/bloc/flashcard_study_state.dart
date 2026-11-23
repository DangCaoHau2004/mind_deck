import 'package:mind_deck/data/models/flashcard_model.dart';

enum StudyStatus { initial, loading, inProgress, submitting, completed, error }

class FlashcardStudyState {
  final StudyStatus status;
  final String sessionId;
  final List<FlashcardModel> cards;
  final List<FlashcardModel> currentRoundCards;
  final List<FlashcardModel> failedCards;
  final Map<String, bool> cardStatus;
  final List<int> swipeHistory;
  final int currentIndex;
  final bool isShuffleMode;
  final bool showBackFirst;
  final int timeLimitSeconds;
  final int remainingSeconds;
  final bool isTimedOut;
  final bool isReadOnly;
  final String? errorMessage;

  const FlashcardStudyState({
    required this.status,
    this.sessionId = "",
    this.cards = const [],
    this.currentRoundCards = const [],
    this.failedCards = const [],
    this.cardStatus = const {},
    this.swipeHistory = const [],
    this.currentIndex = 0,
    this.isShuffleMode = false,
    this.showBackFirst = false,
    this.timeLimitSeconds = 0,
    this.remainingSeconds = 0,
    this.isTimedOut = false,
    this.isReadOnly = false,
    this.errorMessage,
  });

  int get learnedCount => cardStatus.values.where((v) => v == true).length;
  int get unlearnedCount => cardStatus.values.where((v) => v == false).length;
  bool get canUndo => currentIndex > 0 && swipeHistory.isNotEmpty;

  FlashcardModel? get currentCard {
    if (currentIndex < currentRoundCards.length) {
      return currentRoundCards[currentIndex];
    }
    return null;
  }

  FlashcardStudyState copyWith({
    StudyStatus? status,
    String? sessionId,
    List<FlashcardModel>? cards,
    List<FlashcardModel>? currentRoundCards,
    List<FlashcardModel>? failedCards,
    Map<String, bool>? cardStatus,
    List<int>? swipeHistory,
    int? currentIndex,
    bool? isShuffleMode,
    bool? showBackFirst,
    int? timeLimitSeconds,
    int? remainingSeconds,
    bool? isTimedOut,
    bool? isReadOnly,
    String? errorMessage,
  }) {
    return FlashcardStudyState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      cards: cards ?? this.cards,
      currentRoundCards: currentRoundCards ?? this.currentRoundCards,
      failedCards: failedCards ?? this.failedCards,
      cardStatus: cardStatus ?? this.cardStatus,
      swipeHistory: swipeHistory ?? this.swipeHistory,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffleMode: isShuffleMode ?? this.isShuffleMode,
      showBackFirst: showBackFirst ?? this.showBackFirst,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isTimedOut: isTimedOut ?? this.isTimedOut,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
