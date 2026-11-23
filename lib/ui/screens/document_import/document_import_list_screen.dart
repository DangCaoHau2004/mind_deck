import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/constants/document_import_error_messages.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/document_import/bloc/document_import_list_bloc.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/banner_ad_slot.dart';

class DocumentImportListScreen extends StatefulWidget {
  const DocumentImportListScreen({super.key});

  @override
  State<DocumentImportListScreen> createState() => _DocumentImportListScreenState();
}

class _DocumentImportListScreenState extends State<DocumentImportListScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<DocumentImportListBloc>().add(const DocumentImportListLoaded());
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.offset >= _scroll.position.maxScrollExtent * 0.9) {
        context.read<DocumentImportListBloc>().add(const DocumentImportListMore());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, DocumentImportListItem item) async {
    if (item.status == DocumentImportStatus.processing) {
      await context.pushNamed(AppRoute.documentImport.name, queryParameters: {'resume': item.id});
    } else {
      await context.pushNamed(AppRoute.documentImportDraft.name, pathParameters: {'id': item.id});
    }
    if (context.mounted)
      context.read<DocumentImportListBloc>().add(const DocumentImportListLoaded());
  }

  Future<void> _confirmDelete(BuildContext context, DocumentImportListItem item) async {
    final bloc = context.read<DocumentImportListBloc>();
    final processing = item.status == DocumentImportStatus.processing;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(processing ? 'Hủy lượt đang xử lý?' : 'Xóa bản nháp?'),
        content: Text(
          processing
              ? 'Lượt xử lý sẽ dừng. Lượt đã dùng vẫn tính vào số lần thử trong ngày.'
              : 'Bản nháp sẽ bị xóa và không thể khôi phục.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(processing ? 'Hủy lượt' : 'Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(DocumentImportListDeleted(item.id));
  }

  String _statusText(DocumentImportListItem item) {
    switch (item.status) {
      case DocumentImportStatus.processing:
        return item.totalChunks > 0
            ? 'Đang xử lý ${item.doneChunks}/${item.totalChunks}'
            : 'Đang xử lý';
      case DocumentImportStatus.done:
        return '${item.deckCount} bộ · ${item.cardCount} thẻ · chờ duyệt';
      case DocumentImportStatus.failed:
        return 'Lỗi: ${DocumentImportErrorMessages.ofCode(item.errorCode, null)}';
      case DocumentImportStatus.committed:
        return 'Đã lưu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: const Text('Bản nháp của tôi'),
        centerTitle: true,
      ),
      bottomNavigationBar: const BannerAdSlot(unit: AdUnit.bannerImportList),
      body: BlocConsumer<DocumentImportListBloc, DocumentImportListState>(
        listenWhen: (p, c) => c.notice != null && p.noticeId != c.noticeId,
        listener: (context, state) =>
            CustomToast.show(context, CustomToast.danger(message: state.notice!)),
        builder: (context, state) {
          if (state.status == DocumentImportListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DocumentImportListStatus.failure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Có lỗi xảy ra', style: TextStyle(color: cs.error)),
                  TextButton(
                    onPressed: () => context.read<DocumentImportListBloc>().add(
                      const DocumentImportListLoaded(),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          if (state.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có bản nháp nào.\nBản nháp tự xóa sau 30 ngày kể từ lần mở cuối.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<DocumentImportListBloc>();
              bloc.add(const DocumentImportListLoaded());
              await bloc.stream.firstWhere((s) => s.status != DocumentImportListStatus.loading);
            },
            child: ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: state.items.length,
              itemBuilder: (context, i) {
                final item = state.items[i];
                final processing = item.status == DocumentImportStatus.processing;
                return Card(
                  child: ListTile(
                    leading: processing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            item.status == DocumentImportStatus.failed
                                ? Icons.error_outline_rounded
                                : Icons.description_outlined,
                            color: item.status == DocumentImportStatus.failed ? cs.error : null,
                          ),
                    title: Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${_statusText(item)}'
                      '${item.createdAt == null ? '' : '\n${DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!)}'}',
                    ),
                    isThreeLine: item.createdAt != null,
                    trailing: IconButton(
                      icon: Icon(
                        processing ? Icons.stop_circle_outlined : Icons.delete_outline_rounded,
                      ),
                      tooltip: processing ? 'Hủy lượt' : 'Xóa',
                      onPressed: () => _confirmDelete(context, item),
                    ),
                    onTap: () => _open(context, item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
