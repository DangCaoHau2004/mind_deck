import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_state.dart';

/// Nhãn vai trò hiện dưới tên học viên trong ô chọn.
String _roleLabel(ClassRole role) => switch (role) {
  ClassRole.owner => 'Chủ lớp',
  ClassRole.admin => 'Admin',
  ClassRole.tutor => 'Tutor',
  _ => 'Học viên',
};

/// Tên hiển thị của thành viên trong ô chọn.
String analyticsMemberName(ClassMemberModel member) => member.user?.fullName ?? member.fullName;

/// Bottom sheet chọn học viên để xem thống kê; cuộn gần cuối thì tải thêm thành viên.
Future<ClassMemberModel?> showMemberPickerSheet(
  BuildContext context, {
  required String classId,
  required String? selectedUserId,
}) {
  final bloc = context.read<ClassAnalyticsBloc>();
  return showModalBottomSheet<ClassMemberModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _PickerSheet<ClassMemberModel>(
        title: 'Chọn học viên',
        itemsOf: (s) => s.members,
        hasMoreOf: (s) => s.membersPage.hasMore,
        isLoadingOf: (s) => s.membersPage.isLoadingMore,
        onLoadMore: () => bloc.add(ClassAnalyticsMembersMoreLoaded(classId)),
        idOf: (m) => m.userId,
        selectedId: selectedUserId,
        tileOf: (context, m, selected) => _PickerTile(
          leading: (analyticsMemberName(m)).isNotEmpty
              ? analyticsMemberName(m)[0].toUpperCase()
              : '?',
          title: analyticsMemberName(m),
          subtitle: _roleLabel(m.role),
          selected: selected,
        ),
      ),
    ),
  );
}

/// Bottom sheet chọn bài giao; chia hai nhóm "Đang diễn ra" và "Đã kết thúc", cuộn gần cuối thì tải
/// thêm (hết nhóm trên mới tới nhóm dưới).
Future<ClassAssignmentModel?> showAssignmentPickerSheet(
  BuildContext context, {
  required String classId,
  required String? selectedAssignmentId,
}) {
  final bloc = context.read<ClassAnalyticsBloc>();
  return showModalBottomSheet<ClassAssignmentModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _PickerSheet<ClassAssignmentModel>(
        title: 'Chọn bài giao',
        itemsOf: (s) => s.assignments,
        hasMoreOf: (s) => s.hasMoreAssignments,
        isLoadingOf: (s) =>
            s.activeAssignmentsPage.isLoadingMore || s.historyAssignmentsPage.isLoadingMore,
        onLoadMore: () => bloc.add(ClassAnalyticsAssignmentsMoreLoaded(classId)),
        idOf: (a) => a.id,
        selectedId: selectedAssignmentId,
        sectionOf: (a, s) =>
            s.activeAssignments.any((x) => x.id == a.id) ? 'Đang diễn ra' : 'Đã kết thúc',
        tileOf: (context, a, selected) => _PickerTile(
          leading: a.type == AssignmentType.gradedTest ? '✎' : '▤',
          title: a.title,
          subtitle: a.type == AssignmentType.gradedTest ? 'Bài kiểm tra' : 'Bài học',
          selected: selected,
        ),
      ),
    ),
  );
}

/// Danh sách chọn một mục, có tiêu đề nhóm (tùy chọn) và tải thêm khi cuộn.
class _PickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> Function(ClassAnalyticsState) itemsOf;
  final bool Function(ClassAnalyticsState) hasMoreOf;
  final bool Function(ClassAnalyticsState) isLoadingOf;
  final VoidCallback onLoadMore;
  final String Function(T) idOf;
  final String? selectedId;
  final Widget Function(BuildContext, T, bool selected) tileOf;
  final String Function(T, ClassAnalyticsState)? sectionOf;

  const _PickerSheet({
    required this.title,
    required this.itemsOf,
    required this.hasMoreOf,
    required this.isLoadingOf,
    required this.onLoadMore,
    required this.idOf,
    required this.selectedId,
    required this.tileOf,
    this.sectionOf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: BlocBuilder<ClassAnalyticsBloc, ClassAnalyticsState>(
        builder: (context, state) {
          final items = itemsOf(state);

          // Hàng hiển thị: tiêu đề nhóm (String) xen giữa các mục (T).
          final rows = <Object>[];
          String? lastSection;
          for (final item in items) {
            final section = sectionOf?.call(item, state);
            if (section != null && section != lastSection) {
              rows.add(section);
              lastSection = section;
            }
            rows.add(item as Object);
          }
          final showFooter = isLoadingOf(state) || hasMoreOf(state);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                // Gần cuối danh sách thì tải thêm (bloc tự bỏ qua khi hết trang hoặc đang tải).
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 400) onLoadMore();
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: rows.length + (showFooter ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= rows.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                        );
                      }
                      final row = rows[index];
                      if (row is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: Text(
                            row,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }
                      final item = row as T;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(context, item),
                        child: tileOf(context, item, idOf(item) == selectedId),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Một dòng trong ô chọn: ô chữ cái / biểu tượng, tên, dòng phụ, dấu tích khi đang chọn.
class _PickerTile extends StatelessWidget {
  final String leading;
  final String title;
  final String subtitle;
  final bool selected;

  const _PickerTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              leading,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: selected ? colorScheme.onPrimary : colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle_rounded, color: colorScheme.primary),
        ],
      ),
    );
  }
}
