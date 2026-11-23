import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_leaderboard_response_model.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/bloc/class_leaderboard_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/bloc/class_leaderboard_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_leaderboard/bloc/class_leaderboard_state.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';

/// Bảng xếp hạng lớp: MỘT bảng theo THÁNG (giờ Việt Nam).
///
/// Đóng màn bằng `pop(true)` khi lớp đã tắt bảng xếp hạng để hub tải lại chi tiết lớp.
class ClassLeaderboardScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassLeaderboardScreen({super.key, required this.classData});

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

  static const Color _gold = Color(0xFFFFD700);
  static const Color _goldDark = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<ClassLeaderboardBloc, ClassLeaderboardState>(
      listenWhen: (p, c) => !p.isDisabled && c.isDisabled,
      listener: (context, state) {
        // Lớp vừa tắt bảng xếp hạng: báo, đóng màn, hub tải lại chi tiết lớp.
        CustomToast.show(context, CustomToast.danger(message: 'Lớp đã tắt bảng xếp hạng'));
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
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
          backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<ClassLeaderboardBloc, ClassLeaderboardState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildMonthBar(context, state, colorScheme),
                Expanded(child: _buildBody(context, state, colorScheme)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bộ chọn tháng + cách tính
  // ---------------------------------------------------------------------------

  Widget _buildMonthBar(
    BuildContext context,
    ClassLeaderboardState state,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    final bloc = context.read<ClassLeaderboardBloc>();
    final current = LeaderboardMonth.current();
    final previous = LeaderboardMonth.previous(current);
    final selected = state.selectedMonth ?? current;
    final isOther = selected != current && selected != previous;
    final board = state.leaderboard;
    // Nhãn lấy từ `month` của server; chưa có dữ liệu thì dùng tháng đang chọn.
    final shownMonth = (board != null && board.month.isNotEmpty) ? board.month : selected;
    final weights = board?.weights ?? const LeaderboardWeights();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tháng này'),
                  selected: selected == current,
                  onSelected: (_) => bloc.add(ClassLeaderboardMonthChanged(classData.id, null)),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Tháng trước'),
                  selected: selected == previous,
                  onSelected: (_) => bloc.add(ClassLeaderboardMonthChanged(classData.id, previous)),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(CupertinoIcons.calendar, size: 16),
                  label: Text(isOther ? LeaderboardMonth.label(selected) : 'Tháng khác'),
                  selected: isOther,
                  onSelected: (_) => _pickMonth(context, selected),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            LeaderboardMonth.label(shownMonth),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            'Điểm = ${weights.testPercent}% điểm kiểm tra + ${weights.diligencePercent}% mức chăm chỉ. '
            'Người không có bài kiểm tra trong tháng chỉ tính theo mức chăm chỉ.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Chọn tháng cũ hơn: danh sách từ tháng hiện tại lùi về 01/2000 (không có tháng tương lai).
  Future<void> _pickMonth(BuildContext context, String selected) async {
    final bloc = context.read<ClassLeaderboardBloc>();
    final current = LeaderboardMonth.current();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final count = LeaderboardMonth.countBack(current);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            child: ListView.builder(
              itemCount: count,
              itemBuilder: (_, i) {
                final month = LeaderboardMonth.shift(current, -i);
                final isSelected = month == selected;
                return ListTile(
                  title: Text(
                    LeaderboardMonth.label(month),
                    style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(ctx, month),
                );
              },
            ),
          ),
        );
      },
    );
    if (picked != null) bloc.add(ClassLeaderboardMonthChanged(classData.id, picked));
  }

  // ---------------------------------------------------------------------------
  // Thân màn hình
  // ---------------------------------------------------------------------------

  Widget _buildBody(BuildContext context, ClassLeaderboardState state, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final board = state.leaderboard;

    if (state.status == ClassLeaderboardStatus.initial ||
        (state.status == ClassLeaderboardStatus.loading && board == null)) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (state.status == ClassLeaderboardStatus.failure && board == null) {
      return _buildMessage(
        context,
        icon: state.isDisabled ? CupertinoIcons.eye_slash : CupertinoIcons.exclamationmark_circle,
        text: state.isDisabled
            ? 'Lớp này đã tắt bảng xếp hạng'
            : (state.errorMessage ?? 'Có lỗi xảy ra'),
        onRetry: state.isDisabled
            ? null
            : () => context.read<ClassLeaderboardBloc>().add(ClassLeaderboardLoaded(classData.id)),
        isError: !state.isDisabled,
      );
    }

    if (board == null) return const SizedBox.shrink();

    final me = board.me;
    final isEmpty = board.items.isEmpty;
    return Stack(
      children: [
        CommonRefresh(
          onRefresh: () async {
            final bloc = context.read<ClassLeaderboardBloc>();
            bloc.add(ClassLeaderboardRefreshed(classData.id));
            await bloc.stream.firstWhere((s) => !s.isRefreshing);
          },
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, me != null ? 120 : 24),
              sliver: isEmpty
                  ? SliverToBoxAdapter(child: _buildEmpty(context, state))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              board.hasMore
                                  ? 'Top ${board.items.length} / ${board.totalRanked} học viên '
                                        '(hiển thị tối đa ${ClassLeaderboardBloc.pageLimit})'
                                  : '${board.totalRanked} học viên được xếp hạng',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        final entry = board.items[index - 1];
                        return _buildLeaderboardItem(context, entry, colorScheme);
                      }, childCount: board.items.length + 1),
                    ),
            ),
          ],
        ),
        if (me != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCurrentUserRankBanner(me, colorScheme),
          ),
      ],
    );
  }

  /// Chưa ai có điểm: trạng thái hợp lệ (đầu tháng, chưa ai ôn thẻ, chưa có bài kết thúc), không phải lỗi.
  Widget _buildEmpty(BuildContext context, ClassLeaderboardState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final current = LeaderboardMonth.current();
    final viewing = state.selectedMonth ?? current;
    final canGoPrevious = viewing != LeaderboardMonth.earliest;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      child: Column(
        children: [
          Icon(CupertinoIcons.rosette, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Chưa có ai có điểm trong tháng này',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Có thể do đầu tháng, chưa ai ôn thẻ của lớp, hoặc chưa có bài kiểm tra nào kết thúc.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          if (canGoPrevious) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.read<ClassLeaderboardBloc>().add(
                ClassLeaderboardMonthChanged(classData.id, LeaderboardMonth.previous(viewing)),
              ),
              icon: const Icon(CupertinoIcons.calendar),
              label: const Text('Xem tháng trước'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String text,
    VoidCallback? onRetry,
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isError ? colorScheme.error : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Điểm xếp hạng 0–100 (tối đa 2 chữ số thập phân, bỏ số 0 thừa).
  String _valueText(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

  /// "Kiểm tra: 80 · nộp 2/2 bài · 100 thẻ đã ôn" hoặc "Chưa có bài · 20 thẻ đã ôn".
  String _subText(LeaderboardEntryModel e) {
    final test = e.testScore == null
        ? 'Chưa có bài'
        : 'Kiểm tra: ${_valueText(e.testScore!)} · nộp ${e.submittedCount}/${e.testCount} bài';
    return '$test · ${e.cardsReviewed} thẻ đã ôn';
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    LeaderboardEntryModel entry,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    // Hiển thị đúng `rank` server trả (đồng hạng kiểu 1, 1, 3), không tự đánh số lại.
    final rank = entry.rank ?? 0;
    Color medalColor;
    Widget rankWidget;

    if (rank == 1) {
      medalColor = _gold; // Vàng
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
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Text(
          entry.rank == null ? '-' : '$rank',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Highlight top 1 với viền mỏng đặc biệt
    final isTop1 = rank == 1;

    return Container(
      margin: EdgeInsets.only(bottom: isTop1 ? 16 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTop1
              ? _gold.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isTop1 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isTop1 ? 0.05 : 0.02),
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
            backgroundColor: isTop1 ? _gold.withValues(alpha: 0.15) : colorScheme.primaryContainer,
            child: Text(
              entry.fullName.isNotEmpty ? entry.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: isTop1 ? _goldDark : colorScheme.onPrimaryContainer,
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
                Text(
                  _subText(entry),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _valueText(entry.value),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: isTop1 ? _goldDark : colorScheme.primary,
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
      decoration: BoxDecoration(color: medalColor.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(icon, color: medalColor, size: 28),
    );
  }

  /// Vị trí của tôi. `rank == null` nghĩa là chưa được xếp hạng (điểm ≤ 0).
  Widget _buildCurrentUserRankBanner(LeaderboardEntryModel me, ColorScheme colorScheme) {
    final ranked = me.rank != null;
    final detail = [
      if (ranked) '${_valueText(me.value)} điểm',
      if (me.testScore != null) 'Kiểm tra ${_valueText(me.testScore!)}',
      '${me.cardsReviewed} thẻ đã ôn',
    ].join(' · ');
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
            color: colorScheme.primary.withValues(alpha: 0.3),
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
                color: colorScheme.onPrimary.withValues(alpha: 0.2),
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
                    ranked ? 'Hạng hiện tại của bạn' : 'Chưa có hạng',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
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
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                ranked ? '#${me.rank}' : '--',
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
