import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Khung chứa hai tab Thư mục / Học phần. Tiêu đề và thanh chuyển tab nằm trong từng tab
/// (`LibraryHeader`) để cuộn cùng danh sách.
class LibraryScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const LibraryScreen({super.key, required this.navigationShell, required this.children});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: widget.navigationShell.currentIndex,
          children: widget.children.map((child) => _KeepAliveView(child: child)).toList(),
        ),
      ),
    );
  }
}

class _KeepAliveView extends StatefulWidget {
  final Widget child;
  const _KeepAliveView({required this.child});

  @override
  State<_KeepAliveView> createState() => _KeepAliveViewState();
}

class _KeepAliveViewState extends State<_KeepAliveView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
