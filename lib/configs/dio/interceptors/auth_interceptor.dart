import 'package:dio/dio.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/api_endpoints.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/constants/app_error_codes.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;
  final Dio _refreshDio;
  static const String _retriedKey = 'authRetried';
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _requestsQueue = [];
  AuthInterceptor(this._storageService, this._dio, {Dio? refreshDio})
    : _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 do nhập sai mật khẩu hiện tại (vd xóa tài khoản) không phải phiên hết hạn nên không làm mới token.
    if (_isWrongCurrentPassword(err)) return super.onError(err, handler);

    // Request đã chạy lại bằng token mới mà vẫn 401 thì trả lỗi, không làm mới lần nữa.
    if (err.response?.statusCode == 401 && err.requestOptions.extra[_retriedKey] != true) {
      // Nếu đang refresh rồi, đưa request bị lỗi 401 này vào hàng đợi đứng chờ
      if (_isRefreshing) {
        _requestsQueue.add({'options': err.requestOptions, 'handler': handler});
        return;
      }

      _isRefreshing = true;
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _isRefreshing = false;
        return super.onError(err, handler);
      }

      String? newAccessToken;
      try {
        newAccessToken = await _refreshTokens(refreshToken);
      } catch (e) {
        // Mất mạng, timeout, 5xx, 429: phiên vẫn có thể còn tốt nên giữ token, không đăng xuất.
        // Trả lỗi của lệnh làm mới (không phải 401 gốc) để nơi gọi biết đây là lỗi tạm.
        if (!_isSessionRejected(e)) {
          final cause = e is DioException ? e : err;
          for (var queued in _requestsQueue) {
            (queued['handler'] as ErrorInterceptorHandler).reject(cause);
          }
          _requestsQueue.clear();
          _isRefreshing = false;
          return handler.reject(cause);
        }

        // Refresh token bị từ chối thật -> Xóa token, đẩy văng ra login
        await _storageService.clearTokens();
        DI().sl<AuthBloc>().add(LoggedOut(failure: _accountLockedFailure(e)));
        for (var queued in _requestsQueue) {
          (queued['handler'] as ErrorInterceptorHandler).reject(err);
        }
        _requestsQueue.clear();
        _isRefreshing = false;
        return handler.reject(err);
      }

      // Mở khóa trước khi chạy lại để request chạy lại có lỗi 401 không tự chờ chính nó.
      final queuedRequests = List.of(_requestsQueue);
      _requestsQueue.clear();
      _isRefreshing = false;

      if (newAccessToken == null) {
        for (var queued in queuedRequests) {
          (queued['handler'] as ErrorInterceptorHandler).reject(err);
        }
        return super.onError(err, handler);
      }

      // Lỗi của request chạy lại là lỗi của chính nó, token vẫn tốt nên không đăng xuất.
      for (var queued in queuedRequests) {
        _retry(
          queued['options'] as RequestOptions,
          newAccessToken,
          queued['handler'] as ErrorInterceptorHandler,
        );
      }
      await _retry(err.requestOptions, newAccessToken, handler);
      return;
    }
    return super.onError(err, handler);
  }

  /// Làm mới và lưu cặp token mới. Trả null nếu BE không trả access token.
  Future<String?> _refreshTokens(String refreshToken) async {
    final response = await _refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    if (response.statusCode != 200 && response.statusCode != 201) return null;

    final data = response.data;
    final newAccessToken = data['data']?['accessToken'] as String?;
    final newRefreshToken = data['data']?['refreshToken'] as String?;
    if (newAccessToken == null) return null;

    await _storageService.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken ?? refreshToken,
    );
    return newAccessToken;
  }

  Future<void> _retry(
    RequestOptions options,
    String accessToken,
    ErrorInterceptorHandler handler,
  ) async {
    options.headers['Authorization'] = 'Bearer $accessToken';
    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await _dio.fetch(options));
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  /// BE đã trả lời và từ chối lệnh làm mới (4xx trừ 429). Mất mạng, timeout, 5xx, 429 là lỗi tạm.
  bool _isSessionRejected(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode;
    return status != null && status < 500 && status != 429;
  }

  bool _isWrongCurrentPassword(DioException err) {
    final data = err.response?.data;
    return err.response?.statusCode == 401 &&
        data is Map &&
        data['errorCode'] == AppErrorCodes.authCurrentPasswordIncorrect;
  }

  /// Lỗi khi làm mới token mà tài khoản bị khóa (423); các lỗi khác trả null.
  Failure? _accountLockedFailure(Object error) {
    if (error is! DioException) return null;
    final response = error.response;
    final data = response?.data;
    final body = data is Map ? data : const {};
    final params = body['params'];
    final failure = ServerFailure(
      message: body['message']?.toString() ?? '',
      errorCode: body['errorCode']?.toString() ?? AppErrorCodes.unknownError,
      statusCode: response?.statusCode,
      params: params is Map<String, dynamic> ? params : null,
    );
    return failure.isAccountLocked ? failure : null;
  }
}
