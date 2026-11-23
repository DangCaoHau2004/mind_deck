import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/services/media_service.dart';
import 'package:mind_deck/data/models/document_import/document_import_models.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/document_import/bloc/document_import_bloc.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/banner_ad_slot.dart';
import 'package:mind_deck/ui/commons/ads/watch_video_coin_button.dart';

class DocumentImportScreen extends StatefulWidget {
  /// Có giá trị khi mở từ "Bản nháp của tôi" để nối lại một lượt đang xử lý.
  final String? resumeDraftId;

  const DocumentImportScreen({super.key, this.resumeDraftId});

  @override
  State<DocumentImportScreen> createState() => _DocumentImportScreenState();
}

class _DocumentImportScreenState extends State<DocumentImportScreen> {
  int _nextImageId = 0;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<DocumentImportBloc>();
    final resume = widget.resumeDraftId;
    if (resume != null && resume.isNotEmpty) {
      bloc.add(DocumentImportResumeRequested(resume));
    } else {
      bloc.add(const DocumentImportQuotaRequested());
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    final bloc = context.read<DocumentImportBloc>();
    final types = bloc.state.quota?.limits.fileTypes ?? const DocumentImportLimits().fileTypes;
    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: types);
    if (picked == null) return;
    final ext = (picked.extension ?? '').toLowerCase();
    final bytes = await picked.readAsBytes();
    if (documentImageExtensions.contains(ext)) {
      bloc.add(
        DocumentImportImagesAdded([
          PickedImage(id: _nextImageId++, name: picked.name, bytes: bytes),
        ]),
      );
      return;
    }
    bloc.add(
      DocumentImportFilePicked(
        PickedDocument(name: picked.name, extension: ext, size: bytes.length, bytes: bytes),
      ),
    );
  }

  /// Nén ngay khi chọn (cạnh dài ~2000px, JPEG ~85) để đỡ tốn bộ nhớ và dung lượng gửi.
  Future<void> _addImages(BuildContext context, {required bool camera}) async {
    final bloc = context.read<DocumentImportBloc>();
    final media = DI().sl<MediaService>();
    try {
      final List<File> files;
      if (camera) {
        final photo = await media.takePhoto(maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
        files = photo == null ? const [] : [photo];
      } else {
        files = await media.pickMultipleImages(maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
      }
      if (files.isEmpty) return;
      final images = <PickedImage>[];
      for (final f in files) {
        final name = f.path.split(RegExp(r'[\\/]')).last;
        images.add(PickedImage(id: _nextImageId++, name: name, bytes: await f.readAsBytes()));
      }
      bloc.add(DocumentImportImagesAdded(images));
    } on Failure catch (f) {
      if (context.mounted) CustomToast.show(context, CustomToast.danger(message: f.message));
    } catch (_) {
      if (context.mounted) {
        CustomToast.show(
          context,
          CustomToast.danger(message: 'Không thể lấy ảnh. Vui lòng thử lại.'),
        );
      }
    }
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát khỏi màn xử lý?'),
        content: const Text(
          'Máy chủ vẫn tiếp tục xử lý tài liệu. Bạn có thể mở lại kết quả từ "Bản nháp của tôi".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thoát')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<DocumentImportBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lượt xử lý?'),
        content: const Text(
          'Lượt xử lý sẽ dừng và bản nháp bị xóa. Lượt đã dùng vẫn tính vào số lần thử trong ngày.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy lượt')),
        ],
      ),
    );
    if (ok == true) bloc.add(const DocumentImportCancelled());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<DocumentImportBloc, DocumentImportState>(
      listenWhen: (prev, curr) =>
          (curr.notice != null && prev.noticeId != curr.noticeId) ||
          (prev.phase != DocumentImportPhase.done && curr.phase == DocumentImportPhase.done),
      listener: (context, state) {
        if (state.phase == DocumentImportPhase.done && state.completedDraft != null) {
          final draft = state.completedDraft!;
          context.pushReplacementNamed(
            AppRoute.documentImportDraft.name,
            pathParameters: {'id': draft.id},
            extra: draft,
          );
          return;
        }
        final notice = state.notice;
        if (notice != null) CustomToast.show(context, CustomToast.general(message: notice));
      },
      builder: (context, state) {
        final busy =
            state.phase == DocumentImportPhase.uploading ||
            state.phase == DocumentImportPhase.processing;
        return PopScope(
          canPop: !busy,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (await _confirmLeave(context) && context.mounted) context.pop();
          },
          child: Scaffold(
            backgroundColor: colorScheme.surfaceContainer,
            appBar: AppBar(
              backgroundColor: colorScheme.surface,
              title: const Text('Tạo thẻ từ tài liệu'),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Bản nháp của tôi',
                  icon: const Icon(Icons.inventory_2_outlined),
                  onPressed: () => context.pushNamed(AppRoute.documentImportDrafts.name),
                ),
              ],
            ),
            // Chỉ hiện lúc đang chờ AI tạo thẻ.
            bottomNavigationBar: busy ? const BannerAdSlot(unit: AdUnit.bannerImportWaiting) : null,
            body: switch (state.phase) {
              DocumentImportPhase.setup => _SetupView(
                state: state,
                onPick: () => _pickFile(context),
                onCamera: () => _addImages(context, camera: true),
                onGallery: () => _addImages(context, camera: false),
              ),
              DocumentImportPhase.uploading || DocumentImportPhase.processing => _ProgressView(
                state: state,
                onCancel: () => _confirmCancel(context),
              ),
              DocumentImportPhase.failed => _FailedView(state: state),
              DocumentImportPhase.done => const Center(child: CircularProgressIndicator()),
            },
          ),
        );
      },
    );
  }
}

// ===================== SETUP =====================

class _SetupView extends StatelessWidget {
  final DocumentImportState state;
  final VoidCallback onPick;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _SetupView({
    required this.state,
    required this.onPick,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<DocumentImportBloc>();
    final file = state.file;
    final quota = state.quota;
    final limits = quota?.limits ?? const DocumentImportLimits();
    final usesAi = state.willUseAi;
    final hasImages = state.images.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _QuotaBanner(state: state),
        if (state.pendingDraftId != null) ...[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.pending_actions_rounded),
              title: const Text('Bạn có một lượt đang xử lý dở'),
              subtitle: const Text('Nhấn để xem tiến độ hoặc kết quả'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => bloc.add(DocumentImportResumeRequested(state.pendingDraftId!)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const _SectionTitle('1. Chọn tệp hoặc ảnh'),
        const SizedBox(height: 8),
        if (!state.hasInput) ...[
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              'Chọn tệp (${limits.fileTypes.where((t) => !documentImageExtensions.contains(t)).join(', ')})',
            ),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Chụp ảnh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn ảnh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ảnh: tối đa ${limits.maxImages} ảnh mỗi lượt, đúng thứ tự trang. PDF scan: tối đa ${limits.maxScanPdfPages} trang.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ] else if (file != null)
          Card(
            child: ListTile(
              leading: Icon(file.isTable ? Icons.table_chart_rounded : Icons.description_rounded),
              title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${_formatSize(file.size)} · ${file.isTable ? 'Nhập thẳng, không tốn lượt AI' : 'Dùng AI, tốn 1 lượt'}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Bỏ tệp',
                onPressed: () => bloc.add(const DocumentImportFileCleared()),
              ),
              onTap: onPick,
            ),
          )
        else
          _ImagesPanel(state: state, limits: limits, onCamera: onCamera, onGallery: onGallery),
        if (state.hasInput) ...[
          const SizedBox(height: 20),
          const _SectionTitle('2. Cài đặt'),
          const SizedBox(height: 8),
          _OptionsForm(
            state: state,
            isTable: file?.isTable ?? false,
            extension: file?.extension ?? 'image',
          ),
          const SizedBox(height: 16),
          if (usesAi)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nội dung văn bản và ảnh trong tệp sẽ được gửi cho nhà cung cấp AI để tạo thẻ. '
                      'Đừng tải tài liệu hoặc ảnh chứa thông tin nhạy cảm.'
                      '${hasImages ? '\nChụp rõ nét, đủ sáng, chữ không bị cắt thì thẻ mới chính xác.' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ),
                ],
              ),
            ),
          if (usesAi && quota?.coins?.needsVideo == true)
            WatchVideoForCoinButton(
              placement: 'document_import',
              filled: true,
              onRewarded: (_) => bloc.add(const DocumentImportQuotaRequested()),
            )
          else
            FilledButton.icon(
              onPressed: () => bloc.add(const DocumentImportStarted()),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(_createLabel(usesAi, quota?.coins)),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Nhãn nút tạo: ghi rõ lượt này dùng lượt miễn phí hay tốn xu.
String _createLabel(bool usesAi, DocumentImportCoins? coins) {
  if (!usesAi) return 'Nhập thẻ';
  if (coins != null && coins.isCharged) return 'Tạo thẻ (tốn ${coins.price ?? 1} xu)';
  return 'Tạo thẻ (dùng 1 lượt AI)';
}

List<String> _coinLines(DocumentImportCoins coins) => [
  'Bạn có ${coins.balance} xu.',
  if (coins.isCharged) 'Hết lượt miễn phí, mỗi lượt AI tốn ${coins.price ?? 1} xu.',
  if (coins.needsVideo) 'Hết lượt miễn phí và chưa đủ xu: xem video để nhận xu.',
];

/// Danh sách ảnh đã chọn: xem, xóa, đổi thứ tự trang (nút lên/xuống), thêm ảnh.
class _ImagesPanel extends StatelessWidget {
  final DocumentImportState state;
  final DocumentImportLimits limits;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImagesPanel({
    required this.state,
    required this.limits,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<DocumentImportBloc>();
    final images = state.images;
    final canAdd = images.length < limits.maxImages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${images.length}/${limits.maxImages} ảnh · thứ tự từ trên xuống là thứ tự trang',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => bloc.add(const DocumentImportFileCleared()),
                  child: const Text('Xóa hết'),
                ),
              ],
            ),
            for (var i = 0; i < images.length; i++)
              ListTile(
                key: ValueKey(images[i].id),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(images[i].bytes, width: 48, height: 48, fit: BoxFit.cover),
                ),
                title: Text('Trang ${i + 1}'),
                subtitle: Text(_formatSize(images[i].bytes.length)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Lên',
                      icon: const Icon(Icons.arrow_upward_rounded),
                      onPressed: i == 0 ? null : () => bloc.add(DocumentImportImageMoved(i, -1)),
                    ),
                    IconButton(
                      tooltip: 'Xuống',
                      icon: const Icon(Icons.arrow_downward_rounded),
                      onPressed: i == images.length - 1
                          ? null
                          : () => bloc.add(DocumentImportImageMoved(i, 1)),
                    ),
                    IconButton(
                      tooltip: 'Xóa ảnh',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => bloc.add(DocumentImportImageRemoved(i)),
                    ),
                  ],
                ),
              ),
            if (canAdd)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Chụp thêm'),
                  ),
                  TextButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Thêm ảnh'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _QuotaBanner extends StatelessWidget {
  final DocumentImportState state;
  const _QuotaBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final quota = state.quota;

    Widget body;
    if (quota == null) {
      body = state.quotaError != null
          ? Row(
              children: [
                Expanded(
                  child: Text(state.quotaError!, style: TextStyle(color: cs.error)),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<DocumentImportBloc>().add(const DocumentImportQuotaRequested()),
                  child: const Text('Thử lại'),
                ),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(),
            );
    } else {
      final reset = quota.resetsAt == null
          ? null
          : DateFormat('HH:mm dd/MM').format(quota.resetsAt!);
      final lines = <String>[
        if (!quota.aiAvailable)
          'Máy chủ chưa bật AI: chỉ tệp csv/xlsx dùng được lúc này.'
        else
          'Còn ${quota.remainingToday}/${quota.dailyLimit} lượt AI hôm nay'
              '${reset == null ? '' : ' (làm mới lúc $reset theo giờ máy)'}.',
        'Tệp csv/xlsx không tốn lượt AI.',
        if (quota.coins != null) ..._coinLines(quota.coins!),
        if (quota.attemptsLimit > 0)
          'Số lần thử hôm nay: ${quota.attemptsToday}/${quota.attemptsLimit}.',
      ];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l, style: theme.textTheme.bodyMedium),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 20, color: cs.onTertiaryContainer),
              const SizedBox(width: 8),
              Text(
                'Tính năng thử nghiệm',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Đang dùng gói AI miễn phí nên có giới hạn số lượt mỗi ngày và đôi khi hệ thống bận.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

class _OptionsForm extends StatelessWidget {
  final DocumentImportState state;
  final bool isTable;
  final String extension;
  const _OptionsForm({required this.state, required this.isTable, required this.extension});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DocumentImportBloc>();
    final o = state.options;
    final limits = state.quota?.limits ?? const DocumentImportLimits();
    void change(DocumentImportOptions next) => bloc.add(DocumentImportOptionsChanged(next));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Chia thành bộ thẻ'),
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [
                  ('single', 'Một bộ'),
                  ('deck_count', 'Theo số bộ'),
                  ('cards_per_deck', 'Theo số thẻ mỗi bộ'),
                ])
                  ChoiceChip(
                    label: Text(m.$2),
                    selected: o.splitMode == m.$1,
                    onSelected: (_) => change(o.copyWith(splitMode: m.$1)),
                  ),
              ],
            ),
            if (o.splitMode == 'deck_count')
              _IntField(
                label: 'Số bộ thẻ (1–20)',
                value: o.deckCount,
                min: 1,
                max: 20,
                onChanged: (v) => change(o.copyWith(deckCount: v ?? 2)),
              ),
            if (o.splitMode == 'cards_per_deck')
              _IntField(
                label: 'Số thẻ mỗi bộ (2–200)',
                value: o.cardsPerDeck,
                min: 2,
                max: 200,
                onChanged: (v) => change(o.copyWith(cardsPerDeck: v ?? 20)),
              ),
            const SizedBox(height: 12),
            _IntField(
              label:
                  'Số thẻ tối đa (2–${limits.maxCards}, để trống = mặc định ${isTable ? limits.maxCards : 50})',
              value: o.maxCards,
              min: 2,
              max: limits.maxCards,
              onChanged: (v) =>
                  change(v == null ? o.copyWith(clearMaxCards: true) : o.copyWith(maxCards: v)),
            ),
            if (!isTable) ...[
              const SizedBox(height: 12),
              const _Label('Mức chi tiết'),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in const [
                    ('brief', 'Tóm lược'),
                    ('balanced', 'Cân bằng'),
                    ('detailed', 'Chi tiết'),
                  ])
                    ChoiceChip(
                      label: Text(m.$2),
                      selected: o.detailLevel == m.$1,
                      onSelected: (_) => change(o.copyWith(detailLevel: m.$1)),
                    ),
                ],
              ),
            ],
            if (extension == 'pdf') ...[
              const SizedBox(height: 12),
              _Label(
                'Khoảng trang (tối đa ${limits.maxPdfPages} trang mỗi lượt, PDF scan tối đa '
                '${limits.maxScanPdfPages} trang; để trống = cả tài liệu)',
              ),
              Row(
                children: [
                  Expanded(
                    child: _IntField(
                      label: 'Từ trang',
                      value: o.pageFrom,
                      min: 1,
                      max: 100000,
                      onChanged: (v) => change(
                        v == null ? o.copyWith(clearPageFrom: true) : o.copyWith(pageFrom: v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IntField(
                      label: 'Đến trang',
                      value: o.pageTo,
                      min: 1,
                      max: 100000,
                      onChanged: (v) =>
                          change(v == null ? o.copyWith(clearPageTo: true) : o.copyWith(pageTo: v)),
                    ),
                  ),
                ],
              ),
            ],
            if (isTable) ...[
              const SizedBox(height: 12),
              const _Label('Cột dữ liệu (tính từ 1)'),
              Row(
                children: [
                  Expanded(
                    child: _IntField(
                      label: 'Cột mặt trước',
                      value: o.frontColumn,
                      min: 1,
                      max: 1000,
                      onChanged: (v) => change(o.copyWith(frontColumn: v ?? 1)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IntField(
                      label: 'Cột mặt sau',
                      value: o.backColumn,
                      min: 1,
                      max: 1000,
                      onChanged: (v) => change(o.copyWith(backColumn: v ?? 2)),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dòng đầu là tiêu đề'),
                value: o.hasHeader,
                onChanged: (v) => change(o.copyWith(hasHeader: v)),
              ),
              if (extension == 'xlsx')
                TextFormField(
                  initialValue: o.sheet,
                  decoration: const InputDecoration(
                    labelText: 'Tên hoặc số thứ tự sheet (để trống = sheet đầu)',
                  ),
                  onChanged: (v) => change(
                    v.trim().isEmpty ? o.copyWith(clearSheet: true) : o.copyWith(sheet: v),
                  ),
                ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gom vào một thư mục mới khi lưu'),
              subtitle: const Text('Có thể đổi lại khi lưu'),
              value: o.createFolder,
              onChanged: (v) => change(o.copyWith(createFolder: v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntField extends StatefulWidget {
  final String label;
  final int? value;
  final int min;
  final int max;
  final ValueChanged<int?> onChanged;

  const _IntField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label, isDense: true),
        onChanged: (text) {
          final v = int.tryParse(text.trim());
          if (v == null) {
            widget.onChanged(null);
          } else {
            widget.onChanged(v.clamp(widget.min, widget.max));
          }
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

String _formatSize(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

// ===================== PROGRESS =====================

class _ProgressView extends StatelessWidget {
  final DocumentImportState state;
  final VoidCallback onCancel;
  const _ProgressView({required this.state, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uploading = state.phase == DocumentImportPhase.uploading;
    final total = state.totalChunks;
    final fraction = total > 0 ? (state.doneChunks / total).clamp(0.0, 1.0) : null;
    final lastCards = state.chunks.expand((c) => c.cards).toList().reversed.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          state.fileName ?? '',
          style: theme.textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        if (uploading) ...[
          Text('Đang tải lên… ${(state.uploadProgress * 100).round()}%'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: state.uploadProgress > 0 ? state.uploadProgress : null),
          const SizedBox(height: 8),
          Text(
            'Sau khi tải xong, tài liệu sẽ được xử lý.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
        ] else ...[
          Text(
            total > 0
                ? '${state.fileType == 'image' ? 'Đang đọc ảnh' : 'Đang xử lý đoạn'} ${state.doneChunks}/$total'
                : 'Đang xử lý tài liệu…',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: fraction),
          const SizedBox(height: 12),
          Text('Đã tạo ${state.cardCount} thẻ', style: theme.textTheme.bodyLarge),
          if (state.failedChunks > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${state.failedChunks} phần bị lỗi, bản nháp sẽ thiếu phần đó (vẫn dùng được các phần còn lại).',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ),
          if (state.reconnectAttempt > 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mất kết nối, đang thử nối lại (${state.reconnectAttempt}/${DocumentImportBloc.reconnectDelays.length})…',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          if (lastCards.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Thẻ vừa tạo', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final c in lastCards)
              Card(
                child: ListTile(
                  dense: true,
                  title: Text(c.frontText, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(c.backText, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
          const SizedBox(height: 20),
          Text(
            'Bạn có thể thoát: máy chủ vẫn xử lý tiếp, mở lại từ "Bản nháp của tôi".',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Hủy lượt này'),
          ),
        ],
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  final DocumentImportState state;
  const _FailedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasPartial = state.cardCount > 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(
          state.errorIsBusy ? Icons.hourglass_top_rounded : Icons.error_outline_rounded,
          size: 48,
          color: state.errorIsBusy ? cs.tertiary : cs.error,
        ),
        const SizedBox(height: 12),
        Text(
          state.errorMessage ?? 'Có lỗi xảy ra.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (state.errorIsBusy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Lỗi này do hệ thống, bạn không bị trừ lượt.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ),
        if (hasPartial && state.draftId != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: () => context.pushReplacementNamed(
                AppRoute.documentImportDraft.name,
                pathParameters: {'id': state.draftId!},
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: Text('Xem ${state.cardCount} thẻ đã tạo được'),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.read<DocumentImportBloc>().add(const DocumentImportReset()),
          child: const Text('Quay lại'),
        ),
      ],
    );
  }
}
