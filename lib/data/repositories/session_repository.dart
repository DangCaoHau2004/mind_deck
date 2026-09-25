import 'package:mind_deck/data/data_sources/remote/session_remote_data_source.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class SessionRepository {
  Future<List<dynamic>> getSessions();
  Future<void> deleteOtherSessions();
  Future<void> deleteSession({required String sessionId});
}

class SessionRepositoryImpl with ApiHandler implements SessionRepository {
  final SessionRemoteDataSource remoteDataSource;

  SessionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<dynamic>> getSessions() async {
    final response = await executeApi(() => remoteDataSource.getSessions());
    return response.data as List<dynamic>;
  }

  @override
  Future<void> deleteOtherSessions() async {
    await executeApi(() => remoteDataSource.deleteOtherSessions());
  }

  @override
  Future<void> deleteSession({required String sessionId}) async {
    await executeApi(
      () => remoteDataSource.deleteSession(sessionId: sessionId),
    );
  }
}
