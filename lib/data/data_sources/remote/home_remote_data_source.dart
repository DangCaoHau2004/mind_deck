import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class HomeRemoteDataSource {
  Future<Response> getHomeData({String? timezone});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getHomeData({String? timezone}) {
    return dio.get(ApiEndpoints.home, queryParameters: {'timezone': ?timezone});
  }
}
