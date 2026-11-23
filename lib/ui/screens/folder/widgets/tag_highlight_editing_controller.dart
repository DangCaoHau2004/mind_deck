import 'package:flutter/material.dart';

class TagHighlightEditingController extends TextEditingController {
  TagHighlightEditingController({super.text, Map<String, Color>? tagColors})
    : _tagColors = Map<String, Color>.from(tagColors ?? {});

  static final RegExp _tagRegex = RegExp(r'(#[^\s]+)');

  Map<String, Color> _tagColors = {};

  Map<String, Color> get tagColors => Map.unmodifiable(_tagColors);

  /// Cập nhật bảng màu tag
  void setTagColors(Map<String, Color> colors) {
    if (_mapEquals(_tagColors, colors)) return;
    _tagColors = Map<String, Color>.from(colors);
    notifyListeners();
  }

  /// Thêm hoặc ghi đè màu cho một hoặc nhiều tag (giữ bộ nhớ màu không bị mất)
  void addTagColors(Map<String, Color> colors) {
    if (colors.isEmpty) return;
    bool changed = false;
    for (final entry in colors.entries) {
      if (_tagColors[entry.key] != entry.value) {
        _tagColors[entry.key] = entry.value;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool _mapEquals(Map<String, Color> a, Map<String, Color> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = style ?? const TextStyle();

    // Màu cho tag đang gõ dở (chưa nhấn Space) - dạng highlight nhẹ
    final inProgressTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final inProgressBgColor = isDark
        ? Colors.grey.shade800.withValues(alpha: 0.5)
        : Colors.grey.shade300.withValues(alpha: 0.5);

    // Màu xám cho tag không có trong DB
    final notFoundTagColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final notFoundBgColor = isDark
        ? Colors.grey.shade800.withValues(alpha: 0.7)
        : Colors.grey.shade300.withValues(alpha: 0.7);

    final List<TextSpan> spans = [];
    int start = 0;

    for (final match in _tagRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: style));
      }

      final rawTag = match.group(0) ?? '';
      final tagName = rawTag.startsWith('#')
          ? rawTag.substring(1).toLowerCase()
          : rawTag.toLowerCase();

      final isEndedWithSpace = match.end < text.length && text[match.end] == ' ';
      final isCompletedTag = isEndedWithSpace || match.end < text.length;

      final TextStyle tagStyle;
      if (!isCompletedTag && match.end == text.length) {
        // Tag đang gõ dở (chưa Space)
        tagStyle = baseStyle.copyWith(
          color: inProgressTextColor,
          fontWeight: FontWeight.w600,
          backgroundColor: inProgressBgColor,
        );
      } else {
        // Tag đã hoàn thành
        final customColor = _tagColors[tagName];
        if (customColor != null) {
          tagStyle = baseStyle.copyWith(
            color: customColor,
            fontWeight: FontWeight.bold,
            backgroundColor: customColor.withValues(alpha: isDark ? 0.22 : 0.15),
          );
        } else {
          tagStyle = baseStyle.copyWith(
            color: notFoundTagColor,
            fontWeight: FontWeight.bold,
            backgroundColor: notFoundBgColor,
          );
        }
      }

      spans.add(TextSpan(text: rawTag, style: tagStyle));

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return TextSpan(style: style, children: spans);
  }
}
