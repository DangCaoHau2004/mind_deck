import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

class NetworkErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    DioException customError = err;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        customError = DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: err.error,
          message: 'error_timeout'.tr,
        );
        break;

      case DioExceptionType.connectionError:
        customError = DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: err.error,
          message: 'error_connection'.tr,
        );
        break;

      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          customError = DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: err.error,
            message: 'error_no_internet'.tr,
          );
        }
        break;

      default:
        break;
    }

    super.onError(customError, handler);
  }
}
