import 'package:mind_deck/data/data_sources/remote/admin_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/report_model.dart';
import 'package:mind_deck/data/models/user_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class AdminRepository {
  Future<ApiResponse<void>> deleteFolder(
    String folderId, {
    required bool deleteContents,
  });
  Future<ApiResponse<void>> deleteDeck(String deckId);
  Future<ApiListResponse<ReportModel>> getReports({
    int page = 1,
    int limit = 10,
    ReportStatus? status,
  });
  Future<ApiResponse<void>> resolveReport(
    String reportId, {
    required ReportStatus status,
    String? resolutionNote,
  });
  Future<ApiListResponse<UserModel>> getUsers({String? search});
  Future<ApiResponse<void>> lockUser(
    String userId, {
    required int durationDays,
  });
  Future<ApiResponse<void>> unlockUser(String userId);
  Future<ApiResponse<void>> sendManualNotification(Map<String, dynamic> body);
}

class AdminRepositoryImpl with ApiHandler implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<void>> deleteFolder(
    String folderId, {
    required bool deleteContents,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteFolder(
        folderId,
        deleteContents: deleteContents,
      );
      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => {},
      );
    });
  }

  @override
  Future<ApiResponse<void>> deleteDeck(String deckId) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteDeck(deckId);
      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => {},
      );
    });
  }

  @override
  Future<ApiListResponse<ReportModel>> getReports({
    int page = 1,
    int limit = 10,
    ReportStatus? status,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getReports(
        page: page,
        limit: limit,
        status: status?.toJson(),
      );
      return ApiListResponse<ReportModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ReportModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> resolveReport(
    String reportId, {
    required ReportStatus status,
    String? resolutionNote,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.resolveReport(
        reportId,
        status: status.toJson(),
        resolutionNote: resolutionNote,
      );
      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => {},
      );
    });
  }

  @override
  Future<ApiListResponse<UserModel>> getUsers({String? search}) async {
    return executeApi(() async {
      final response = await remoteDataSource.getUsers(search: search);
      return ApiListResponse<UserModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> lockUser(
    String userId, {
    required int durationDays,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.lockUser(
        userId,
        durationDays: durationDays,
      );
      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => {},
      );
    });
  }

  @override
  Future<ApiResponse<void>> unlockUser(String userId) async {
    return executeApi(() async {
      final response = await remoteDataSource.unlockUser(userId);
      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => {},
      );
    });
  }

  @override
  Future<ApiResponse<void>> sendManualNotification(
    Map<String, dynamic> body,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.sendManualNotification(body);
      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => {},
      );
    });
  }
}
