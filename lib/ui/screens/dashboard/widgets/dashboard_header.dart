import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/dashboard_data_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';

class DashboardHeader extends StatelessWidget {
  final DashboardUserModel user;

  const DashboardHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  "dashboard_system_title".tr,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${"dashboard_greeting".tr} ${user.fullName.split(' ').first} 👋',
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
                    onPressed: () => context.goNamed(AppRoute.notifications.name),
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
}
