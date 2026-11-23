import 'package:mind_deck/data/data_sources/remote/deck_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/deck_list_response_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class DeckRepository {
  Future<ApiResponse<DeckModel>> createDeck(Map<String, dynamic> data);
  Future<DeckListResponseModel> getDecks({
    int page = 1,
    int limit = 20,
    String? search,
    String? filter,
    String? sort,
    String? order,
  });
  Future<ApiResponse<DeckModel>> getDeckById(String id, {String? token});
  Future<ApiResponse<DeckModel>> updateDeck(String id, Map<String, dynamic> data);
  Future<ApiResponse<void>> deleteDeck(String id);
  Future<ApiResponse<void>> shareDeck(String id, {required String accessLevel});
  Future<ApiResponse<DeckModel>> cloneDeck(String id, {String? token});
  Future<ApiResponse<DeckModel>> starDeck(String id);
  Future<ApiResponse<void>> deleteDecks(List<String> ids);
  Future<ApiResponse<void>> starDecks(List<String> ids, {required bool isStarred});
}

class DeckRepositoryImpl with ApiHandler implements DeckRepository {
  final DeckRemoteDataSource remoteDataSource;

  DeckRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<DeckModel>> createDeck(Map<String, dynamic> data) async {
    return executeApi(() async {
      final response = await remoteDataSource.createDeck(data);
      return ApiResponse<DeckModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeckModel.fromJson(json),
      );
    });
  }

  @override
  Future<DeckListResponseModel> getDecks({
    int page = 1,
    int limit = 20,
    String? search,
    String? filter,
    String? sort,
    String? order,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getDecks(
        page: page,
        limit: limit,
        search: search,
        filter: filter,
        sort: sort,
        order: order,
      );
      return DeckListResponseModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<ApiResponse<DeckModel>> getDeckById(String id, {String? token}) async {
    return executeApi(() async {
      final response = await remoteDataSource.getDeckById(id, token: token);
      return ApiResponse<DeckModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeckModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<DeckModel>> updateDeck(String id, Map<String, dynamic> data) async {
    return executeApi(() async {
      final response = await remoteDataSource.updateDeck(id, data);
      return ApiResponse<DeckModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeckModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> deleteDeck(String id) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteDeck(id);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> shareDeck(String id, {required String accessLevel}) async {
    return executeApi(() async {
      final response = await remoteDataSource.shareDeck(id, accessLevel: accessLevel);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<DeckModel>> cloneDeck(String id, {String? token}) async {
    return executeApi(() async {
      final response = await remoteDataSource.cloneDeck(id, token: token);
      return ApiResponse<DeckModel>.fromJson(response.data as Map<String, dynamic>, (json) {
        final deckJson = json['deck'] as Map<String, dynamic>? ?? json;
        return DeckModel.fromJson(deckJson);
      });
    });
  }

  @override
  Future<ApiResponse<void>> deleteDecks(List<String> ids) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteDecks(ids);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> starDecks(List<String> ids, {required bool isStarred}) async {
    return executeApi(() async {
      final response = await remoteDataSource.starDecks(ids, isStarred: isStarred);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<DeckModel>> starDeck(String id) async {
    return executeApi(() async {
      final response = await remoteDataSource.starDeck(id);
      return ApiResponse<DeckModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeckModel.fromJson(json),
      );
    });
  }
}
