import 'package:flutter/material.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Hình bộ thẻ (chi tiết bộ thẻ và bản xem trước trong form): ô vuông bo góc chứa icon, hai thẻ nhạt nghiêng
/// thò ra phía sau bên phải. [size] là cạnh ô vuông.
class DeckIllustration extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const DeckIllustration({super.key, required this.color, required this.icon, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    final cardWidth = size * 0.75;

    return SizedBox(
      width: size * 1.3,
      height: size * 1.15,
      child: Stack(
        children: [
          Positioned(
            left: size * 0.35,
            top: 0,
            child: Transform.rotate(
              angle: 0.16,
              child: Container(
                width: cardWidth,
                height: size * 0.85,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.28),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
          Positioned(
            left: size * 0.2,
            top: size * 0.05,
            child: Transform.rotate(
              angle: 0.06,
              child: Container(
                width: cardWidth,
                height: size * 0.85,
                decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: radius,
                // Màu quá sáng thì thêm viền để không chìm vào nền nhạt
                border: ColorUtils.isLightColor(color)
                    ? Border.all(color: Colors.grey.shade300)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: ColorUtils.getContrastColor(color), size: size * 0.42),
            ),
          ),
        ],
      ),
    );
  }
}
