import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class DashboardRemoteDataSource {
  Future<Response> getDashboardData({required int timezoneOffset});
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getDashboardData({required int timezoneOffset}) {
    return dio.get(
      ApiEndpoints.dashboard,
      queryParameters: {'client_timezone_offset': timezoneOffset},
    );
  }
}
