import 'package:flutter/material.dart';

class CustomColors {
  // Loading Dot Colors
  static const Color loadingDotIndigo = Color(0xFF6366F1);
  static const Color loadingDotPurple = Color(0xFFA855F7);
  static const Color loadingDotPink = Color(0xFFEC4899);

  // Toast Colors
  static const Color toastPrimary = Color(0xFF1E88E5);
  static const Color toastSuccess = Color(0xFF43A047);
  static const Color toastDanger = Color(0xFFE53935);
  static const Color toastWarning = Color(0xFFFFA000);
  static const Color toastGeneral = Color(0xFF37474F);

  // Mức độ chính xác (biểu đồ Home): từ 80% dùng màu chính của theme
  static const Color accuracyWarning = Color(0xFFFF9800); // cam, 30–79%
  static const Color accuracyBad = Color(0xFFE57373); // đỏ nhạt, dưới 30%
}
