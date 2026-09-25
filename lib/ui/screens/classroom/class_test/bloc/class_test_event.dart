import 'package:equatable/equatable.dart';

abstract class ClassTestEvent extends Equatable {
  const ClassTestEvent();

  @override
  List<Object?> get props => [];
}

class ClassTestStarted extends ClassTestEvent {
  final String classId;
  final String assignmentId;
  final String testId;

  const ClassTestStarted({
    required this.classId,
    required this.assignmentId,
    required this.testId,
  });

  @override
  List<Object?> get props => [classId, assignmentId, testId];
}

class ClassTestAnswerSelected extends ClassTestEvent {
  final int questionIndex;
  final dynamic answer;
  final bool isCorrect;
  final int durationMs;

  const ClassTestAnswerSelected({
    required this.questionIndex,
    required this.answer,
    required this.isCorrect,
    required this.durationMs,
  });

  @override
  List<Object?> get props => [questionIndex, answer, isCorrect, durationMs];
}

class ClassTestTimerTicked extends ClassTestEvent {
  final int secondsRemaining;

  const ClassTestTimerTicked(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}

class ClassTestSubmitRequested extends ClassTestEvent {
  const ClassTestSubmitRequested();
}
