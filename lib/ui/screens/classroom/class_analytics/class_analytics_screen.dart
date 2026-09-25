import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_analytics/bloc/class_analytics_state.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';

class AnalyticsScreen extends StatelessWidget {
  final ClassModel classData;

  const AnalyticsScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DI().sl<ClassAnalyticsBloc>()..add(ClassAnalyticsLoaded(classData.id)),
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
    final isAdminOrTutor =
        widget.classData.myRole == 'admin' ||
        widget.classData.myRole == 'owner' ||
        widget.classData.myRole == 'tutor';

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
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.6),
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
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: "Tổng hợp Lớp"),
                Tab(text: "Cá nhân hóa"),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<ClassAnalyticsBloc, ClassAnalyticsState>(
        builder: (context, state) {
          if (state.status == ClassAnalyticsStatus.initial ||
              (state.status == ClassAnalyticsStatus.loading &&
                  state.members.isEmpty &&
                  !state.isRefreshing)) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          if (state.status == ClassAnalyticsStatus.failure && state.members.isEmpty) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Có lỗi xảy ra',
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.error),
              ),
            );
          }

          return TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [
              _buildClassOverviewTab(context, state, colorScheme),
              _buildPersonalTab(context, state, colorScheme, isAdminOrTutor),
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
              if (state.selectedAssignment != null)
                _buildAssignmentProgressCard(context, state, colorScheme),
              const SizedBox(height: 16),
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
        state.personalDeckHealth.isNotEmpty ||
        state.personalHardestCards.isNotEmpty ||
        state.personalReviewWorkload.isNotEmpty;

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
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
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

  Widget _buildMemberSelector(
    BuildContext context,
    ClassAnalyticsState state,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
          value: state.selectedMember?.userId,
          items: state.members.map((member) {
            return DropdownMenuItem<String>(
              value: member.userId,
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
                      (member.user?.fullName ?? '').isNotEmpty
                          ? (member.user?.fullName ?? '')[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    member.user?.fullName ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (userId) {
            if (userId != null) {
              final member = state.members.firstWhere((m) => m.userId == userId);
              context.read<ClassAnalyticsBloc>().add(
                ClassAnalyticsMemberSelected(widget.classData.id, member),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCurrentUserHeader(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
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
    if (state.assignmentProgress.isEmpty) return const SizedBox.shrink();

    int total = 0;
    int completed = 0;
    int inProgress = 0;
    int pending = 0;
    int overdue = 0;

    for (var p in state.assignmentProgress) {
      total += p.count;
      if (p.status == 'completed')
        completed = p.count;
      else if (p.status == 'in_progress')
        inProgress = p.count;
      else if (p.status == 'pending')
        pending = p.count;
      else if (p.status == 'overdue')
        overdue = p.count;
    }

    if (total == 0) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                      color: colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: state.selectedAssignment?.id,
                        icon: Icon(Icons.expand_more_rounded, color: colorScheme.onSurfaceVariant),
                        items: state.assignments.map((assignment) {
                          return DropdownMenuItem<String>(
                            value: assignment.id,
                            child: Text(
                              assignment.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final assignment = state.assignments.firstWhere((a) => a.id == val);
                            context.read<ClassAnalyticsBloc>().add(
                              ClassAnalyticsAssignmentSelected(widget.classData.id, assignment),
                            );
                          }
                        },
                      ),
                    ),
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
                        if (completed > 0)
                          Flexible(
                            flex: completed,
                            child: Container(color: Colors.green.shade500),
                          ),
                        if (inProgress > 0)
                          Flexible(
                            flex: inProgress,
                            child: Container(color: Colors.amber.shade500),
                          ),
                        if (overdue > 0)
                          Flexible(
                            flex: overdue,
                            child: Container(color: Colors.red.shade500),
                          ),
                        if (pending > 0)
                          Flexible(
                            flex: pending,
                            child: Container(color: colorScheme.outlineVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildProgressRow(
                  context,
                  state,
                  Icons.check_circle_rounded,
                  "Đã hoàn thành",
                  completed,
                  'completed',
                  Colors.green.shade500,
                ),
                const SizedBox(height: 12),
                _buildProgressRow(
                  context,
                  state,
                  Icons.timelapse_rounded,
                  "Đang làm dở",
                  inProgress,
                  'in_progress',
                  Colors.amber.shade600,
                ),
                if (overdue > 0) ...[
                  const SizedBox(height: 12),
                  _buildProgressRow(
                    context,
                    state,
                    Icons.warning_rounded,
                    "Quá hạn",
                    overdue,
                    'overdue',
                    Colors.red.shade500,
                  ),
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
    IconData icon,
    String label,
    int count,
    String status,
    Color mainColor,
  ) {
    return InkWell(
      onTap: count > 0 && state.selectedAssignment != null
          ? () {
              _showDrillDownSheet(context, state.selectedAssignment!.id, status, label, mainColor);
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: mainColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mainColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: mainColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: mainColor, fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const Spacer(),
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
        );
      },
    );
  }

  Widget _buildDeckHealthCard(
    BuildContext context,
    List<DeckHealthModel> health,
    String title,
    String badge,
    ColorScheme colorScheme,
  ) {
    if (health.isEmpty) return const SizedBox.shrink();

    int total = 0;
    int newCount = 0;
    int learningCount = 0;
    int reviewCount = 0;
    int masteredCount = 0;

    for (var h in health) {
      total += h.count;
      if (h.state == 'new')
        newCount = h.count;
      else if (h.state == 'learning')
        learningCount = h.count;
      else if (h.state == 'review')
        reviewCount = h.count;
      else if (h.state == 'relearning')
        reviewCount += h.count;
      else if (h.state == 'mastered')
        masteredCount = h.count; // assuming some API might return this, or FSRS states only?
    }
    // FSRS states usually: new, learning, review, relearning. We will map relearning to review or separate it.

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
      padding: const EdgeInsets.all(24),
      child: Column(
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
              child: total > 0
                  ? Row(
                      children: [
                        if (newCount > 0)
                          Flexible(
                            flex: newCount,
                            child: Container(color: Colors.blue.shade500),
                          ),
                        if (learningCount > 0)
                          Flexible(
                            flex: learningCount,
                            child: Container(color: Colors.orange.shade500),
                          ),
                        if (reviewCount > 0)
                          Flexible(
                            flex: reviewCount,
                            child: Container(color: Colors.amber.shade500),
                          ),
                        if (masteredCount > 0)
                          Flexible(
                            flex: masteredCount,
                            child: Container(color: Colors.green.shade500),
                          ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(Colors.blue.shade500, "Mới (New)"),
              _buildLegendItem(Colors.orange.shade500, "Đang học (Learning)"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(Colors.amber.shade500, "Cần ôn (Review)"),
              _buildLegendItem(Colors.green.shade500, "Đã thuộc (Mastered)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHardestCardsCard(
    BuildContext context,
    List<HardestCardModel> cards,
    String title,
    String badge,
    ColorScheme colorScheme,
  ) {
    if (cards.isEmpty) return const SizedBox.shrink();

    // Get max wrong count for scaling
    int maxWrong = cards.fold(0, (max, e) => e.wrongCount > max ? e.wrongCount : max);
    if (maxWrong == 0) maxWrong = 1;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                          '${card.wrongCount} lỗi',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
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
          }).toList(),
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
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.02),
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
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
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

  const _DrillDownSheet({
    required this.classId,
    required this.assignmentId,
    required this.status,
    required this.label,
    required this.color,
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
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
                color: Colors.black.withOpacity(0.1),
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
                        color: widget.color.withOpacity(0.15),
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
              Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
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
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.15),
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
                                student.email,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${student.progressCount} thẻ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                if (student.scorePercentage != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${student.scorePercentage!.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: widget.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
