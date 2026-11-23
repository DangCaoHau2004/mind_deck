import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class CoinRemoteDataSource {
  Future<Response> getCoins();
  Future<Response> getHistory({int page, int limit});
}

class CoinRemoteDataSourceImpl implements CoinRemoteDataSource {
  final Dio dio;

  CoinRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getCoins() => dio.get(ApiEndpoints.coins);

  @override
  Future<Response> getHistory({int page = 1, int limit = 20}) {
    return dio.get(ApiEndpoints.coinsHistory, queryParameters: {'page': page, 'limit': limit});
  }
}
