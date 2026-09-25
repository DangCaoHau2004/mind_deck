import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class ReportRemoteDataSource {
  Future<Response> createReport({
    required String type,
    required String targetType,
    String? targetId,
    required String description,
    List<String>? attachments,
  });

  Future<Response> getReports({int page = 1, int limit = 20});

  Future<Response> getReportById(String id);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final Dio dio;

  ReportRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> createReport({
    required String type,
    required String targetType,
    String? targetId,
    required String description,
    List<String>? attachments,
  }) {
    return dio.post(
      ApiEndpoints.reports,
      data: {
        'type': type,
        'targetType': targetType,
        'targetId': ?targetId,
        'description': description,
        'attachments': ?attachments,
      },
    );
  }

  @override
  Future<Response> getReports({int page = 1, int limit = 20}) {
    return dio.get(ApiEndpoints.reports, queryParameters: {'page': page, 'limit': limit});
  }

  @override
  Future<Response> getReportById(String id) {
    return dio.get('${ApiEndpoints.reportById}$id');
  }
}
