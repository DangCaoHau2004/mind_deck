import 'package:dio/dio.dart';

/// Interceptor giả lập độ trễ mạng thực tế (Network Latency)
class SimulateDelayInterceptor extends Interceptor {
  final int delayMs;

  const SimulateDelayInterceptor({this.delayMs = 1500});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    handler.next(options);
  }
}
