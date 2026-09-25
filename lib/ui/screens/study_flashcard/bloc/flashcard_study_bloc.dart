import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'flashcard_study_event.dart';
import 'flashcard_study_state.dart';

class FlashcardStudyBloc extends Bloc<FlashcardStudyEvent, FlashcardStudyState> {
  final StudyRepository _studyRepository;
  final Map<String, Map<String, dynamic>> _aggregatedAnswers = {};
  late DateTime _currentCardStartedAt;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  bool _hasUnsyncedChanges = false;

  FlashcardStudyBloc({required StudyRepository studyRepository})
    : _studyRepository = studyRepository,
      super(const FlashcardStudyState(status: StudyStatus.initial)) {
    on<InitStudyEvent>(_onInitStudy);
    on<SwipeCardEvent>(_onSwipeCard);
    on<UndoSwipeEvent>(_onUndoSwipe);
    on<ToggleShuffleEvent>(_onToggleShuffle);
    on<ToggleShowBackFirstEvent>(_onToggleShowBackFirst);
    on<ResetCardsEvent>(_onResetCards);
    on<SyncProgressEvent>(_onSyncProgress);
    on<ForceSubmitEvent>(_onSubmitStudy);
  }

  void _onInitStudy(InitStudyEvent event, Emitter<FlashcardStudyState> emit) {
    final sessionId = event.sessionId;
    final cards = event.cards;
    final reviewLogs = event.reviewLogs;

    if (sessionId.isEmpty || cards.isEmpty) {
      emit(
        state.copyWith(
          status: StudyStatus.error,
          errorMessage: 'Có lỗi xảy ra vui lòng thử lại sau',
        ),
      );
      return;
    }

    _aggregatedAnswers.clear();
    _currentCardStartedAt = DateTime.now();

    final restoredCardStatus = <String, bool>{};
    for (final log in reviewLogs) {
      final cardId = log['cardId'] as String?;
      if (cardId != null) {
        _aggregatedAnswers[cardId] = Map<String, dynamic>.from(log);
        if (log.containsKey('isRemembered')) {
          restoredCardStatus[cardId] = log['isRemembered'] as bool;
        }
      }
    }

    List<FlashcardModel> currentRoundCards;
    List<FlashcardModel> failedCards = [];

    // Trường hợp Resume (đã có reviewLogs trước đó)
    if (reviewLogs.isNotEmpty) {
      final reviewedCardIds = restoredCardStatus.keys.toSet();
      final unreviewedCards = cards.where((c) => !reviewedCardIds.contains(c.id)).toList();

      if (unreviewedCards.isNotEmpty) {
        // Còn thẻ chưa học ở vòng này
        currentRoundCards = unreviewedCards;
        // Các thẻ đã học nhưng bị sai gom vào failedCards để học vòng tiếp theo
        final failedIds = restoredCardStatus.entries
            .where((e) => e.value == false)
            .map((e) => e.key)
            .toSet();
        failedCards = cards.where((c) => failedIds.contains(c.id)).toList();
      } else {
        // Đã học hết 1 lượt, gom các thẻ nhớ sai để học lại (vòng 2)
        final failedIds = restoredCardStatus.entries
            .where((e) => e.value == false)
            .map((e) => e.key)
            .toSet();
        final failedToRetry = cards.where((c) => failedIds.contains(c.id)).toList();

        if (failedToRetry.isNotEmpty) {
          currentRoundCards = failedToRetry;
        } else {
          currentRoundCards = List.from(cards);
        }
      }
    } else {
      // Trường hợp Start mới hoàn toàn
      currentRoundCards = List.from(cards);
    }

    emit(
      state.copyWith(
        status: StudyStatus.inProgress,
        sessionId: sessionId,
        cards: cards,
        currentRoundCards: currentRoundCards,
        failedCards: failedCards,
        cardStatus: restoredCardStatus,
        swipeHistory: [],
        currentIndex: 0,
      ),
    );
  }

  void _onSwipeCard(SwipeCardEvent event, Emitter<FlashcardStudyState> emit) {
    if (state.currentCard == null) return;

    final card = state.currentCard!;
    final now = DateTime.now();
    final durationMs = now.difference(_currentCardStartedAt).inMilliseconds;
    final isCorrect = event.direction == 1;

    // Ghi nhận dữ liệu nộp bài theo định dạng ReviewLog
    final currentDuration = _aggregatedAnswers[card.id]?['durationMs'] as int? ?? 0;
    final newDuration = currentDuration + durationMs;
    final previousResult = _aggregatedAnswers[card.id]?['isRemembered'] as bool?;
    final finalIsRemembered = previousResult == null ? isCorrect : (previousResult && isCorrect);

    _aggregatedAnswers[card.id] = {
      'cardId': card.id,
      'isRemembered': finalIsRemembered,
      'durationMs': newDuration,
      'reviewTimestamp': now.toIso8601String(),
    };
    _hasUnsyncedChanges = true;

    // 1. Lưu tức thì vào Hive Local Storage (Local-First)
    final sessionKey = state.sessionId.isNotEmpty ? state.sessionId : (state.cards.firstOrNull?.deckId ?? '');
    if (sessionKey.isNotEmpty) {
      _studyRepository.localDataSource.saveSession(sessionKey, {
        'sessionId': state.sessionId,
        'deckId': state.cards.firstOrNull?.deckId ?? '',
        'reviewLogs': _aggregatedAnswers,
        'updatedAt': now.toIso8601String(),
      });
    }

    // 2. Quản lý Debounce Timer 5 giây để đồng bộ lên Backend
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      add(SyncProgressEvent());
    });

    final updatedCardStatus = Map<String, bool>.from(state.cardStatus)..[card.id] = isCorrect;
    final updatedHistory = List<int>.from(state.swipeHistory)..add(event.direction);
    final updatedFailed = List<FlashcardModel>.from(state.failedCards);
    if (!isCorrect) {
      updatedFailed.add(card);
    }

    if (state.currentIndex < state.currentRoundCards.length - 1) {
      _currentCardStartedAt = DateTime.now();
      emit(
        state.copyWith(
          currentIndex: state.currentIndex + 1,
          cardStatus: updatedCardStatus,
          swipeHistory: updatedHistory,
          failedCards: updatedFailed,
        ),
      );
    } else {
      // Hết vòng hiện tại
      if (updatedFailed.isNotEmpty) {
        List<FlashcardModel> nextRound = List.from(updatedFailed);
        if (state.isShuffleMode) nextRound.shuffle();

        _currentCardStartedAt = DateTime.now();
        emit(
          state.copyWith(
            currentRoundCards: nextRound,
            failedCards: [],
            swipeHistory: [],
            currentIndex: 0,
            cardStatus: updatedCardStatus,
          ),
        );
      } else {
        emit(state.copyWith(cardStatus: updatedCardStatus));
        add(ForceSubmitEvent());
      }
    }
  }

  void _onUndoSwipe(UndoSwipeEvent event, Emitter<FlashcardStudyState> emit) {
    if (!state.canUndo) return;

    final previousIndex = state.currentIndex - 1;
    final lastAction = state.swipeHistory.last;
    final card = state.currentRoundCards[previousIndex];

    final updatedHistory = List<int>.from(state.swipeHistory)..removeLast();
    final updatedCardStatus = Map<String, bool>.from(state.cardStatus)..remove(card.id);
    final updatedFailed = List<FlashcardModel>.from(state.failedCards);

    if (lastAction == -1 && updatedFailed.isNotEmpty) {
      updatedFailed.removeLast();
    }

    _currentCardStartedAt = DateTime.now();
    emit(
      state.copyWith(
        currentIndex: previousIndex,
        swipeHistory: updatedHistory,
        cardStatus: updatedCardStatus,
        failedCards: updatedFailed,
      ),
    );
  }

  void _onToggleShuffle(ToggleShuffleEvent event, Emitter<FlashcardStudyState> emit) {
    if (state.currentRoundCards.isEmpty || state.currentIndex >= state.currentRoundCards.length) {
      emit(state.copyWith(isShuffleMode: event.isShuffle));
      return;
    }

    final learnedCards = state.currentRoundCards.sublist(0, state.currentIndex);
    final remainingCards = List<FlashcardModel>.from(
      state.currentRoundCards.sublist(state.currentIndex),
    );

    if (event.isShuffle) {
      remainingCards.shuffle();
    } else {
      remainingCards.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final updatedCards = [...learnedCards, ...remainingCards];

    emit(state.copyWith(isShuffleMode: event.isShuffle, currentRoundCards: updatedCards));
  }

  void _onToggleShowBackFirst(ToggleShowBackFirstEvent event, Emitter<FlashcardStudyState> emit) {
    emit(state.copyWith(showBackFirst: event.showBackFirst));
  }

  void _onResetCards(ResetCardsEvent event, Emitter<FlashcardStudyState> emit) {
    _debounceTimer?.cancel();
    _aggregatedAnswers.clear();
    _hasUnsyncedChanges = false;
    final resetCards = List<FlashcardModel>.from(state.cards)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final sessionKey = state.sessionId.isNotEmpty ? state.sessionId : (state.cards.firstOrNull?.deckId ?? '');
    if (sessionKey.isNotEmpty) {
      _studyRepository.localDataSource.deleteSession(sessionKey);
    }

    _currentCardStartedAt = DateTime.now();
    emit(
      state.copyWith(
        currentRoundCards: resetCards,
        failedCards: [],
        cardStatus: {},
        swipeHistory: [],
        currentIndex: 0,
        isShuffleMode: false,
      ),
    );
  }

  Future<void> _onSyncProgress(SyncProgressEvent event, Emitter<FlashcardStudyState> emit) async {
    if (_isSyncing || !_hasUnsyncedChanges) return;
    _debounceTimer?.cancel();

    final sessionId = state.sessionId;
    if (sessionId.isEmpty) return;

    final reviewLogs = _aggregatedAnswers.values.toList();
    if (reviewLogs.isEmpty) return;

    _isSyncing = true;
    try {
      final response = await _studyRepository.saveProgress(sessionId, reviewLogs);
      if (response.success) {
        _hasUnsyncedChanges = false;
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _onSubmitStudy(ForceSubmitEvent event, Emitter<FlashcardStudyState> emit) async {
    _debounceTimer?.cancel();
    emit(state.copyWith(status: StudyStatus.submitting));

    final sessionId = state.sessionId;
    final reviewLogs = _aggregatedAnswers.values.toList();

    final response = await _studyRepository.completeSession(sessionId, reviewLogs);

    if (response.success) {
      emit(state.copyWith(status: StudyStatus.completed));
    } else {
      emit(
        state.copyWith(
          status: StudyStatus.error,
          errorMessage: response.message ?? 'Lỗi khi nộp bài học tập.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
