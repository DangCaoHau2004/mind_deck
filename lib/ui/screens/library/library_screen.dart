import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LibraryScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const LibraryScreen({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.children.length,
      initialIndex: widget.navigationShell.currentIndex,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _tabController.index) {
      _tabController.animateTo(
        widget.navigationShell.currentIndex,
        duration: Duration.zero,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Thư viện',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: TabBar(
            controller: _tabController,
            onTap: (index) => widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade500,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Thư mục'),
              Tab(text: 'Học phần'),
            ],
          ),
        ),
      ),
      // ko có animation lướt
      // THAY ĐỔI TOÀN BỘ BODY Ở ĐÂY
      body: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return IndexedStack(
            index: _tabController.index,
            children: widget.children
                .map((child) => _KeepAliveView(child: child))
                .toList(),
          );
        },
      ),
      // có animation lướt
      // body: TabBarView(
      //   controller: _tabController,
      //   physics: const HardSwipePhysics(),
      //   children: widget.children.map((child) => _KeepAliveView(child: child)).toList(),
      // ),
    );
  }
}

// Định nghĩa Physics ngay tại file để không phải thêm file mới
class HardSwipePhysics extends PageScrollPhysics {
  const HardSwipePhysics({super.parent});

  @override
  HardSwipePhysics applyTo(ScrollPhysics? ancestor) {
    return HardSwipePhysics(parent: buildParent(ancestor));
  }

  // Tăng tốc độ cần thiết để kích hoạt vuốt
  @override
  double get minFlingVelocity => 3000.0;

  // Giảm độ nhạy khi kéo tay
  @override
  double get dragStartDistanceMotionThreshold => 30.0;

  @override
  bool get allowImplicitScrolling => false;
}

class _KeepAliveView extends StatefulWidget {
  final Widget child;
  const _KeepAliveView({required this.child});

  @override
  State<_KeepAliveView> createState() => _KeepAliveViewState();
}

class _KeepAliveViewState extends State<_KeepAliveView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
