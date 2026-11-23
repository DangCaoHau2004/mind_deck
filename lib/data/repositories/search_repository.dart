import 'package:mind_deck/data/data_sources/remote/search_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/global_search_model.dart';
import 'package:mind_deck/data/models/search_suggestion_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class SearchRepository {
  Future<GlobalSearchResponseModel> search({
    required String query,
    String type = 'all',
    String sort = 'relevance',
    int page = 1,
    int limit = 20,
  });

  Future<ApiResponse<SearchSuggestionResponseModel>> suggest({
    required String query,
    String type = 'all',
  });
}

class SearchRepositoryImpl with ApiHandler implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<GlobalSearchResponseModel> search({
    required String query,
    String type = 'all',
    String sort = 'relevance',
    int page = 1,
    int limit = 20,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.search(
        query: query,
        type: type,
        sort: sort,
        page: page,
        limit: limit,
      );
      return GlobalSearchResponseModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<ApiResponse<SearchSuggestionResponseModel>> suggest({
    required String query,
    String type = 'all',
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.suggest(query: query, type: type);
      return ApiResponse<SearchSuggestionResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => SearchSuggestionResponseModel.fromJson(json),
      );
    });
  }
}
