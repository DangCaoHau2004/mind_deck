import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/data/data_sources/remote/home_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/home/home_data_model.dart';

abstract class HomeRepository {
  Future<ApiResponse<HomeDataModel>> getHomeData({String? timezone});
}

class HomeRepositoryImpl with ApiHandler implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<HomeDataModel>> getHomeData({String? timezone}) async {
    return executeApi(() async {
      final response = await remoteDataSource.getHomeData(timezone: timezone);
      return ApiResponse<HomeDataModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => HomeDataModel.fromJson(json),
      );
    });
  }
}
