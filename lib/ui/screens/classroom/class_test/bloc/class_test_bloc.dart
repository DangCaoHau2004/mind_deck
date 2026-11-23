import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/core/server_clock.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/utils/test_answer_builder.dart';
import 'class_test_event.dart';
import 'class_test_state.dart';

/// Làm bài kiểm tra của lớp.
///
/// Luồng: `Start (bắt buộc assignmentId)` -> làm bài (nháp tự lưu thưa) -> `Submit`.
/// Server chấm lại bằng đề của phiên Start nên FE chỉ gửi `qid` + `userAnswer` (+ `pairs`);
/// điểm / đáp án hiển thị theo `visibility` mà server trả về.
class ClassTestBloc extends Bloc<ClassTestEvent, ClassTestState> {
  final TestRepository testRepository;
  final ClassRepository classRepository;

  /// Khoảng cách tối thiểu giữa hai lần lưu nháp. Câu trả lời rơi vào khoảng này không bị bỏ:
  /// một lần lưu bù được hẹn ở cuối khoảng, mang bản nháp mới nhất.
  static const Duration minSaveGap = Duration(seconds: 3);

  /// Hiện đồng hồ khi sắp tới hạn cứng của phiên (kể cả đề không giới hạn giờ).
  static const int hardDeadlineWarningSeconds = 600;

  /// Các lỗi mà phiên làm bài không còn cứu được: đóng màn hình thay vì cho thử lại.
  static const Set<String> _fatalCodes = {
    AppErrorCodes.testSessionExpired,
    AppErrorCodes.testSessionNotFound,
    AppErrorCodes.testEnded,
    AppErrorCodes.testNotStarted,
    AppErrorCodes.testAttemptsExhausted,
    AppErrorCodes.testNotInClass,
    AppErrorCodes.testNotFound,
    AppErrorCodes.classAssignmentNotFound,
    AppErrorCodes.classNotFound,
    AppErrorCodes.classNotAMember,
  };

  Timer? _timer;
  String _assignmentId = '';
  String _testId = '';

  /// Thời gian đã làm = `_baseElapsedSeconds` (server trả) + đồng hồ đơn điệu cục bộ,
  /// nên đổi giờ máy giữa chừng không ảnh hưởng.
  final Stopwatch _stopwatch = Stopwatch();
  int _baseElapsedSeconds = 0;

  DateTime? _lastSaveAt;
  Timer? _pendingSave;
  ClassTestInProgressState? _latestDraft;

  /// Đã bấm nộp (hoặc đã nộp xong): dừng lưu nháp, bỏ qua lỗi lưu nháp đến muộn.
  bool _submitStarted = false;

  ClassTestBloc({required this.testRepository, required this.classRepository})
    : super(ClassTestInitial()) {
    on<ClassTestStarted>(_onStarted);
    on<ClassTestAnswerSelected>(_onAnswerSelected);
    on<ClassTestTimerTicked>(_onTimerTicked);
    on<ClassTestSubmitRequested>(_onSubmitRequested);
    on<ClassTestSessionLost>(_onSessionLost);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    // Thoát giữa chừng: đẩy nốt bản nháp đang chờ để lần vào lại không mất câu vừa làm.
    if (_pendingSave != null) {
      _pendingSave!.cancel();
      _pendingSave = null;
      _flushDraft();
    }
    return super.close();
  }

  int get _elapsedSeconds => _baseElapsedSeconds + _stopwatch.elapsed.inSeconds;

  void _onSessionLost(ClassTestSessionLost event, Emitter<ClassTestState> emit) {
    // Lỗi của một lần lưu nháp gửi trước khi nộp: phiên kết thúc vì ĐÃ NỘP, không phải lỗi.
    if (_submitStarted) return;
    final current = state;
    if (current is ClassTestInProgressState && (current.isSubmitting || current.isSuccess)) return;
    _timer?.cancel();
    emit(ClassTestFailure(event.message));
  }

  /// Số giây còn lại theo giờ giới hạn của đề và hạn cứng của phiên (nhỏ hơn); null = không giới hạn.
  int? _remainingSeconds(ClassTestInProgressState s) {
    final limit = s.testModel.timeLimitSeconds;
    final byLimit = limit > 0 ? limit - _elapsedSeconds : null;
    // `expiresAt` là giờ server: so với giờ server ước lượng (header `Date`), không so với giờ máy.
    final expires = s.testModel.expiresAt;
    final byHard = expires?.difference(ServerClock.now()).inSeconds;
    if (byLimit == null) return byHard;
    if (byHard == null) return byLimit;
    return byLimit < byHard ? byLimit : byHard;
  }

  Future<void> _onStarted(ClassTestStarted event, Emitter<ClassTestState> emit) async {
    emit(ClassTestLoading());
    _assignmentId = event.assignmentId;
    _testId = event.testId;
    _submitStarted = false;
    try {
      // Start có tác dụng phụ (tạo / trả lại phiên): chỉ gọi khi người dùng thực sự mở bài.
      final response = await testRepository.startTest(
        event.testId,
        assignmentId: event.assignmentId,
      );
      final testModel = response.data;
      if (!response.success || testModel == null) {
        emit(ClassTestFailure(response.message ?? 'Không thể tải bài kiểm tra.'));
        return;
      }

      final questions = testModel.questions;
      if (questions.isEmpty) {
        emit(const ClassTestFailure('Bài kiểm tra này chưa có câu hỏi nào.'));
        return;
      }

      // Khôi phục bản nháp khi `resumed` (ghép theo qid).
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

      _baseElapsedSeconds = testModel.elapsedSeconds;
      _stopwatch
        ..reset()
        ..start();
      _lastSaveAt = null;
      _pendingSave?.cancel();
      _pendingSave = null;

      final initial = ClassTestInProgressState(
        testModel: testModel,
        questions: questions,
        currentQuestionIndex: firstOpen,
        timeRemainingSeconds: 0,
        startedAt: DateTime.now().subtract(Duration(seconds: testModel.elapsedSeconds)),
        currentQuestionStartedAt: DateTime.now(),
        answersMap: answers,
        answersCorrectnessMap: correctness,
        questionDurationMap: durations,
      );
      final remaining = _remainingSeconds(initial);
      emit(
        initial.copyWith(
          timeRemainingSeconds: remaining ?? 0,
          hasTimer:
              testModel.timeLimitSeconds > 0 ||
              (remaining != null && remaining <= hardDeadlineWarningSeconds),
        ),
      );

      if (remaining != null) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!isClosed) add(const ClassTestTimerTicked());
        });
      }
    } on Failure catch (f) {
      emit(ClassTestFailure(ClassErrorMessages.of(f), errorCode: f.errorCode));
    }
  }

  void _onTimerTicked(ClassTestTimerTicked event, Emitter<ClassTestState> emit) {
    final current = state;
    if (current is! ClassTestInProgressState || current.isSuccess) return;

    final remaining = _remainingSeconds(current);
    if (remaining == null) return;

    emit(
      current.copyWith(
        timeRemainingSeconds: remaining < 0 ? 0 : remaining,
        hasTimer: current.testModel.timeLimitSeconds > 0 || remaining <= hardDeadlineWarningSeconds,
      ),
    );

    // Hết giờ: nộp ngay (trong 60 giây sau hạn; không dùng PATCH).
    if (remaining <= 0 && !current.isSubmitting) {
      _timer?.cancel();
      add(const ClassTestSubmitRequested());
    }
  }

  void _onAnswerSelected(ClassTestAnswerSelected event, Emitter<ClassTestState> emit) {
    final current = state;
    if (current is! ClassTestInProgressState || current.isSubmitting) return;
    final index = event.questionIndex;

    final updatedAnswersMap = Map<int, dynamic>.from(current.answersMap)..[index] = event.answer;
    final updatedCorrectnessMap = Map<int, bool>.from(current.answersCorrectnessMap)
      ..[index] = event.isCorrect;

    final newDurationMap = Map<int, int>.from(current.questionDurationMap);
    newDurationMap[index] = (newDurationMap[index] ?? 0) + event.durationMs;

    final nextIndex = index + 1;
    final next = current.copyWith(
      answersMap: updatedAnswersMap,
      answersCorrectnessMap: updatedCorrectnessMap,
      questionDurationMap: newDurationMap,
      currentQuestionIndex: nextIndex,
      currentQuestionStartedAt: nextIndex < current.questions.length
          ? DateTime.now()
          : current.currentQuestionStartedAt,
    );
    emit(next);

    if (nextIndex >= current.questions.length) {
      // Đã trả lời câu cuối: tự động nộp bài.
      add(const ClassTestSubmitRequested());
    } else {
      _saveDraft(next);
    }
  }

  /// Lưu nháp (ghi đè toàn bộ bản nháp trên server): gửi ĐỦ các câu đã trả lời, có `qid`.
  /// Tối đa một lần mỗi [minSaveGap]; trong khoảng đó chỉ hẹn MỘT lần lưu bù ở cuối khoảng
  /// với bản nháp mới nhất. Không chặn giao diện.
  void _saveDraft(ClassTestInProgressState s) {
    if (_submitStarted || s.testModel.sessionId == null) return;
    _latestDraft = s;
    final now = DateTime.now();
    final since = _lastSaveAt == null ? null : now.difference(_lastSaveAt!);
    if (since == null || since >= minSaveGap) {
      _pendingSave?.cancel();
      _pendingSave = null;
      _flushDraft();
      return;
    }
    _pendingSave ??= Timer(minSaveGap - since, () {
      _pendingSave = null;
      _flushDraft();
    });
  }

  void _flushDraft() {
    final s = _latestDraft;
    final sessionId = s?.testModel.sessionId;
    if (s == null || sessionId == null || _submitStarted) return;
    _lastSaveAt = DateTime.now();
    final answers = _buildAnswers(s, onlyAnswered: true);
    final elapsed = _elapsedSeconds;

    unawaited(() async {
      try {
        await testRepository.saveProgress(
          sessionId,
          answers: answers,
          elapsedSeconds: elapsed,
          currentQuestionIndex: s.currentQuestionIndex,
        );
      } on Failure catch (f) {
        // Phiên đã hết hạn / bài bị xóa / không còn được giao: không làm tiếp được nữa.
        if (_fatalCodes.contains(f.errorCode) && !isClosed) {
          add(ClassTestSessionLost(ClassErrorMessages.of(f)));
        }
      }
    }());
  }

  List<Map<String, dynamic>> _buildAnswers(
    ClassTestInProgressState s, {
    required bool onlyAnswered,
  }) {
    return [
      for (var i = 0; i < s.questions.length; i++)
        if (!onlyAnswered || s.answersMap.containsKey(i))
          TestAnswerBuilder.build(s.questions[i], s.answersMap[i], s.questionDurationMap[i] ?? 0),
    ];
  }

  Future<void> _onSubmitRequested(
    ClassTestSubmitRequested event,
    Emitter<ClassTestState> emit,
  ) async {
    final current = state;
    if (current is! ClassTestInProgressState || current.isSubmitting || current.isSuccess) return;

    emit(current.copyWith(isSubmitting: true));
    _submitStarted = true;
    _pendingSave?.cancel();
    _pendingSave = null;
    final testModel = current.testModel;

    try {
      // Một phần tử cho MỖI câu của đề (câu bỏ trống: userAnswer ""). Server tự chấm lại.
      final response = await testRepository.submitTest(
        testId: _testId.isNotEmpty ? _testId : testModel.id,
        assignmentId: _assignmentId,
        durationMs: _elapsedSeconds * 1000,
        answers: _buildAnswers(current, onlyAnswered: false),
      );
      _timer?.cancel();
      _stopwatch.stop();
      emit(current.copyWith(isSubmitting: false, isSuccess: true, result: response.data));
    } on Failure catch (f) {
      if (_fatalCodes.contains(f.errorCode)) {
        _timer?.cancel();
        emit(ClassTestFailure(ClassErrorMessages.of(f), errorCode: f.errorCode));
        return;
      }
      // Lỗi tạm thời (mạng...): đưa về màn "Nộp lại", không để đồng hồ tự nộp lặp.
      // Phiên vẫn còn trên server nên mở lại cờ để thao tác sau (nếu có) không bị chặn.
      _timer?.cancel();
      _submitStarted = false;
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: ClassErrorMessages.of(f),
          currentQuestionIndex: current.questions.length,
        ),
      );
    }
  }
}
