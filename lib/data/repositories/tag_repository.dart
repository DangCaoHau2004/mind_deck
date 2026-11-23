import 'package:dio/dio.dart';
import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/data_sources/remote/tag_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';

abstract class TagRepository {
  /// Danh sách tag đã tải lần gần nhất (trong bộ nhớ); null nếu chưa tải lần nào hoặc đã bị xóa.
  List<TagModel>? get cachedTags;

  /// Luôn gọi mạng để lấy danh sách mới nhất và cập nhật bản đã nhớ.
  Future<ApiListResponse<TagModel>> getTags();

  /// Tải trước tag (vd khi vào Thư viện) để form mở ra là có sẵn; lỗi thì bỏ qua.
  Future<void> prefetch();

  /// Xóa bản đã nhớ (khi đổi tài khoản, đăng xuất).
  void clearCache();

  Future<ApiResponse<TagModel>> createTag({required String name, String? color});
}

class TagRepositoryImpl with ApiHandler implements TagRepository {
  final TagRemoteDataSource remoteDataSource;

  TagRepositoryImpl({required this.remoteDataSource});

  List<TagModel>? _cache;

  /// Lượt tải đang chạy: nhiều nơi gọi cùng lúc (hai tab Thư viện, form) thì dùng chung một lượt.
  Future<ApiListResponse<TagModel>>? _inFlight;

  /// Tăng khi xóa bản đã nhớ, để lượt tải của tài khoản cũ về muộn không ghi đè.
  int _epoch = 0;

  @override
  List<TagModel>? get cachedTags => _cache;

  @override
  Future<ApiListResponse<TagModel>> getTags() => _inFlight ??= _fetch();

  Future<ApiListResponse<TagModel>> _fetch() async {
    final epoch = _epoch;
    try {
      final response = await remoteDataSource.getTags();
      final result = ApiListResponse<TagModel>.fromJson(
        response.data,
        (json) => TagModel.fromJson(json),
      );
      if (epoch == _epoch) _cache = result.data;
      return result;
    } on DioException catch (e) {
      throw ServerFailure(
        message: e.response?.data?['message'] ?? e.message ?? 'Lỗi lấy danh sách tag',
      );
    } catch (e) {
      throw ServerFailure(message: e.toString());
    } finally {
      if (epoch == _epoch) _inFlight = null;
    }
  }

  @override
  Future<void> prefetch() async {
    try {
      await getTags();
    } catch (_) {
      // Tải trước chỉ để tăng tốc, lỗi thì form sẽ tự tải lại khi mở
    }
  }

  @override
  void clearCache() {
    _epoch++;
    _cache = null;
    _inFlight = null;
  }

  @override
  Future<ApiResponse<TagModel>> createTag({required String name, String? color}) async {
    // Dùng executeApi để giữ `errorCode` và `params` (vd 409 TAG_ALREADY_EXISTS kèm `existingTag`).
    return executeApi(() async {
      final data = {'name': name};
      if (color != null) data['color'] = color;

      final response = await remoteDataSource.createTag(data);
      final result = ApiResponse<TagModel>.fromJson(
        response.data,
        (json) => TagModel.fromJson(json),
      );
      // Tag mới vào luôn bản đã nhớ, không phải tải lại
      final created = result.data;
      if (created != null && _cache != null) _cache = [..._cache!, created];
      return result;
    });
  }
}
