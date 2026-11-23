import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'flashcard_study_event.dart';
import 'flashcard_study_state.dart';

class FlashcardStudyBloc extends Bloc<FlashcardStudyEvent, FlashcardStudyState> {
  final StudyRepository _studyRepository;
  final Map<String, Map<String, dynamic>> _aggregatedAnswers = {};
  late DateTime _currentCardStartedAt;
  Timer? _debounceTimer;
  Timer? _countdownTimer;
  bool _isSyncing = false;
  bool _hasUnsyncedChanges = false;

  FlashcardStudyBloc({required StudyRepository studyRepository})
    : _studyRepository = studyRepository,
      super(const FlashcardStudyState(status: StudyStatus.initial)) {
    on<InitStudyEvent>(_onInitStudy);
    on<StudyTimerTickedEvent>(_onTimerTicked);
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

    if ((sessionId.isEmpty && !event.readOnly) || cards.isEmpty) {
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

    final timeLimitSeconds = event.timeLimitSeconds;
    final initialRemaining = timeLimitSeconds > 0
        ? (timeLimitSeconds - event.elapsedSeconds).clamp(0, timeLimitSeconds)
        : 0;

    _startCountdownTimer(initialRemaining);

    emit(
      state.copyWith(
        status: StudyStatus.inProgress,
        sessionId: sessionId,
        isReadOnly: event.readOnly,
        cards: cards,
        currentRoundCards: currentRoundCards,
        failedCards: failedCards,
        cardStatus: restoredCardStatus,
        swipeHistory: [],
        currentIndex: 0,
        timeLimitSeconds: timeLimitSeconds,
        remainingSeconds: initialRemaining,
        showBackFirst: event.showBackFirst,
        isTimedOut: false,
      ),
    );
  }

  void _startCountdownTimer(int initialSeconds) {
    _countdownTimer?.cancel();
    if (initialSeconds <= 0) return;

    int remaining = initialSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      add(StudyTimerTickedEvent(remaining));
      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  void _onTimerTicked(StudyTimerTickedEvent event, Emitter<FlashcardStudyState> emit) {
    if (state.status != StudyStatus.inProgress) return;

    emit(state.copyWith(remainingSeconds: event.remainingSeconds));

    if (event.remainingSeconds <= 0) {
      _handleTimeOut(emit);
    }
  }

  void _handleTimeOut(Emitter<FlashcardStudyState> emit) {
    _countdownTimer?.cancel();
    _debounceTimer?.cancel();
    final now = DateTime.now();

    // Với tất cả các thẻ chưa từng được swipe/đánh giá nhớ -> Tự động tính Chưa nhớ (isRemembered: false)
    for (final card in state.cards) {
      if (!_aggregatedAnswers.containsKey(card.id)) {
        _aggregatedAnswers[card.id] = {
          'cardId': card.id,
          'isRemembered': false,
          'durationMs': 0,
          'reviewTimestamp': now.toIso8601String(),
        };
      }
    }

    emit(state.copyWith(isTimedOut: true));
    add(ForceSubmitEvent());
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
    // Học thử: không lưu Hive (nếu không, syncPendingSessions sẽ gửi deckId như sessionId)
    // và không đồng bộ lên BE.
    if (!state.isReadOnly) {
      _hasUnsyncedChanges = true;

      // 1. Lưu tức thì vào Hive Local Storage (Local-First)
      final sessionKey = state.sessionId.isNotEmpty
          ? state.sessionId
          : (state.cards.firstOrNull?.deckId ?? '');
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
    }

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

    final sessionKey = state.sessionId.isNotEmpty
        ? state.sessionId
        : (state.cards.firstOrNull?.deckId ?? '');
    if (!state.isReadOnly && sessionKey.isNotEmpty) {
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
    if (state.isReadOnly || _isSyncing || !_hasUnsyncedChanges) return;
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
    } on Failure catch (f) {
      // Lỗi tạm thời: bản nháp vẫn nằm trong Hive, lần sau đồng bộ lại.
      // Mất quyền (bị đuổi / rời lớp / phiên bị xóa): không thử nữa; lỗi sẽ hiện khi nộp.
      if (studyPermanentErrorCodes.contains(f.errorCode)) _hasUnsyncedChanges = false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _onSubmitStudy(ForceSubmitEvent event, Emitter<FlashcardStudyState> emit) async {
    _debounceTimer?.cancel();
    if (state.isReadOnly) {
      // Học thử: không có phiên để hoàn tất, không ghi FSRS.
      _countdownTimer?.cancel();
      emit(state.copyWith(status: StudyStatus.completed));
      return;
    }
    emit(state.copyWith(status: StudyStatus.submitting));

    final sessionId = state.sessionId;
    final reviewLogs = _aggregatedAnswers.values.toList();

    try {
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
    } on Failure catch (f) {
      if (studyPermanentErrorCodes.contains(f.errorCode)) {
        // Phiên không còn hợp lệ: bỏ bản lưu tạm để không đồng bộ lại mãi.
        final deckId = state.cards.firstOrNull?.deckId;
        if (deckId != null && deckId.isNotEmpty) {
          await _studyRepository.localDataSource.deleteSession(deckId);
        }
        if (sessionId.isNotEmpty) {
          await _studyRepository.localDataSource.deleteSession(sessionId);
        }
      }
      emit(state.copyWith(status: StudyStatus.error, errorMessage: _completeErrorMessage(f)));
    }
  }

  String _completeErrorMessage(Failure f) {
    switch (f.errorCode) {
      case 'DECK_NOT_FOUND':
        return 'Bạn không còn quyền học bộ thẻ này (có thể đã rời lớp), kết quả không được lưu.';
      case 'STUDY_NO_ACTIVE_SESSION':
        return 'Phiên học này không còn nữa, kết quả không được lưu.';
      case 'STUDY_NO_CARDS_FOUND':
        return 'Không còn thẻ nào bạn có thể ghi kết quả.';
    }
    return f.message.isNotEmpty
        ? f.message
        : 'Chưa lưu được kết quả. Tiến trình vẫn được giữ trên máy, hãy thử lại sau.';
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}
