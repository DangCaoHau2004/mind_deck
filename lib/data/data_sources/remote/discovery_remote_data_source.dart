import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class DiscoveryRemoteDataSource {
  Future<Response> getDiscoveryFeed();
  Future<Response> getPopularContent({int page = 1, int limit = 20});
}

class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  final Dio dio;

  DiscoveryRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getDiscoveryFeed() {
    return dio.get(ApiEndpoints.discovery);
  }

  @override
  Future<Response> getPopularContent({int page = 1, int limit = 20}) {
    return dio.get(ApiEndpoints.discoveryPopular, queryParameters: {'page': page, 'limit': limit});
  }
}
