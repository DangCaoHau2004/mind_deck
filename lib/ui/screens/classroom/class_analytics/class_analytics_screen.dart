import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_state.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/widgets/analytics_attempt_sheets.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/widgets/analytics_pick_sheets.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/widgets/score_distribution_card.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';

/// Nhãn / màu trạng thái bài giao dùng chung trong màn thống kê.
String _statusLabel(String status) => switch (status) {
  'scheduled' => 'Chưa đến giờ',
  'pending' => 'Chưa làm',
  'in_progress' => 'Đang làm dở',
  'completed' => 'Đã hoàn thành',
  'overdue' => 'Quá hạn',
  'skipped' => 'Không giao',
  _ => status,
};

Color _statusColor(String status) => switch (status) {
  'scheduled' => Colors.blueGrey.shade400,
  'pending' => Colors.grey.shade500,
  'in_progress' => Colors.amber.shade600,
  'completed' => Colors.green.shade500,
  'overdue' => Colors.red.shade500,
  'skipped' => Colors.brown.shade300,
  _ => Colors.grey.shade500,
};

class AnalyticsScreen extends StatelessWidget {
  final ClassModel classData;

  const AnalyticsScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<ClassAnalyticsBloc>()
            ..add(ClassAnalyticsLoaded(classData.id, isTeacher: classData.isTeacher)),
      child: _AnalyticsView(classData: classData),
    );
  }
}

class _AnalyticsView extends StatefulWidget {
  final ClassModel classData;

  const _AnalyticsView({required this.classData});

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTeacher = widget.classData.isTeacher;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Báo cáo",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        // Học viên chỉ có số liệu của chính mình nên không cần tab "Tổng hợp Lớp".
        bottom: isTeacher
            ? PreferredSize(
                preferredSize: const Size.fromHeight(66),
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "Tổng hợp Lớp"),
                      Tab(text: "Cá nhân hóa"),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: BlocBuilder<ClassAnalyticsBloc, ClassAnalyticsState>(
        builder: (context, state) {
          if (state.status == ClassAnalyticsStatus.initial ||
              (state.status == ClassAnalyticsStatus.loading &&
                  state.members.isEmpty &&
                  state.personalDeckHealth == null &&
                  !state.isRefreshing)) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          if (state.status == ClassAnalyticsStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? 'Có lỗi xảy ra',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.read<ClassAnalyticsBloc>().add(
                        ClassAnalyticsLoaded(widget.classData.id, isTeacher: isTeacher),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!isTeacher) {
            return _buildPersonalTab(context, state, colorScheme, false);
          }

          return TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [
              _buildClassOverviewTab(context, state, colorScheme),
              _buildPersonalTab(context, state, colorScheme, true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClassOverviewTab(
    BuildContext context,
    ClassAnalyticsState state,
    ColorScheme colorScheme,
  ) {
    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<ClassAnalyticsBloc>();
        bloc.add(ClassAnalyticsRefreshed(widget.classData.id));
        await bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (state.selectedAssignment != null) ...[
                _buildAssignmentProgressCard(context, state, colorScheme),
                const SizedBox(height: 16),
              ],
              if (state.scoreDistribution != null) ...[
                ScoreDistributionCard(distribution: state.scoreDistribution!),
                const SizedBox(height: 16),
              ],
              _buildDeckHealthCard(
                context,
                state.classDeckHealth,
                "SỨC KHỎE BỘ THẺ",
                "TOÀN LỚP",
                colorScheme,
              ),
              const SizedBox(height: 16),
              _buildHardestCardsCard(
                context,
                state.classHardestCards,
                "THẺ KHÓ (TỬ HUYỆT)",
                "TOÀN LỚP",
                colorScheme,
                showStudentCount: true,
              ),
              const SizedBox(height: 16),
              _buildSwitchToPersonalCard(colorScheme),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalTab(
    BuildContext context,
    ClassAnalyticsState state,
    ColorScheme colorScheme,
    bool isAdminOrTutor,
  ) {
    final theme = Theme.of(context);
    final hasData =
        (state.personalDeckHealth != null && !state.personalDeckHealth!.isEmpty) ||
        state.personalHardestCards.isNotEmpty ||
        state.personalReviewWorkload.any((w) => w.count > 0) ||
        state.personalAssignments.isNotEmpty;

    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<ClassAnalyticsBloc>();
        bloc.add(ClassAnalyticsRefreshed(widget.classData.id));
        await bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (isAdminOrTutor && state.members.isNotEmpty)
                _buildMemberSelector(context, state, colorScheme)
              else
                _buildCurrentUserHeader(colorScheme),
              const SizedBox(height: 16),
              if (hasData) ...[
                if (state.personalAssignments.isNotEmpty) ...[
                  _buildStudentResultsCard(context, state, colorScheme),
                  const SizedBox(height: 16),
                ],
                _buildDeckHealthCard(
                  context,
                  state.personalDeckHealth,
                  "SỨC KHỎE BỘ THẺ",
                  "CÁ NHÂN",
                  colorScheme,
                ),
                const SizedBox(height: 16),
                _buildHardestCardsCard(
                  context,
                  state.personalHardestCards,
                  "THẺ KHÓ (TỬ HUYỆT)",
                  "CÁ NHÂN",
                  colorScheme,
                ),
                const SizedBox(height: 16),
                _buildReviewWorkloadCard(
                  context,
                  state.personalReviewWorkload,
                  "LỊCH ÔN 7 NGÀY TỚI",
                  "CÁ NHÂN",
                  colorScheme,
                ),
                const SizedBox(height: 24),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.chart_pie,
                            size: 80,
                            color: colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Chưa có dữ liệu học tập",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Hoàn thành các bài tập để xem thống kê",
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  /// Kết quả của học viên đang chọn trên từng bài giao (giảng viên xem).
  Widget _buildStudentResultsCard(
    BuildContext context,
    ClassAnalyticsState state,
    ColorScheme colorScheme,
  ) {
    final student = state.selectedMember;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, color: Colors.purple.shade400, size: 22),
              const SizedBox(width: 8),
              Text(
                "KẾT QUẢ BÀI GIAO",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in state.personalAssignments)
            _buildStudentResultRow(context, item, student),
        ],
      ),
    );
  }

  Widget _buildStudentResultRow(
    BuildContext context,
    StudentAssignmentResult item,
    ClassMemberModel? student,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = item.result;
    final color = _statusColor(r.status);
    final canOpen = item.isTest && r.attemptsCount > 0 && student != null;

    final String summary;
    if (item.isTest) {
      final score = r.bestScore ?? r.scorePercentage;
      summary = score == null
          ? _statusLabel(r.status)
          : '${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)}%';
    } else if (r.targetCount != null) {
      summary = '${r.progressCount ?? 0}/${r.targetCount} thẻ';
    } else {
      summary = _statusLabel(r.status);
    }

    return InkWell(
      onTap: canOpen
          ? () => showStudentAttemptsSheet(
              context,
              classId: widget.classData.id,
              assignmentId: item.assignmentId,
              userId: r.userId.isNotEmpty ? r.userId : student.userId,
              studentName: r.fullName.isNotEmpty ? r.fullName : student.fullName,
            )
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              item.isTest ? Icons.quiz_rounded : Icons.menu_book_rounded,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      _statusLabel(r.status),
                      if (item.isTest && r.attemptsCount > 0) '${r.attemptsCount} lượt',
                      if (r.isLate) 'nộp muộn',
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Text(
              summary,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            if (canOpen) Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelector(
    BuildContext context,
    ClassAnalyticsState state,
    ColorScheme colorScheme,
  ) {
    final selected = state.selectedMember;
    final selectedName = selected == null ? '' : analyticsMemberName(selected);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final bloc = context.read<ClassAnalyticsBloc>();
          final picked = await showMemberPickerSheet(
            context,
            classId: widget.classData.id,
            selectedUserId: state.selectedMember?.userId,
          );
          if (picked != null && picked.userId != state.selectedMember?.userId) {
            bloc.add(ClassAnalyticsMemberSelected(widget.classData.id, picked));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  selectedName.isNotEmpty ? selectedName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  selectedName.isNotEmpty ? selectedName : 'Chọn học viên',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserHeader(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ĐANG PHÂN TÍCH DỮ LIỆU CỦA",
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Bạn (Học viên)",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentProgressCard(
    BuildContext context,
    ClassAnalyticsState state,
    ColorScheme colorScheme,
  ) {
    final isTest = state.selectedAssignment?.type == AssignmentType.gradedTest;

    // BE luôn trả đủ 6 trạng thái; ghi nhận theo thứ tự hiển thị.
    final counts = <String, int>{for (final p in state.assignmentProgress) p.status: p.count};
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    // Hiển thị bài học: luôn có "Đã hoàn thành" và "Đang làm dở"; bài kiểm tra không có "đang làm dở".
    const order = ['completed', 'in_progress', 'pending', 'overdue', 'scheduled', 'skipped'];
    final alwaysShow = isTest ? const ['completed'] : const ['completed', 'in_progress'];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 6, color: Colors.purple.shade400),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insert_chart_rounded, color: Colors.purple.shade400, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "TIẾN ĐỘ BÀI TẬP",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.assignments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final bloc = context.read<ClassAnalyticsBloc>();
                        final picked = await showAssignmentPickerSheet(
                          context,
                          classId: widget.classData.id,
                          selectedAssignmentId: state.selectedAssignment?.id,
                        );
                        if (picked != null && picked.id != state.selectedAssignment?.id) {
                          bloc.add(ClassAnalyticsAssignmentSelected(widget.classData.id, picked));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.selectedAssignment?.title ?? 'Chọn bài giao',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(Icons.expand_more_rounded, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (total == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Chưa có học viên nào được giao bài này',
                        style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 16,
                      width: double.infinity,
                      color: colorScheme.surfaceVariant,
                      child: Row(
                        children: [
                          for (final status in order)
                            if ((counts[status] ?? 0) > 0)
                              Flexible(
                                flex: counts[status]!,
                                child: Container(color: _statusColor(status)),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final status in order)
                    if ((counts[status] ?? 0) > 0 || alwaysShow.contains(status)) ...[
                      _buildProgressRow(
                        context,
                        state,
                        status,
                        counts[status] ?? 0,
                        isTest: isTest,
                        note: status == 'skipped' ? 'Học viên không còn thẻ phù hợp để giao' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    ClassAnalyticsState state,
    String status,
    int count, {
    required bool isTest,
    String? note,
  }) {
    final mainColor = _statusColor(status);
    final label = _statusLabel(status);
    final icon = switch (status) {
      'completed' => Icons.check_circle_rounded,
      'in_progress' => Icons.timelapse_rounded,
      'overdue' => Icons.warning_rounded,
      'scheduled' => Icons.schedule_rounded,
      'skipped' => Icons.remove_circle_outline_rounded,
      _ => Icons.hourglass_empty_rounded,
    };

    return InkWell(
      onTap: count > 0 && state.selectedAssignment != null
          ? () {
              _showDrillDownSheet(
                context,
                state.selectedAssignment!.id,
                status,
                label,
                mainColor,
                isTest,
              );
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: mainColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mainColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: mainColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: mainColor, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  if (note != null)
                    Text(
                      note,
                      style: TextStyle(color: mainColor.withValues(alpha: 0.8), fontSize: 11),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: mainColor, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Text(
                    "$count hs",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrillDownSheet(
    BuildContext context,
    String assignmentId,
    String status,
    String label,
    Color color,
    bool isTest,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DrillDownSheet(
          classId: widget.classData.id,
          assignmentId: assignmentId,
          status: status,
          label: label,
          color: color,
          isTest: isTest,
        );
      },
    );
  }

  Widget _buildDeckHealthCard(
    BuildContext context,
    DeckHealthResponse? health,
    String title,
    String badge,
    ColorScheme colorScheme,
  ) {
    if (health == null || health.isEmpty) return const SizedBox.shrink();

    // Thứ tự theo vòng đời của thẻ (FSRS).
    final entries = <({String state, String label, Color color})>[
      (state: 'new', label: 'Mới', color: Colors.blue.shade500),
      (state: 'learning', label: 'Đang học', color: Colors.orange.shade500),
      (state: 'review', label: 'Cần ôn', color: Colors.amber.shade500),
      (state: 'relearning', label: 'Học lại', color: Colors.red.shade400),
      (state: 'mastered', label: 'Đã thuộc', color: Colors.green.shade500),
    ];
    final total = health.totalPairs;

    String percent(double? v) => v == null ? '--' : '${(v * 100).round()}%';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_large_rounded, color: Colors.blue.shade500, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 16,
              width: double.infinity,
              color: colorScheme.surfaceVariant,
              child: Row(
                children: [
                  for (final e in entries)
                    if (health.countOf(e.state) > 0)
                      Flexible(
                        flex: health.countOf(e.state),
                        child: Container(color: e.color),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              for (final e in entries)
                _buildLegendItem(
                  e.color,
                  '${e.label} · ${health.countOf(e.state)}'
                  ' (${total == 0 ? 0 : (health.countOf(e.state) * 100 / total).round()}%)',
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHealthStat(colorScheme, 'Độ nhớ TB', percent(health.avgRetrievability)),
              _buildHealthStat(
                colorScheme,
                'Độ bền TB',
                health.avgStabilityDays == null
                    ? '--'
                    : '${health.avgStabilityDays!.toStringAsFixed(1)} ngày',
              ),
              _buildHealthStat(
                colorScheme,
                'Nguy cơ quên',
                health.learnedPairs <= 0 ? '--' : '${(health.atRiskRatio * 100).round()}%',
                hint: '< ${(health.atRiskThreshold * 100).round()}% độ nhớ',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            health.scope == 'class'
                ? '${health.totalCards} thẻ × ${health.studentCount} học viên'
                : '${health.totalCards} thẻ',
            style: TextStyle(fontSize: 11, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStat(ColorScheme colorScheme, String label, String value, {String? hint}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          if (hint != null) Text(hint, style: TextStyle(fontSize: 9, color: colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildHardestCardsCard(
    BuildContext context,
    List<HardestCardModel> cards,
    String title,
    String badge,
    ColorScheme colorScheme, {
    bool showStudentCount = false,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();

    // Get max wrong count for scaling
    int maxWrong = cards.fold(0, (max, e) => e.wrongCount > max ? e.wrongCount : max);
    if (maxWrong == 0) maxWrong = 1;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.whatshot_rounded, color: Colors.red.shade500, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...cards.take(5).map((card) {
            double fraction = card.wrongCount / maxWrong;
            final meta = [
              if (card.backText.isNotEmpty) card.backText,
              if (card.deckName != null && card.deckName!.isNotEmpty) card.deckName!,
              if (showStudentCount && card.studentCount > 0) '${card.studentCount} học viên sai',
            ].join(' · ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          card.frontText,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${card.wrongCount} phiên quên',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: Colors.red.shade50,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewWorkloadCard(
    BuildContext context,
    List<ReviewWorkloadModel> workload,
    String title,
    String badge,
    ColorScheme colorScheme,
  ) {
    if (workload.isEmpty) return const SizedBox.shrink();

    int maxCount = workload.fold(0, (max, e) => e.count > max ? e.count : max);
    if (maxCount == 0) maxCount = 1;

    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Colors.indigo.shade500, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.indigo.shade600,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: workload.take(7).map((w) {
                double heightRatio = w.count / maxCount;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${w.count}',
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 28,
                          height: heightRatio * 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.indigo.shade300, Colors.indigo.shade500],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      daysOfWeek[w.day.weekday - 1],
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchToPersonalCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.manage_accounts_rounded, color: colorScheme.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            "Dữ liệu Cá nhân hóa",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Lịch ôn tập FSRS là thuộc tính cá nhân. Yêu cầu chuyển sang tab Học viên để xem chi tiết.",
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text(
                "Xem Báo cáo Cá Nhân",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrillDownSheet extends StatefulWidget {
  final String classId;
  final String assignmentId;
  final String status;
  final String label;
  final Color color;
  final bool isTest;

  const _DrillDownSheet({
    required this.classId,
    required this.assignmentId,
    required this.status,
    required this.label,
    required this.color,
    required this.isTest,
  });

  @override
  State<_DrillDownSheet> createState() => _DrillDownSheetState();
}

class _DrillDownSheetState extends State<_DrillDownSheet> {
  bool _isLoading = true;
  String? _error;
  List<AssignmentDrillDownModel> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchDrillDownData();
  }

  Future<void> _fetchDrillDownData() async {
    try {
      final repository = DI().sl<ClassRepository>();
      final resp = await repository.getAssignmentDrillDown(
        widget.classId,
        widget.assignmentId,
        status: widget.status,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (resp.success) {
            _students = resp.data;
          } else {
            _error = resp.message;
          }
        });
      }
    } on Failure catch (f) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = ClassErrorMessages.of(f);
        });
      }
    }
  }

  String _trailingTop(AssignmentDrillDownModel s) {
    if (widget.isTest) {
      final score = s.bestScore ?? s.scorePercentage;
      if (score == null) return s.attemptsCount > 0 ? '${s.attemptsCount} lượt' : '--';
      return '${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)}%';
    }
    if (s.targetCount != null) return '${s.progressCount ?? 0}/${s.targetCount} thẻ';
    return '${s.progressCount ?? 0} thẻ';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag handle chuẩn iOS
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people_alt_rounded, color: widget.color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_students.length} hs",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: widget.color))
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                        ),
                      )
                    : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 64,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Không có học viên nào",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final canOpen = widget.isTest && student.attemptsCount > 0;
                          return ListTile(
                            onTap: canOpen
                                ? () => showStudentAttemptsSheet(
                                    context,
                                    classId: widget.classId,
                                    assignmentId: widget.assignmentId,
                                    userId: student.userId,
                                    studentName: student.fullName,
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                student.fullName.isNotEmpty
                                    ? student.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: widget.color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              student.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [
                                  if (student.email != null && student.email!.isNotEmpty)
                                    student.email!,
                                  if (widget.isTest && student.attemptsCount > 0)
                                    '${student.attemptsCount} lượt',
                                  if (student.isLate) 'Nộp muộn',
                                ].join(' · '),
                                style: TextStyle(
                                  color: student.isLate
                                      ? Colors.red.shade500
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _trailingTop(student),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: widget.color,
                                    fontSize: 14,
                                  ),
                                ),
                                if (canOpen)
                                  Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
