import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';

abstract class Failure {
  final String message;
  final String errorCode;
  final int? statusCode;

  /// Dữ liệu kèm theo lỗi từ BE (`params`), vd `duplicates`, `max`, `required`.
  final Map<String, dynamic>? params;
  Failure({
    required this.message,
    this.errorCode = AppErrorCodes.unknownError,
    this.statusCode,
    this.params,
  });
  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure({
    required super.message,
    super.errorCode = AppErrorCodes.systemInternalError,
    super.statusCode,
    super.params,
  });
}

class NetworkFailure extends Failure {
  NetworkFailure({String? message, String? errorCode, super.statusCode})
    : super(
        message: message ?? 'error_no_internet'.tr,
        errorCode: errorCode ?? AppErrorCodes.networkError,
      );
}

class ValidationFailure extends Failure {
  ValidationFailure(String message)
    : super(message: message, errorCode: AppErrorCodes.validationError);
}

class CacheFailure extends Failure {
  CacheFailure({String? message, String? errorCode, super.statusCode})
    : super(message: message ?? 'error_cache'.tr, errorCode: errorCode ?? AppErrorCodes.cacheError);
}

class UnknownFailure extends Failure {
  UnknownFailure({String? message, String? errorCode, super.statusCode})
    : super(
        message: message ?? 'error_unknown'.tr,
        errorCode: errorCode ?? AppErrorCodes.unknownError,
      );
}

class PermissionFailure extends Failure {
  PermissionFailure({String? message, String? errorCode, super.statusCode})
    : super(
        message: message ?? 'error_permission'.tr,
        errorCode: errorCode ?? AppErrorCodes.permissionDenied,
      );
}
