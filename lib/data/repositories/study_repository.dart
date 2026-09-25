import 'package:mind_deck/data/data_sources/local/study_local_data_source.dart';
import 'package:mind_deck/data/data_sources/remote/study_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/study/study_session_model.dart';
import 'package:mind_deck/data/models/study/study_complete_result_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class StudyRepository {
  Future<ApiResponse<StudySessionModel>> startStudySession({
    String? deckId,
    List<String>? cardIds,
  });
  Future<ApiResponse<StudySessionModel>> resumeStudySession(String sessionId);
  Future<ApiResponse<StudySessionModel>> saveProgress(
    String sessionId,
    List<Map<String, dynamic>> reviewLogs,
  );
  Future<ApiResponse<StudyCompleteResultModel>> completeSession(
    String sessionId,
    List<Map<String, dynamic>> reviewLogs,
  );
  Future<void> syncPendingSessions();
  StudyLocalDataSource get localDataSource;
}

class StudyRepositoryImpl with ApiHandler implements StudyRepository {
  final StudyRemoteDataSource remoteDataSource;
  @override
  final StudyLocalDataSource localDataSource;

  StudyRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<ApiResponse<StudySessionModel>> startStudySession({
    String? deckId,
    List<String>? cardIds,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.startStudySession(
        deckId: deckId,
        cardIds: cardIds,
      );
      return ApiResponse<StudySessionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StudySessionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<StudySessionModel>> resumeStudySession(String sessionId) async {
    return executeApi(() async {
      final response = await remoteDataSource.resumeStudySession(sessionId);
      return ApiResponse<StudySessionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StudySessionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<StudySessionModel>> saveProgress(
    String sessionId,
    List<Map<String, dynamic>> reviewLogs,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.saveProgress(sessionId, reviewLogs);
      return ApiResponse<StudySessionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StudySessionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<StudyCompleteResultModel>> completeSession(
    String sessionId,
    List<Map<String, dynamic>> reviewLogs,
  ) async {
    final result = await executeApi(() async {
      final response = await remoteDataSource.completeSession(sessionId, reviewLogs);
      return ApiResponse<StudyCompleteResultModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StudyCompleteResultModel.fromJson(json),
      );
    });

    if (result.success) {
      final deckId = result.data?.deckId;
      if (deckId != null && deckId.isNotEmpty) {
        await localDataSource.deleteSession(deckId);
      }
      await localDataSource.deleteSession(sessionId);
    }
    return result;
  }

  @override
  Future<void> syncPendingSessions() async {
    try {
      final pendingSessions = localDataSource.getAllPendingSessions();
      if (pendingSessions.isEmpty) return;

      for (final sessionData in pendingSessions) {
        final sessionId = sessionData['sessionId'] as String? ??
            sessionData['deckId'] as String? ??
            '';
        if (sessionId.isEmpty) continue;

        final reviewLogsMap = sessionData['reviewLogs'] as Map?;
        if (reviewLogsMap == null || reviewLogsMap.isEmpty) continue;

        final reviewLogs = reviewLogsMap.values
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        if (reviewLogs.isEmpty) continue;

        final result = await saveProgress(sessionId, reviewLogs);
        if (result.success) {
          final deckId = sessionData['deckId'] as String?;
          if (deckId != null && deckId.isNotEmpty) {
            await localDataSource.deleteSession(deckId);
          }
          await localDataSource.deleteSession(sessionId);
        }
      }
    } catch (_) {
      // Chạy ngầm an toàn, không ném exception làm gián đoạn app
    }
  }
}
