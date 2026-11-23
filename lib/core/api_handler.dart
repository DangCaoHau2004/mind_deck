import 'dart:async';
import 'package:dio/dio.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'failures.dart';

mixin ApiHandler {
  Future<T> executeApi<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String errorMessage = 'error_server'.tr;
      String errorCode = AppErrorCodes.unknownError;
      Map<String, dynamic>? params;

      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          errorMessage = data['message']?.toString() ?? 'error_server'.tr;
          errorCode =
              data['errorCode']?.toString() ??
              data['code']?.toString() ??
              AppErrorCodes.unknownError;
          final rawParams = data['params'];
          if (rawParams is Map<String, dynamic>) params = rawParams;
        }
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure(
          message: e.message,
          errorCode: AppErrorCodes.timeoutError,
          statusCode: statusCode,
        );
      }

      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        throw NetworkFailure(
          message: e.message,
          errorCode: AppErrorCodes.networkError,
          statusCode: statusCode,
        );
      }

      throw ServerFailure(
        message: errorMessage,
        errorCode: errorCode,
        statusCode: statusCode,
        params: params,
      );
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw UnknownFailure(message: e.toString(), errorCode: AppErrorCodes.unknownError);
    }
  }
}
