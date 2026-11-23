import 'package:flutter/material.dart';

/// Nút quay lại nổi (tròn đen mờ) cho màn chi tiết đang hiện skeleton toàn trang, khi chưa có dữ liệu
/// để dựng thanh nút đầy đủ. Dùng bên trong một `Stack`.
class SkeletonBackButton extends StatelessWidget {
  const SkeletonBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      child: SizedBox(
        height: kToolbarHeight,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              iconSize: 20,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(10),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
      ),
    );
  }
}
