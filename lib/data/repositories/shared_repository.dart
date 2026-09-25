import 'package:mind_deck/data/data_sources/remote/shared_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class SharedRepository {
  Future<ApiResponse<String>> generateLink({
    required String targetType,
    required String targetId,
  });
  Future<ApiResponse<void>> revokeLink({
    required String targetType,
    required String targetId,
  });
}

class SharedRepositoryImpl with ApiHandler implements SharedRepository {
  final SharedRemoteDataSource remoteDataSource;

  SharedRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<String>> generateLink({
    required String targetType,
    required String targetId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.generateLink(
        targetType: targetType,
        targetId: targetId,
      );
      final data = response.data as Map<String, dynamic>;
      final shareToken = data['data']['shareToken'] as String;
      return ApiResponse<String>.fromJson(data, (_) => shareToken);
    });
  }

  @override
  Future<ApiResponse<void>> revokeLink({
    required String targetType,
    required String targetId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.revokeLink(
        targetType: targetType,
        targetId: targetId,
      );
      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) {},
      );
    });
  }
}
