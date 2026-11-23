import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class AuthRemoteDataSource {
  Future<Response> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String dateOfBirth,
  });
  Future<Response> login({required String email, required String password});
  Future<Response> loginGoogle({required String idToken});
  Future<Response> refreshToken({required String refreshToken});
  Future<Response> forgotPassword({required String email});
  Future<Response> verifyOtp({required String email, required String otp});
  Future<Response> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Response> logout({String? fcmToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String dateOfBirth,
  }) {
    return dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
      },
    );
  }

  @override
  Future<Response> login({required String email, required String password}) {
    return dio.post(ApiEndpoints.login, data: {'email': email, 'password': password});
  }

  @override
  Future<Response> loginGoogle({required String idToken}) {
    return dio.post(ApiEndpoints.loginGoogle, data: {'idToken': idToken});
  }

  @override
  Future<Response> refreshToken({required String refreshToken}) {
    return dio.post(ApiEndpoints.refreshToken, data: {'refreshToken': refreshToken});
  }

  @override
  Future<Response> forgotPassword({required String email}) {
    return dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  @override
  Future<Response> verifyOtp({required String email, required String otp}) {
    return dio.post(ApiEndpoints.verifyOtp, data: {'email': email, 'otp': otp});
  }

  @override
  Future<Response> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) {
    return dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  @override
  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return dio.post(
      ApiEndpoints.changePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  @override
  Future<Response> logout({String? fcmToken}) {
    return dio.post(ApiEndpoints.logout, data: {'fcmToken': ?fcmToken});
  }
}
