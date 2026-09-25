import 'package:dio/dio.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/api_endpoints.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _requestsQueue = [];
  AuthInterceptor(this._storageService, this._dio);
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
    if (err.response?.statusCode == 401) {
      // 1. Nếu chưa có tiến trình refresh nào đang chạy
      if (!_isRefreshing) {
        _isRefreshing = true;
        final refreshToken = await _storageService.getRefreshToken();

        if (refreshToken == null || refreshToken.isEmpty) {
          _isRefreshing = false;
          return super.onError(err, handler);
        }

        try {
          final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data;
            final newAccessToken = data['data']?['accessToken'] as String?;
            final newRefreshToken = data['data']?['refreshToken'] as String?;

            if (newAccessToken != null) {
              // Lưu lại cả cặp token mới
              await _storageService.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken ?? refreshToken,
              );

              // Chạy lại request gốc bị lỗi
              err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(err.requestOptions);
              handler.resolve(retryResponse);

              // Mở khóa hàng đợi, chạy lại tất cả các request đang đứng chờ
              for (var queued in _requestsQueue) {
                final options = queued['options'] as RequestOptions;
                final qHandler = queued['handler'] as ErrorInterceptorHandler;

                options.headers['Authorization'] = 'Bearer $newAccessToken';
                _dio
                    .fetch(options)
                    .then(
                      (res) => qHandler.resolve(res),
                      onError: (e) => qHandler.reject(e as DioException),
                    );
              }

              // Dọn dẹp
              _requestsQueue.clear();
              _isRefreshing = false;
              return;
            }
          }

          _isRefreshing = false;
        } catch (e) {
          // Nếu refresh token thực sự lỗi/hết hạn -> Xóa token, đẩy văng ra login
          await _storageService.clearTokens();
          DI().sl<AuthBloc>().add(LoggedOut());
          for (var queued in _requestsQueue) {
            (queued['handler'] as ErrorInterceptorHandler).reject(err);
          }
          _requestsQueue.clear();
          _isRefreshing = false;
          return handler.reject(err);
        }
      } else {
        // 2. Nếu đang refresh rồi, đưa request bị lỗi 401 này vào hàng đợi đứng chờ
        _requestsQueue.add({'options': err.requestOptions, 'handler': handler});
        return;
      }
    }
    return super.onError(err, handler);
  }
}
