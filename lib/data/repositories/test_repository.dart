import 'package:mind_deck/data/data_sources/remote/test_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/test_attempt_model.dart';
import 'package:mind_deck/data/models/resolved_source_deck_model.dart';
import 'package:mind_deck/data/models/test_attempt_detail_model.dart';
import 'package:mind_deck/data/models/test_session_summary_model.dart';
import 'package:mind_deck/data/models/test_source_models.dart';
import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/utils/timezone_utils.dart';

abstract class TestRepository {
  /// Không truyền `classId` = đề CÁ NHÂN (chỉ `kind: auto`, chỉ thẻ của deck cá nhân của mình).
  /// Đề lớp: `classId` bắt buộc, chỉ giảng viên. Đề auto cần `cardIds` + `questionTypes`;
  /// đề manual cần `questions`. `questions` trả về của đề auto chỉ để xem trước — đề làm thật lấy từ [startTest].
  Future<ApiResponse<CustomTestModel>> generateTest({
    String? classId,
    String? kind,
    List<String>? cardIds,
    String? name,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
    Map<String, dynamic>? settings,
  });

  /// Xem thử ngẫu nhiên, không lưu (giảng viên).
  Future<ApiResponse<CustomTestModel>> previewTest({
    required String classId,
    required List<String> cardIds,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  });

  Future<ApiResponse<CustomTestModel>> getTestDetail(String testId);

  /// `locked` (đã có người làm) thì chỉ được gửi `name`, nếu không BE trả 403 `TEST_EDIT_LOCKED`.
  Future<ApiResponse<CustomTestModel>> updateTest(
    String testId, {
    String? name,
    Map<String, dynamic>? settings,
    List<String>? cardIds,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
  });

  /// Có tác dụng phụ: luôn sinh đề mới và ghi đè phiên dở. Đề lớp bắt buộc `assignmentId`.
  Future<ApiResponse<CustomTestModel>> startTest(
    String testId, {
    String? assignmentId,
    bool restart = false,
  });
  Future<ApiResponse<List<TestSessionSummary>>> getSessions({int? limit, String? type});

  Future<ApiResponse<CustomTestModel>> resumeSession(String sessionId);

  /// Có gửi `answers` thì ghi đè toàn bộ bản nháp; lưu thưa (≥ 30 giây hoặc khi đổi câu).
  Future<void> saveProgress(
    String sessionId, {
    List<Map<String, dynamic>>? answers,
    int? elapsedSeconds,
    int? currentQuestionIndex,
  });

  /// Gửi đáp án; server chấm lại bằng đề của phiên Start (phải Start trước).
  Future<ApiResponse<TestSubmitResponseModel>> submitTest({
    required String testId,
    String? assignmentId,
    int? durationMs,
    required List<Map<String, dynamic>> answers,
  });

  Future<ApiListResponse<TestAttemptModel>> getHistoryTests({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
    String? sourceId,
    String? sourceType,
    String? questionTypes,
    String? classId,
  });

  Future<ApiResponse<TestAttemptDetailModel>> getTestAttemptDetail(String attemptId);

  /// Không truyền `classId` = đề CÁ NHÂN của mình; có `classId` = kho đề của lớp (giảng viên).
  Future<ApiListResponse<CustomTestModel>> getTests({
    int page = 1,
    int limit = 20,
    String? search,
    String? classId,
  });

  Future<ApiListResponse<DeckModel>> getAvailableDecks({
    required String contextType,
    String? contextId,
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<ApiListResponse<ResolvedSourceDeck>> resolveSources({
    List<String>? folderIds,
    List<String>? deckIds,
    List<String>? tagIds,
    List<String>? classIds,
    bool onlyDue = false,
    bool onlyNew = false,
    bool countsOnly = false,
    int? limit,
    String? timezone,
  });

  Future<ApiResponse<PersonalSourcesData>> getPersonalSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
  });

  Future<ApiResponse<ClassSourcesData>> getClassSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
  });
}

class TestRepositoryImpl with ApiHandler implements TestRepository {
  final TestRemoteDataSource remoteDataSource;

  TestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<CustomTestModel>> generateTest({
    String? classId,
    String? kind,
    List<String>? cardIds,
    String? name,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
    Map<String, dynamic>? settings,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.generateTest(
        classId: classId,
        kind: kind,
        cardIds: cardIds,
        name: name,
        questionTypes: questionTypes,
        questions: questions,
        settings: settings,
      );
      return ApiResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<CustomTestModel>> previewTest({
    required String classId,
    required List<String> cardIds,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.previewTest(
        classId: classId,
        cardIds: cardIds,
        questionTypes: questionTypes,
        settings: settings,
      );
      return ApiResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<CustomTestModel>> getTestDetail(String testId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getTestDetail(testId);
      return ApiResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<CustomTestModel>> updateTest(
    String testId, {
    String? name,
    Map<String, dynamic>? settings,
    List<String>? cardIds,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.updateTest(
        testId,
        name: name,
        settings: settings,
        cardIds: cardIds,
        questionTypes: questionTypes,
        questions: questions,
      );
      return ApiResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<CustomTestModel>> startTest(
    String testId, {
    String? assignmentId,
    bool restart = false,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.startTest(
        testId,
        assignmentId: assignmentId,
        restart: restart,
      );
      return ApiResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<List<TestSessionSummary>>> getSessions({int? limit, String? type}) async {
    return executeApi(() async {
      final response = await remoteDataSource.getSessions(limit: limit, type: type);
      return ApiResponse<List<TestSessionSummary>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => [
          for (final e in json['sessions'] as List<dynamic>? ?? [])
            TestSessionSummary.fromJson(e as Map<String, dynamic>),
        ],
      );
    });
  }

  @override
  Future<ApiResponse<CustomTestModel>> resumeSession(String sessionId) async {
    return executeApi(() async {
      final response = await remoteDataSource.resumeSession(sessionId);
      return ApiResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<void> saveProgress(
    String sessionId, {
    List<Map<String, dynamic>>? answers,
    int? elapsedSeconds,
    int? currentQuestionIndex,
  }) async {
    return executeApi(() async {
      await remoteDataSource.saveProgress(
        sessionId,
        answers: answers,
        elapsedSeconds: elapsedSeconds,
        currentQuestionIndex: currentQuestionIndex,
      );
    });
  }

  @override
  Future<ApiResponse<TestSubmitResponseModel>> submitTest({
    required String testId,
    String? assignmentId,
    int? durationMs,
    required List<Map<String, dynamic>> answers,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.submitTest(
        testId: testId,
        assignmentId: assignmentId,
        durationMs: durationMs,
        answers: answers,
      );
      return ApiResponse<TestSubmitResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TestSubmitResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<TestAttemptModel>> getHistoryTests({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
    String? sourceId,
    String? sourceType,
    String? questionTypes,
    String? classId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getHistoryTests(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
        sourceId: sourceId,
        sourceType: sourceType,
        questionTypes: questionTypes,
        classId: classId,
      );
      return ApiListResponse<TestAttemptModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TestAttemptModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<TestAttemptDetailModel>> getTestAttemptDetail(String attemptId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getTestAttemptDetail(attemptId);
      return ApiResponse<TestAttemptDetailModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TestAttemptDetailModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<CustomTestModel>> getTests({
    int page = 1,
    int limit = 20,
    String? search,
    String? classId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getTests(
        page: page,
        limit: limit,
        search: search,
        classId: classId,
      );
      return ApiListResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<DeckModel>> getAvailableDecks({
    required String contextType,
    String? contextId,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getAvailableDecks(
        contextType: contextType,
        contextId: contextId,
        page: page,
        limit: limit,
        search: search,
      );
      return ApiListResponse<DeckModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeckModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ResolvedSourceDeck>> resolveSources({
    List<String>? folderIds,
    List<String>? deckIds,
    List<String>? tagIds,
    List<String>? classIds,
    bool onlyDue = false,
    bool onlyNew = false,
    bool countsOnly = false,
    int? limit,
    String? timezone,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.resolveSources(
        folderIds: folderIds,
        deckIds: deckIds,
        tagIds: tagIds,
        classIds: classIds,
        onlyDue: onlyDue,
        onlyNew: onlyNew,
        countsOnly: countsOnly,
        limit: limit,
        timezone: timezone ?? await localTimezone(),
      );
      return ApiListResponse<ResolvedSourceDeck>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ResolvedSourceDeck.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<PersonalSourcesData>> getPersonalSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getPersonalSources(
        page: page,
        limit: limit,
        search: search,
        sort: sort,
        order: order,
        isStarred: isStarred,
        filterType: filterType,
        onlyDue: onlyDue,
        onlyNew: onlyNew,
        timezone: await localTimezone(),
      );
      final resMap = response.data as Map<String, dynamic>;
      final dataMap = Map<String, dynamic>.from(resMap['data'] as Map<String, dynamic>? ?? {});
      if (resMap.containsKey('meta')) {
        dataMap['meta'] = resMap['meta'];
      }
      return ApiResponse<PersonalSourcesData>(
        success: resMap['success'] as bool? ?? false,
        code: resMap['code'] as String?,
        message: resMap['message'] as String?,
        data: PersonalSourcesData.fromJson(dataMap),
      );
    });
  }

  @override
  Future<ApiResponse<ClassSourcesData>> getClassSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getClassSources(
        page: page,
        limit: limit,
        search: search,
        sort: sort,
        order: order,
        isStarred: isStarred,
        filterType: filterType,
        onlyDue: onlyDue,
        onlyNew: onlyNew,
        timezone: await localTimezone(),
      );
      final resMap = response.data as Map<String, dynamic>;
      final dataMap = Map<String, dynamic>.from(resMap['data'] as Map<String, dynamic>? ?? {});
      if (resMap.containsKey('meta')) {
        dataMap['meta'] = resMap['meta'];
      }
      return ApiResponse<ClassSourcesData>(
        success: resMap['success'] as bool? ?? false,
        code: resMap['code'] as String?,
        message: resMap['message'] as String?,
        data: ClassSourcesData.fromJson(dataMap),
      );
    });
  }
}
