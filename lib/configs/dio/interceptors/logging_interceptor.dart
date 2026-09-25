import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logPrint('\n*** API Request - Start ***');
    printKV('URI', options.uri);
    printKV('METHOD', options.method);

    logPrint('HEADERS:');
    options.headers.forEach((key, v) {
      printKV(' - $key', v);
    });

    logPrint('BODY:');
    if (options.data is FormData) {
      final formData = options.data as FormData;
      printKV(' - FormData Fields', formData.fields);
      printKV(' - FormData Files', formData.files.map((e) => e.key).toList());
    } else {
      printAll(options.data);
    }

    logPrint('*** API Request - End ***\n');

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logPrint('\n*** Api Error - Start ***');
    logPrint('URI: ${err.requestOptions.uri}');

    if (err.response != null) {
      logPrint('STATUS CODE: ${err.response?.statusCode}');
      printKV('REDIRECT', err.response?.realUri ?? '');
      logPrint('BODY:');
      printAll(err.response?.data);
    }
    logPrint('ERROR MESSAGE: ${err.message}');
    logPrint('*** Api Error - End ***\n');

    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logPrint('\n*** Api Response - Start ***');
    printKV('URI', response.requestOptions.uri);
    printKV('STATUS CODE', response.statusCode ?? '');

    logPrint('BODY:');
    printAll(response.data);

    logPrint('*** Api Response - End ***\n');

    handler.next(response);
  }

  void printKV(String key, Object? v) {
    logPrint('$key: $v');
  }

  void printAll(dynamic msg) {
    if (msg == null || msg.toString().isEmpty) {
      logPrint('No body data');
      return;
    }

    try {
      dynamic jsonObj = msg;
      if (msg is String) {
        jsonObj = jsonDecode(msg);
      }

      final encoder = const JsonEncoder.withIndent('  ');
      final prettyString = encoder.convert(jsonObj);
      logPrint(prettyString);
    } catch (e) {
      logPrint(msg.toString());
    }
  }

  void logPrint(String s) {
    // Thay debugPrint bằng developer.log
    developer.log(s, name: 'API_LOG');
  }
}
