import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   centerTitle: true,
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.settings_outlined, color: colorScheme.primary, size: 28),
      //       onPressed: () {
      //         context.pushNamed(AppRoute.settings.name);
      //       },
      //     ),
      //     const SizedBox(width: 8),
      //   ],
      // ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Hiệu ứng khối màu mờ phá cách phía nền giống Dashboard
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 12.0,
                bottom: MediaQuery.of(context).padding.bottom + 120, // Tránh bị Bottom Nav chắn
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildModernProfileHeader(context),
                  const SizedBox(height: 32),
                  // _buildPremiumBanner(context),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tiến độ học tập', style: theme.textTheme.titleLarge),
                  ),
                  const SizedBox(height: 16),
                  _buildLearningDashboard(context),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Hỗ trợ & Cộng đồng', style: theme.textTheme.titleLarge),
                  ),
                  const SizedBox(height: 16),
                  _buildSupportSection(context),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final userName = user?.fullName ?? 'Người dùng';
        final userEmail = user?.email ?? '';
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

        return Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primaryContainer, width: 3),
                    // Thêm bóng nhẹ cho avatar
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Text(
                      initial,
                      style: theme.textTheme.displayMedium?.copyWith(color: colorScheme.primary),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 3),
                  ),
                  child: Icon(Icons.camera_alt_rounded, size: 18, color: colorScheme.onPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(userName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          // Nâng cấp bóng cho banner để có cảm giác nổi bật 3D
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nâng cấp Premium',
                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mở khóa toàn bộ tính năng',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningDashboard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _buildVerticalDashboardCard(
          context,
          icon: Icons.bar_chart_rounded,
          title: 'Thống kê chuyên sâu',
          subtitle: 'Heatmap, biểu đồ quên lãng...',
          iconBgColor: colorScheme.primaryContainer,
          iconColor: colorScheme.primary,
          onTap: () {
            context.pushNamed(AppRoute.statistics.name);
          },
        ),
        const SizedBox(height: 16),
        _buildVerticalDashboardCard(
          context,
          icon: Icons.history_rounded,
          title: 'Lịch sử ôn tập',
          subtitle: 'Xem lại kết quả các bài kiểm tra',
          iconBgColor: colorScheme.secondaryContainer,
          iconColor: colorScheme.secondary,
          onTap: () {
            context.pushNamed(AppRoute.testHistory.name);
          },
        ),
        const SizedBox(height: 16),
        _buildVerticalDashboardCard(
          context,
          icon: Icons.school_rounded,
          title: 'Lớp học của tôi',
          subtitle: 'Tham gia và quản lý lớp học',
          iconBgColor: colorScheme.tertiaryContainer,
          iconColor: colorScheme.tertiary,
          onTap: () {
            context.pushNamed(AppRoute.classrooms.name);
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      children: [
        _buildVerticalDashboardCard(
          context,
          icon: Icons.feedback_rounded,
          title: 'Phản hồi & Báo cáo lỗi',
          subtitle: 'Gửi khiếu nại, báo cáo lỗi hệ thống',
          iconBgColor: Colors.orange.withValues(alpha: 0.15),
          iconColor: Colors.orange,
          onTap: () {
            context.pushNamed(AppRoute.reportHistory.name);
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return _buildVerticalDashboardCard(
      context,
      icon: Icons.logout_rounded,
      title: 'Đăng xuất',
      subtitle: 'Thoát khỏi tài khoản hiện tại',
      iconBgColor: Colors.red.withValues(alpha: 0.15),
      iconColor: Colors.red,
      onTap: () => _logout(context),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthBloc>().add(LoggedOut());
  }
}

Widget _buildVerticalDashboardCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color iconBgColor,
  required Color iconColor,
  void Function()? onTap,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Giữ màu trắng
        borderRadius: BorderRadius.circular(20),
        // Bổ sung viền mỏng và bóng đổ rõ nét hơn
        border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ],
      ),
    ),
  );
}
