import 'package:dio/dio.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/data_sources/remote/tag_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

abstract class TagRepository {
  Future<ApiListResponse<TagModel>> getTags();
  Future<ApiResponse<TagModel>> createTag({
    required String name,
    String? color,
  });
}

class TagRepositoryImpl implements TagRepository {
  final TagRemoteDataSource remoteDataSource;

  TagRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiListResponse<TagModel>> getTags() async {
    try {
      final response = await remoteDataSource.getTags();
      return ApiListResponse<TagModel>.fromJson(
        response.data,
        (json) => TagModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerFailure(
        message:
            e.response?.data?['message'] ??
            e.message ??
            'Lỗi lấy danh sách tag',
      );
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<ApiResponse<TagModel>> createTag({
    required String name,
    String? color,
  }) async {
    try {
      final data = {'name': name};
      if (color != null) data['color'] = color;

      final response = await remoteDataSource.createTag(data);
      return ApiResponse<TagModel>.fromJson(
        response.data,
        (json) => TagModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Lỗi tạo tag',
      );
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
