import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_state.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/widgets/create_edit_assignment_screen.dart';

class ClassAssignmentsScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassAssignmentsScreen({Key? key, required this.classData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<ClassAssignmentsBloc>()..add(ClassAssignmentsLoaded(classData.id)),
      child: _ClassAssignmentsView(classData: classData),
    );
  }
}

class _ClassAssignmentsView extends StatelessWidget {
  final ClassModel classData;

  const _ClassAssignmentsView({required this.classData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isAdminOrTutor =
        classData.isOwner || classData.myRole == 'admin' || classData.myRole == 'tutor';

    return DefaultTabController(
      length: 3,
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
              fontWeight: FontWeight.w900, // Đậm hơn chút cho hiện đại
              letterSpacing: 0.2,
            ),
          ),
          backgroundColor: colorScheme.surface.withOpacity(
            0.9,
          ), // Dùng withOpacity thay vì withValues cho an toàn
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          // Bắt đầu lột xác TabBar thành dạng Segmented Control
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
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
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: "Chờ làm"),
                  Tab(text: "Quá hạn"),
                  Tab(text: "Đã nộp"),
                ],
              ),
            ),
          ),
          // Kết thúc phần lột xác TabBar
          actions: [
            if (isAdminOrTutor)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  icon: Icon(
                    CupertinoIcons.add_circled_solid,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<ClassAssignmentsBloc>(),
                          child: CreateEditAssignmentScreen(classId: classData.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        body: BlocConsumer<ClassAssignmentsBloc, ClassAssignmentsState>(
          listenWhen: (prev, current) => prev.isProcessing != current.isProcessing,
          listener: (context, state) {
            if (!state.isProcessing && state.processErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.processErrorMessage!),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == ClassAssignmentsStatus.loading) {
              return Center(child: CircularProgressIndicator(color: colorScheme.primary));
            }
            if (state.status == ClassAssignmentsStatus.failure) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Có lỗi xảy ra',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                ),
              );
            }

            return TabBarView(
              physics: const NeverScrollableScrollPhysics(), // Thêm độ nảy cho tab mượt hơn
              children: [
                _buildActiveTab(context, state, isAdminOrTutor),
                _buildSubmissionsTab(context, state, state.overdueAssignments, true),
                _buildSubmissionsTab(context, state, state.mySubmissions, false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.doc_text_search, size: 64, color: colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, ClassAssignmentsState state, bool isAdminOrTutor) {
    if (state.assignments.isEmpty) {
      return _buildEmpty(context, 'Lớp chưa có bài tập nào.');
    }

    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<ClassAssignmentsBloc>();
        bloc.add(ClassAssignmentsLoaded(classData.id));
        await bloc.stream.firstWhere(
          (s) => !s.isProcessing && s.status != ClassAssignmentsStatus.loading,
        );
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final assignment = state.assignments[index];
              return _buildAssignmentCard(context, assignment, isAdminOrTutor);
            }, childCount: state.assignments.length),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsTab(
    BuildContext context,
    ClassAssignmentsState state,
    List<ClassAssignmentSubmissionModel> items,
    bool isOverdue,
  ) {
    if (items.isEmpty) {
      return _buildEmpty(
        context,
        isOverdue ? 'Không có bài tập quá hạn nào.' : 'Chưa có bài tập nào đã nộp.',
      );
    }

    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<ClassAssignmentsBloc>();
        bloc.add(ClassAssignmentsLoaded(classData.id));
        await bloc.stream.firstWhere(
          (s) => !s.isProcessing && s.status != ClassAssignmentsStatus.loading,
        );
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final submission = items[index];
              return _buildSubmissionCard(context, submission, isOverdue);
            }, childCount: items.length),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    ClassAssignmentSubmissionModel submission,
    bool isOverdue,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isTest = submission.type == AssignmentType.gradedTest;
    final typeColor = isTest ? Colors.orange.shade600 : Colors.blue.shade600;
    final typeBgColor = isTest
        ? (isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50)
        : (isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50);

    Color scoreColor = Colors.grey;
    final double displayScore = submission.scorePercentage ?? 0.0;

    if (displayScore == 100)
      scoreColor = Colors.blue.shade600;
    else if (displayScore >= 80)
      scoreColor = Colors.green.shade600;
    else if (displayScore >= 50)
      scoreColor = Colors.orange.shade600;
    else
      scoreColor = Colors.red.shade500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            if (isTest && submission.testAttemptId != null && !isOverdue) {
              context.pushNamed(
                AppRoute.testHistoryDetail.name,
                pathParameters: {'attemptId': submission.testAttemptId!},
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isOverdue
                    ? colorScheme.error.withOpacity(0.3)
                    : colorScheme.outlineVariant.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Quá hạn',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                      )
                    else if (!isOverdue)
                      Row(
                        children: [
                          Icon(Icons.stars_rounded, color: scoreColor, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${displayScore.toStringAsFixed(1)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  submission.title ?? 'Bài tập',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (submission.deadline != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.timer, size: 14, color: colorScheme.error),
                            const SizedBox(width: 6),
                            Text(
                              "Hạn: ${submission.deadline!.day}/${submission.deadline!.month}/${submission.deadline!.year}",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (submission.completedAt != null)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Nộp lúc: ${submission.completedAt!.day}/${submission.completedAt!.month}",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

  Widget _buildAssignmentCard(
    BuildContext context,
    ClassAssignmentModel assignment,
    bool isAdminOrTutor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Màu sắc riêng biệt cho từng loại bài tập để dễ nhận diện
    final isTest = assignment.type == AssignmentType.gradedTest;
    final typeColor = isTest ? Colors.orange.shade600 : Colors.blue.shade600;
    final typeBgColor = isTest
        ? (isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50)
        : (isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () async {
            if (assignment.type == AssignmentType.studyMission && assignment.deckId != null) {
              context.pushNamed(
                AppRoute.deckDetail.name,
                pathParameters: {'id': assignment.deckId!},
                extra: {'classId': classData.id, 'assignmentId': assignment.id},
              );
            } else if (assignment.type == AssignmentType.gradedTest && assignment.testId != null) {
              final result = await context.pushNamed<bool>(
                AppRoute.classTest.name,
                pathParameters: {
                  'classId': classData.id,
                  'assignmentId': assignment.id,
                  'testId': assignment.testId!,
                },
              );
              if (result == true && context.mounted) {
                context.read<ClassAssignmentsBloc>().add(ClassAssignmentsLoaded(classData.id));
              }
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    ),
                    if (isAdminOrTutor)
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<ClassAssignmentsBloc>(),
                                    child: CreateEditAssignmentScreen(
                                      classId: classData.id,
                                      existingAssignment: assignment,
                                    ),
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              context.read<ClassAssignmentsBloc>().add(
                                ClassAssignmentDeleted(
                                  classId: classData.id,
                                  assignmentId: assignment.id,
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
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
                            ];
                          },
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.timer, size: 14, color: colorScheme.error),
                          const SizedBox(width: 6),
                          Text(
                            "Hạn: ${assignment.deadline.day}/${assignment.deadline.month}/${assignment.deadline.year}",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isAdminOrTutor) ...[
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          if (assignment.type == AssignmentType.studyMission &&
                              assignment.deckId != null) {
                            context.pushNamed(
                              AppRoute.deckDetail.name,
                              pathParameters: {'id': assignment.deckId!},
                              extra: {'classId': classData.id, 'assignmentId': assignment.id},
                            );
                          } else if (assignment.type == AssignmentType.gradedTest &&
                              assignment.testId != null) {
                            final result = await context.pushNamed<bool>(
                              AppRoute.classTest.name,
                              pathParameters: {
                                'classId': classData.id,
                                'assignmentId': assignment.id,
                                'testId': assignment.testId!,
                              },
                            );
                            if (result == true && context.mounted) {
                              context.read<ClassAssignmentsBloc>().add(
                                ClassAssignmentsLoaded(classData.id),
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Làm bài',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
