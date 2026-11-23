import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/ui/screens/main_shell/bottom_bar_slot.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tabs = [
      _BottomNavItem(icon: Icons.dashboard_rounded, label: 'Trang chủ'),
      _BottomNavItem(icon: Icons.local_library_rounded, label: 'Thư viện'),
      _BottomNavItem(icon: Icons.explore_rounded, label: 'Khám phá'),
      _BottomNavItem(icon: Icons.person_rounded, label: 'Hồ sơ'),
    ];

    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true, // Cho phép nội dung body cuộn xuống dưới thanh BottomBar mờ
      body: navigationShell,
      // Thanh điều hướng và thanh thay thế (vd chọn nhiều) dùng chung một chỗ: thanh cũ trượt xuống mờ dần,
      // thanh mới trượt lên, chiều cao đổi mượt từ dưới lên.
      bottomNavigationBar: ValueListenableBuilder<Widget?>(
        valueListenable: bottomBarSlot,
        builder: (context, slot, navBar) => AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
            child: slot != null
                ? KeyedSubtree(key: const ValueKey('bottom_slot'), child: slot)
                : KeyedSubtree(key: const ValueKey('bottom_nav'), child: navBar!),
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Hiệu ứng dịch chuyển viên thuốc chọn (Liquid active pill background)
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutBack,
                        alignment: Alignment(-1.0 + (currentIndex * 2.0 / (tabs.length - 1)), 0.0),
                        child: FractionallySizedBox(
                          widthFactor: 1 / tabs.length,
                          child: Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.85),
                                  colorScheme.tertiary.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Hàng chứa các tab icon & label
                      Row(
                        children: List.generate(tabs.length, (index) {
                          final tab = tabs[index];
                          final isSelected = index == currentIndex;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onTabTapped(index),
                              child: AnimatedScale(
                                scale: isSelected ? 1.05 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        tab.icon,
                                        key: ValueKey('${tab.label}_$isSelected'),
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface.withValues(alpha: 0.55),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tab.label,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface.withValues(alpha: 0.55),
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  _BottomNavItem({required this.icon, required this.label});
}
