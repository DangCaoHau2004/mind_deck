import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/models/test_question_model.dart';

abstract class ClassTestState extends Equatable {
  const ClassTestState();

  @override
  List<Object?> get props => [];
}

class ClassTestInitial extends ClassTestState {}

class ClassTestLoading extends ClassTestState {}

class ClassTestInProgressState extends ClassTestState {
  final CustomTestModel testModel;
  final List<TestQuestionModel> questions;
  final int currentQuestionIndex;
  final int timeRemainingSeconds;
  final DateTime startedAt;
  final DateTime currentQuestionStartedAt;

  // Maps question index to the user's answer
  final Map<int, dynamic> answersMap;
  // Maps question index to correctness
  final Map<int, bool> answersCorrectnessMap;
  // Maps question index to duration spent (milliseconds)
  final Map<int, int> questionDurationMap;

  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const ClassTestInProgressState({
    required this.testModel,
    required this.questions,
    required this.currentQuestionIndex,
    required this.timeRemainingSeconds,
    required this.startedAt,
    required this.currentQuestionStartedAt,
    this.answersMap = const {},
    this.answersCorrectnessMap = const {},
    this.questionDurationMap = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ClassTestInProgressState copyWith({
    CustomTestModel? testModel,
    List<TestQuestionModel>? questions,
    int? currentQuestionIndex,
    int? timeRemainingSeconds,
    DateTime? startedAt,
    DateTime? currentQuestionStartedAt,
    Map<int, dynamic>? answersMap,
    Map<int, bool>? answersCorrectnessMap,
    Map<int, int>? questionDurationMap,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ClassTestInProgressState(
      testModel: testModel ?? this.testModel,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      startedAt: startedAt ?? this.startedAt,
      currentQuestionStartedAt:
          currentQuestionStartedAt ?? this.currentQuestionStartedAt,
      answersMap: answersMap ?? this.answersMap,
      answersCorrectnessMap:
          answersCorrectnessMap ?? this.answersCorrectnessMap,
      questionDurationMap: questionDurationMap ?? this.questionDurationMap,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
    testModel,
    questions,
    currentQuestionIndex,
    timeRemainingSeconds,
    startedAt,
    currentQuestionStartedAt,
    answersMap,
    answersCorrectnessMap,
    questionDurationMap,
    isSubmitting,
    errorMessage,
    isSuccess,
  ];
}

class ClassTestFailure extends ClassTestState {
  final String errorMessage;

  const ClassTestFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
