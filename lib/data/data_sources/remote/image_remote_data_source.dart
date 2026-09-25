import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class ImageRemoteDataSource {
  Future<Response> uploadImage(File file);
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
}
