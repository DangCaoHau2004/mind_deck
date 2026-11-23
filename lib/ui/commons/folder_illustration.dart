import 'package:flutter/material.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Hình thư mục dùng chung (danh sách, chi tiết thư mục, bản xem trước trong form): nắp màu đậm phía sau,
/// tờ giấy trắng thò lên và thân thư mục theo màu chọn chứa icon. Thiết kế gốc 60×56, [scale] phóng to
/// cả hình theo tỉ lệ.
class FolderIllustration extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double scale;

  const FolderIllustration({super.key, required this.color, required this.icon, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60 * scale,
      height: 56 * scale,
      child: FittedBox(
        child: SizedBox(
          width: 60,
          height: 56,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: 34,
                height: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(color, Colors.black, 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 4,
                height: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              ),
              Positioned.fill(
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    // Màu quá sáng thì thêm viền để không chìm vào nền nhạt
                    border: ColorUtils.isLightColor(color)
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                  ),
                  child: Icon(icon, color: ColorUtils.getContrastColor(color), size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
