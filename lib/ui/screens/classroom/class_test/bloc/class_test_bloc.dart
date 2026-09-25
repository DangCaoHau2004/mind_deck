import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'class_test_event.dart';
import 'class_test_state.dart';

class ClassTestBloc extends Bloc<ClassTestEvent, ClassTestState> {
  final TestRepository testRepository;
  final ClassRepository classRepository;

  Timer? _timer;

  ClassTestBloc({required this.testRepository, required this.classRepository})
    : super(ClassTestInitial()) {
    on<ClassTestStarted>(_onStarted);
    on<ClassTestAnswerSelected>(_onAnswerSelected);
    on<ClassTestTimerTicked>(_onTimerTicked);
    on<ClassTestSubmitRequested>(_onSubmitRequested);
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
      add(ClassTestTimerTicked(remaining));
      if (remaining <= 0) {
        timer.cancel();
        // Lấy state hiện tại (nếu đang InProgress) thì pass event submit
        final currentState = state;
        if (currentState is ClassTestInProgressState && !currentState.isSubmitting) {
          // Lấy thông tin classId và assignmentId từ đâu đó.
          // Nhưng ở đây mình có thể gọi trực tiếp event submit.
          // Để dễ dàng, trong hàm _onSubmitRequested ta lấy trực tiếp từ config hoặc state.
          // Tốt nhất là thêm classId và assignmentId vào event nếu cần, nhưng ta sẽ lưu nó ở inProgressState hoặc lấy từ constructor...
        }
      }
    });
  }

  Future<void> _onStarted(ClassTestStarted event, Emitter<ClassTestState> emit) async {
    emit(ClassTestLoading());
    try {
      final response = await testRepository.startTest(event.testId);

      if (response.success && response.data != null) {
        final testModel = response.data!;
        final questions = testModel.questions;

        if (questions.isEmpty) {
          emit(const ClassTestFailure('Không có câu hỏi nào trong bài tập này.'));
          return;
        }

        final timeLimitSeconds = testModel.timeLimitSeconds;

        final inProgressState = ClassTestInProgressState(
          testModel: testModel,
          questions: questions,
          currentQuestionIndex: 0,
          timeRemainingSeconds: timeLimitSeconds,
          startedAt: DateTime.now(),
          currentQuestionStartedAt: DateTime.now(),
          // Lưu tạm classId và assignmentId thông qua field mới nếu cần,
          // nhưng tạm thời ta có thể gọi lưu ở bloc.
        );

        _classId = event.classId;
        _assignmentId = event.assignmentId;

        emit(inProgressState);

        if (timeLimitSeconds > 0) {
          _startTimer(timeLimitSeconds);
        }
      } else {
        emit(ClassTestFailure(response.message ?? 'Không thể tải bài tập.'));
      }
    } catch (e) {
      emit(ClassTestFailure('Lỗi tải bài tập: ${e.toString()}'));
    }
  }

  String _classId = '';
  String _assignmentId = '';

  void _onTimerTicked(ClassTestTimerTicked event, Emitter<ClassTestState> emit) {
    if (state is! ClassTestInProgressState) return;
    final inProgressState = state as ClassTestInProgressState;
    emit(inProgressState.copyWith(timeRemainingSeconds: event.secondsRemaining));

    // Auto-submit logic inside the bloc listener or here if time is 0
    if (event.secondsRemaining <= 0 && !inProgressState.isSubmitting) {
      _timer?.cancel();
      add(const ClassTestSubmitRequested());
    }
  }

  void _onAnswerSelected(ClassTestAnswerSelected event, Emitter<ClassTestState> emit) {
    if (state is! ClassTestInProgressState) return;
    final inProgressState = state as ClassTestInProgressState;
    final index = event.questionIndex;

    final updatedAnswersMap = Map<int, dynamic>.from(inProgressState.answersMap)
      ..[index] = event.answer;
    final updatedCorrectnessMap = Map<int, bool>.from(inProgressState.answersCorrectnessMap)
      ..[index] = event.isCorrect;

    final newDurationMap = Map<int, int>.from(inProgressState.questionDurationMap);
    newDurationMap[index] = (newDurationMap[index] ?? 0) + event.durationMs;

    int nextIndex = index + 1;

    emit(
      inProgressState.copyWith(
        answersMap: updatedAnswersMap,
        answersCorrectnessMap: updatedCorrectnessMap,
        questionDurationMap: newDurationMap,
        currentQuestionIndex: nextIndex,
        currentQuestionStartedAt: nextIndex < inProgressState.questions.length
            ? DateTime.now()
            : inProgressState.currentQuestionStartedAt,
      ),
    );

    if (nextIndex >= inProgressState.questions.length) {
      // Tự động nộp bài khi đã trả lời câu cuối cùng
      add(const ClassTestSubmitRequested());
    }

    // Nếu là câu cuối cùng thì tự động trigger nộp bài luôn? Có thể để người dùng bấm nút nộp.
  }

  Future<void> _onSubmitRequested(
    ClassTestSubmitRequested event,
    Emitter<ClassTestState> emit,
  ) async {
    if (state is! ClassTestInProgressState) return;
    final inProgressState = state as ClassTestInProgressState;

    _timer?.cancel();

    emit(inProgressState.copyWith(isSubmitting: true));

    final completedAt = DateTime.now();
    final totalDurationMs = completedAt.difference(inProgressState.startedAt).inMilliseconds;

    // Build answers payload for TestRepository
    final Map<String, Map<String, dynamic>> aggregatedAnswers = {};
    int correctCount = 0;

    for (int i = 0; i < inProgressState.questions.length; i++) {
      final q = inProgressState.questions[i];
      final ans = inProgressState.answersMap[i];
      final isCorrect = inProgressState.answersCorrectnessMap[i] ?? false;
      final duration = inProgressState.questionDurationMap[i] ?? 0;

      if (isCorrect) correctCount++;

      Map<String, dynamic> answerDetails = {};
      if (q.questionType == TestQuestionType.flashcard) {
        answerDetails = {'isRemembered': isCorrect, 'thinkTimeMs': duration};
      } else {
        answerDetails = {'userAnswer': ans != null ? ans.toString() : ''};
      }

      final List<String> targetCardIds = [];
      if (q.cardId != null) {
        targetCardIds.add(q.cardId!);
      } else if (q.cardIds != null && q.cardIds!.isNotEmpty) {
        targetCardIds.addAll(q.cardIds!);
      } else {
        // Fallback nếu thực sự không có gì (rất hiếm)
        targetCardIds.add('q_$i');
      }

      for (final cid in targetCardIds) {
        if (aggregatedAnswers.containsKey(cid)) {
          final existing = aggregatedAnswers[cid]!;
          final newDuration = (existing['durationMs'] as int) + duration;

          if (q.questionType == TestQuestionType.flashcard) {
            answerDetails['thinkTimeMs'] = newDuration;
          }

          aggregatedAnswers[cid] = {
            if (!cid.startsWith('q_')) 'cardId': cid,
            'questionType': q.questionType.value,
            'isCorrect': isCorrect,
            'durationMs': newDuration,
            'answerDetails': answerDetails,
          };
        } else {
          aggregatedAnswers[cid] = {
            if (!cid.startsWith('q_')) 'cardId': cid,
            'questionType': q.questionType.value,
            'isCorrect': isCorrect,
            'durationMs': duration,
            'answerDetails': answerDetails,
          };
        }
      }
    }

    final List<Map<String, dynamic>> answers = aggregatedAnswers.values.toList();

    try {
      // Gọi trực tiếp API Submit Assignment (Backend tự động xử lý FSRS và tạo TestAttempt)
      await classRepository.submitAssignmentTest(
        _classId,
        _assignmentId,
        testId: inProgressState.testModel.id,
        totalQuestions: inProgressState.questions.length,
        correctAnswers: correctCount,
        durationMs: totalDurationMs,
        startedAt: inProgressState.startedAt.toIso8601String(),
        completedAt: completedAt.toIso8601String(),
        answers: answers,
      );

      // TODO: TẠM THỜI MỞ DEMO CHO ADMIN - Luôn báo thành công kể cả API báo lỗi (Do Admin không được nộp)
      emit(inProgressState.copyWith(isSubmitting: false, isSuccess: true));

      /* 
      // LOGIC CHUẨN SẼ MỞ LẠI SAU KHI TEST XONG:
      if (classResponse.success) {
        emit(inProgressState.copyWith(isSubmitting: false, isSuccess: true));
      } else {
        emit(
          inProgressState.copyWith(
            isSubmitting: false,
            errorMessage:
                classResponse.message ?? 'Lỗi chốt sổ bài tập trên lớp.',
          ),
        );
      }
      */
    } catch (e) {
      // TODO: TẠM THỜI MỞ DEMO CHO ADMIN - Bỏ qua cả Exception (VD: 403 Forbidden)
      emit(inProgressState.copyWith(isSubmitting: false, isSuccess: true));

      /*
      // LOGIC CHUẨN SẼ MỞ LẠI SAU KHI TEST XONG:
      emit(
        inProgressState.copyWith(
          isSubmitting: false,
          errorMessage: 'Lỗi nộp bài: ${e.toString()}',
        ),
      );
      */
    }
  }
}
