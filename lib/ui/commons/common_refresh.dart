import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';

/// Kéo-để-làm-mới dùng chung cho các màn dạng sliver.
///
/// Dựa trên `CupertinoSliverRefreshControl` (có sẵn trong Flutter): chỉ thanh cuộn dọc chính mới kích hoạt,
/// nên vuốt ngang ở danh sách con không kéo cả màn xuống. Cần physics có nảy ở đầu trang
/// (`BouncingScrollPhysics`), đặt luôn ở đây để không phụ thuộc cấu hình chung.
class CommonRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;

  const CommonRefresh({super.key, required this.onRefresh, required this.slivers, this.controller});

  /// Kéo quá khoảng này thì kích hoạt làm mới.
  static const double _refreshThreshold = 120.0;

  /// Chiều cao giữ lại cho vòng xoay trong lúc đang làm mới.
  static const double _refreshingHeight = 60.0;

  Future<void> _handleRefresh(BuildContext context) async {
    // Đang offline (chưa tải được hồ sơ) thì thử tải lại hồ sơ luôn; không offline thì bloc tự bỏ qua.
    context.read<AuthBloc>().add(const ProfileRetried());
    await onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: _refreshThreshold,
          refreshIndicatorExtent: _refreshingHeight,
          onRefresh: () => _handleRefresh(context),
          builder: _buildIndicator,
        ),
        ...slivers,
      ],
    );
  }

  /// Giữ giao diện cũ: icon xoay và rõ dần theo độ kéo, đủ ngưỡng thì đổi màu, đang tải thì hiện vòng xoay.
  static Widget _buildIndicator(
    BuildContext context,
    RefreshIndicatorMode mode,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
    final isArmed = mode == RefreshIndicatorMode.armed;
    final isRefreshing = mode == RefreshIndicatorMode.refresh || mode == RefreshIndicatorMode.done;

    return Center(
      child: isRefreshing
          ? SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary),
            )
          : Opacity(
              opacity: percentage,
              child: Transform.rotate(
                angle: percentage * math.pi,
                child: Icon(
                  Icons.refresh,
                  color: isArmed ? colorScheme.primary : colorScheme.outline,
                  size: 28,
                ),
              ),
            ),
    );
  }
}
