import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mind_deck/constants/custom_colors.dart';

enum LoadingType { dots, classic }

class CommonLoading extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final LoadingType type;
  final Color? color;

  const CommonLoading({
    super.key,
    this.title,
    this.subtitle,
    this.type = LoadingType.classic,
    this.color,
  });

  const CommonLoading.dots({super.key, this.title, this.subtitle, this.color})
    : type = LoadingType.dots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (type == LoadingType.classic) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: color ?? colorScheme.primary),
            if (title != null && title!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DotsLoadingIndicator(),
          const SizedBox(height: 32),
          if (title != null && title!.isNotEmpty)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: CustomColors.loadingDotPurple,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DotsLoadingIndicator extends StatefulWidget {
  const _DotsLoadingIndicator();

  @override
  State<_DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<_DotsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Tốc độ lặp mượt mà
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DotInfo(
          color: CustomColors.loadingDotIndigo,
          delay: 0.0,
          controller: _controller,
        ), // Xanh indigo
        const SizedBox(width: 12),
        _DotInfo(
          color: CustomColors.loadingDotPurple,
          delay: math.pi / 4,
          controller: _controller,
        ), // Tím purple
        const SizedBox(width: 12),
        _DotInfo(
          color: CustomColors.loadingDotPink,
          delay: math.pi / 2,
          controller: _controller,
        ), // Hồng pink
      ],
    );
  }
}

class _DotInfo extends StatelessWidget {
  final Color color;
  final double delay;
  final AnimationController controller;

  const _DotInfo({
    required this.color,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Tính toán độ nảy bằng sine wave
        double offset = math.sin((controller.value * math.pi * 2) - delay);
        // Chỉ nảy lên (khi offset > 0)
        if (offset < 0) offset = 0;

        return Transform.translate(
          offset: Offset(0, -offset * 16),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
