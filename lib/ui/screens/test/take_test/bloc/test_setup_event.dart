import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

abstract class TestSetupEvent extends Equatable {
  const TestSetupEvent();

  @override
  List<Object?> get props => [];
}

class TestSetupInitialized extends TestSetupEvent {
  final dynamic initData;

  const TestSetupInitialized({this.initData});

  @override
  List<Object?> get props => [initData];
}

class TestSetupSourcesChanged extends TestSetupEvent {
  final List<DeckModel> decks;
  final List<FolderModel> folders;
  final List<TagModel> tags;

  const TestSetupSourcesChanged({
    required this.decks,
    required this.folders,
    required this.tags,
  });

  @override
  List<Object?> get props => [decks, folders, tags];
}

class TestSetupSourceRemoved extends TestSetupEvent {
  final TestSourceType type;
  final String id;

  const TestSetupSourceRemoved({required this.type, required this.id});

  @override
  List<Object?> get props => [type, id];
}

class TestSetupCardToggled extends TestSetupEvent {
  final String cardId;

  const TestSetupCardToggled(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class TestSetupAllCardsToggled extends TestSetupEvent {
  final bool value;

  const TestSetupAllCardsToggled(this.value);

  @override
  List<Object?> get props => [value];
}

class TestSetupSettingsChanged extends TestSetupEvent {
  final bool? timeLimitEnabled;
  final int? timeLimitMinutes;
  final String? questionSide; // 'front' | 'back' | 'random'
  final bool? showAnswerInstantly;

  const TestSetupSettingsChanged({
    this.timeLimitEnabled,
    this.timeLimitMinutes,
    this.questionSide,
    this.showAnswerInstantly,
  });

  @override
  List<Object?> get props => [
    timeLimitEnabled,
    timeLimitMinutes,
    questionSide,
    showAnswerInstantly,
  ];
}

class TestSetupQuestionTypesChanged extends TestSetupEvent {
  final Set<TestQuestionType> questionTypes;

  const TestSetupQuestionTypesChanged(this.questionTypes);

  @override
  List<Object?> get props => [questionTypes];
}

class TestSetupGenerateRequested extends TestSetupEvent {
  final String? name;

  const TestSetupGenerateRequested({this.name});

  @override
  List<Object?> get props => [name];
}

class TestSetupTimerTicked extends TestSetupEvent {
  final int remainingSeconds;

  const TestSetupTimerTicked(this.remainingSeconds);

  @override
  List<Object?> get props => [remainingSeconds];
}

class TestSetupAnswerSubmitted extends TestSetupEvent {
  final dynamic answer;

  const TestSetupAnswerSubmitted(this.answer);

  @override
  List<Object?> get props => [answer];
}

class TestSetupNextQuestionRequested extends TestSetupEvent {
  const TestSetupNextQuestionRequested();
}

class TestSetupSubmitRequested extends TestSetupEvent {
  const TestSetupSubmitRequested();
}

class TestSetupCompletedExternally extends TestSetupEvent {
  const TestSetupCompletedExternally();
}

class TestSetupReset extends TestSetupEvent {
  const TestSetupReset();
}
