import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mind_deck/configs/dio/interceptors/auth_interceptor.dart';
import 'package:mind_deck/configs/dio/interceptors/logging_interceptor.dart';
import 'package:mind_deck/configs/dio/interceptors/network_error_interceptor.dart';
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
      AuthInterceptor(GetIt.instance<StorageService>(), dio),
      LoggingInterceptor(),
      NetworkErrorInterceptor(),
    ];

    dio.interceptors.addAll(interceptors);
    return dio;
  }
}
