import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/home/home_user_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/core/theme/app_styles.dart';
import 'package:mind_deck/ui/screens/home/widgets/streak_badge.dart';

/// Lời chào + chuỗi ngày học + nút thông báo.
class HomeHeader extends StatelessWidget {
  final HomeUserModel user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Tên tiếng Việt: tên gọi là từ cuối.
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    final name = parts.last.isEmpty ? 'home_greeting_fallback'.tr : parts.last;
    final unread = user.unreadNotifications;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${'home_greeting'.tr} $name 👋',
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        StreakBadge(streak: user.currentStreak, isIntact: user.isIntact),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppStyles.cardShadow(colorScheme),
          ),
          child: IconButton(
            style: IconButton.styleFrom(backgroundColor: colorScheme.surface),
            onPressed: () => context.pushNamed(AppRoute.notifications.name),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: Icon(Icons.notifications_none_rounded, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
