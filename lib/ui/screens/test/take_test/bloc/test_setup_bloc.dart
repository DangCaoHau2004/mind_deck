import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/core/server_clock.dart';
import 'package:mind_deck/utils/test_answer_builder.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
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

  /// Phiên không còn cứu được khi nộp/mở lại: về màn thiết lập thay vì cho bấm nộp mãi.
  static const Set<String> _fatalSessionCodes = {
    AppErrorCodes.testSessionExpired,
    AppErrorCodes.testSessionNotFound,
    AppErrorCodes.testNotFound,
    AppErrorCodes.testNoQuestions,
    AppErrorCodes.testNoCardsFound,
  };

  static const Duration _minDraftGap = Duration(seconds: 3);

  Timer? _timer;

  /// Id đề đang làm (generate trả về, hoặc lấy từ phiên dở). Không dựa vào `id` của payload Start.
  String _activeTestId = '';
  bool _submitStarted = false;
  DateTime? _lastDraftSaveAt;
  Timer? _pendingDraft;
  TestSetupInProgressState? _latestDraft;

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
    on<TestSetupOnlyDueCardsToggled>(_onOnlyDueCardsToggled);
    on<TestSetupSettingsChanged>(_onSettingsChanged);
    on<TestSetupQuestionTypesChanged>(_onQuestionTypesChanged);
    on<TestSetupGenerateRequested>(_onGenerateRequested);
    on<TestSetupTimerTicked>(_onTimerTicked);
    on<TestSetupAnswerSubmitted>(_onAnswerSubmitted);
    on<TestSetupNextQuestionRequested>(_onNextQuestionRequested);
    on<TestSetupSubmitRequested>(_onSubmitRequested);
    on<TestSetupReset>(_onReset);
    on<TestSetupCompletedExternally>(_onCompletedExternally);
    on<TestSetupResumeRequested>(_onResumeRequested);
    on<TestSetupRestartRequested>(_onRestartRequested);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    if (_pendingDraft != null) {
      _pendingDraft!.cancel();
      _pendingDraft = null;
      _flushDraft();
    }
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
        } else if (event.initData is List<DeckModel>) {
          initialSelectedDecks.addAll(event.initData as List<DeckModel>);
        } else if (event.initData is List<FolderModel>) {
          initialSelectedFolders.addAll(event.initData as List<FolderModel>);
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

  Future<void> _onOnlyDueCardsToggled(
    TestSetupOnlyDueCardsToggled event,
    Emitter<TestSetupState> emit,
  ) async {
    if (state is! TestSetupConfigState) return;
    final configState = state as TestSetupConfigState;

    if (event.value) {
      final dueCardIds = configState.resolvedSourceDecks
          .expand((d) => d.cards)
          .where((c) => c.isDueCard)
          .map((c) => c.id)
          .toSet();
      emit(configState.copyWith(onlyDueCards: true, selectedCardIds: dueCardIds));
    } else {
      final allCardIds = configState.resolvedSourceDecks
          .expand((d) => d.cards)
          .map((c) => c.id)
          .toSet();
      emit(configState.copyWith(onlyDueCards: false, selectedCardIds: allCardIds));
    }
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

    // Chỉ chọn "Flashcard": đây là ôn tập (không chấm điểm) đi qua `/study/start`, KHÔNG gọi `/tests/*`.
    // Dựng phiên giả chứa các thẻ để màn hình mở luồng học (xem TakeTestScreen).
    if (configState.selectedQuestionTypes.every((t) => t == TestQuestionType.flashcard)) {
      final cards = configState.selectedCardIds.toList();
      _lastConfigState = configState.copyWith(isGenerating: false, errorMessage: null);
      emit(
        TestSetupInProgressState(
          testModel: CustomTestModel(
            id: '',
            name: event.name ?? 'Ôn tập flashcard',
            questionTypes: [TestQuestionType.flashcard.value],
            createdAt: DateTime.now(),
            questions: [
              for (final id in cards)
                TestQuestionModel(
                  cardId: id,
                  questionType: TestQuestionType.flashcard,
                  questionData: const {},
                ),
            ],
          ),
          questions: const [],
          startedAt: DateTime.now(),
          currentQuestionStartedAt: DateTime.now(),
        ),
      );
      return;
    }

    // Đề cá nhân chỉ lấy thẻ của deck cá nhân của chính mình: BE loại thẻ bản sao lớp IM LẶNG
    // (đề ít câu hơn mong đợi, hoặc 404 TEST_NO_CARDS_FOUND). FE lọc trước và báo rõ.
    final classDeckIds = <String>{
      for (final d in configState.selectedDecks)
        if (d.isClassCopy) d.id,
      for (final f in configState.selectedFolders)
        for (final d in f.decks ?? const <DeckModel>[])
          if (f.isClassCopy || d.isClassCopy) d.id,
    };
    final classCardIds = <String>{
      for (final rd in configState.resolvedSourceDecks)
        if (classDeckIds.contains(rd.deckId))
          for (final c in rd.cards) c.id,
    };
    final personalCardIds = [
      for (final id in configState.selectedCardIds)
        if (!classCardIds.contains(id)) id,
    ];
    final skippedClassCards = configState.selectedCardIds.length - personalCardIds.length;
    if (personalCardIds.isEmpty) {
      emit(
        configState.copyWith(
          errorMessage:
              'Đề kiểm tra chỉ tạo được từ bộ thẻ cá nhân của bạn. '
              'Thẻ của lớp hãy ôn bằng chế độ Flashcard.',
        ),
      );
      return;
    }

    emit(configState.copyWith(isGenerating: true, errorMessage: null));
    try {
      final Map<String, dynamic> settings = {
        'timeLimitEnabled': configState.timeLimitEnabled,
        if (configState.timeLimitEnabled) 'timeLimitMinutes': configState.timeLimitMinutes,
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

      // Đề cá nhân: chỉ `kind: auto`, chỉ thẻ của deck cá nhân của mình, `flashcard` không phải dạng câu của đề.
      final generated = await testRepository.generateTest(
        cardIds: personalCardIds,
        name: testName,
        questionTypes: [
          for (final t in configState.selectedQuestionTypes)
            if (t != TestQuestionType.flashcard) t.value,
        ],
        settings: settings,
      );

      // `questions` trong response của generate chỉ là bản xem trước (không lưu). Đề làm thật
      // phải lấy từ Start: nó sinh bộ câu mới cho phiên này và server dùng nó để chấm khi nộp.
      if (generated.success && generated.data != null) _activeTestId = generated.data!.id;
      final response = generated.success && generated.data != null
          ? await testRepository.startTest(generated.data!.id)
          : generated;

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
        // Giới hạn giờ lấy từ phiên Start (phiên không giới hạn giờ thì không hết hạn).
        final timeLimitSeconds = testModel.timeLimitSeconds;

        final inProgressState = TestSetupInProgressState(
          testModel: testModel,
          questions: questions,
          currentQuestionIndex: 0,
          timeRemainingSeconds: timeLimitSeconds,
          startedAt: DateTime.now(),
          currentQuestionStartedAt: DateTime.now(),
          errorMessage: skippedClassCards > 0
              ? 'Đã bỏ $skippedClassCards thẻ của lớp: đề cá nhân chỉ dùng thẻ của bạn.'
              : null,
        );

        _lastConfigState = configState.copyWith(isGenerating: false, errorMessage: null);
        _resetDraftState();
        emit(inProgressState);

        if (timeLimitSeconds > 0) {
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
    } on Failure catch (f) {
      // VD: TEST_NO_CARDS_FOUND khi thẻ không thuộc deck cá nhân của mình, TEST_PERSONAL_AUTO_ONLY...
      emit(configState.copyWith(isGenerating: false, errorMessage: ClassErrorMessages.of(f)));
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

    final next = inProgressState.copyWith(
      questions: updatedQuestions,
      answersMap: updatedAnswersMap,
      isAnswerCheckedMap: updatedIsCheckedMap,
      answersCorrectnessMap: updatedCorrectnessMap,
      correctCount: newCorrectCount,
    );
    emit(next);
    _saveDraft(next);
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
    _submitStarted = true;
    _pendingDraft?.cancel();
    _pendingDraft = null;

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

    // Gửi MỘT phần tử cho MỖI câu, có `qid` (câu bỏ trống: userAnswer ""). Server chấm lại bằng đề của
    // phiên Start nên không gửi `expectedAnswer` / `isCorrect` / số câu đúng nữa.
    final List<Map<String, dynamic>> answers = [
      for (int i = 0; i < inProgressState.questions.length; i++)
        if (inProgressState.questions[i].questionType != TestQuestionType.flashcard)
          TestAnswerBuilder.build(
            inProgressState.questions[i],
            inProgressState.answersMap[i],
            finalDurationMap[i] ?? 0,
          ),
    ];

    try {
      final response = await testRepository.submitTest(
        testId: _activeTestId.isNotEmpty ? _activeTestId : inProgressState.testModel.id,
        durationMs: totalDurationMs,
        answers: answers,
      );
      final result = response.data;

      // Điểm chính thức là kết quả CHẤM LẠI của server: ghi đè kết quả chấm cục bộ (ghép theo qid).
      final serverCorrectness = <int, bool>{};
      final serverAnswers = result?.answers;
      if (serverAnswers != null) {
        for (int i = 0; i < inProgressState.questions.length; i++) {
          final qid = inProgressState.questions[i].qid;
          if (qid == null) continue;
          final match = serverAnswers.where((a) => a.qid == qid);
          if (match.isNotEmpty) serverCorrectness[i] = match.first.isCorrect;
        }
      }

      emit(
        TestSetupCompletedState(
          testModel: inProgressState.testModel,
          correctCount: result?.correctAnswers ?? inProgressState.correctCount,
          totalQuestions: result?.totalQuestions ?? inProgressState.questions.length,
          timeSpentSeconds: totalDurationMs ~/ 1000,
          answersMap: inProgressState.answersMap,
          answersCorrectnessMap: serverCorrectness.isNotEmpty
              ? serverCorrectness
              : inProgressState.answersCorrectnessMap,
          questions: inProgressState.questions,
          attemptId: result?.attemptId ?? '',
        ),
      );
    } on Failure catch (f) {
      // Không giả lập kết quả cục bộ khi nộp lỗi (điểm chỉ có giá trị khi server đã chấm).
      if (_fatalSessionCodes.contains(f.errorCode)) {
        // Phiên hết hạn / không còn: bài làm mất phía server, nộp lại vô ích → về màn thiết lập.
        emit(
          (_lastConfigState ?? const TestSetupConfigState()).copyWith(
            isGenerating: false,
            errorMessage: '${ClassErrorMessages.of(f)} Hãy tạo bài mới để làm lại.',
          ),
        );
        return;
      }
      // Lỗi tạm thời (mạng...): giữ bài làm, cho bấm nộp lại.
      _submitStarted = false;
      emit(inProgressState.copyWith(isSubmitting: false, errorMessage: ClassErrorMessages.of(f)));
    }
  }

  // ---------------------------------------------------------------------------
  // Phiên dở: lưu nháp lên server + mở lại
  // ---------------------------------------------------------------------------

  void _resetDraftState() {
    _submitStarted = false;
    _lastDraftSaveAt = null;
    _pendingDraft?.cancel();
    _pendingDraft = null;
    _latestDraft = null;
  }

  /// Lưu nháp thưa (≤ 1 lần / [_minDraftGap]); câu trả lời trong khoảng chờ được gửi ở lần lưu bù.
  void _saveDraft(TestSetupInProgressState s) {
    if (_submitStarted || s.testModel.sessionId == null) return;
    _latestDraft = s;
    final since = _lastDraftSaveAt == null ? null : DateTime.now().difference(_lastDraftSaveAt!);
    if (since == null || since >= _minDraftGap) {
      _pendingDraft?.cancel();
      _pendingDraft = null;
      _flushDraft();
      return;
    }
    _pendingDraft ??= Timer(_minDraftGap - since, () {
      _pendingDraft = null;
      _flushDraft();
    });
  }

  void _flushDraft() {
    final s = _latestDraft;
    final sessionId = s?.testModel.sessionId;
    if (s == null || sessionId == null || _submitStarted) return;
    _lastDraftSaveAt = DateTime.now();
    final answers = [
      for (int i = 0; i < s.questions.length; i++)
        if (s.answersMap.containsKey(i) &&
            s.questions[i].questionType != TestQuestionType.flashcard)
          TestAnswerBuilder.build(s.questions[i], s.answersMap[i], s.questionDurationMap[i] ?? 0),
    ];
    final elapsed = DateTime.now().difference(s.startedAt).inSeconds;
    unawaited(() async {
      try {
        await testRepository.saveProgress(
          sessionId,
          answers: answers,
          elapsedSeconds: elapsed,
          currentQuestionIndex: s.currentQuestionIndex,
        );
      } on Failure catch (_) {
        // Lưu nháp chỉ là phòng hờ; lỗi phiên sẽ được báo khi nộp.
      }
    }());
  }

  Future<void> _onResumeRequested(
    TestSetupResumeRequested event,
    Emitter<TestSetupState> emit,
  ) async {
    final config = state is TestSetupConfigState
        ? state as TestSetupConfigState
        : const TestSetupConfigState();
    _lastConfigState = config.copyWith(isGenerating: false);
    emit(config.copyWith(isGenerating: true));

    try {
      final response = await testRepository.resumeSession(event.sessionId);
      final testModel = response.data;
      if (!response.success || testModel == null || testModel.questions.isEmpty) {
        emit(
          config.copyWith(
            isGenerating: false,
            errorMessage: response.message ?? 'Không mở lại được bài đang làm dở.',
          ),
        );
        return;
      }

      final questions = testModel.questions;
      final answers = <int, dynamic>{};
      final durations = <int, int>{};
      for (final draft in testModel.drafts) {
        final qid = draft['qid']?.toString();
        final index = questions.indexWhere((q) => q.qid != null && q.qid == qid);
        if (index < 0) continue;
        final restored = TestAnswerBuilder.restore(questions[index], draft);
        if (restored == null) continue;
        answers[index] = restored;
        durations[index] = (draft['durationMs'] as num?)?.toInt() ?? 0;
      }
      final correctness = {
        for (final e in answers.entries) e.key: questions[e.key].checkAnswer(e.value),
      };
      var firstOpen = 0;
      while (firstOpen < questions.length && answers.containsKey(firstOpen)) {
        firstOpen++;
      }

      // Giờ còn lại theo server: giới hạn giờ − đã làm, chặn bởi `expiresAt` (giờ server).
      int remaining = testModel.timeLimitSeconds > 0
          ? testModel.timeLimitSeconds - testModel.elapsedSeconds
          : 0;
      final expires = testModel.expiresAt;
      if (expires != null) {
        final byHard = expires.difference(ServerClock.now()).inSeconds;
        remaining = remaining > 0 && remaining < byHard ? remaining : byHard;
      }

      _activeTestId = event.testId;
      _resetDraftState();
      _timer?.cancel();
      final now = DateTime.now();
      final resumed = TestSetupInProgressState(
        testModel: testModel,
        questions: questions,
        currentQuestionIndex: firstOpen >= questions.length ? questions.length - 1 : firstOpen,
        timeRemainingSeconds: remaining > 0 ? remaining : 0,
        answersMap: answers,
        isAnswerCheckedMap: {for (final i in answers.keys) i: true},
        answersCorrectnessMap: correctness,
        questionDurationMap: durations,
        correctCount: correctness.values.where((v) => v).length,
        startedAt: now.subtract(Duration(seconds: testModel.elapsedSeconds)),
        currentQuestionStartedAt: now,
      );
      emit(resumed);

      final hasDeadline = testModel.timeLimitSeconds > 0 || expires != null;
      if (hasDeadline && remaining <= 0) {
        add(const TestSetupSubmitRequested());
      } else if (hasDeadline) {
        _startTimer(remaining);
      }
    } on Failure catch (f) {
      emit(config.copyWith(isGenerating: false, errorMessage: ClassErrorMessages.of(f)));
    }
  }

  /// "Làm đề mới": cùng đề cá nhân nhưng bỏ phiên dở và sinh bộ câu hỏi mới (`?restart=true`).
  Future<void> _onRestartRequested(
    TestSetupRestartRequested event,
    Emitter<TestSetupState> emit,
  ) async {
    final config = state is TestSetupConfigState
        ? state as TestSetupConfigState
        : const TestSetupConfigState();
    _lastConfigState = config.copyWith(isGenerating: false);
    emit(config.copyWith(isGenerating: true));

    try {
      final response = await testRepository.startTest(event.testId, restart: true);
      final testModel = response.data;
      if (!response.success || testModel == null || testModel.questions.isEmpty) {
        emit(
          config.copyWith(
            isGenerating: false,
            errorMessage: response.message ?? 'Không tạo được đề mới.',
          ),
        );
        return;
      }

      _activeTestId = event.testId;
      _resetDraftState();
      _timer?.cancel();
      final now = DateTime.now();
      emit(
        TestSetupInProgressState(
          testModel: testModel,
          questions: testModel.questions,
          currentQuestionIndex: 0,
          timeRemainingSeconds: testModel.timeLimitSeconds,
          startedAt: now,
          currentQuestionStartedAt: now,
        ),
      );
      if (testModel.timeLimitSeconds > 0) _startTimer(testModel.timeLimitSeconds);
    } on Failure catch (f) {
      emit(config.copyWith(isGenerating: false, errorMessage: ClassErrorMessages.of(f)));
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

      // 3. Với các Deck MỚI thêm vào -> Mặc định chọn thẻ (tuân thủ onlyDueCards)
      for (final rd in resolvedDecks) {
        if (!prevResolvedDeckIds.contains(rd.deckId)) {
          if (configState.onlyDueCards) {
            updatedCardIds.addAll(rd.cards.where((c) => c.isDueCard).map((c) => c.id));
          } else {
            updatedCardIds.addAll(rd.cards.map((c) => c.id));
          }
        }
      }

      emit(
        configState.copyWith(resolvedSourceDecks: resolvedDecks, selectedCardIds: updatedCardIds),
      );
    } catch (e) {
      emit(
        configState.copyWith(
          errorMessage: e is Failure ? e.displayMessage : 'Lỗi gom thẻ từ nguồn: ${e.toString()}',
        ),
      );
    }
  }
}
