import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/data/models/resolved_source_deck_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/models/test_question_model.dart';

abstract class TestSetupState extends Equatable {
  const TestSetupState();

  @override
  List<Object?> get props => [];
}

class TestSetupConfigState extends TestSetupState {
  final List<DeckModel> selectedDecks;
  final List<FolderModel> selectedFolders;
  final List<TagModel> selectedTags;
  final List<ResolvedSourceDeck> resolvedSourceDecks;
  final Set<String> selectedCardIds;
  final bool timeLimitEnabled;
  final int timeLimitMinutes;
  final String questionSide; // 'front' | 'back' | 'mixed'
  final bool showAnswerInstantly;
  final Set<TestQuestionType> selectedQuestionTypes;
  final bool isGenerating;
  final String? errorMessage;

  const TestSetupConfigState({
    this.selectedDecks = const [],
    this.selectedFolders = const [],
    this.selectedTags = const [],
    this.resolvedSourceDecks = const [],
    this.selectedCardIds = const {},
    this.timeLimitEnabled = false,
    this.timeLimitMinutes = 15,
    this.questionSide = 'front',
    this.showAnswerInstantly = true,
    this.selectedQuestionTypes = const {
      TestQuestionType.multipleChoice,
      TestQuestionType.trueFalse,
      TestQuestionType.fillInTheBlank,
      TestQuestionType.matching,
      TestQuestionType.dictation,
    },
    this.isGenerating = false,
    this.errorMessage,
  });

  TestSetupConfigState copyWith({
    List<DeckModel>? selectedDecks,
    List<FolderModel>? selectedFolders,
    List<TagModel>? selectedTags,
    List<ResolvedSourceDeck>? resolvedSourceDecks,
    Set<String>? selectedCardIds,
    bool? timeLimitEnabled,
    int? timeLimitMinutes,
    String? questionSide,
    bool? showAnswerInstantly,
    Set<TestQuestionType>? selectedQuestionTypes,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return TestSetupConfigState(
      selectedDecks: selectedDecks ?? this.selectedDecks,
      selectedFolders: selectedFolders ?? this.selectedFolders,
      selectedTags: selectedTags ?? this.selectedTags,
      resolvedSourceDecks: resolvedSourceDecks ?? this.resolvedSourceDecks,
      selectedCardIds: selectedCardIds ?? this.selectedCardIds,
      timeLimitEnabled: timeLimitEnabled ?? this.timeLimitEnabled,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      questionSide: questionSide ?? this.questionSide,
      showAnswerInstantly: showAnswerInstantly ?? this.showAnswerInstantly,
      selectedQuestionTypes:
          selectedQuestionTypes ?? this.selectedQuestionTypes,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedDecks,
    selectedFolders,
    selectedTags,
    resolvedSourceDecks,
    selectedCardIds,
    timeLimitEnabled,
    timeLimitMinutes,
    questionSide,
    showAnswerInstantly,
    selectedQuestionTypes,
    isGenerating,
    errorMessage,
  ];
}

class TestSetupInProgressState extends TestSetupState {
  final CustomTestModel testModel;
  final List<TestQuestionModel> questions;
  final int currentQuestionIndex;
  final int timeRemainingSeconds;
  final Map<int, dynamic> answersMap; // index -> câu trả lời
  final Map<int, bool>
  isAnswerCheckedMap; // index -> đã check chưa (ở chế độ hiển thị ngay)
  final Map<int, bool> answersCorrectnessMap; // index -> đúng/sai
  final Map<int, int> questionDurationMap; // index -> duration in ms
  final int correctCount;
  final DateTime startedAt;
  final DateTime currentQuestionStartedAt;
  final String? errorMessage;
  final bool isSubmitting;

  const TestSetupInProgressState({
    required this.testModel,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.timeRemainingSeconds = 0,
    this.answersMap = const {},
    this.isAnswerCheckedMap = const {},
    this.answersCorrectnessMap = const {},
    this.questionDurationMap = const {},
    this.correctCount = 0,
    required this.startedAt,
    required this.currentQuestionStartedAt,
    this.errorMessage,
    this.isSubmitting = false,
  });

  TestSetupInProgressState copyWith({
    CustomTestModel? testModel,
    List<TestQuestionModel>? questions,
    int? currentQuestionIndex,
    int? timeRemainingSeconds,
    Map<int, dynamic>? answersMap,
    Map<int, bool>? isAnswerCheckedMap,
    Map<int, bool>? answersCorrectnessMap,
    Map<int, int>? questionDurationMap,
    int? correctCount,
    DateTime? startedAt,
    DateTime? currentQuestionStartedAt,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return TestSetupInProgressState(
      testModel: testModel ?? this.testModel,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      answersMap: answersMap ?? this.answersMap,
      isAnswerCheckedMap: isAnswerCheckedMap ?? this.isAnswerCheckedMap,
      answersCorrectnessMap:
          answersCorrectnessMap ?? this.answersCorrectnessMap,
      questionDurationMap: questionDurationMap ?? this.questionDurationMap,
      correctCount: correctCount ?? this.correctCount,
      startedAt: startedAt ?? this.startedAt,
      currentQuestionStartedAt:
          currentQuestionStartedAt ?? this.currentQuestionStartedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    testModel,
    questions,
    currentQuestionIndex,
    timeRemainingSeconds,
    answersMap,
    isAnswerCheckedMap,
    answersCorrectnessMap,
    questionDurationMap,
    correctCount,
    startedAt,
    currentQuestionStartedAt,
    errorMessage,
    isSubmitting,
  ];
}

class TestSetupCompletedState extends TestSetupState {
  final CustomTestModel testModel;
  final int correctCount;
  final int totalQuestions;
  final int timeSpentSeconds;
  final Map<int, dynamic> answersMap;
  final Map<int, bool> answersCorrectnessMap;
  final List<TestQuestionModel> questions;
  final String attemptId;
  final String? errorMessage;

  const TestSetupCompletedState({
    required this.testModel,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.answersMap,
    required this.answersCorrectnessMap,
    required this.questions,
    required this.attemptId,
    this.errorMessage,
  });

  TestSetupCompletedState copyWith({
    CustomTestModel? testModel,
    int? correctCount,
    int? totalQuestions,
    int? timeSpentSeconds,
    Map<int, dynamic>? answersMap,
    Map<int, bool>? answersCorrectnessMap,
    List<TestQuestionModel>? questions,
    String? attemptId,
    String? errorMessage,
  }) {
    return TestSetupCompletedState(
      testModel: testModel ?? this.testModel,
      correctCount: correctCount ?? this.correctCount,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      answersMap: answersMap ?? this.answersMap,
      answersCorrectnessMap:
          answersCorrectnessMap ?? this.answersCorrectnessMap,
      questions: questions ?? this.questions,
      attemptId: attemptId ?? this.attemptId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    testModel,
    correctCount,
    totalQuestions,
    timeSpentSeconds,
    answersMap,
    answersCorrectnessMap,
    questions,
    attemptId,
    errorMessage,
  ];
}
