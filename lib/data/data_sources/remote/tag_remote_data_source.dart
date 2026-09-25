import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class TagRemoteDataSource {
  Future<Response> getTags();
  Future<Response> createTag(Map<String, dynamic> data);
}

class TagRemoteDataSourceImpl implements TagRemoteDataSource {
  final Dio dio;

  TagRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getTags() async {
    return await dio.get(ApiEndpoints.tags);
  }

  @override
  Future<Response> createTag(Map<String, dynamic> data) async {
    return await dio.post(ApiEndpoints.tags, data: data);
  }
}
