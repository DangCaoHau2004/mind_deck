import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class SharedRemoteDataSource {
  Future<Response> generateLink({required String targetType, required String targetId});
  Future<Response> revokeLink({required String targetType, required String targetId});
}

class SharedRemoteDataSourceImpl implements SharedRemoteDataSource {
  final Dio dio;

  SharedRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> generateLink({required String targetType, required String targetId}) {
    return dio.post(
      ApiEndpoints.sharedGenerateLink,
      data: {'target_type': targetType, 'target_id': targetId},
    );
  }

  @override
  Future<Response> revokeLink({required String targetType, required String targetId}) {
    return dio.post(
      ApiEndpoints.sharedRevokeLink,
      data: {'target_type': targetType, 'target_id': targetId},
    );
  }
}
