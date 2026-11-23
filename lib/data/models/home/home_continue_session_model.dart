import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/study/active_study_session_model.dart';
import 'package:mind_deck/data/models/test_session_summary_model.dart';

/// Một phiên dở trong khối "Đang học dở" của Home: hoặc phiên flashcard hoặc phiên bài kiểm tra
/// (đúng một trong hai khác null), BE đã gộp và sắp theo `updatedAt`.
class HomeContinueSession extends Equatable {
  final ActiveStudySession? study;
  final TestSessionSummary? test;

  const HomeContinueSession({this.study, this.test}) : assert((study == null) != (test == null));

  factory HomeContinueSession.fromJson(Map<String, dynamic> json) {
    return json['sessionKind'] == 'test'
        ? HomeContinueSession(test: TestSessionSummary.fromJson(json))
        : HomeContinueSession(study: ActiveStudySession.fromJson(json));
  }

  String get sessionId => study?.sessionId ?? test!.sessionId;

  @override
  List<Object?> get props => [study, test];
}
