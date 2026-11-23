import 'package:flutter/material.dart';

class AppStyles {
  static const String fontFamily = 'SF Pro Display';

  // ==========================================
  // BÓNG ĐỔ CHUNG CHO THẺ (dùng cho toàn app, chỉnh ở đây là áp cho tất cả)
  // ==========================================
  static List<BoxShadow> cardShadow(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.primary.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ==========================================
  // TEXT THEME (Giữ nguyên của bạn)
  // ==========================================
  static final TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 40.0,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.0,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 28.0, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.0,
      fontWeight: FontWeight.w800,
      height: 1.2,
    ),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 24.0, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 20.0, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18.0, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12.0, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 12.0, fontWeight: FontWeight.w500),
  );

  // ==========================================
  // COLOR SCHEMES - BLUE THEME (Ảnh 1)
  // ==========================================
  static const ColorScheme blueLightColorScheme = ColorScheme.light(
    primary: Color(0xFF1565C0),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF90CAF9),
    secondary: Color(0xFF039BE5),
    secondaryContainer: Color(0xFFCBE6FF),
    tertiary: Color(0xFF0277BD), // Đã bổ sung tertiary
    tertiaryContainer: Color(0xFFBEDCFF), // Đã bổ sung tertiaryContainer
    surface: Colors.white,
    surfaceContainer: Color(0xFFF8F9FA),
    error: Color(0xFFB00020),
    errorContainer: Color(0xFFFFDAD6),
    outline: Colors.grey,
  );

  static const ColorScheme blueDarkColorScheme = ColorScheme.dark(
    primary: Color(0xFF90CAF9),
    onPrimary: Color(0xFF0D47A1),
    primaryContainer: Color(0xFF0D47A1),
    secondary: Color(0xFF81D4FA),
    secondaryContainer: Color(0xFF004B73),
    tertiary: Color(0xFFE1F5FE), // Đã bổ sung tertiary
    tertiaryContainer: Color(0xFF1A567D), // Đã bổ sung tertiaryContainer
    surface: Color(0xFF1E1E1E),
    surfaceContainer: Color(0xFF121212),
    error: Color(0xFFCF6679),
    errorContainer: Color(0xFF93000A),
    outline: Colors.grey,
  );

  // ==========================================
  // COLOR SCHEMES - PURPLE THEME (Ảnh 2)
  // ==========================================
  static const ColorScheme purpleColorScheme = ColorScheme.light(
    primary: Color(0xFFA855F7),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE9D5FF),
    secondary: Color(0xFFD946EF),
    secondaryContainer: Color(0xFFFDF4FF),
    tertiary: Color(0xFF8B5CF6), // Tertiary cho bản Tím
    tertiaryContainer: Color(0xFFEDE9FE), // TertiaryContainer cho bản Tím
    surface: Colors.white,
    surfaceContainer: Color(0xFFF3E8FF),
    error: Color(0xFFB3261E),
    outline: Color(0xFFD8B4FE),
  );
}
