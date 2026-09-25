import 'package:mind_deck/data/data_sources/remote/sync_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/sync_models.dart';
import 'package:mind_deck/data/models/review_log_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class SyncRepository {
  Future<ApiResponse<SyncDownResponseModel>> syncDown({
    String? lastSyncTimestamp,
  });
  Future<ApiResponse<SyncUpResponseModel>> syncUp({
    required List<ReviewLogModel> reviewLogs,
  });
}

class SyncRepositoryImpl with ApiHandler implements SyncRepository {
  final SyncRemoteDataSource remoteDataSource;

  SyncRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<SyncDownResponseModel>> syncDown({
    String? lastSyncTimestamp,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.syncDown(
        lastSyncTimestamp: lastSyncTimestamp,
      );
      return ApiResponse<SyncDownResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => SyncDownResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<SyncUpResponseModel>> syncUp({
    required List<ReviewLogModel> reviewLogs,
  }) async {
    return executeApi(() async {
      final reviewLogsPayload = reviewLogs
          .map(
            (log) => {
              'cardId': log.cardId,
              'grade': log.grade,
              'durationMs': log.durationMs,
              'reviewTimestamp': log.reviewTimestamp.toIso8601String(),
            },
          )
          .toList();

      final response = await remoteDataSource.syncUp(
        reviewLogs: reviewLogsPayload,
      );
      return ApiResponse<SyncUpResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => SyncUpResponseModel.fromJson(json),
      );
    });
  }
}
