import 'package:mind_deck/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/data/data_sources/remote/google_auth_remote_datasource.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/auth/auth_response_model.dart';
import 'package:mind_deck/data/models/auth/change_password_response_model.dart';
import 'package:mind_deck/data/models/auth/forgot_password_response_model.dart';
import 'package:mind_deck/data/models/auth/reset_password_response_model.dart';
import 'package:mind_deck/data/models/auth/token_response_model.dart';
import 'package:mind_deck/data/models/auth/verify_otp_response_model.dart';

abstract class AuthRepository {
  Future<ApiResponse<AuthResponseModel>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String dateOfBirth,
  });
  Future<ApiResponse<AuthResponseModel>> login({required String email, required String password});
  Future<ApiResponse<AuthResponseModel>?> loginGoogle();
  Future<ApiResponse<TokenResponseModel>> refreshToken({required String refreshToken});
  Future<ApiResponse<ForgotPasswordResponseModel>> forgotPassword({required String email});
  Future<ApiResponse<VerifyOtpResponseModel>> verifyOtp({
    required String email,
    required String otp,
  });
  Future<ApiResponse<ResetPasswordResponseModel>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  });
  Future<ApiResponse<ChangePasswordResponseModel>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<ApiResponse<void>> logout({String? fcmToken});
}

class AuthRepositoryImpl with ApiHandler implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final GoogleAuthRemoteDataSource googleAuthRemoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource, required this.googleAuthRemoteDataSource});

  @override
  Future<ApiResponse<AuthResponseModel>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String dateOfBirth,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
      );
      return ApiResponse<AuthResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuthResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<AuthResponseModel>> login({required String email, required String password}) {
    return executeApi(() async {
      final response = await remoteDataSource.login(email: email, password: password);
      return ApiResponse<AuthResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuthResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<AuthResponseModel>?> loginGoogle() async {
    final String? idToken = await googleAuthRemoteDataSource.getGoogleToken();
    if (idToken == null) {
      return null;
    }
    return executeApi(() async {
      final response = await remoteDataSource.loginGoogle(idToken: idToken);
      return ApiResponse<AuthResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuthResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<TokenResponseModel>> refreshToken({required String refreshToken}) async {
    return executeApi(() async {
      final response = await remoteDataSource.refreshToken(refreshToken: refreshToken);
      return ApiResponse<TokenResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TokenResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ForgotPasswordResponseModel>> forgotPassword({required String email}) async {
    return executeApi(() async {
      final response = await remoteDataSource.forgotPassword(email: email);
      return ApiResponse<ForgotPasswordResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ForgotPasswordResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<VerifyOtpResponseModel>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.verifyOtp(email: email, otp: otp);
      return ApiResponse<VerifyOtpResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => VerifyOtpResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ResetPasswordResponseModel>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.resetPassword(
        email: email,
        resetToken: resetToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return ApiResponse<ResetPasswordResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ResetPasswordResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ChangePasswordResponseModel>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return ApiResponse<ChangePasswordResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ChangePasswordResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> logout({String? fcmToken}) async {
    return executeApi(() async {
      final response = await remoteDataSource.logout(fcmToken: fcmToken);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }
}
