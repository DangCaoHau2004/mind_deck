import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'test_setup_event.dart';
import 'test_setup_state.dart';

class TestSetupBloc extends Bloc<TestSetupEvent, TestSetupState> {
  final TestRepository testRepository;
  final DeckRepository deckRepository;
  final FolderRepository folderRepository;

  Timer? _timer;

  TestSetupBloc({
    required this.testRepository,
    required this.deckRepository,
    required this.folderRepository,
  }) : super(const TestSetupConfigState()) {
    on<TestSetupInitialized>(_onInitialized);
    on<TestSetupSourcesChanged>(_onSourcesChanged);
    on<TestSetupSourceRemoved>(_onSourceRemoved);
    on<TestSetupCardToggled>(_onCardToggled);
    on<TestSetupAllCardsToggled>(_onAllCardsToggled);
    on<TestSetupSettingsChanged>(_onSettingsChanged);
    on<TestSetupQuestionTypesChanged>(_onQuestionTypesChanged);
    on<TestSetupGenerateRequested>(_onGenerateRequested);
    on<TestSetupTimerTicked>(_onTimerTicked);
    on<TestSetupAnswerSubmitted>(_onAnswerSubmitted);
    on<TestSetupNextQuestionRequested>(_onNextQuestionRequested);
    on<TestSetupSubmitRequested>(_onSubmitRequested);
    on<TestSetupReset>(_onReset);
    on<TestSetupCompletedExternally>(_onCompletedExternally);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _startTimer(int initialSeconds) {
    _timer?.cancel();
    int remaining = initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      add(TestSetupTimerTicked(remaining));
      if (remaining <= 0) {
        timer.cancel();
        add(const TestSetupSubmitRequested());
      }
    });
  }

  Future<void> _onInitialized(TestSetupInitialized event, Emitter<TestSetupState> emit) async {
    emit(const TestSetupConfigState(isGenerating: false));
    try {
      List<DeckModel> initialSelectedDecks = [];
      List<FolderModel> initialSelectedFolders = [];
      List<TagModel> initialSelectedTags = [];

      if (event.initData != null) {
        if (event.initData is DeckModel) {
          initialSelectedDecks.add(event.initData as DeckModel);
        } else if (event.initData is FolderModel) {
          initialSelectedFolders.add(event.initData as FolderModel);
        } else if (event.initData is TagModel) {
          initialSelectedTags.add(event.initData as TagModel);
        }
      }

      emit(
        TestSetupConfigState(
          selectedDecks: initialSelectedDecks,
          selectedFolders: initialSelectedFolders,
          selectedTags: initialSelectedTags,
        ),
      );

      await _resolveCurrentSelection(emit);
    } catch (e) {
      emit(TestSetupConfigState(errorMessage: 'Lỗi khởi tạo nguồn ôn tập: ${e.toString()}'));
    }
  }

  Future<void> _onSourcesChanged(
    TestSetupSourcesChanged event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    emit(
      configState.copyWith(
        selectedDecks: event.decks,
        selectedFolders: event.folders,
        selectedTags: event.tags,
      ),
    );

    await _resolveCurrentSelection(emit);
  }

  Future<void> _onSourceRemoved(TestSetupSourceRemoved event, Emitter<TestSetupState> emit) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;
    List<DeckModel> updatedDecks = List.from(configState.selectedDecks);
    List<FolderModel> updatedFolders = List.from(configState.selectedFolders);
    List<TagModel> updatedTags = List.from(configState.selectedTags);
    switch (event.type) {
      case TestSourceType.deck:
        updatedDecks.removeWhere((d) => d.id == event.id);
        break;
      case TestSourceType.folder:
        updatedFolders.removeWhere((f) => f.id == event.id);
        break;
      case TestSourceType.tag:
        updatedTags.removeWhere((t) => t.id == event.id);
        break;
    }
    emit(
      configState.copyWith(
        selectedDecks: updatedDecks,
        selectedFolders: updatedFolders,
        selectedTags: updatedTags,
      ),
    );
    await _resolveCurrentSelection(emit);
  }

  Future<void> _onCardToggled(TestSetupCardToggled event, Emitter<TestSetupState> emit) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    final updatedCardIds = Set<String>.from(configState.selectedCardIds);
    if (updatedCardIds.contains(event.cardId)) {
      updatedCardIds.remove(event.cardId);
    } else {
      updatedCardIds.add(event.cardId);
    }
    emit(configState.copyWith(selectedCardIds: updatedCardIds));
  }

  Future<void> _onAllCardsToggled(
    TestSetupAllCardsToggled event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    final updatedCardIds = <String>{};
    if (event.value) {
      for (final deck in configState.resolvedSourceDecks) {
        for (final card in deck.cards) {
          updatedCardIds.add(card.id);
        }
      }
    }
    emit(configState.copyWith(selectedCardIds: updatedCardIds));
  }

  Future<void> _onSettingsChanged(
    TestSetupSettingsChanged event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    emit(
      configState.copyWith(
        timeLimitEnabled: event.timeLimitEnabled ?? configState.timeLimitEnabled,
        timeLimitMinutes: event.timeLimitMinutes ?? configState.timeLimitMinutes,
        questionSide: event.questionSide ?? configState.questionSide,
        showAnswerInstantly: event.showAnswerInstantly ?? configState.showAnswerInstantly,
      ),
    );
  }

  Future<void> _onQuestionTypesChanged(
    TestSetupQuestionTypesChanged event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    final incoming = event.questionTypes;
    final previous = configState.selectedQuestionTypes;

    Set<TestQuestionType> result = {};
    if (incoming.contains(TestQuestionType.flashcard) &&
        !previous.contains(TestQuestionType.flashcard)) {
      result = {TestQuestionType.flashcard};
    } else if (incoming.contains(TestQuestionType.flashcard) && incoming.length > 1) {
      result = Set.from(incoming)..remove(TestQuestionType.flashcard);
    } else {
      result = incoming;
    }

    emit(configState.copyWith(selectedQuestionTypes: result));
  }

  Future<void> _onGenerateRequested(
    TestSetupGenerateRequested event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    if (configState.selectedCardIds.isEmpty) {
      emit(configState.copyWith(errorMessage: 'Vui lòng chọn ít nhất một thẻ câu hỏi để làm bài.'));
      return;
    }
    if (configState.selectedQuestionTypes.isEmpty) {
      emit(configState.copyWith(errorMessage: 'Vui lòng chọn ít nhất một loại câu hỏi.'));
      return;
    }

    emit(configState.copyWith(isGenerating: true, errorMessage: null));
    try {
      final Map<String, dynamic> settings = {
        'timeLimitEnabled': configState.timeLimitEnabled,
        'timeLimitMinutes': configState.timeLimitMinutes,
        'questionSide': configState.questionSide,
        'showAnswerInstantly': configState.showAnswerInstantly,
      };

      String testName = event.name ?? '';
      if (testName.isEmpty) {
        final now = DateTime.now();
        final formattedDate = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';

        final sourceCount =
            configState.selectedDecks.length +
            configState.selectedFolders.length +
            configState.selectedTags.length;
        if (sourceCount == 1) {
          final String name = configState.selectedDecks.isNotEmpty
              ? configState.selectedDecks.first.name
              : configState.selectedFolders.isNotEmpty
              ? configState.selectedFolders.first.name
              : configState.selectedTags.first.name;
          testName = 'Bài ôn tập: $name ($formattedDate)';
        } else if (sourceCount > 1) {
          testName = 'Bài ôn tập tổng hợp ($sourceCount nguồn) ($formattedDate)';
        } else {
          testName = 'Bài ôn tập ($formattedDate)';
        }
      }

      final response = await testRepository.generateTest(
        cardIds: configState.selectedCardIds.toList(),
        name: testName,
        questionTypes: configState.selectedQuestionTypes.map((t) => t.value).toList(),
        settings: settings,
      );

      if (response.success && response.data != null) {
        final testModel = response.data!;
        final questions = testModel.questions;

        if (questions.isEmpty) {
          emit(
            configState.copyWith(
              isGenerating: false,
              errorMessage: 'Không tìm thấy câu hỏi tương thích với lựa chọn của bạn.',
            ),
          );
          return;
        }

        _timer?.cancel();
        final timeLimitSeconds = configState.timeLimitEnabled
            ? configState.timeLimitMinutes * 60
            : 0;

        final inProgressState = TestSetupInProgressState(
          testModel: testModel,
          questions: questions,
          currentQuestionIndex: 0,
          timeRemainingSeconds: timeLimitSeconds,
          startedAt: DateTime.now(),
          currentQuestionStartedAt: DateTime.now(),
        );

        _lastConfigState = configState.copyWith(isGenerating: false, errorMessage: null);
        emit(inProgressState);

        if (configState.timeLimitEnabled) {
          _startTimer(timeLimitSeconds);
        }
      } else {
        emit(
          configState.copyWith(
            isGenerating: false,
            errorMessage: response.message ?? 'Không thể tạo bài kiểm tra.',
          ),
        );
      }
    } catch (e) {
      emit(
        configState.copyWith(
          isGenerating: false,
          errorMessage: 'Lỗi tạo bài kiểm tra: ${e.toString()}',
        ),
      );
    }
  }

  void _onTimerTicked(TestSetupTimerTicked event, Emitter<TestSetupState> emit) {
    if (state is! TestSetupInProgressState) return;
    final inProgressState = state as TestSetupInProgressState;
    emit(inProgressState.copyWith(timeRemainingSeconds: event.remainingSeconds));
  }

  Future<void> _onAnswerSubmitted(
    TestSetupAnswerSubmitted event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupInProgressState) return;
    final inProgressState = state as TestSetupInProgressState;
    final index = inProgressState.currentQuestionIndex;
    final question = inProgressState.questions[index];
    final userAns = event.answer;
    final bool isCorrect = question.checkAnswer(userAns);

    final updatedAnswersMap = Map<int, dynamic>.from(inProgressState.answersMap)..[index] = userAns;
    final updatedIsCheckedMap = Map<int, bool>.from(inProgressState.isAnswerCheckedMap)
      ..[index] = true;
    final updatedCorrectnessMap = Map<int, bool>.from(inProgressState.answersCorrectnessMap)
      ..[index] = isCorrect;

    int newCorrectCount = inProgressState.correctCount;
    if (isCorrect) {
      newCorrectCount++;
    }

    List<TestQuestionModel> updatedQuestions = List.from(inProgressState.questions);
    // nếu là flashcard thì nó tự động ném xuống cuối
    if (question.questionType == TestQuestionType.flashcard && !isCorrect) {
      updatedQuestions.add(question);
    }

    emit(
      inProgressState.copyWith(
        questions: updatedQuestions,
        answersMap: updatedAnswersMap,
        isAnswerCheckedMap: updatedIsCheckedMap,
        answersCorrectnessMap: updatedCorrectnessMap,
        correctCount: newCorrectCount,
      ),
    );
  }

  Future<void> _onNextQuestionRequested(
    TestSetupNextQuestionRequested event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupInProgressState) return;
    final inProgressState = state as TestSetupInProgressState;
    final nextIndex = inProgressState.currentQuestionIndex + 1;
    final now = DateTime.now();
    final durationMs = now.difference(inProgressState.currentQuestionStartedAt).inMilliseconds;

    final newDurationMap = Map<int, int>.from(inProgressState.questionDurationMap);
    newDurationMap[inProgressState.currentQuestionIndex] =
        (newDurationMap[inProgressState.currentQuestionIndex] ?? 0) + durationMs;

    if (nextIndex >= inProgressState.questions.length) {
      emit(
        inProgressState.copyWith(
          questionDurationMap: newDurationMap,
          currentQuestionStartedAt: now,
        ),
      );
      add(const TestSetupSubmitRequested());
    } else {
      emit(
        inProgressState.copyWith(
          currentQuestionIndex: nextIndex,
          questionDurationMap: newDurationMap,
          currentQuestionStartedAt: now,
        ),
      );
    }
  }

  Future<void> _onSubmitRequested(
    TestSetupSubmitRequested event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupInProgressState) return;
    final inProgressState = state as TestSetupInProgressState;

    _timer?.cancel();

    emit(inProgressState.copyWith(isSubmitting: true));

    final completedAt = DateTime.now();
    final totalDurationMs = completedAt.difference(inProgressState.startedAt).inMilliseconds;

    // Calculate duration for the last question being viewed if they submit directly
    final lastQDurationMs = completedAt
        .difference(inProgressState.currentQuestionStartedAt)
        .inMilliseconds;
    final finalDurationMap = Map<int, int>.from(inProgressState.questionDurationMap);
    finalDurationMap[inProgressState.currentQuestionIndex] =
        (finalDurationMap[inProgressState.currentQuestionIndex] ?? 0) + lastQDurationMs;

    final Map<String, Map<String, dynamic>> aggregatedAnswers = {};
    for (int i = 0; i < inProgressState.questions.length; i++) {
      final q = inProgressState.questions[i];
      final ans = inProgressState.answersMap[i];
      final isCorrect = inProgressState.answersCorrectnessMap[i] ?? false;
      final duration = finalDurationMap[i] ?? 0;

      if (q.questionType == TestQuestionType.matching) {
        final matches = (ans as Map<String, String>?) ?? {};
        final leftColumn = q.leftColumn;
        final numCards = leftColumn.isNotEmpty
            ? leftColumn.length
            : (matches.isNotEmpty ? matches.length : 1);
        final perCardDuration = duration ~/ numCards;

        for (final item in leftColumn) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            final matchedWith = matches[id];
            final matchedCorrect = matchedWith == id;

            if (aggregatedAnswers.containsKey(id)) {
              final existing = aggregatedAnswers[id]!;
              final newDuration = (existing['durationMs'] as int) + perCardDuration;
              aggregatedAnswers[id] = {
                'cardId': id,
                'questionType': TestQuestionType.matching.value,
                'isCorrect': matchedCorrect,
                'durationMs': newDuration,
                'answerDetails': {},
              };
            } else {
              aggregatedAnswers[id] = {
                'cardId': id,
                'questionType': TestQuestionType.matching.value,
                'isCorrect': matchedCorrect,
                'durationMs': perCardDuration,
                'answerDetails': {},
              };
            }
          }
        }
        continue; // Skip the rest for matching
      }

      dynamic answerDetails;
      if (q.questionType == TestQuestionType.flashcard) {
        answerDetails = {
          'isRemembered': isCorrect,
          'thinkTimeMs': 0, // Sẽ tính tổng bên dưới
        };
      } else {
        answerDetails = {'userAnswer': ans != null ? ans.toString() : ''};
      }

      final mapKey = q.cardId ?? 'unknown_$i';

      if (aggregatedAnswers.containsKey(mapKey)) {
        final existing = aggregatedAnswers[mapKey]!;
        final newDuration = (existing['durationMs'] as int) + duration;

        if (q.questionType == TestQuestionType.flashcard) {
          answerDetails['thinkTimeMs'] = newDuration;
        }

        aggregatedAnswers[mapKey] = {
          'cardId': q.cardId,
          'questionType': q.questionType.value,
          'isCorrect': isCorrect, // Lấy trạng thái đúng sai mới nhất
          'durationMs': newDuration, // Cộng dồn thời gian
          'answerDetails': answerDetails,
        };
      } else {
        if (q.questionType == TestQuestionType.flashcard) {
          answerDetails['thinkTimeMs'] = duration;
        }
        aggregatedAnswers[mapKey] = {
          'cardId': q.cardId,
          'questionType': q.questionType.value,
          'isCorrect': isCorrect,
          'durationMs': duration,
          'answerDetails': answerDetails,
        };
      }
    }

    final List<Map<String, dynamic>> answers = aggregatedAnswers.values.toList();

    try {
      final response = await testRepository.submitTest(
        testId: inProgressState.testModel.id,
        totalQuestions: inProgressState.questions.length,
        correctAnswers: inProgressState.correctCount,
        durationMs: totalDurationMs,
        startedAt: inProgressState.startedAt.toIso8601String(),
        completedAt: completedAt.toIso8601String(),
        answers: answers,
      );

      final attemptId = response.data?.attemptId ?? '';

      emit(
        TestSetupCompletedState(
          testModel: inProgressState.testModel,
          correctCount: inProgressState.correctCount,
          totalQuestions: inProgressState.questions.length,
          timeSpentSeconds: totalDurationMs ~/ 1000,
          answersMap: inProgressState.answersMap,
          answersCorrectnessMap: inProgressState.answersCorrectnessMap,
          questions: inProgressState.questions,
          attemptId: attemptId,
          errorMessage: response.success
              ? null
              : 'Kết nối mạng không ổn định, kết quả thi được lưu tạm thời.',
        ),
      );
    } catch (e) {
      emit(
        TestSetupCompletedState(
          testModel: inProgressState.testModel,
          correctCount: inProgressState.correctCount,
          totalQuestions: inProgressState.questions.length,
          timeSpentSeconds: totalDurationMs ~/ 1000,
          answersMap: inProgressState.answersMap,
          answersCorrectnessMap: inProgressState.answersCorrectnessMap,
          questions: inProgressState.questions,
          attemptId: '',
          errorMessage: 'Lỗi nộp bài: ${e.toString()}. Kết quả được hiển thị cục bộ.',
        ),
      );
    }
  }

  TestSetupConfigState? _lastConfigState;

  void _onCompletedExternally(TestSetupCompletedExternally event, Emitter<TestSetupState> emit) {
    if (state is TestSetupInProgressState) {
      final inProgressState = state as TestSetupInProgressState;
      emit(
        TestSetupCompletedState(
          testModel: inProgressState.testModel,
          correctCount: inProgressState.correctCount,
          totalQuestions: inProgressState.questions.length,
          timeSpentSeconds: 0,
          answersMap: inProgressState.answersMap,
          answersCorrectnessMap: inProgressState.answersCorrectnessMap,
          questions: inProgressState.questions,
          attemptId: '',
        ),
      );
    }
  }

  void _onReset(TestSetupReset event, Emitter<TestSetupState> emit) {
    _timer?.cancel();
    emit(_lastConfigState ?? const TestSetupConfigState());
  }

  // xem có bao nhiêu card từ các nguồn đã chọn và liệt kê chúng
  Future<void> _resolveCurrentSelection(Emitter<TestSetupState> emit) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    final folderIds = configState.selectedFolders.map((f) => f.id).toList();
    final deckIds = configState.selectedDecks.map((d) => d.id).toList();
    final tagIds = configState.selectedTags.map((t) => t.id).toList();

    if (folderIds.isEmpty && deckIds.isEmpty && tagIds.isEmpty) {
      emit(configState.copyWith(resolvedSourceDecks: [], selectedCardIds: {}));
      return;
    }

    try {
      final response = await testRepository.resolveSources(
        folderIds: folderIds,
        deckIds: deckIds,
        tagIds: tagIds,
      );

      final resolvedDecks = response.data;
      final prevResolvedDeckIds = configState.resolvedSourceDecks.map((rd) => rd.deckId).toSet();

      // 1. Tập hợp tất cả ID thẻ đang tồn tại từ Backend trả về
      final allValidCardIds = resolvedDecks.expand((d) => d.cards.map((c) => c.id)).toSet();

      // 2. Giữ lại những thẻ cũ đang chọn mà vẫn còn tồn tại (loại bỏ thẻ của Deck đã bị xóa)
      final updatedCardIds = configState.selectedCardIds.intersection(allValidCardIds).toSet();

      // 3. Với các Deck MỚI thêm vào -> Mặc định chọn tất cả thẻ của nó
      for (final rd in resolvedDecks) {
        if (!prevResolvedDeckIds.contains(rd.deckId)) {
          updatedCardIds.addAll(rd.cards.map((c) => c.id));
        }
      }

      emit(
        configState.copyWith(resolvedSourceDecks: resolvedDecks, selectedCardIds: updatedCardIds),
      );
    } catch (e) {
      emit(configState.copyWith(errorMessage: 'Lỗi gom thẻ từ nguồn: ${e.toString()}'));
    }
  }
}
