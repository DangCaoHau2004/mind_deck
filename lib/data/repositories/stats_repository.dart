import 'package:mind_deck/data/data_sources/remote/stats_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/stats_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class StatsRepository {
  Future<ApiResponse<FSRSStatsModel>> getFSRSStats(String deckId);
  Future<ApiResponse<StatsOverviewModel>> getStatsOverview({
    int clientTimezoneOffset = 0,
    int limit = 10,
  });
}

class StatsRepositoryImpl with ApiHandler implements StatsRepository {
  final StatsRemoteDataSource remoteDataSource;

  StatsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<FSRSStatsModel>> getFSRSStats(String deckId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getFSRSStats(deckId);
      return ApiResponse<FSRSStatsModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FSRSStatsModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<StatsOverviewModel>> getStatsOverview({
    int clientTimezoneOffset = 0,
    int limit = 10,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getStatsOverview(
        clientTimezoneOffset: clientTimezoneOffset,
        limit: limit,
      );
      return ApiResponse<StatsOverviewModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StatsOverviewModel.fromJson(json),
      );
    });
  }
}
