import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class SyncRemoteDataSource {
  Future<Response> syncDown({String? lastSyncTimestamp});
  Future<Response> syncUp({required List<Map<String, dynamic>> reviewLogs});
}

class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final Dio dio;

  SyncRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> syncDown({String? lastSyncTimestamp}) {
    return dio.post(
      ApiEndpoints.syncDown,
      queryParameters: lastSyncTimestamp != null ? {'lastSyncTimestamp': lastSyncTimestamp} : null,
    );
  }

  @override
  Future<Response> syncUp({required List<Map<String, dynamic>> reviewLogs}) {
    return dio.post(ApiEndpoints.syncUp, data: {'reviewLogs': reviewLogs});
  }
}
