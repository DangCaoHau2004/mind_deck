import 'package:flutter/material.dart';

/// Giữ MỘT animation chung cho cả danh sách: [active] bật thì vệt sáng chạy, tắt thì dừng hẳn.
/// Các thẻ bọc bằng [ShimmerSweep] dùng chung animation này nên vệt sáng chạy đồng bộ.
class ShimmerScope extends StatefulWidget {
  final bool active;
  final Widget child;

  const ShimmerScope({super.key, required this.active, required this.child});

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ShimmerScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerData(animation: widget.active ? _controller : null, child: widget.child);
  }
}

class _ShimmerData extends InheritedWidget {
  /// null khi vệt sáng đang tắt.
  final Animation<double>? animation;

  const _ShimmerData({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_ShimmerData oldWidget) => oldWidget.animation != animation;
}

/// Vệt sáng nhạt lướt ngang qua [child] (không làm mờ, không chặn chạm). Ngoài [ShimmerScope] hoặc
/// khi scope đang tắt thì chỉ hiện [child].
class ShimmerSweep extends StatelessWidget {
  final Widget child;

  const ShimmerSweep({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final animation = context.dependOnInheritedWidgetOfExactType<_ShimmerData>()?.animation;
    if (animation == null) return child;

    final tint = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [tint.withValues(alpha: 0), tint, tint.withValues(alpha: 0)],
          stops: const [0.3, 0.5, 0.7],
          transform: _SlideTransform(animation.value * 2 - 1),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

/// Dịch gradient ngang theo [percent] (-1 đến 1) bề rộng.
class _SlideTransform extends GradientTransform {
  final double percent;

  const _SlideTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}
