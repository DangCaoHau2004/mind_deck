import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/data/data_sources/remote/document_import_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';

abstract class DocumentImportRepository {
  Future<DocumentImportQuota> getQuota();

  /// Mở luồng sự kiện của lượt tải lên. Sự kiện `ping` và `type` lạ đã được lọc bỏ.
  Future<Stream<DocumentImportStreamEvent>> upload({
    required List<DocumentUploadFile> files,
    required String fileType,
    required DocumentImportOptions options,
    void Function(int sent, int total)? onSendProgress,
  });

  /// Nối lại luồng của bản nháp (server phát lại các đoạn đã có).
  Future<Stream<DocumentImportStreamEvent>> resume(String id);

  Future<DocumentImportDraft> getDraft(String id);
  Future<ApiListResponse<DocumentImportListItem>> list({int page = 1, int limit = 20});
  Future<DocumentImportDraft> saveDraft(String id, List<DraftDeck> decks);
  Future<CommitResult> commit(
    String id, {
    List<DraftDeck>? decks,
    String? folderId,
    String? folderName,
    bool? createFolder,
  });
  Future<void> delete(String id);
}

class DocumentImportRepositoryImpl with ApiHandler implements DocumentImportRepository {
  final DocumentImportRemoteDataSource remoteDataSource;

  DocumentImportRepositoryImpl({required this.remoteDataSource});

  Map<String, dynamic> _data(dynamic body) {
    final map = body as Map<String, dynamic>;
    return Map<String, dynamic>.from(map['data'] as Map);
  }

  Stream<DocumentImportStreamEvent> _events(Stream<Map<String, dynamic>> lines) {
    return lines
        .map(DocumentImportStreamEvent.fromJson)
        .where(
          (e) =>
              e.type != DocumentImportEventType.ping && e.type != DocumentImportEventType.unknown,
        );
  }

  @override
  Future<DocumentImportQuota> getQuota() {
    return executeApi(() async {
      final response = await remoteDataSource.getQuota();
      return DocumentImportQuota.fromJson(_data(response.data));
    });
  }

  @override
  Future<Stream<DocumentImportStreamEvent>> upload({
    required List<DocumentUploadFile> files,
    required String fileType,
    required DocumentImportOptions options,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return executeApi(() async {
      final lines = await remoteDataSource.upload(
        files: files,
        fields: options.toFields(fileType),
        onSendProgress: onSendProgress,
      );
      return _events(lines);
    });
  }

  @override
  Future<Stream<DocumentImportStreamEvent>> resume(String id) {
    return executeApi(() async => _events(await remoteDataSource.resume(id)));
  }

  @override
  Future<DocumentImportDraft> getDraft(String id) {
    return executeApi(() async {
      final response = await remoteDataSource.getDraft(id);
      return DocumentImportDraft.fromJson(_data(response.data));
    });
  }

  @override
  Future<ApiListResponse<DocumentImportListItem>> list({int page = 1, int limit = 20}) {
    return executeApi(() async {
      final response = await remoteDataSource.list(page: page, limit: limit);
      return ApiListResponse<DocumentImportListItem>.fromJson(
        response.data as Map<String, dynamic>,
        DocumentImportListItem.fromJson,
      );
    });
  }

  @override
  Future<DocumentImportDraft> saveDraft(String id, List<DraftDeck> decks) {
    return executeApi(() async {
      final response = await remoteDataSource.patch(id, decks.map((d) => d.toJson()).toList());
      return DocumentImportDraft.fromJson(_data(response.data));
    });
  }

  @override
  Future<CommitResult> commit(
    String id, {
    List<DraftDeck>? decks,
    String? folderId,
    String? folderName,
    bool? createFolder,
  }) {
    return executeApi(() async {
      final response = await remoteDataSource.commit(id, {
        if (decks != null) 'decks': decks.map((d) => d.toJson()).toList(),
        'folderId': ?folderId,
        'folderName': ?folderName,
        'createFolder': ?createFolder,
      });
      return CommitResult.fromJson(_data(response.data));
    });
  }

  @override
  Future<void> delete(String id) {
    return executeApi(() async {
      await remoteDataSource.delete(id);
    });
  }
}
