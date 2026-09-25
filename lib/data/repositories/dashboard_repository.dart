import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/data/data_sources/remote/dashboard_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/dashboard_data_model.dart';

abstract class DashboardRepository {
  Future<ApiResponse<DashboardDataModel>> getDashboardData({
    required int timezoneOffset,
  });
}

class DashboardRepositoryImpl with ApiHandler implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<DashboardDataModel>> getDashboardData({
    required int timezoneOffset,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getDashboardData(
        timezoneOffset: timezoneOffset,
      );
      return ApiResponse<DashboardDataModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DashboardDataModel.fromJson(json),
      );
    });
  }
}
