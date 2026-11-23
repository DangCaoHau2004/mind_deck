import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_state.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/widgets/assignment_start_sheet.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/widgets/create_edit_assignment_screen.dart';

class ClassAssignmentsScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassAssignmentsScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<ClassAssignmentsBloc>()
            ..add(ClassAssignmentsLoaded(classData.id, isTeacher: classData.isTeacher)),
      child: _ClassAssignmentsView(classData: classData),
    );
  }
}

String _fmt(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

class _ClassAssignmentsView extends StatelessWidget {
  final ClassModel classData;

  const _ClassAssignmentsView({required this.classData});

  void _reload(BuildContext context) {
    context.read<ClassAssignmentsBloc>().add(
      ClassAssignmentsLoaded(classData.id, isTeacher: classData.isTeacher),
    );
  }

  void _openForm(BuildContext context, {ClassAssignmentModel? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ClassAssignmentsBloc>(),
          child: CreateEditAssignmentScreen(classData: classData, existingAssignment: existing),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ClassAssignmentModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài tập?'),
        content: Text(
          'Xóa "${a.title}". Chưa có hoạt động thì xóa hẳn; đã có hoạt động thì bài bị ẩn khỏi học viên '
          'và khỏi xếp hạng / thống kê của lớp (dữ liệu cá nhân của học viên vẫn được giữ).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ClassAssignmentsBloc>().add(
        ClassAssignmentDeleted(classId: classData.id, assignmentId: a.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isTeacher = classData.isTeacher;

    return DefaultTabController(
      length: isTeacher ? 2 : 3,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Bài tập",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: isTeacher
                    ? const [Tab(text: "Đang diễn ra"), Tab(text: "Đã kết thúc")]
                    : const [Tab(text: "Chờ làm"), Tab(text: "Quá hạn"), Tab(text: "Đã làm")],
              ),
            ),
          ),
          actions: [
            if (isTeacher)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  tooltip: 'Giao bài mới',
                  icon: Icon(
                    CupertinoIcons.add_circled_solid,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () => _openForm(context),
                ),
              ),
          ],
        ),
        body: BlocConsumer<ClassAssignmentsBloc, ClassAssignmentsState>(
          listenWhen: (prev, current) => prev.noticeId != current.noticeId,
          listener: (context, state) {
            final notice = state.notice;
            if (notice == null) return;
            CustomToast.show(
              context,
              state.noticeIsError
                  ? CustomToast.danger(message: notice)
                  : CustomToast.success(message: notice),
            );
          },
          builder: (context, state) {
            if (state.status == ClassAssignmentsStatus.loading &&
                state.active.isEmpty &&
                state.history.isEmpty) {
              return Center(child: CircularProgressIndicator(color: colorScheme.primary));
            }
            if (state.status == ClassAssignmentsStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.errorMessage ?? 'Có lỗi xảy ra',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _reload(context),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: isTeacher
                  ? [
                      _assignmentList(
                        context,
                        state.active,
                        'Chưa có bài tập nào đang diễn ra hoặc đã hẹn giờ.',
                      ),
                      _assignmentList(context, state.history, 'Chưa có bài tập nào kết thúc.'),
                    ]
                  : [
                      _assignmentList(context, state.active, 'Bạn không có bài tập nào cần làm.'),
                      _overdueList(context, state.overdue),
                      _assignmentList(context, state.studentDone, 'Bạn chưa làm bài tập nào.'),
                    ],
            );
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.doc_text_search, size: 64, color: colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ClassAssignmentsBloc>();
    _reload(context);
    await bloc.stream.firstWhere(
      (s) => !s.isProcessing && s.status != ClassAssignmentsStatus.loading,
    );
  }

  Widget _assignmentList(BuildContext context, List<ClassAssignmentModel> items, String emptyText) {
    if (items.isEmpty) return _empty(context, emptyText);
    return CommonRefresh(
      onRefresh: () => _refresh(context),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAssignmentCard(context, items[index]),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _overdueList(BuildContext context, List<ClassAssignmentSubmissionModel> items) {
    if (items.isEmpty) return _empty(context, 'Không có bài tập quá hạn nào.');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CommonRefresh(
      onRefresh: () => _refresh(context),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              final isTest = item.type == AssignmentType.gradedTest;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _typeBadge(context, isTest),
                          const Spacer(),
                          _pill('Quá hạn', colorScheme.error),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.title ?? 'Bài tập',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (item.endAt != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(CupertinoIcons.timer, size: 14, color: colorScheme.error),
                            const SizedBox(width: 6),
                            Text(
                              'Hạn: ${_fmt(item.endAt!)}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }, childCount: items.length),
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(BuildContext context, bool isTest) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = isTest ? Colors.orange.shade600 : Colors.blue.shade600;
    final typeBgColor = isTest
        ? (isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50)
        : (isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: typeBgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTest ? Icons.assignment_late_rounded : Icons.menu_book_rounded,
            size: 14,
            color: typeColor,
          ),
          const SizedBox(width: 6),
          Text(
            isTest ? 'Bài Kiểm Tra' : 'Nhiệm Vụ Học',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: typeColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  /// Tóm tắt tiến độ của TÔI: bài học = thanh tiến độ (đã chặn trên bởi mục tiêu); bài kiểm tra = điểm / lượt.
  Widget _myProgress(BuildContext context, ClassAssignmentModel a) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mine = a.my;
    if (mine == null) return const SizedBox.shrink();

    if (!a.isTest) {
      final target = mine.targetCount;
      final done = mine.clampedProgress;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                mine.status.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: mine.status == AssignmentStatus.completed
                      ? Colors.green.shade600
                      : cs.primary,
                ),
              ),
              const Spacer(),
              Text(
                target == null ? '$done thẻ' : '$done/$target thẻ',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          if (target != null && target > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: done / target, minHeight: 8),
            ),
          ],
        ],
      );
    }

    final parts = <String>[
      mine.status.label,
      if (mine.attemptsAllowed != null) 'Lượt ${mine.attemptsCount}/${mine.attemptsAllowed}',
      if (mine.attemptsCount > 0)
        (mine.scorePercentage == null
            ? 'Điểm do giảng viên công bố'
            : 'Điểm: ${mine.scorePercentage!.toStringAsFixed(mine.scorePercentage! % 1 == 0 ? 0 : 1)}%'),
    ];
    return Text(
      parts.join(' · '),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, ClassAssignmentModel assignment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTeacher = classData.isTeacher;
    final isTest = assignment.isTest;

    final phaseColor = switch (assignment.phase) {
      AssignmentPhase.scheduled => Colors.blueGrey.shade500,
      AssignmentPhase.running => Colors.green.shade600,
      AssignmentPhase.ended => colorScheme.outline,
    };

    // Học viên: hành động theo `phase` / `my` (không dựa vào tab BE).
    final String? actionLabel = isTeacher
        ? null
        : assignment.canRetake
        ? 'Làm lại'
        : (assignment.canStudentDo ? (isTest ? 'Làm bài' : 'Học ngay') : null);

    void openStart() => showAssignmentStartSheet(
      context,
      classData: classData,
      assignment: assignment,
      onChanged: () => _reload(context),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: isTeacher || actionLabel == null ? null : openStart,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _typeBadge(context, isTest),
                    const SizedBox(width: 8),
                    _pill(assignment.phase.label, phaseColor),
                    const Spacer(),
                    if (isTeacher)
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openForm(context, existing: assignment);
                            } else if (value == 'delete') {
                              _confirmDelete(context, assignment);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 12),
                                  Text('Chỉnh sửa'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, size: 18, color: colorScheme.error),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Xóa bài tập',
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  assignment.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    assignment.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                if (!isTeacher && assignment.my != null) ...[
                  const SizedBox(height: 14),
                  _myProgress(context, assignment),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (assignment.phase == AssignmentPhase.scheduled &&
                              assignment.startAt != null)
                            _timeLine(
                              context,
                              Icons.play_circle_outline_rounded,
                              'Bắt đầu: ${_fmt(assignment.startAt!)}',
                              Colors.blueGrey.shade600,
                            ),
                          _timeLine(
                            context,
                            CupertinoIcons.timer,
                            'Hạn: ${_fmt(assignment.endAt)}',
                            colorScheme.error,
                          ),
                        ],
                      ),
                    ),
                    if (actionLabel != null)
                      FilledButton(
                        onPressed: openStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeLine(BuildContext context, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
