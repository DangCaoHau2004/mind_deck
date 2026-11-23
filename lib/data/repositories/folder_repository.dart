import 'package:mind_deck/data/data_sources/remote/folder_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/folder_list_response_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class FolderRepository {
  Future<ApiResponse<FolderModel>> createFolder({
    required String name,
    String? description,
    String? icon,
    String? color,
    bool? isPublic,
    List<String>? tagIds,
    List<String>? deckIds,
  });
  Future<FolderListResponseModel> getFolders({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
  });

  /// Chi tiết thư mục kèm một trang bộ thẻ trong `FolderModel.decks`.
  Future<ApiResponse<FolderModel>> getFolderById(
    String id, {
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    String? token,
  });
  Future<ApiResponse<FolderModel>> updateFolder({
    required String id,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isPublic,
    List<String>? tagIds,
  });
  Future<ApiResponse<void>> deleteFolder(String id);
  Future<ApiResponse<void>> deleteFolders(List<String> ids);
  Future<ApiResponse<void>> starFolders(List<String> ids, {required bool isStarred});
  Future<ApiResponse<void>> shareFolder(String id, {required String accessLevel});
  Future<ApiResponse<FolderModel>> cloneFolder(String id, {String? token});
  Future<ApiResponse<FolderModel>> starFolder(String id);
  Future<ApiResponse<void>> addDecksToFolder(String folderId, List<String> deckIds);
  Future<ApiResponse<void>> removeDecksFromFolder(String folderId, List<String> deckIds);
}

class FolderRepositoryImpl with ApiHandler implements FolderRepository {
  final FolderRemoteDataSource remoteDataSource;

  FolderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<FolderModel>> createFolder({
    required String name,
    String? description,
    String? icon,
    String? color,
    bool? isPublic,
    List<String>? tagIds,
    List<String>? deckIds,
  }) async {
    return executeApi(() async {
      final requestData = {
        'name': name,
        'description': ?description,
        'icon': ?icon,
        'color': ?color,
        'isPublic': ?isPublic,
        'tagIds': ?tagIds,
        if (deckIds != null && deckIds.isNotEmpty) 'deckIds': deckIds,
      };
      final response = await remoteDataSource.createFolder(requestData);
      return ApiResponse<FolderModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FolderModel.fromJson(json),
      );
    });
  }

  @override
  Future<FolderListResponseModel> getFolders({
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    bool? isStarred,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getFolders(
        page: page,
        limit: limit,
        search: search,
        sort: sort,
        order: order,
        isStarred: isStarred,
      );
      return FolderListResponseModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<ApiResponse<FolderModel>> getFolderById(
    String id, {
    int page = 1,
    int limit = 20,
    String? search,
    String? sort,
    String? order,
    String? token,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getFolderById(
        id,
        page: page,
        limit: limit,
        search: search,
        sort: sort,
        order: order,
        token: token,
      );
      return ApiResponse<FolderModel>.fromJson(response.data as Map<String, dynamic>, (json) {
        final folderJson = json['folder'] as Map<String, dynamic>? ?? json;
        return FolderModel.fromJson(folderJson);
      });
    });
  }

  @override
  Future<ApiResponse<FolderModel>> updateFolder({
    required String id,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isPublic,
    List<String>? tagIds,
  }) async {
    return executeApi(() async {
      final requestData = {
        'name': ?name,
        'description': ?description,
        'icon': ?icon,
        'color': ?color,
        'isPublic': ?isPublic,
        'tagIds': ?tagIds,
      };
      final response = await remoteDataSource.updateFolder(id, requestData);
      return ApiResponse<FolderModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FolderModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> deleteFolder(String id) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteFolder(id);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> deleteFolders(List<String> ids) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteFolders(ids);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> starFolders(List<String> ids, {required bool isStarred}) async {
    return executeApi(() async {
      final response = await remoteDataSource.starFolders(ids, isStarred: isStarred);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> shareFolder(String id, {required String accessLevel}) async {
    return executeApi(() async {
      final response = await remoteDataSource.shareFolder(id, accessLevel: accessLevel);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<FolderModel>> cloneFolder(String id, {String? token}) async {
    return executeApi(() async {
      final response = await remoteDataSource.cloneFolder(id, token: token);
      return ApiResponse<FolderModel>.fromJson(response.data as Map<String, dynamic>, (json) {
        final folderJson = json['folder'] as Map<String, dynamic>? ?? json;
        return FolderModel.fromJson(folderJson);
      });
    });
  }

  @override
  Future<ApiResponse<FolderModel>> starFolder(String id) async {
    return executeApi(() async {
      final response = await remoteDataSource.starFolder(id);
      return ApiResponse<FolderModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FolderModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> addDecksToFolder(String folderId, List<String> deckIds) async {
    return executeApi(() async {
      final response = await remoteDataSource.addDecksToFolder(folderId, deckIds);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> removeDecksFromFolder(String folderId, List<String> deckIds) async {
    return executeApi(() async {
      final response = await remoteDataSource.removeDecksFromFolder(folderId, deckIds);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }
}
