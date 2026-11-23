import 'package:dio/dio.dart';

import 'package:mind_deck/constants/api_endpoints.dart';

abstract class StudyRemoteDataSource {
  Future<Response> startStudySession({
    String? deckId,
    List<String>? cardIds,
    int? timeLimitSeconds,
    bool restart = false,
  });
  Future<Response> resumeStudySession(String sessionId);
  Future<Response> getActiveSessions({int? limit, String? deckId, String? type});
  Future<Response> deleteSession(String sessionId);
  Future<Response> saveProgress(String sessionId, List<Map<String, dynamic>> reviewLogs);
  Future<Response> completeSession(String sessionId, List<Map<String, dynamic>> reviewLogs);
}

class StudyRemoteDataSourceImpl implements StudyRemoteDataSource {
  final Dio dio;

  StudyRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> startStudySession({
    String? deckId,
    List<String>? cardIds,
    int? timeLimitSeconds,
    bool restart = false,
  }) {
    final Map<String, dynamic> data = {};
    if (deckId != null && deckId.isNotEmpty) {
      data['deckId'] = deckId;
    }
    if (cardIds != null && cardIds.isNotEmpty) {
      data['cardIds'] = cardIds;
    }
    if (timeLimitSeconds != null && timeLimitSeconds > 0) {
      data['timeLimitSeconds'] = timeLimitSeconds;
    }
    if (restart) {
      data['restart'] = true;
    }
    return dio.post('${ApiEndpoints.study}/start', data: data);
  }

  @override
  Future<Response> resumeStudySession(String sessionId) {
    return dio.get('${ApiEndpoints.study}/$sessionId/resume');
  }

  @override
  Future<Response> getActiveSessions({int? limit, String? deckId, String? type}) {
    return dio.get(
      ApiEndpoints.studyActive,
      queryParameters: {'limit': ?limit, 'deckId': ?deckId, 'type': ?type},
    );
  }

  @override
  Future<Response> deleteSession(String sessionId) {
    return dio.delete('${ApiEndpoints.study}/$sessionId');
  }

  @override
  Future<Response> saveProgress(String sessionId, List<Map<String, dynamic>> reviewLogs) {
    return dio.patch('${ApiEndpoints.study}/$sessionId/progress', data: {'reviewLogs': reviewLogs});
  }

  @override
  Future<Response> completeSession(String sessionId, List<Map<String, dynamic>> reviewLogs) {
    return dio.post('${ApiEndpoints.study}/$sessionId/complete', data: {'reviewLogs': reviewLogs});
  }
}
