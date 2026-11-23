import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/document_import/bloc/document_import_draft_bloc.dart';

class DocumentImportDraftScreen extends StatefulWidget {
  final String draftId;
  final DocumentImportDraft? initialDraft;

  const DocumentImportDraftScreen({super.key, required this.draftId, this.initialDraft});

  @override
  State<DocumentImportDraftScreen> createState() => _DocumentImportDraftScreenState();
}

class _DocumentImportDraftScreenState extends State<DocumentImportDraftScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DocumentImportDraftBloc>().add(
      DocumentImportDraftLoaded(widget.draftId, initial: widget.initialDraft),
    );
  }

  static const Map<String, String> _warningText = {
    'TEXT_TRUNCATED': 'Tài liệu quá dài, phần cuối đã bị bỏ.',
    'TABLE_ROWS_TRUNCATED': 'Bảng quá 1000 dòng, các dòng sau đã bị bỏ.',
    'CARDS_TRIMMED': 'Số thẻ vượt giới hạn nên đã bị cắt bớt.',
    'SOME_CHUNKS_FAILED': 'Một số phần của tài liệu xử lý lỗi nên bản nháp bị thiếu.',
  };

  Future<bool> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Có thay đổi chưa lưu'),
        content: const Text('Thoát bây giờ sẽ mất các chỉnh sửa chưa lưu nháp.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thoát')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final bloc = context.read<DocumentImportDraftBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bỏ bản nháp?'),
        content: const Text('Bản nháp sẽ bị xóa và không thể khôi phục.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bỏ bản nháp')),
        ],
      ),
    );
    if (ok == true) bloc.add(const DraftDiscardRequested());
  }

  Future<String?> _askText(
    BuildContext context, {
    required String title,
    String initial = '',
    String? hint,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCard(
    BuildContext context, {
    required int deck,
    int? card,
    DraftCard? current,
  }) async {
    final bloc = context.read<DocumentImportDraftBloc>();
    final front = TextEditingController(text: current?.frontText ?? '');
    final back = TextEditingController(text: current?.backText ?? '');
    final result = await showModalBottomSheet<DraftCard>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(card == null ? 'Thêm thẻ' : 'Sửa thẻ', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: front,
              maxLines: 3,
              minLines: 1,
              maxLength: DocumentImportDraftBloc.maxFront,
              decoration: const InputDecoration(labelText: 'Mặt trước'),
            ),
            TextField(
              controller: back,
              maxLines: 6,
              minLines: 2,
              maxLength: DocumentImportDraftBloc.maxBack,
              decoration: const InputDecoration(labelText: 'Mặt sau'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                DraftCard(frontText: front.text.trim(), backText: back.text.trim()),
              ),
              child: const Text('Xong'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    if (card == null) {
      bloc.add(DraftCardAdded(deck, result));
    } else {
      bloc.add(DraftCardChanged(deck, card, result));
    }
  }

  Future<void> _chooseTargetAndCommit(BuildContext context, DocumentImportDraft draft) async {
    final bloc = context.read<DocumentImportDraftBloc>();
    final problem = bloc.validateForCommit();
    if (problem != null) {
      CustomToast.show(context, CustomToast.warning(message: problem));
      return;
    }
    final defaultCreate = draft.options['createFolder'] == true;
    final target = await showModalBottomSheet<CommitTarget>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TargetSheet(
        defaultKind: defaultCreate ? CommitTargetKind.byFileName : CommitTargetKind.none,
        fileName: draft.fileName,
        deckCount: bloc.state.decks.length,
        cardCount: bloc.state.cardCount,
      ),
    );
    if (target != null) bloc.add(DraftCommitRequested(target));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<DocumentImportDraftBloc, DocumentImportDraftState>(
      listenWhen: (prev, curr) =>
          (curr.notice != null && prev.noticeId != curr.noticeId) || prev.status != curr.status,
      listener: (context, state) {
        if (state.status == DocumentImportDraftStatus.committed && state.result != null) {
          final r = state.result!;
          CustomToast.show(
            context,
            CustomToast.success(message: 'Đã tạo ${r.decks.length} bộ thẻ (${r.totalCards} thẻ).'),
          );
          if (r.folderId != null) {
            context.pushReplacementNamed(
              AppRoute.folderDetail.name,
              pathParameters: {'id': r.folderId!},
            );
          } else if (r.decks.length == 1) {
            context.pushReplacementNamed(
              AppRoute.deckDetail.name,
              pathParameters: {'id': r.decks.first.id},
            );
          } else {
            context.go(AppRoute.library.path);
          }
          return;
        }
        if (state.status == DocumentImportDraftStatus.discarded) {
          CustomToast.show(context, CustomToast.general(message: 'Đã bỏ bản nháp.'));
          if (context.canPop()) context.pop();
          return;
        }
        final notice = state.notice;
        if (notice != null) CustomToast.show(context, CustomToast.general(message: notice));
      },
      builder: (context, state) {
        final draft = state.draft;
        final ready = state.status == DocumentImportDraftStatus.ready && draft != null;
        return PopScope(
          canPop: !(ready && state.dirty),
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (await _confirmLeave(context) && context.mounted) context.pop();
          },
          child: Scaffold(
            backgroundColor: cs.surfaceContainer,
            appBar: AppBar(
              backgroundColor: cs.surface,
              title: const Text('Bản nháp bộ thẻ'),
              centerTitle: true,
              actions: [
                if (ready)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'discard') _confirmDiscard(context);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'discard', child: Text('Bỏ bản nháp')),
                    ],
                  ),
              ],
            ),
            body: switch (state.status) {
              DocumentImportDraftStatus.loading => const Center(child: CircularProgressIndicator()),
              DocumentImportDraftStatus.failure => _Message(
                text: state.errorMessage ?? 'Có lỗi xảy ra',
              ),
              DocumentImportDraftStatus.committed || DocumentImportDraftStatus.discarded =>
                const Center(child: CircularProgressIndicator()),
              DocumentImportDraftStatus.ready =>
                ready ? _buildEditor(context, state, draft) : const SizedBox(),
            },
            bottomNavigationBar: ready && draft.status != DocumentImportStatus.processing
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.dirty && !state.saving && !state.committing
                                  ? () => context.read<DocumentImportDraftBloc>().add(
                                      const DraftSaveRequested(),
                                    )
                                  : null,
                              child: state.saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Lưu nháp'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: state.committing || state.saving || state.decks.isEmpty
                                  ? null
                                  : () => _chooseTargetAndCommit(context, draft),
                              child: state.committing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Lưu thành bộ thẻ'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEditor(
    BuildContext context,
    DocumentImportDraftState state,
    DocumentImportDraft draft,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final days = draft.daysUntilExpiry();
    final processing = draft.status == DocumentImportStatus.processing;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.fileName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.decks.length} bộ thẻ · ${state.cardCount} thẻ',
                  style: theme.textTheme.bodyMedium,
                ),
                if (days != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Bản nháp tự xóa sau $days ngày nếu không mở lại.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (processing)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Bản nháp này vẫn đang được xử lý, kết quả có thể chưa đủ.'),
                ),
                TextButton(
                  onPressed: () => context.pushReplacementNamed(
                    AppRoute.documentImport.name,
                    queryParameters: {'resume': draft.id},
                  ),
                  child: const Text('Xem tiến độ'),
                ),
              ],
            ),
          ),
        if (draft.status == DocumentImportStatus.failed && draft.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(draft.errorMessage!),
          ),
        for (final w in draft.warnings)
          if (_warningText.containsKey(w))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: cs.tertiary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_warningText[w]!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
        const SizedBox(height: 12),
        if (state.decks.isEmpty)
          const _Message(text: 'Bản nháp chưa có thẻ nào.')
        else
          for (var i = 0; i < state.decks.length; i++) _deckTile(context, state, i),
      ],
    );
  }

  Widget _deckTile(BuildContext context, DocumentImportDraftState state, int i) {
    final bloc = context.read<DocumentImportDraftBloc>();
    final deck = state.decks[i];
    final cs = Theme.of(context).colorScheme;
    final tooFew = deck.cards.length < 2;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: state.decks.length == 1,
        title: Text(
          deck.name.isEmpty ? '(chưa đặt tên)' : deck.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${deck.cards.length} thẻ${tooFew ? ' · cần ít nhất 2 thẻ để lưu' : ''}',
          style: TextStyle(color: tooFew ? cs.error : null),
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final name = await _askText(context, title: 'Đổi tên bộ thẻ', initial: deck.name);
                  if (name != null && name.isNotEmpty) bloc.add(DraftDeckRenamed(i, name));
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Đổi tên'),
              ),
              TextButton.icon(
                onPressed: () => bloc.add(DraftDeckRemoved(i)),
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
                label: Text('Xóa bộ', style: TextStyle(color: cs.error)),
              ),
            ],
          ),
          for (var c = 0; c < deck.cards.length; c++)
            ListTile(
              dense: true,
              title: Text(
                deck.cards[c].frontText.isEmpty ? '(trống)' : deck.cards[c].frontText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: deck.cards[c].isComplete ? null : cs.error),
              ),
              subtitle: Text(
                deck.cards[c].backText.isEmpty ? '(trống)' : deck.cards[c].backText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Xóa thẻ',
                onPressed: () => bloc.add(DraftCardRemoved(i, c)),
              ),
              onTap: () => _editCard(context, deck: i, card: c, current: deck.cards[c]),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _editCard(context, deck: i),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm thẻ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}

/// Chọn nơi lưu các bộ thẻ.
class _TargetSheet extends StatefulWidget {
  final CommitTargetKind defaultKind;
  final String fileName;
  final int deckCount;
  final int cardCount;

  const _TargetSheet({
    required this.defaultKind,
    required this.fileName,
    required this.deckCount,
    required this.cardCount,
  });

  @override
  State<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends State<_TargetSheet> {
  late CommitTargetKind _kind = widget.defaultKind;
  final TextEditingController _name = TextEditingController();
  String? _folderId;
  String? _folderName;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final folder = await showModalBottomSheet<FolderModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _FolderPickerSheet(),
    );
    if (folder != null) {
      setState(() {
        _kind = CommitTargetKind.existingFolder;
        _folderId = folder.id;
        _folderName = folder.name;
        _error = null;
      });
    }
  }

  void _confirm() {
    switch (_kind) {
      case CommitTargetKind.byFileName:
        Navigator.pop(context, const CommitTarget.byFileName());
      case CommitTargetKind.none:
        Navigator.pop(context, const CommitTarget.none());
      case CommitTargetKind.newFolder:
        final name = _name.text.trim();
        if (name.isEmpty) {
          setState(() => _error = 'Vui lòng nhập tên thư mục.');
          return;
        }
        Navigator.pop(context, CommitTarget.newFolder(name));
      case CommitTargetKind.existingFolder:
        if (_folderId == null) {
          setState(() => _error = 'Vui lòng chọn một thư mục.');
          return;
        }
        Navigator.pop(context, CommitTarget.existing(id: _folderId!, name: _folderName ?? ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lưu ${widget.deckCount} bộ thẻ (${widget.cardCount} thẻ)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Các bộ thẻ được tạo ở chế độ riêng tư.', style: theme.textTheme.bodySmall),
            RadioGroup<CommitTargetKind>(
              groupValue: _kind,
              onChanged: (v) => setState(() {
                _kind = v ?? _kind;
                _error = null;
              }),
              child: Column(
                children: [
                  const RadioListTile<CommitTargetKind>(
                    value: CommitTargetKind.byFileName,
                    title: Text('Thư mục mới theo tên tệp'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const RadioListTile<CommitTargetKind>(
                    value: CommitTargetKind.newFolder,
                    title: Text('Thư mục mới, tự đặt tên'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_kind == CommitTargetKind.newFolder)
                    TextField(
                      controller: _name,
                      maxLength: 100,
                      decoration: const InputDecoration(hintText: 'Tên thư mục'),
                    ),
                  RadioListTile<CommitTargetKind>(
                    value: CommitTargetKind.existingFolder,
                    title: Text(
                      _folderName == null ? 'Thư mục có sẵn…' : 'Thư mục có sẵn: $_folderName',
                    ),
                    contentPadding: EdgeInsets.zero,
                    toggleable: false,
                  ),
                  if (_kind == CommitTargetKind.existingFolder)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: _pickFolder, child: const Text('Chọn thư mục')),
                    ),
                  const RadioListTile<CommitTargetKind>(
                    value: CommitTargetKind.none,
                    title: Text('Không dùng thư mục'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            FilledButton(onPressed: _confirm, child: const Text('Lưu')),
          ],
        ),
      ),
    );
  }
}

class _FolderPickerSheet extends StatefulWidget {
  const _FolderPickerSheet();

  @override
  State<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<_FolderPickerSheet> {
  late final Future<List<FolderModel>> _future = DI()
      .sl<FolderRepository>()
      .getFolders(limit: 50)
      .then((r) => r.data);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: FutureBuilder<List<FolderModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Không thể tải danh sách thư mục.'));
          }
          final folders = snap.data ?? const [];
          if (folders.isEmpty) {
            return const Center(child: Text('Bạn chưa có thư mục nào.'));
          }
          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.folder_rounded),
              title: Text(folders[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(context, folders[i]),
            ),
          );
        },
      ),
    );
  }
}
