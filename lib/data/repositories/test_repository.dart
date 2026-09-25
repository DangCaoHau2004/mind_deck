import 'package:mind_deck/data/data_sources/remote/test_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/test_attempt_model.dart';
import 'package:mind_deck/data/models/resolved_source_deck_model.dart';
import 'package:mind_deck/data/models/test_attempt_detail_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class TestRepository {
  Future<ApiResponse<CustomTestModel>> generateTest({
    required List<String> cardIds,
    String? name,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  });

  Future<ApiResponse<CustomTestModel>> startTest(String testId);

  Future<ApiResponse<TestSubmitResponseModel>> submitTest({
    required String testId,
    required int totalQuestions,
    required int correctAnswers,
    int? durationMs,
    String? startedAt,
    String? completedAt,
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
  });

  Future<ApiResponse<TestAttemptDetailModel>> getTestAttemptDetail(String attemptId);

  Future<ApiListResponse<CustomTestModel>> getTests({int page = 1, int limit = 20, String? search});

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
  });
}

class TestRepositoryImpl with ApiHandler implements TestRepository {
  final TestRemoteDataSource remoteDataSource;

  TestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<CustomTestModel>> generateTest({
    required List<String> cardIds,
    String? name,
    required List<String> questionTypes,
    Map<String, dynamic>? settings,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.generateTest(
        cardIds: cardIds,
        name: name,
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
  Future<ApiResponse<CustomTestModel>> startTest(String testId) async {
    return executeApi(() async {
      final response = await remoteDataSource.startTest(testId);
      return ApiResponse<CustomTestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomTestModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<TestSubmitResponseModel>> submitTest({
    required String testId,
    required int totalQuestions,
    required int correctAnswers,
    int? durationMs,
    String? startedAt,
    String? completedAt,
    required List<Map<String, dynamic>> answers,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.submitTest(
        testId: testId,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        durationMs: durationMs,
        startedAt: startedAt,
        completedAt: completedAt,
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
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getTests(page: page, limit: limit, search: search);
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
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.resolveSources(
        folderIds: folderIds,
        deckIds: deckIds,
        tagIds: tagIds,
      );
      return ApiListResponse<ResolvedSourceDeck>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ResolvedSourceDeck.fromJson(json),
      );
    });
  }
}
