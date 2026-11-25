import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/class_access_monitor.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_hub/bloc/class_hub_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_hub/bloc/class_hub_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_hub/bloc/class_hub_state.dart';
import 'package:mind_deck/ui/screens/classroom/classrooms_screen.dart'; // Cho SlideRightRoute và FeatureGridItem
import 'package:mind_deck/ui/screens/classroom/class_members/class_members_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/class_materials_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/class_assignments_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/class_leaderboard_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/class_analytics_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_tests/class_tests_screen.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/commons/state_screens/common_loading.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/widgets/share_qr_widget.dart';
import 'package:mind_deck/ui/screens/classroom/class_settings/class_settings_screen.dart';

class FeatureGridItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const FeatureGridItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Auto-adapt colors cho Dark/Light mode để bento box luôn đẹp
    final resolvedBgColor = isDark ? color.withValues(alpha: 0.15) : bgColor;

    return Material(
      color: resolvedBgColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias, // Cắt phần icon tràn viền
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Watermark Icon khổng lồ làm nền (Điểm nhấn phá cách)
            Positioned(
              right: -20,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  icon,
                  size: 110,
                  color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Content chính
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon nhỏ nổi bật ở góc trên
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w900, // Chữ đậm hơn để tạo khối
                      fontSize: 17,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color, // Dùng chính màu chủ đạo cho text phụ
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassHubScreen extends StatelessWidget {
  final String classId;
  final ClassModel? classModel;

  const ClassHubScreen({Key? key, required this.classId, this.classModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<ClassHubBloc>(param1: classId, param2: classModel)..add(ClassHubLoaded()),
      child: _ClassAccessGuard(classId: classId, child: const _ClassHubView()),
    );
  }
}

/// Đóng mọi màn con của lớp khi một request bất kỳ báo mất quyền vào lớp
/// (`CLASS_NOT_A_MEMBER` / `CLASS_NOT_FOUND`: bị đuổi, đã rời, lớp bị xóa).
///
/// Đưa người dùng về hub rồi tải lại hub: hub nhận cùng lỗi và tự thoát về danh sách lớp
/// kèm thông báo, nên chỉ có một luồng thoát duy nhất.
class _ClassAccessGuard extends StatefulWidget {
  final String classId;
  final Widget child;

  const _ClassAccessGuard({required this.classId, required this.child});

  @override
  State<_ClassAccessGuard> createState() => _ClassAccessGuardState();
}

class _ClassAccessGuardState extends State<_ClassAccessGuard> {
  StreamSubscription<ClassAccessLost>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ClassAccessMonitor.instance.forClass(widget.classId).listen((_) => _onLost());
  }

  void _onLost() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    // Hub đang ở trên cùng: lỗi đến từ chính hub, hub bloc tự xử lý.
    if (route == null || route.isCurrent) return;
    Navigator.of(context).popUntil((r) => r == route);
    context.read<ClassHubBloc>().add(ClassHubLoaded());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ClassHubView extends StatelessWidget {
  const _ClassHubView();

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời khỏi lớp học?'),
        content: const Text(
          'Bạn sẽ không còn xem được học liệu của lớp. Tiến trình học cá nhân của bạn vẫn được giữ lại.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Rời lớp', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ClassHubBloc>().add(ClassHubLeaveRequested());
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lớp học?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lớp sẽ biến mất với mọi thành viên. Dữ liệu được giữ 90 ngày rồi xóa hẳn và không thể khôi phục.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLength: 1000,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Lý do (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa lớp', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (ok == true && context.mounted) {
      context.read<ClassHubBloc>().add(
        ClassHubDeleteRequested(reason: reason.isEmpty ? null : reason),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<ClassHubBloc, ClassHubState>(
      listenWhen: (p, c) => c.noticeId != p.noticeId || (c.exit != null && p.exit != c.exit),
      listener: (context, state) {
        final notice = state.notice;
        if (notice != null) {
          CustomToast.show(
            context,
            state.noticeIsError
                ? CustomToast.danger(message: notice)
                : CustomToast.success(message: notice),
          );
        }
        // Không còn ở trong lớp (rời / xóa / từ chối lời mời / lớp không còn truy cập được).
        // Đóng cả các màn con đang mở phía trên hub (nếu có) rồi mới đóng hub.
        if (state.exit != null) {
          final route = ModalRoute.of(context);
          final navigator = Navigator.of(context);
          if (route != null && !route.isCurrent) navigator.popUntil((r) => r == route);
          navigator.maybePop();
        }
      },
      builder: (context, state) {
        Widget buildRefreshable(Widget child) {
          return CommonRefresh(
            onRefresh: () async {
              final bloc = context.read<ClassHubBloc>();
              bloc.add(ClassHubLoaded());
              await bloc.stream.firstWhere((s) => s.status != ClassHubStatus.loading);
            },
            slivers: [SliverFillRemaining(child: child)],
          );
        }

        if (state.status == ClassHubStatus.loading && state.classModel == null) {
          return Scaffold(
            backgroundColor: colorScheme.background,
            body: buildRefreshable(const Center(child: CommonLoading())),
          );
        }

        if (state.status == ClassHubStatus.failure && state.classModel == null) {
          return Scaffold(
            appBar: AppBar(
              leading: const BackButton(),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            backgroundColor: colorScheme.background,
            body: buildRefreshable(
              CommonFailure(errorMessage: state.errorMessage ?? "Có lỗi xảy ra"),
            ),
          );
        }

        final classData = state.classModel;
        if (classData == null) {
          return Scaffold(
            appBar: AppBar(
              leading: const BackButton(),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            backgroundColor: colorScheme.background,
            body: buildRefreshable(const CommonEmpty(title: "Không tìm thấy thông tin lớp học")),
          );
        }

        final bool isTeacher = classData.isTeacher;
        final bool isPreview = classData.isPreview;
        final joinCode = classData.joinCode;
        final bool hasJoinCode = !isPreview && joinCode != null && joinCode.isNotEmpty;

        return Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            backgroundColor: colorScheme.surface.withValues(alpha: 0.8), // Kính mờ nhẹ
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: IconButton(
              icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Phòng học",
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            centerTitle: true,
            actions: [
              if (!isPreview)
                PopupMenuButton<String>(
                  enabled: !state.isBusy,
                  icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface),
                  onSelected: (value) {
                    if (value == 'leave') _confirmLeave(context);
                    if (value == 'delete') _confirmDelete(context);
                  },
                  itemBuilder: (_) => [
                    // Chủ lớp không rời lớp được (phải xóa lớp).
                    if (classData.isOwner)
                      const PopupMenuItem(value: 'delete', child: Text('Xóa lớp học'))
                    else
                      const PopupMenuItem(value: 'leave', child: Text('Rời lớp học')),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Phá cách với Abstract background
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withRed(100).withBlue(200), // Pha trộn màu tạo độ sâu
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Abstract Shapes trang trí nền
                      Positioned(
                        top: -50,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -60,
                        left: -40,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),

                      // Nội dung Banner
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    classData.name,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                // Mọi thành viên đều có cài đặt thông báo của mình; phần cài đặt lớp
                                // chỉ owner/admin sửa được (xem màn cài đặt).
                                if (!isPreview)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.tune, color: colorScheme.onPrimary),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          SlideRightRoute(
                                            page: ClassSettingsScreen(classData: classData),
                                          ),
                                        );
                                        if (result == true && context.mounted) {
                                          context.read<ClassHubBloc>().add(ClassHubLoaded());
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Stats dạng Glassmorphism blocks
                            if (isPreview) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatBlock(
                                      context,
                                      "THÀNH VIÊN",
                                      "${classData.memberCount}",
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatBlock(
                                      context,
                                      "GIÁO VIÊN",
                                      classData.ownerName ?? '--',
                                      small: true,
                                    ),
                                  ),
                                ],
                              ),
                              if (classData.description != null &&
                                  classData.description!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  classData.description!,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ] else
                              Row(
                                children: [
                                  if (isTeacher) ...[
                                    Expanded(
                                      child: _buildStatBlock(
                                        context,
                                        "SĨ SỐ",
                                        "${classData.memberCount}",
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatBlock(
                                        context,
                                        "CHỜ DUYỆT",
                                        // Chỉ đếm tối đa một trang lớn (xem `ClassHubBloc`)
                                        state.pendingCount >= ClassHubBloc.pendingCountLimit
                                            ? '${ClassHubBloc.pendingCountLimit - 1}+'
                                            : '${state.pendingCount}',
                                      ),
                                    ),
                                  ] else
                                    // Học viên: hạng/điểm xem trong màn Bảng xếp hạng (BE dặn không
                                    // gọi bảng xếp hạng khi mở lớp).
                                    Expanded(
                                      child: _buildStatBlock(
                                        context,
                                        "THÀNH VIÊN",
                                        "${classData.memberCount}",
                                      ),
                                    ),
                                ],
                              ),

                            // Mã lớp chỉ giảng viên mới có (học viên nhận null)
                            if (hasJoinCode) ...[
                              const SizedBox(height: 16),
                              _buildJoinCodeBar(context, classData, joinCode),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (isPreview)
                  _buildPreviewActions(context, state, classData)
                else ...[
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "Chức năng",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: colorScheme.onBackground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid Chức năng (Tăng aspect ratio để form thẻ bento hơi thuôn đẹp mắt)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      FeatureGridItem(
                        title: "Học liệu",
                        subtitle: "Thẻ & Thư mục",
                        icon: CupertinoIcons.book_solid,
                        color: Colors.blue.shade600,
                        bgColor: Colors.blue.shade50,
                        onTap: () => Navigator.push(
                          context,
                          SlideRightRoute(page: ClassMaterialsScreen(classData: classData)),
                        ),
                      ),
                      FeatureGridItem(
                        title: "Bài tập",
                        subtitle: "Kiểm tra",
                        icon: CupertinoIcons.doc_text_fill,
                        color: Colors.orange.shade600,
                        bgColor: Colors.orange.shade50,
                        onTap: () => Navigator.push(
                          context,
                          SlideRightRoute(page: ClassAssignmentsScreen(classData: classData)),
                        ),
                      ),
                      FeatureGridItem(
                        title: "Thống kê",
                        subtitle: "Tiến độ học",
                        icon: CupertinoIcons.chart_pie_fill,
                        color: Colors.purple.shade600,
                        bgColor: Colors.purple.shade50,
                        onTap: () => Navigator.push(
                          context,
                          SlideRightRoute(page: AnalyticsScreen(classData: classData)),
                        ),
                      ),
                      // Kho đề: chỉ giảng viên tạo / sửa đề của lớp.
                      if (isTeacher)
                        FeatureGridItem(
                          title: "Kho đề",
                          subtitle: "Tạo & quản lý đề",
                          icon: CupertinoIcons.square_list_fill,
                          color: Colors.teal.shade600,
                          bgColor: Colors.teal.shade50,
                          onTap: () => Navigator.push(
                            context,
                            SlideRightRoute(page: ClassTestsScreen(classData: classData)),
                          ),
                        ),
                      // Lớp có thể tắt bảng xếp hạng với học viên (`permissions.canViewLeaderboard`).
                      if (classData.canViewLeaderboard)
                        FeatureGridItem(
                          title: "Bảng xếp hạng",
                          subtitle: "Đua top",
                          icon: Icons.workspace_premium_rounded,
                          color: Colors.yellow.shade800,
                          bgColor: Colors.yellow.shade100,
                          onTap: () {
                            final hubBloc = context.read<ClassHubBloc>();
                            Navigator.push<dynamic>(
                              context,
                              SlideRightRoute(page: ClassLeaderboardScreen(classData: classData)),
                            ).then((closedByDisabled) {
                              // Lớp vừa tắt bảng xếp hạng: tải lại chi tiết lớp để ẩn nút này.
                              if (closedByDisabled == true) hubBloc.add(ClassHubLoaded());
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nút Danh sách thành viên kiểu Wide Bento Card
                  Material(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        final hubBloc = context.read<ClassHubBloc>();
                        Navigator.push<dynamic>(
                          context,
                          SlideRightRoute(page: ClassMembersScreen(classData: classData)),
                        ).then((transferred) {
                          // Vừa chuyển quyền chủ lớp: tải lại để cập nhật vai trò của tôi.
                          if (transferred == true) hubBloc.add(ClassHubLoaded());
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.people_alt_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Danh sách Thành viên",
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Xem những người tham gia",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.arrow_right,
                                color: colorScheme.onSurface,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Người ngoài lớp: nút theo `myStatus` (not_joined → Tham gia, pending → Chờ duyệt,
  /// invited → Chấp nhận / Từ chối). Yêu cầu đang chờ duyệt hủy được bằng `DELETE requests/me`.
  Widget _buildPreviewActions(BuildContext context, ClassHubState state, ClassModel classData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bloc = context.read<ClassHubBloc>();

    Widget progress() => const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
    );

    final Widget actions;
    switch (classData.myStatus) {
      case 'pending':
        actions = Column(
          children: [
            FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('Đang chờ giáo viên duyệt'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: state.isBusy
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hủy yêu cầu tham gia?'),
                          content: const Text('Bạn có thể gửi yêu cầu lại sau.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Giữ lại'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Hủy yêu cầu',
                                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) bloc.add(ClassHubJoinRequestCancelled());
                    },
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: state.isBusy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Hủy yêu cầu'),
            ),
          ],
        );
      case 'invited':
        actions = Column(
          children: [
            const Text('Bạn được mời tham gia lớp học này', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isBusy
                        ? null
                        : () => bloc.add(const ClassHubInviteResponded(accept: false)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: state.isBusy
                        ? null
                        : () => bloc.add(const ClassHubInviteResponded(accept: true)),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                    child: state.isBusy ? progress() : const Text('Chấp nhận'),
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        actions = Column(
          children: [
            FilledButton(
              onPressed: state.isBusy ? null : () => bloc.add(ClassHubJoinRequested()),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: state.isBusy ? progress() : const Text('Tham gia lớp học'),
            ),
            if (classData.requireApproval)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Cần sự phê duyệt của giáo viên',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        );
    }

    return Padding(padding: const EdgeInsets.only(top: 24), child: actions);
  }

  Widget _buildJoinCodeBar(BuildContext context, ClassModel classData, String joinCode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.vpn_key_rounded,
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            "Mã lớp:",
            style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(width: 6),
          Text(
            joinCode,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: joinCode));
              CustomToast.show(context, CustomToast.success(message: 'Đã copy mã lớp!'));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.copy, color: colorScheme.onPrimary, size: 14),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  backgroundColor: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mã QR Lớp Học',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 24),
                        ShareQrWidget(
                          targetType: 'class',
                          targetId: 'join',
                          shareToken: joinCode,
                          customLink:
                              "minddeck://minddeck.com/profile/classrooms/join?code=$joinCode",
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Mã lớp: $joinCode",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Đóng"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.qr_code_2, color: colorScheme.primary, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Widget con hỗ trợ vẽ thông số trong Banner để code clean hơn
  Widget _buildStatBlock(BuildContext context, String label, String value, {bool small = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.12), // Hiệu ứng kính
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: small ? 16 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
