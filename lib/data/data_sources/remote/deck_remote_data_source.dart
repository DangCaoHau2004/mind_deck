import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';
import 'package:mind_deck/utils/timezone_utils.dart';

abstract class DeckRemoteDataSource {
  Future<Response> createDeck(Map<String, dynamic> data);
  Future<Response> getDecks({
    int page = 1,
    int limit = 20,
    String? search,
    String? filter,
    String? sort,
    String? order,
  });
  Future<Response> getDeckById(String id, {String? token});
  Future<Response> updateDeck(String id, Map<String, dynamic> data);
  Future<Response> deleteDeck(String id);
  Future<Response> shareDeck(String id, {required String accessLevel});
  Future<Response> cloneDeck(String id, {String? token});
  Future<Response> starDeck(String id);
  Future<Response> deleteDecks(List<String> ids);
  Future<Response> starDecks(List<String> ids, {required bool isStarred});
}

class DeckRemoteDataSourceImpl implements DeckRemoteDataSource {
  final Dio dio;

  DeckRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> createDeck(Map<String, dynamic> data) {
    return dio.post(ApiEndpoints.decks, data: data);
  }

  @override
  Future<Response> getDecks({
    int page = 1,
    int limit = 20,
    String? search,
    String? filter,
    String? sort,
    String? order,
  }) async {
    return dio.get(
      ApiEndpoints.decks,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (order != null && order.isNotEmpty) 'order': order,
        'timezone': ?await localTimezone(),
      },
    );
  }

  @override
  Future<Response> getDeckById(String id, {String? token}) {
    return dio.get('${ApiEndpoints.deckById}$id', queryParameters: {'token': ?token});
  }

  @override
  Future<Response> updateDeck(String id, Map<String, dynamic> data) {
    return dio.put('${ApiEndpoints.deckById}$id', data: data);
  }

  @override
  Future<Response> deleteDeck(String id) {
    return dio.delete('${ApiEndpoints.deckById}$id');
  }

  @override
  Future<Response> shareDeck(String id, {required String accessLevel}) {
    return dio.patch('${ApiEndpoints.shareDeck}$id/share', data: {'accessLevel': accessLevel});
  }

  @override
  Future<Response> cloneDeck(String id, {String? token}) {
    return dio.post('${ApiEndpoints.cloneDeck}$id/clone', queryParameters: {'token': ?token});
  }

  @override
  Future<Response> deleteDecks(List<String> ids) {
    return dio.delete(ApiEndpoints.decks, data: {'ids': ids});
  }

  @override
  Future<Response> starDecks(List<String> ids, {required bool isStarred}) {
    return dio.patch('${ApiEndpoints.decks}/star', data: {'ids': ids, 'isStarred': isStarred});
  }

  @override
  Future<Response> starDeck(String id) {
    return dio.patch('${ApiEndpoints.starDeck}$id/star');
  }
}
