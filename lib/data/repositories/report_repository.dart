import 'package:mind_deck/data/data_sources/remote/report_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/report_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class ReportRepository {
  Future<ApiResponse<ReportModel>> createReport({
    required ReportType type,
    required ReportTargetType targetType,
    String? targetId,
    required String description,
    List<String>? attachments,
  });

  Future<ApiListResponse<ReportModel>> getReports({
    int page = 1,
    int limit = 20,
  });

  Future<ApiResponse<ReportModel>> getReportById(String id);
}

class ReportRepositoryImpl with ApiHandler implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<ReportModel>> createReport({
    required ReportType type,
    required ReportTargetType targetType,
    String? targetId,
    required String description,
    List<String>? attachments,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.createReport(
        type: type.toJson(),
        targetType: targetType.toJson(),
        targetId: targetId,
        description: description,
        attachments: attachments,
      );
      return ApiResponse<ReportModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ReportModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ReportModel>> getReports({
    int page = 1,
    int limit = 20,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getReports(
        page: page,
        limit: limit,
      );
      return ApiListResponse<ReportModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ReportModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ReportModel>> getReportById(String id) async {
    return executeApi(() async {
      final response = await remoteDataSource.getReportById(id);
      return ApiResponse<ReportModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ReportModel.fromJson(json),
      );
    });
  }
}
