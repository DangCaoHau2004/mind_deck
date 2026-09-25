import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class TestRemoteDataSource {
  Future<Response> generateTest({
    required List<String> cardIds,
    String? name,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  });

  Future<Response> startTest(String testId);

  Future<Response> submitTest({
    required String testId,
    required int totalQuestions,
    required int correctAnswers,
    int? durationMs,
    String? startedAt,
    String? completedAt,
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
  });

  Future<Response> getTestAttemptDetail(String attemptId);

  Future<Response> getTests({int page = 1, int limit = 20, String? search});

  Future<Response> getAvailableDecks({
    required String contextType,
    String? contextId,
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Response> resolveSources({
    List<String>? folderIds,
    List<String>? deckIds,
    List<String>? tagIds,
  });
}

class TestRemoteDataSourceImpl implements TestRemoteDataSource {
  final Dio dio;

  TestRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> startTest(String testId) {
    return dio.get('/tests/$testId/start');
  }

  @override
  Future<Response> generateTest({
    required List<String> cardIds,
    String? name,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  }) {
    return dio.post(
      ApiEndpoints.testsGenerate,
      data: {
        'cardIds': cardIds,
        'name': ?name,
        'questionTypes': questionTypes,
        'settings': ?settings,
      },
    );
  }

  @override
  Future<Response> submitTest({
    required String testId,
    required int totalQuestions,
    required int correctAnswers,
    int? durationMs,
    String? startedAt,
    String? completedAt,
    required List<Map<String, dynamic>> answers,
  }) {
    return dio.post(
      '${ApiEndpoints.testsSubmit}$testId/submit',
      data: {
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'durationMs': ?durationMs,
        'startedAt': ?startedAt,
        'completedAt': ?completedAt,
        'answers': answers,
      },
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
      },
    );
  }

  @override
  Future<Response> getTestAttemptDetail(String attemptId) {
    return dio.get('${ApiEndpoints.historyTests}/$attemptId');
  }

  @override
  Future<Response> getTests({int page = 1, int limit = 20, String? search}) {
    return dio.get(
      ApiEndpoints.tests,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
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
  }) {
    return dio.post(
      ApiEndpoints.testsResolveSources,
      data: {
        'folderIds': folderIds ?? [],
        'deckIds': deckIds ?? [],
        'tagIds': tagIds ?? [],
      },
    );
  }
}
