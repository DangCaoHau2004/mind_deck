import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class TestRemoteDataSource {
  /// Không truyền `classId` = đề CÁ NHÂN (chỉ `kind: auto`). Đề lớp: `classId` bắt buộc, chỉ giảng viên.
  /// Đề auto cần `cardIds` + `questionTypes`; đề manual cần `questions`.
  Future<Response> generateTest({
    String? classId,
    String? kind,
    List<String>? cardIds,
    String? name,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
    Map<String, dynamic>? settings,
  });

  /// Xem thử (không lưu): chỉ giảng viên.
  Future<Response> previewTest({
    required String classId,
    required List<String> cardIds,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  });

  Future<Response> getTestDetail(String testId);

  Future<Response> updateTest(
    String testId, {
    String? name,
    Map<String, dynamic>? settings,
    List<String>? cardIds,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
  });

  /// Có tác dụng phụ: luôn sinh đề MỚI và ghi đè phiên dở của đề này (đừng prefetch / cache).
  /// Đề lớp bắt buộc `assignmentId`; đề cá nhân thì bỏ trống.
  Future<Response> startTest(String testId, {String? assignmentId, bool restart = false});
  Future<Response> getSessions({int? limit, String? type});

  Future<Response> resumeSession(String sessionId);

  /// Có gửi `answers` thì GHI ĐÈ toàn bộ bản nháp (gửi `[]` = xóa nháp).
  Future<Response> saveProgress(
    String sessionId, {
    List<Map<String, dynamic>>? answers,
    int? elapsedSeconds,
    int? currentQuestionIndex,
  });

  /// Server chấm lại bằng đề của phiên Start; chỉ cần `qid` + `userAnswer` (+ `pairs`) mỗi câu.
  Future<Response> submitTest({
    required String testId,
    String? assignmentId,
    int? durationMs,
    required List<Map<String, dynamic>> answers,
  });

  Future<Response> getHistoryTests({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
    String? sourceId,
    String? sourceType,
    String? questionTypes,
    String? classId,
  });

  Future<Response> getTestAttemptDetail(String attemptId);

  /// Không truyền `classId` = danh sách đề CÁ NHÂN của mình; có `classId` = kho đề của lớp (giảng viên).
  Future<Response> getTests({int page = 1, int limit = 20, String? search, String? classId});

  Future<Response> getAvailableDecks({
    required String contextType,
    String? contextId,
    int page = 1,
    int limit = 20,
    String? search,
  });

  /// `classIds` lấy mọi bản sao học liệu của lớp (kể cả trong folder). Nguồn không đủ quyền bị loại im lặng.
  ///
  /// Không chọn nguồn nào = tất cả thẻ ghi được ("Học nhanh"), thẻ quá hạn lâu nhất trước; khi đó
  /// BE dùng `limit` mặc định 5 nếu không gửi. `countsOnly` chỉ trả số đếm theo deck, không có `cards`.
  Future<Response> resolveSources({
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

  Future<Response> getPersonalSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
    String? timezone,
  });

  Future<Response> getClassSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
    String? timezone,
  });
}

class TestRemoteDataSourceImpl implements TestRemoteDataSource {
  final Dio dio;

  TestRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> startTest(String testId, {String? assignmentId, bool restart = false}) {
    return dio.get(
      '${ApiEndpoints.testById}$testId/start',
      queryParameters: {'assignmentId': ?assignmentId, if (restart) 'restart': true},
    );
  }

  @override
  Future<Response> getSessions({int? limit, String? type}) {
    return dio.get(
      ApiEndpoints.testsSessionsList,
      queryParameters: {'limit': ?limit, 'type': ?type},
    );
  }

  @override
  Future<Response> resumeSession(String sessionId) {
    return dio.get('${ApiEndpoints.testsSessions}$sessionId/resume');
  }

  @override
  Future<Response> saveProgress(
    String sessionId, {
    List<Map<String, dynamic>>? answers,
    int? elapsedSeconds,
    int? currentQuestionIndex,
  }) {
    return dio.patch(
      '${ApiEndpoints.testsSessions}$sessionId/progress',
      data: {
        'answers': ?answers,
        'elapsedSeconds': ?elapsedSeconds,
        'currentQuestionIndex': ?currentQuestionIndex,
      },
    );
  }

  @override
  Future<Response> generateTest({
    String? classId,
    String? kind,
    List<String>? cardIds,
    String? name,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
    Map<String, dynamic>? settings,
  }) {
    return dio.post(
      ApiEndpoints.testsGenerate,
      data: {
        'classId': ?classId,
        'kind': ?kind,
        'cardIds': ?cardIds,
        'name': ?name,
        'questionTypes': ?questionTypes,
        'questions': ?questions,
        'settings': ?settings,
      },
    );
  }

  @override
  Future<Response> previewTest({
    required String classId,
    required List<String> cardIds,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  }) {
    return dio.post(
      ApiEndpoints.testsPreview,
      data: {
        'classId': classId,
        'cardIds': cardIds,
        'questionTypes': questionTypes,
        'settings': ?settings,
      },
    );
  }

  @override
  Future<Response> getTestDetail(String testId) {
    return dio.get('${ApiEndpoints.testById}$testId');
  }

  @override
  Future<Response> updateTest(
    String testId, {
    String? name,
    Map<String, dynamic>? settings,
    List<String>? cardIds,
    List<String>? questionTypes,
    List<Map<String, dynamic>>? questions,
  }) {
    return dio.put(
      '${ApiEndpoints.testById}$testId',
      data: {
        'name': ?name,
        'settings': ?settings,
        'cardIds': ?cardIds,
        'questionTypes': ?questionTypes,
        'questions': ?questions,
      },
    );
  }

  @override
  Future<Response> submitTest({
    required String testId,
    String? assignmentId,
    int? durationMs,
    required List<Map<String, dynamic>> answers,
  }) {
    return dio.post(
      '${ApiEndpoints.testsSubmit}$testId/submit',
      data: {'assignmentId': ?assignmentId, 'durationMs': ?durationMs, 'answers': answers},
    );
  }

  @override
  Future<Response> getHistoryTests({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
    String? sourceId,
    String? sourceType,
    String? questionTypes,
    String? classId,
  }) {
    return dio.get(
      ApiEndpoints.historyTests,
      queryParameters: {
        'page': page,
        'limit': limit,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'sourceId': ?sourceId,
        'sourceType': ?sourceType,
        'questionTypes': ?questionTypes,
        'classId': ?classId,
      },
    );
  }

  @override
  Future<Response> getTestAttemptDetail(String attemptId) {
    return dio.get('${ApiEndpoints.historyTests}/$attemptId');
  }

  @override
  Future<Response> getTests({int page = 1, int limit = 20, String? search, String? classId}) {
    return dio.get(
      ApiEndpoints.tests,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        'classId': ?classId,
      },
    );
  }

  @override
  Future<Response> getAvailableDecks({
    required String contextType,
    String? contextId,
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return dio.get(
      ApiEndpoints.testsAvailableDecks,
      queryParameters: {
        'contextType': contextType,
        if (contextId != null && contextId.isNotEmpty) 'contextId': contextId,
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
  }

  @override
  Future<Response> resolveSources({
    List<String>? folderIds,
    List<String>? deckIds,
    List<String>? tagIds,
    List<String>? classIds,
    bool onlyDue = false,
    bool onlyNew = false,
    bool countsOnly = false,
    int? limit,
    String? timezone,
  }) {
    return dio.post(
      ApiEndpoints.testsResolveSources,
      data: {
        'folderIds': folderIds ?? [],
        'deckIds': deckIds ?? [],
        'tagIds': tagIds ?? [],
        'classIds': classIds ?? [],
        if (onlyDue) 'onlyDue': true,
        if (onlyNew) 'onlyNew': true,
        if (countsOnly) 'countsOnly': true,
        'limit': ?limit,
        'timezone': ?timezone,
      },
    );
  }

  @override
  Future<Response> getPersonalSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
    String? timezone,
  }) {
    return dio.get(
      ApiEndpoints.testsPersonalSources,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (order != null && order.isNotEmpty) 'order': order,
        if (isStarred != null) 'isStarred': isStarred,
        if (filterType != null && filterType.isNotEmpty) 'filterType': filterType,
        if (onlyDue != null) 'onlyDue': onlyDue,
        if (onlyNew != null) 'onlyNew': onlyNew,
        'timezone': ?timezone,
      },
    );
  }

  @override
  Future<Response> getClassSources({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
    String? filterType,
    bool? onlyDue,
    bool? onlyNew,
    String? timezone,
  }) {
    return dio.get(
      ApiEndpoints.testsClassSources,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (order != null && order.isNotEmpty) 'order': order,
        if (isStarred != null) 'isStarred': isStarred,
        if (filterType != null && filterType.isNotEmpty) 'filterType': filterType,
        if (onlyDue != null) 'onlyDue': onlyDue,
        if (onlyNew != null) 'onlyNew': onlyNew,
        'timezone': ?timezone,
      },
    );
  }
}
