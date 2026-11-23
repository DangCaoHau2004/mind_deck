import 'package:dio/dio.dart';
import 'package:mind_deck/core/server_clock.dart';

/// Ghi lại độ lệch giờ máy so với server từ header `Date` của mọi response (kể cả lỗi).
class ServerClockInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    ServerClock.syncFromHttpDate(response.headers.value('date'));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ServerClock.syncFromHttpDate(err.response?.headers.value('date'));
    handler.next(err);
  }
}
