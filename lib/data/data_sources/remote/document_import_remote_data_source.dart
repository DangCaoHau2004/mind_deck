import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';
import 'package:mind_deck/data/data_sources/remote/ndjson_stream.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';

abstract class DocumentImportRemoteDataSource {
  Future<Response> getQuota();

  /// Mở luồng NDJSON của lượt tải lên. Lỗi HTTP trước khi mở luồng ném [DioException] có `response.data` là Map.
  Future<Stream<Map<String, dynamic>>> upload({
    required List<DocumentUploadFile> files,
    required Map<String, String> fields,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<Stream<Map<String, dynamic>>> resume(String id);
  Future<Response> getDraft(String id);
  Future<Response> list({int page = 1, int limit = 20});
  Future<Response> patch(String id, List<Map<String, dynamic>> decks);
  Future<Response> commit(String id, Map<String, dynamic> body);
  Future<Response> delete(String id);
}

class DocumentImportRemoteDataSourceImpl implements DocumentImportRemoteDataSource {
  final Dio dio;

  DocumentImportRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> getQuota() => dio.get(ApiEndpoints.documentImportQuota);

  @override
  Future<Stream<Map<String, dynamic>>> upload({
    required List<DocumentUploadFile> files,
    required Map<String, String> fields,
    void Function(int sent, int total)? onSendProgress,
  }) {
    // Lặp trường `file` cho nhiều ảnh (FormData.fromMap chỉ cho một giá trị mỗi khóa).
    final formData = FormData();
    fields.forEach((k, v) => formData.fields.add(MapEntry(k, v)));
    for (final f in files) {
      formData.files.add(MapEntry('file', MultipartFile.fromBytes(f.bytes, filename: f.fileName)));
    }
    return _openStream(
      () => dio.post<ResponseBody>(
        ApiEndpoints.documentImports,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.stream,
          headers: {'Accept': 'application/x-ndjson'},
          // Luồng chạy lâu: đã có đồng hồ im lặng riêng trong parseNdjson.
          receiveTimeout: Duration.zero,
          sendTimeout: const Duration(minutes: 3),
        ),
      ),
    );
  }

  @override
  Future<Stream<Map<String, dynamic>>> resume(String id) {
    return _openStream(
      () => dio.get<ResponseBody>(
        ApiEndpoints.documentImportStream(id),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'application/x-ndjson'},
          receiveTimeout: Duration.zero,
        ),
      ),
    );
  }

  @override
  Future<Response> getDraft(String id) => dio.get(ApiEndpoints.documentImportById(id));

  @override
  Future<Response> list({int page = 1, int limit = 20}) =>
      dio.get(ApiEndpoints.documentImports, queryParameters: {'page': page, 'limit': limit});

  @override
  Future<Response> patch(String id, List<Map<String, dynamic>> decks) =>
      dio.patch(ApiEndpoints.documentImportById(id), data: {'decks': decks});

  @override
  Future<Response> commit(String id, Map<String, dynamic> body) =>
      dio.post(ApiEndpoints.documentImportCommit(id), data: body);

  @override
  Future<Response> delete(String id) => dio.delete(ApiEndpoints.documentImportById(id));

  Future<Stream<Map<String, dynamic>>> _openStream(
    Future<Response<ResponseBody>> Function() call,
  ) async {
    try {
      final response = await call();
      final body = response.data;
      if (body == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Máy chủ không trả luồng dữ liệu',
        );
      }
      return parseNdjson(body.stream);
    } on DioException catch (e) {
      // Với responseType.stream, body lỗi (400/404/409/429...) cũng là luồng byte: đọc hết và giải mã
      // thành Map để ApiHandler lấy được errorCode/params như các API thường.
      final data = e.response?.data;
      if (data is ResponseBody) {
        final raw = await _readAll(data.stream);
        Object? decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (_) {
          decoded = null;
        }
        throw DioException(
          requestOptions: e.requestOptions,
          response: Response(
            requestOptions: e.requestOptions,
            statusCode: e.response?.statusCode,
            data: decoded is Map ? Map<String, dynamic>.from(decoded) : raw,
          ),
          type: e.type,
          error: e.error,
          message: e.message,
        );
      }
      rethrow;
    }
  }

  Future<String> _readAll(Stream<Uint8List> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return utf8.decode(builder.takeBytes(), allowMalformed: true);
  }
}
