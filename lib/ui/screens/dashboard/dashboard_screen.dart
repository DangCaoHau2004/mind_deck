import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/ui/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:mind_deck/ui/screens/dashboard/bloc/dashboard_event.dart';
import 'package:mind_deck/ui/screens/dashboard/bloc/dashboard_state.dart';
import 'package:mind_deck/data/models/dashboard_data_model.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DI().sl<DashboardBloc>()..add(const DashboardLoadStarted()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Dữ liệu mẫu danh sách lớp học không gian chung (Nhiều hơn 1 data)

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: Stack(
        children: [
          // Hiệu ứng khối màu mờ phá cách phía nền
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
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardInitial || state is DashboardLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is DashboardFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.error, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<DashboardBloc>().add(const DashboardLoadStarted()),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DashboardSuccess) {
                  final data = state.data;
                  return CommonRefresh(
                    onRefresh: () async {
                      final bloc = context.read<DashboardBloc>();
                      bloc.add(const DashboardLoadStarted());
                      await bloc.stream.firstWhere((s) => s is! DashboardLoading);
                    },
                    slivers: [
                      _buildHeader(context, textTheme, colorScheme, data.user),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildGlowingStreakCard(
                              textTheme,
                              colorScheme,
                              data.user.currentStreak,
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeader('Thống kê tiến độ FSRS', textTheme, colorScheme),
                            const SizedBox(height: 12),
                            _buildFlChartStatsCard(textTheme, colorScheme, data.fsrsStats),
                            const SizedBox(height: 32),
                            _buildSectionHeader('Học gần đây', textTheme, colorScheme),
                            const SizedBox(height: 16),
                            _buildRecentLearningList(textTheme, colorScheme, data.recentDecks),
                            const SizedBox(height: 32),
                            _buildSectionHeader('Lớp học không gian chung', textTheme, colorScheme),
                            const SizedBox(height: 16),
                            ...data.classes.map(
                              (room) => _buildClassroomCard(context, room, textTheme, colorScheme),
                            ),
                            const SizedBox(height: 30),
                          ]),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER GREETING
  // ==========================================
  Widget _buildHeader(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    DashboardUserModel user,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HỆ THỐNG GHI NHỚ NGẮN HẠN & DÀI HẠN',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chào ${user.fullName.split(' ').first} 👋',
                  style: textTheme.displayMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_rounded, color: colorScheme.primary, size: 24),
                    onPressed: () {
                      context.pushNamed(AppRoute.notifications.name);
                    },
                  ),
                  if (user.unreadNotifications > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          user.unreadNotifications > 9 ? '9+' : '${user.unreadNotifications}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  // ==========================================
  // 1. STREAK CAPSULE
  // ==========================================
  Widget _buildGlowingStreakCard(TextTheme textTheme, ColorScheme colorScheme, int currentStreak) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orangeAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentStreak NGÀY LIÊN TIẾP ',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Duy trì mục tiêu để giữ vững chuỗi!',
                    style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. THỐNG KÊ TIẾN ĐỘ VỚI FL_CHART
  // ==========================================
  Widget _buildFlChartStatsCard(
    TextTheme textTheme,
    ColorScheme colorScheme,
    DashboardFsrsStatsModel fsrsStats,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            children: [
              Text(
                'Khả năng truy xuất bộ nhớ (R)',
                style: textTheme.titleSmall?.copyWith(color: colorScheme.outline),
              ),
              Text(
                'Ổn định: ${fsrsStats.retentionRate}%',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // fl_chart LineChart tích hợp chuẩn xác và mượt mà
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (fsrsStats.chart.isEmpty ? 1 : fsrsStats.chart.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: fsrsStats.chart.isEmpty
                        ? [const FlSpot(0, 0)]
                        : fsrsStats.chart.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.accuracy);
                          }).toList(),
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.2),
                          colorScheme.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Chỉ số phân bổ thẻ khoa học, không bị cấn mắt
          Row(
            children: [
              Expanded(
                child: _buildSubStatInfo(
                  '${fsrsStats.dueTodayCount} Thẻ',
                  'Cần ôn hôm nay ',
                  colorScheme.secondary,
                  textTheme,
                ),
              ),
              Container(width: 1, height: 30, color: colorScheme.outline.withValues(alpha: 0.15)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _buildSubStatInfo(
                    '${fsrsStats.masteredCount} Thẻ',
                    'Đã thuộc lòng (Mastered) ',
                    Colors.green,
                    textTheme,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubStatInfo(String value, String label, Color indicatorColor, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ==========================================
  // 3. HỌC GẦN ĐÂY
  // ==========================================
  Widget _buildRecentLearningList(
    TextTheme textTheme,
    ColorScheme colorScheme,
    List<DashboardRecentDeckModel> items,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chưa có học phần nào học gần đây.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final accentColor = _parseColor(item.color, colorScheme.primary);

          return Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Material(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  context.pushNamed(AppRoute.deckDetail.name, pathParameters: {'id': item.id});
                },
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.05),
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon == 'code'
                                  ? Icons.code_rounded
                                  : (item.icon == 'language'
                                        ? Icons.language_rounded
                                        : Icons.folder_special_rounded),
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "HỌC TIẾP",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.play_arrow_rounded, color: accentColor, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.name,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.progressText,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(_parseProgress(item.progressText) * 100).toInt()}%',
                            style: textTheme.bodySmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _parseProgress(item.progressText),
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: accentColor,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 4. THÀNH PHẦN LỚP HỌC (DÙNG CHO NHIỀU DATA)
  // ==========================================
  // Cập nhật hàm này trong class DashboardScreen để truyền thêm BuildContext context
  Widget _buildClassroomCard(
    BuildContext context,
    DashboardClassModel room,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              // TODO: Điều hướng sang ClassHubScreen khi bấm vào thẻ lớp học
              // context.pushNamed(
              //   AppRoute.classroomDetail.name,
              //   pathParameters: {'id': room.id},
              // );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  // Avatar/Icon không gian lớp học tinh tế
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withOpacity(0.15),
                          colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Icon(Icons.school_rounded, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Dấu chấm tròn (Active dot) tạo cảm giác không gian đang live
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                room.activityText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nút Go/Arrow mềm mại
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.arrow_forward_rounded, color: colorScheme.primary, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TIÊU ĐỀ KHỐI CHUNG
  Widget _buildSectionHeader(String title, TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Icon(Icons.arrow_right_alt_rounded, color: colorScheme.primary, size: 24),
      ],
    );
  }

  Color _parseColor(String colorString, Color defaultColor) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      }
      return defaultColor;
    } catch (e) {
      return defaultColor;
    }
  }

  double _parseProgress(String progressText) {
    // "10/18 thẻ" => 10/18 = 0.55
    try {
      final parts = progressText.split(' ')[0].split('/');
      if (parts.length == 2) {
        final current = double.parse(parts[0]);
        final total = double.parse(parts[1]);
        if (total == 0) return 0;
        return current / total;
      }
    } catch (e) {
      // ignore
    }
    return 0;
  }
}
