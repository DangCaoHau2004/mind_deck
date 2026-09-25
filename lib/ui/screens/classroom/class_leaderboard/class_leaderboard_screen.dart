import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_leaderboard_response_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/bloc/class_leaderboard_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/bloc/class_leaderboard_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/bloc/class_leaderboard_state.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';

class ClassLeaderboardScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassLeaderboardScreen({Key? key, required this.classData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<ClassLeaderboardBloc>()..add(ClassLeaderboardLoaded(classData.id)),
      child: _ClassLeaderboardView(classData: classData),
    );
  }
}

class _ClassLeaderboardView extends StatelessWidget {
  final ClassModel classData;

  const _ClassLeaderboardView({required this.classData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Bảng xếp hạng",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<ClassLeaderboardBloc, ClassLeaderboardState>(
        builder: (context, state) {
          final bool isInitialLoading =
              state.status == ClassLeaderboardStatus.initial ||
              (state.status == ClassLeaderboardStatus.loading && state.leaderboard == null);

          Widget content;
          if (isInitialLoading) {
            content = Center(child: CircularProgressIndicator(color: colorScheme.primary));
          } else if (state.status == ClassLeaderboardStatus.failure && state.leaderboard == null) {
            content = Center(
              child: Text(
                state.errorMessage ?? 'Có lỗi xảy ra',
                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
              ),
            );
          } else if (state.leaderboard == null || state.leaderboard!.top10.isEmpty) {
            content = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.rosette, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có dữ liệu bảng xếp hạng.",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          } else {
            content = CommonRefresh(
              onRefresh: () async {
                final bloc = context.read<ClassLeaderboardBloc>();
                bloc.add(ClassLeaderboardRefreshed(classData.id));
                await bloc.stream.firstWhere((s) => !s.isRefreshing);
              },
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = state.leaderboard!.top10[index];
                      return _buildLeaderboardItem(context, entry, index, colorScheme);
                    }, childCount: state.leaderboard!.top10.length),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              content,
              if (state.leaderboard != null && state.leaderboard!.currentUserRank != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildCurrentUserRankBanner(
                    state.leaderboard!.currentUserRank!,
                    colorScheme,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    LeaderboardEntryModel entry,
    int index,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    final rank = index + 1;
    Color medalColor;
    Widget rankWidget;

    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Vàng
      rankWidget = _buildMedalWidget(medalColor, Icons.workspace_premium_rounded);
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Bạc
      rankWidget = _buildMedalWidget(medalColor, Icons.workspace_premium_rounded);
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Đồng
      rankWidget = _buildMedalWidget(medalColor, Icons.workspace_premium_rounded);
    } else {
      rankWidget = Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        child: Text(
          '$rank',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Highlight top 1 với viền mỏng đặc biệt (Tuỳ chọn thêm để đẹp hơn)
    final isTop1 = rank == 1;

    return Container(
      margin: EdgeInsets.only(bottom: isTop1 ? 16 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTop1
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : colorScheme.outlineVariant.withOpacity(0.5),
          width: isTop1 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isTop1 ? 0.05 : 0.02),
            blurRadius: isTop1 ? 16 : 10,
            offset: Offset(0, isTop1 ? 6 : 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          rankWidget,
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 24,
            backgroundColor: isTop1
                ? const Color(0xFFFFD700).withOpacity(0.15)
                : colorScheme.primaryContainer,
            child: Text(
              entry.fullName.isNotEmpty ? entry.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: isTop1 ? const Color(0xFFD4AF37) : colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.layers_alt_fill,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.cardsMasteredCount} thẻ thuộc',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.totalScore}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: isTop1 ? const Color(0xFFD4AF37) : colorScheme.primary,
                ),
              ),
              Text(
                'điểm',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedalWidget(Color medalColor, IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: medalColor.withOpacity(0.15), shape: BoxShape.circle),
      child: Icon(icon, color: medalColor, size: 28),
    );
  }

  Widget _buildCurrentUserRankBanner(String rank, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32), // Floating effect
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false, // Vì đã có margin bottom
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_rounded, color: colorScheme.onPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hạng hiện tại của bạn',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cố gắng vươn lên nhé!',
                    style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
