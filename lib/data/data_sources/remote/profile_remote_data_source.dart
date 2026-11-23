import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class ProfileRemoteDataSource {
  Future<Response> getProfile();
  Future<Response> updateProfile({required Map<String, dynamic> data});
  Future<Response> linkGoogle({required String token});
  Future<Response> unlinkGoogle();
  Future<Response> deleteAccount({String? password});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getProfile() {
    return dio.get(ApiEndpoints.profile);
  }

  @override
  Future<Response> updateProfile({required Map<String, dynamic> data}) {
    return dio.put(ApiEndpoints.profile, data: data);
  }

  @override
  Future<Response> linkGoogle({required String token}) {
    return dio.post(ApiEndpoints.linkGoogle, data: {'token': token});
  }

  @override
  Future<Response> unlinkGoogle() {
    return dio.delete(ApiEndpoints.unlinkGoogle);
  }

  @override
  Future<Response> deleteAccount({String? password}) {
    return dio.delete(ApiEndpoints.profile, data: password == null ? null : {'password': password});
  }
}
