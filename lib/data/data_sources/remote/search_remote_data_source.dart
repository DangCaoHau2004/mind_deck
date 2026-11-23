import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class SearchRemoteDataSource {
  Future<Response> search({
    required String query,
    String type = 'all',
    String sort = 'relevance',
    int page = 1,
    int limit = 20,
  });
  Future<Response> suggest({required String query, String type = 'all'});
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio dio;

  SearchRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> search({
    required String query,
    String type = 'all',
    String sort = 'relevance',
    int page = 1,
    int limit = 20,
  }) {
    return dio.get(
      ApiEndpoints.search,
      queryParameters: {'q': query, 'type': type, 'sort': sort, 'page': page, 'limit': limit},
    );
  }

  @override
  Future<Response> suggest({required String query, String type = 'all'}) {
    return dio.get(ApiEndpoints.searchSuggest, queryParameters: {'q': query, 'type': type});
  }
}
