import 'package:mind_deck/data/data_sources/remote/discovery_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/discovery/discovery_response_model.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_content_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class DiscoveryRepository {
  Future<ApiResponse<DiscoveryResponseModel>> getDiscoveryFeed();
  Future<ApiListResponse<DiscoverySuggestedContentModel>> getPopularContent({
    int page = 1,
    int limit = 20,
  });
}

class DiscoveryRepositoryImpl with ApiHandler implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;

  DiscoveryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<DiscoveryResponseModel>> getDiscoveryFeed() async {
    return executeApi(() async {
      final response = await remoteDataSource.getDiscoveryFeed();
      return ApiResponse<DiscoveryResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DiscoveryResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<DiscoverySuggestedContentModel>> getPopularContent({
    int page = 1,
    int limit = 20,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getPopularContent(page: page, limit: limit);
      return ApiListResponse<DiscoverySuggestedContentModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DiscoverySuggestedContentModel.fromJson(json),
      );
    });
  }
}
