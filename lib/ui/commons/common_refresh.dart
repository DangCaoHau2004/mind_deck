import 'package:flutter/material.dart';
import 'dart:math' as math;

class CommonRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;

  const CommonRefresh({super.key, required this.onRefresh, required this.slivers, this.controller});

  @override
  State<CommonRefresh> createState() => _CommonRefreshState();
}

class _CommonRefreshState extends State<CommonRefresh> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;
  late Animation<double> _animation;

  double _pullDistance = 0.0;
  bool _isRefreshing = false;

  final double _refreshThreshold = 120.0; // Điểm kích hoạt refresh
  final double _refreshingHeight = 60.0; // Vị trí neo lại khi đang xoay load
  final double _maxPullDistance = 250.0; // Giới hạn kéo tối đa

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _animController.addListener(() {
      setState(() {
        _pullDistance = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _animation = Tween<double>(
      begin: _pullDistance,
      end: target,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward(from: 0.0);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isRefreshing) return;

    if (_scrollController.hasClients && _scrollController.offset <= 0) {
      if (event.delta.dy > 0 || _pullDistance > 0) {
        setState(() {
          double friction = 1.0 - (_pullDistance / _maxPullDistance).clamp(0.0, 0.85);
          _pullDistance += event.delta.dy * friction;

          if (_pullDistance < 0) _pullDistance = 0;
        });
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) async {
    if (_isRefreshing) return;

    if (_pullDistance >= _refreshThreshold) {
      setState(() {
        _isRefreshing = true;
      });
      _animateTo(_refreshingHeight);

      await widget.onRefresh();

      if (!mounted) return;

      setState(() {
        _isRefreshing = false;
      });
      _animateTo(0.0);
    } else if (_pullDistance > 0) {
      _animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double percentage = (_pullDistance / _refreshThreshold).clamp(0.0, 1.0);
    final bool isArmed = _pullDistance >= _refreshThreshold;

    return Listener(
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _pullDistance,
            child: Center(
              child: _isRefreshing
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.primary,
                      ),
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
            ),
          ),

          Transform.translate(
            offset: Offset(0, _pullDistance),
            child: CustomScrollView(controller: _scrollController, slivers: widget.slivers),
          ),
        ],
      ),
    );
  }
}
