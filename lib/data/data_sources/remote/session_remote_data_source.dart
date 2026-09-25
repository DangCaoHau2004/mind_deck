import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class SessionRemoteDataSource {
  Future<Response> getSessions();
  Future<Response> deleteOtherSessions();
  Future<Response> deleteSession({required String sessionId});
}

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final Dio dio;

  SessionRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getSessions() {
    return dio.get(ApiEndpoints.sessions);
  }

  @override
  Future<Response> deleteOtherSessions() {
    return dio.delete(ApiEndpoints.sessions);
  }

  @override
  Future<Response> deleteSession({required String sessionId}) {
    return dio.delete('${ApiEndpoints.sessionById}$sessionId');
  }
}
