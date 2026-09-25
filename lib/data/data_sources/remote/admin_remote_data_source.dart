import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class AdminRemoteDataSource {
  Future<Response> deleteFolder(
    String folderId, {
    required bool deleteContents,
  });
  Future<Response> deleteDeck(String deckId);
  Future<Response> getReports({int page = 1, int limit = 10, String? status});
  Future<Response> resolveReport(
    String reportId, {
    required String status,
    String? resolutionNote,
  });
  Future<Response> getUsers({String? search});
  Future<Response> lockUser(String userId, {required int durationDays});
  Future<Response> unlockUser(String userId);
  Future<Response> sendManualNotification(Map<String, dynamic> body);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> deleteFolder(
    String folderId, {
    required bool deleteContents,
  }) {
    return dio.delete(
      '${ApiEndpoints.adminFolders}$folderId',
      data: {'delete_contents': deleteContents},
    );
  }

  @override
  Future<Response> deleteDeck(String deckId) {
    return dio.delete('${ApiEndpoints.adminDecks}$deckId');
  }

  @override
  Future<Response> getReports({int page = 1, int limit = 10, String? status}) {
    return dio.get(
      ApiEndpoints.adminReports,
      queryParameters: {
        'page': page,
        'limit': limit,
        'status': ?status,
      },
    );
  }

  @override
  Future<Response> resolveReport(
    String reportId, {
    required String status,
    String? resolutionNote,
  }) {
    return dio.put(
      '${ApiEndpoints.adminResolveReport}$reportId/resolve',
      data: {
        'status': status,
        'resolutionNote': ?resolutionNote,
      },
    );
  }

  @override
  Future<Response> getUsers({String? search}) {
    return dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {'search': ?search},
    );
  }

  @override
  Future<Response> lockUser(String userId, {required int durationDays}) {
    return dio.post(
      '${ApiEndpoints.adminLockUser}$userId/lock',
      data: {'duration_days': durationDays},
    );
  }

  @override
  Future<Response> unlockUser(String userId) {
    return dio.post('${ApiEndpoints.adminUnlockUser}$userId/unlock');
  }

  @override
  Future<Response> sendManualNotification(Map<String, dynamic> body) {
    return dio.post(ApiEndpoints.adminSendNotification, data: body);
  }
}
