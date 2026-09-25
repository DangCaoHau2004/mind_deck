import 'package:flutter/material.dart';

class ColorUtils {
  static Color parseHex(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF1565C0);
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.6;
  }

  static Color getContrastColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black87 : Colors.white;
  }
}
