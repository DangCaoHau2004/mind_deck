import 'dart:io';
import 'package:mind_deck/data/data_sources/remote/image_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/data/models/image_search_model.dart';

abstract class ImageRepository {
  Future<ApiResponse<Map<String, dynamic>>> uploadImage(File file);
  Future<ApiResponse<ImageSearchPage>> searchImages({required String query, int page = 1});

  /// Báo đã chọn ảnh theo quy định của kho ảnh.
  Future<void> selectImage(String trackingUrl);
}

class ImageRepositoryImpl with ApiHandler implements ImageRepository {
  final ImageRemoteDataSource remoteDataSource;

  ImageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<Map<String, dynamic>>> uploadImage(File file) async {
    return executeApi(() async {
      final response = await remoteDataSource.uploadImage(file);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
    });
  }

  @override
  Future<ApiResponse<ImageSearchPage>> searchImages({required String query, int page = 1}) async {
    return executeApi(() async {
      final response = await remoteDataSource.searchImages(query: query, page: page);
      return ApiResponse<ImageSearchPage>.fromJson(
        response.data as Map<String, dynamic>,
        ImageSearchPage.fromJson,
      );
    });
  }

  @override
  Future<void> selectImage(String trackingUrl) async {
    return executeApi(() async {
      await remoteDataSource.selectImage(trackingUrl);
    });
  }
}
