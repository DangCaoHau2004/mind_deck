import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class ImageRemoteDataSource {
  Future<Response> uploadImage(File file);
  Future<Response> searchImages({required String query, int page = 1, int perPage = 20});
  Future<Response> selectImage(String trackingUrl);
}

class ImageRemoteDataSourceImpl implements ImageRemoteDataSource {
  final Dio dio;

  ImageRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> uploadImage(File file) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    return dio.post(
      ApiEndpoints.uploadImage,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  @override
  Future<Response> searchImages({required String query, int page = 1, int perPage = 20}) {
    return dio.get(
      ApiEndpoints.imageSearch,
      queryParameters: {'q': query, 'page': page, 'perPage': perPage},
    );
  }

  @override
  Future<Response> selectImage(String trackingUrl) {
    return dio.post(ApiEndpoints.imageSearchSelect, data: {'trackingUrl': trackingUrl});
  }
}
