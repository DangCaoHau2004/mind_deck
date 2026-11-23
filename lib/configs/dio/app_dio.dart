import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mind_deck/configs/dio/interceptors/auth_interceptor.dart';
import 'package:mind_deck/configs/dio/interceptors/class_access_interceptor.dart';
import 'package:mind_deck/configs/dio/interceptors/logging_interceptor.dart';
import 'package:mind_deck/configs/dio/interceptors/network_error_interceptor.dart';
import 'package:mind_deck/configs/dio/interceptors/server_clock_interceptor.dart';
import 'package:mind_deck/configs/dio/interceptors/simulate_delay_interceptor.dart';
import 'package:mind_deck/constants/api_endpoints.dart';
import 'package:mind_deck/services/storage_service.dart';

class AppDio {
  static Dio setupDio({bool enableLogging = true, bool enableConnectivityCheck = true}) {
    final int connectTimeout = 60000;
    final int receiveTimeout = 60000;
    final options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      connectTimeout: Duration(milliseconds: connectTimeout),
      receiveTimeout: Duration(milliseconds: receiveTimeout),
    );
    final dio = Dio(options);
    final List<Interceptor> interceptors = [
      // TODO: TẠM để test vệt sáng/vòng xoay khi tìm kiếm chậm (>300ms). Test xong thì comment lại.
      const SimulateDelayInterceptor(delayMs: 1500),
      ServerClockInterceptor(),
      AuthInterceptor(GetIt.instance<StorageService>(), dio),
      LoggingInterceptor(),
      ClassAccessInterceptor(),
      NetworkErrorInterceptor(),
    ];

    dio.interceptors.addAll(interceptors);
    return dio;
  }
}
