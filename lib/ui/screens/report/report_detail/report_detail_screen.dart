import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/constants/api_endpoints.dart';
import 'package:mind_deck/data/models/report_model.dart';
import 'package:mind_deck/ui/commons/image_screens/common_image_gallery.dart';
import 'bloc/report_detail_bloc.dart';
import 'bloc/report_detail_event.dart';
import 'bloc/report_detail_state.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportDetailBloc>().add(ReportDetailLoaded(reportId: widget.reportId));
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.processing:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  /// Báo cáo từ admin luôn đã giải quyết nên hiện nhãn nguồn thay cho trạng thái.
  Color _statusColorOf(ReportModel report) =>
      report.isFromAdmin ? Colors.deepOrange : _getStatusColor(report.status);

  String _statusTextOf(ReportModel report) =>
      report.isFromAdmin ? 'Từ quản trị viên' : _getStatusText(report.status);

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Chờ xử lý';
      case ReportStatus.processing:
        return 'Đang xem xét';
      case ReportStatus.resolved:
        return 'Đã giải quyết';
      case ReportStatus.dismissed:
        return 'Từ chối';
    }
  }

  String _getTypeText(ReportType type) {
    switch (type) {
      case ReportType.contentViolation:
        return 'Vi phạm nội dung';
      case ReportType.bugUi:
        return 'Lỗi giao diện / chức năng';
      case ReportType.paymentIssue:
        return 'Vấn đề thanh toán';
      case ReportType.accountSupport:
        return 'Hỗ trợ tài khoản';
      case ReportType.other:
        return 'Khác';
    }
  }

  String _targetText(ReportModel report) {
    final type = switch (report.targetType) {
      ReportTargetType.deck => 'Bộ thẻ',
      ReportTargetType.folder => 'Thư mục',
      ReportTargetType.user => 'Người dùng',
      ReportTargetType.classroom => 'Lớp học',
      ReportTargetType.system => 'Hệ thống',
    };
    final name = report.targetName;
    return name == null || name.isEmpty ? type : '$type · $name';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: BlocBuilder<ReportDetailBloc, ReportDetailState>(
          buildWhen: (a, b) => a.report?.source != b.report?.source,
          builder: (context, state) => Text(
            state.report?.isFromAdmin == true ? 'Thông báo từ quản trị viên' : 'Chi tiết phản ánh',
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ReportDetailBloc, ReportDetailState>(
        builder: (context, state) {
          if (state.status == ReportDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ReportDetailStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? 'Có lỗi xảy ra',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  TextButton(
                    onPressed: () => context.read<ReportDetailBloc>().add(
                      ReportDetailLoaded(reportId: widget.reportId),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final report = state.report;
          if (report == null) {
            return const Center(child: Text('Không tìm thấy dữ liệu'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColorOf(report).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusTextOf(report),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _statusColorOf(report),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt.toLocal()),
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loại vấn đề:',
                        style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeText(report.type),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (report.targetType != ReportTargetType.system) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Đối tượng bị báo cáo:',
                          style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.outline),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _targetText(report),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        report.isFromAdmin ? 'Lý do:' : 'Nội dung chi tiết:',
                        style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.isFromAdmin && report.description.isEmpty
                            ? (report.resolutionNote ?? '')
                            : report.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (report.attachments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Ảnh đính kèm:',
                          style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.outline),
                        ),
                        const SizedBox(height: 8),
                        CommonImageGallery(images: report.attachments, baseUrl: ApiEndpoints.url),
                      ],
                    ],
                  ),
                ),
                if (!report.isFromAdmin &&
                    report.status != ReportStatus.pending &&
                    report.resolutionNote != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Phản hồi từ Admin',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.resolutionNote!,
                          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        ),
                        if (report.updatedAt != null &&
                            report.updatedAt!.isAfter(report.createdAt)) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Cập nhật lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(report.updatedAt!.toLocal())}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
