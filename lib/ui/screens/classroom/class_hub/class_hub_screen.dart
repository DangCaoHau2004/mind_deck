import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
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
    final resolvedBgColor = isDark ? color.withOpacity(0.15) : bgColor;

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
                  color: isDark ? color.withOpacity(0.1) : color.withOpacity(0.08),
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
                      color: isDark ? color.withOpacity(0.2) : Colors.white.withOpacity(0.6),
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
      child: const _ClassHubView(),
    );
  }
}

class _ClassHubView extends StatelessWidget {
  const _ClassHubView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ClassHubBloc, ClassHubState>(
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

        final bool isAdminOrTutor =
            classData.isOwner || classData.myRole == 'admin' || classData.myRole == 'tutor';

        return Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            backgroundColor: colorScheme.surface.withOpacity(0.8), // Kính mờ nhẹ
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
                        color: colorScheme.primary.withOpacity(0.3),
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
                            color: colorScheme.onPrimary.withOpacity(0.1),
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
                            color: colorScheme.onPrimary.withOpacity(0.08),
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
                                if (isAdminOrTutor)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.onPrimary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.tune,
                                        color: colorScheme.onPrimary,
                                      ), // Đổi icon nhìn pro hơn
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          SlideRightRoute(
                                            page: ClassSettingsScreen(classData: classData),
                                          ),
                                        );
                                        if (result == true) {
                                          context.read<ClassHubBloc>().add(ClassHubLoaded());
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Stats dạng Glassmorphism blocks
                            Row(
                              children: [
                                if (isAdminOrTutor) ...[
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
                                      "${state.pendingCount}",
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: _buildStatBlock(
                                      context,
                                      "ĐIỂM THI ĐUA",
                                      "${state.totalScore}",
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatBlock(context, "HẠNG", "#${state.rank}"),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Join Code Container mỏng, dài
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.onPrimary.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.vpn_key_rounded,
                                    color: colorScheme.onPrimary.withOpacity(0.8),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Mã lớp:",
                                    style: TextStyle(
                                      color: colorScheme.onPrimary.withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    classData.joinCode,
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
                                      Clipboard.setData(ClipboardData(text: classData.joinCode));
                                      CustomToast.show(
                                        context,
                                        CustomToast.success(message: 'Đã copy mã lớp!'),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.onPrimary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.copy,
                                        color: colorScheme.onPrimary,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(28),
                                          ),
                                          backgroundColor: colorScheme.surface,
                                          child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Mã QR Lớp Học',
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                ShareQrWidget(
                                                  targetType: 'class',
                                                  targetId: 'join',
                                                  shareToken: classData.joinCode,
                                                  customLink:
                                                      "minddeck://minddeck.com/profile/classrooms/join?code=${classData.joinCode}",
                                                ),
                                                const SizedBox(height: 24),
                                                Text(
                                                  "Mã lớp: ${classData.joinCode}",
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
                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
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
                                      child: Icon(
                                        Icons.qr_code_2,
                                        color: colorScheme.primary,
                                        size: 14,
                                      ),
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
                ),

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
                    FeatureGridItem(
                      title: "Bảng xếp hạng",
                      subtitle: "Đua top",
                      icon: Icons.workspace_premium_rounded,
                      color: Colors.yellow.shade800,
                      bgColor: Colors.yellow.shade100,
                      onTap: () => Navigator.push(
                        context,
                        SlideRightRoute(page: ClassLeaderboardScreen(classData: classData)),
                      ),
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
                    onTap: () => Navigator.push(
                      context,
                      SlideRightRoute(page: ClassMembersScreen(classData: classData)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
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
                              color: colorScheme.surfaceVariant.withOpacity(0.5),
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget con hỗ trợ vẽ thông số trong Banner để code clean hơn
  Widget _buildStatBlock(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.12), // Hiệu ứng kính
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
