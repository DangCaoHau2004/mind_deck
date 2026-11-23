import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/models/test_attempt_model.dart';
import 'package:mind_deck/data/models/test_question_model.dart';

abstract class ClassTestState extends Equatable {
  const ClassTestState();

  @override
  List<Object?> get props => [];
}

class ClassTestInitial extends ClassTestState {}

class ClassTestLoading extends ClassTestState {}

class ClassTestInProgressState extends ClassTestState {
  /// Đề + phiên làm bài (`sessionId`, `expiresAt`, `attemptNo`, `visibility`...) lấy từ Start / Resume.
  final CustomTestModel testModel;
  final List<TestQuestionModel> questions;
  final int currentQuestionIndex;

  /// Số giây còn lại: `timeLimitSeconds − elapsedSeconds`, bị chặn bởi `expiresAt`.
  /// Chỉ có nghĩa khi [hasTimer].
  final int timeRemainingSeconds;

  /// Có đồng hồ đếm ngược hiển thị (đề có giới hạn giờ, hoặc sắp tới hạn cứng).
  final bool hasTimer;
  final DateTime startedAt;
  final DateTime currentQuestionStartedAt;

  // Maps question index to the user's answer (giá trị UI, xem TestAnswerBuilder)
  final Map<int, dynamic> answersMap;
  // Maps question index to correctness (chấm cục bộ, chỉ để hiện đúng/sai tức thì)
  final Map<int, bool> answersCorrectnessMap;
  // Maps question index to duration spent (milliseconds)
  final Map<int, int> questionDurationMap;

  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  /// Kết quả CHẤM LẠI của server (điểm chính thức) — có khi [isSuccess].
  final TestSubmitResponseModel? result;

  const ClassTestInProgressState({
    required this.testModel,
    required this.questions,
    required this.currentQuestionIndex,
    required this.timeRemainingSeconds,
    this.hasTimer = false,
    required this.startedAt,
    required this.currentQuestionStartedAt,
    this.answersMap = const {},
    this.answersCorrectnessMap = const {},
    this.questionDurationMap = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
    this.result,
  });

  ClassTestInProgressState copyWith({
    CustomTestModel? testModel,
    List<TestQuestionModel>? questions,
    int? currentQuestionIndex,
    int? timeRemainingSeconds,
    bool? hasTimer,
    DateTime? startedAt,
    DateTime? currentQuestionStartedAt,
    Map<int, dynamic>? answersMap,
    Map<int, bool>? answersCorrectnessMap,
    Map<int, int>? questionDurationMap,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    TestSubmitResponseModel? result,
  }) {
    return ClassTestInProgressState(
      testModel: testModel ?? this.testModel,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      hasTimer: hasTimer ?? this.hasTimer,
      startedAt: startedAt ?? this.startedAt,
      currentQuestionStartedAt: currentQuestionStartedAt ?? this.currentQuestionStartedAt,
      answersMap: answersMap ?? this.answersMap,
      answersCorrectnessMap: answersCorrectnessMap ?? this.answersCorrectnessMap,
      questionDurationMap: questionDurationMap ?? this.questionDurationMap,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    testModel,
    questions,
    currentQuestionIndex,
    timeRemainingSeconds,
    hasTimer,
    startedAt,
    currentQuestionStartedAt,
    answersMap,
    answersCorrectnessMap,
    questionDurationMap,
    isSubmitting,
    errorMessage,
    isSuccess,
    result,
  ];
}

class ClassTestFailure extends ClassTestState {
  final String errorMessage;

  /// Mã lỗi BE (nếu có) để màn hình quyết định có đóng lại hay cho thử lại.
  final String? errorCode;

  const ClassTestFailure(this.errorMessage, {this.errorCode});

  @override
  List<Object?> get props => [errorMessage, errorCode];
}
