import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class FolderRemoteDataSource {
  Future<Response> createFolder(Map<String, dynamic> data);
  Future<Response> getFolders({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
  });
  Future<Response> getFolderById(String id, {String? token});
  Future<Response> updateFolder(String id, Map<String, dynamic> data);
  Future<Response> deleteFolder(String id, {required bool keepDecks});
  Future<Response> shareFolder(String id, {required String accessLevel});
  Future<Response> cloneFolder(String id, {String? token});
  Future<Response> starFolder(String id);
  Future<Response> addDecksToFolder(String folderId, List<String> deckIds);
  Future<Response> removeDecksFromFolder(String folderId, List<String> deckIds);
}

class FolderRemoteDataSourceImpl implements FolderRemoteDataSource {
  final Dio dio;

  FolderRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> createFolder(Map<String, dynamic> data) {
    return dio.post(ApiEndpoints.folders, data: data);
  }

  @override
  Future<Response> getFolders({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
  }) {
    return dio.get(
      ApiEndpoints.folders,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (order != null && order.isNotEmpty) 'order': order,
        'isStarred': ?isStarred,
      },
    );
  }

  @override
  Future<Response> getFolderById(String id, {String? token}) {
    return dio.get(
      '${ApiEndpoints.folderById}$id',
      queryParameters: {'token': ?token},
    );
  }

  @override
  Future<Response> updateFolder(String id, Map<String, dynamic> data) {
    return dio.put('${ApiEndpoints.folderById}$id', data: data);
  }

  @override
  Future<Response> deleteFolder(String id, {required bool keepDecks}) {
    return dio.delete('${ApiEndpoints.folderById}$id', queryParameters: {'keepDecks': keepDecks});
  }

  @override
  Future<Response> shareFolder(String id, {required String accessLevel}) {
    return dio.patch(
      '${ApiEndpoints.shareFolder}$id/share',
      data: {'accessLevel': accessLevel, 'shareMode': accessLevel},
    );
  }

  @override
  Future<Response> cloneFolder(String id, {String? token}) {
    return dio.post(
      '${ApiEndpoints.cloneFolder}$id/clone',
      queryParameters: {'token': ?token},
    );
  }

  @override
  Future<Response> starFolder(String id) {
    return dio.patch('${ApiEndpoints.folders}/$id/star');
  }

  @override
  Future<Response> addDecksToFolder(String folderId, List<String> deckIds) {
    return dio.post('${ApiEndpoints.folders}/$folderId/decks', data: {'deckIds': deckIds});
  }

  @override
  Future<Response> removeDecksFromFolder(String folderId, List<String> deckIds) {
    return dio.delete('${ApiEndpoints.folders}/$folderId/decks', data: {'deckIds': deckIds});
  }
}
