import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/data/models/report_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'bloc/report_history_bloc.dart';
import 'bloc/report_history_event.dart';
import 'bloc/report_history_state.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportHistoryBloc>().add(ReportHistoryLoaded());
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange.shade600;
      case ReportStatus.processing:
        return Colors.blue.shade600;
      case ReportStatus.resolved:
        return Colors.green.shade600;
      case ReportStatus.dismissed:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Chờ xử lý';
      case ReportStatus.processing:
        return 'Đang xử lý';
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

  // Thêm hàm UI hỗ trợ lấy Icon cho từng loại Report để giao diện trực quan hơn
  IconData _getTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.contentViolation:
        return Icons.gavel_rounded;
      case ReportType.bugUi:
        return Icons.bug_report_rounded;
      case ReportType.paymentIssue:
        return Icons.payment_rounded;
      case ReportType.accountSupport:
        return Icons.manage_accounts_rounded;
      case ReportType.other:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: BlocBuilder<ReportHistoryBloc, ReportHistoryState>(
        builder: (context, state) {
          return CommonRefresh(
            onRefresh: () async {
              final bloc = context.read<ReportHistoryBloc>();
              bloc.add(ReportHistoryRefreshed());
              await bloc.stream.firstWhere((s) => !s.isRefreshing);
            },
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: colorScheme.surface.withOpacity(0.9), // Kính mờ nhẹ
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                leading: IconButton(
                  icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                centerTitle: true,
                title: Text(
                  'Lịch sử phản ánh',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () async {
                        final result = await context.pushNamed(AppRoute.reportCreate.name);
                        if (result == true && context.mounted) {
                          context.read<ReportHistoryBloc>().add(ReportHistoryRefreshed());
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_rounded, color: colorScheme.primary, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              if (state.status == ReportHistoryStatus.loading)
                SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                )
              else if (state.status == ReportHistoryStatus.failure && state.reports.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage ?? 'Có lỗi xảy ra',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () =>
                              context.read<ReportHistoryBloc>().add(ReportHistoryLoaded()),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state.reports.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.inbox_rounded, size: 64, color: colorScheme.outline),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Chưa có phản ánh nào',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mọi góp ý của bạn sẽ được hiển thị tại đây.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 32),
                  sliver: SliverList.separated(
                    itemCount: state.reports.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final report = state.reports[index];
                      final statusColor = _getStatusColor(report.status);
                      final typeIcon = _getTypeIcon(report.type);

                      return Material(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: () {
                            context.pushNamed(
                              AppRoute.reportDetail.name,
                              pathParameters: {'id': report.id},
                            );
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withOpacity(0.5),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.02),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Status & Date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: statusColor.withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        _getStatusText(report.status),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: colorScheme.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(report.createdAt.toLocal()),
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: colorScheme.outline,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Middle row: Icon, Type & Arrow
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        typeIcon,
                                        color: colorScheme.onSecondaryContainer,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getTypeText(report.type),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: colorScheme.onSurface,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            report.description,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
