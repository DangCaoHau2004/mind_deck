import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class StatsRemoteDataSource {
  Future<Response> getFSRSStats(String deckId);
  Future<Response> getStatsOverview({int clientTimezoneOffset = 0, int limit = 10});
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  final Dio dio;

  StatsRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getFSRSStats(String deckId) {
    return dio.get('${ApiEndpoints.statsFSRS}$deckId/fsrs');
  }

  @override
  Future<Response> getStatsOverview({int clientTimezoneOffset = 0, int limit = 10}) {
    return dio.get(
      ApiEndpoints.statsOverview,
      queryParameters: {'client_timezone_offset': clientTimezoneOffset, 'limit': limit},
    );
  }
}
