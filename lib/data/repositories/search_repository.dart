import 'package:mind_deck/data/data_sources/remote/search_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/global_search_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class SearchRepository {
  Future<ApiListResponse<GlobalSearchModel>> search({
    required String query,
    String type = 'all',
  });
}

class SearchRepositoryImpl with ApiHandler implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiListResponse<GlobalSearchModel>> search({
    required String query,
    String type = 'all',
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.search(query: query, type: type);
      return ApiListResponse<GlobalSearchModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => GlobalSearchModel.fromJson(json),
      );
    });
  }
}
