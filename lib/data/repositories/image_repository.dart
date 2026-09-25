import 'dart:io';
import 'package:mind_deck/data/data_sources/remote/image_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class ImageRepository {
  Future<ApiResponse<Map<String, dynamic>>> uploadImage(File file);
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
}
