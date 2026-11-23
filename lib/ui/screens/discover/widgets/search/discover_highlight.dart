import 'package:flutter/material.dart';

/// Tô đậm + gạch chân phần khớp [term] (không phân biệt hoa/thường) trong [text].
TextSpan discoverHighlight(
  String text,
  String term, {
  required TextStyle? base,
  Color? accent,
  bool underline = true,
}) {
  final needle = term.trim().toLowerCase();
  final index = needle.isEmpty ? -1 : text.toLowerCase().indexOf(needle);
  if (index < 0) return TextSpan(text: text, style: base);
  final end = index + needle.length;
  return TextSpan(
    style: base,
    children: [
      TextSpan(text: text.substring(0, index)),
      TextSpan(
        text: text.substring(index, end),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: accent,
          decoration: underline ? TextDecoration.underline : null,
          decorationColor: accent,
        ),
      ),
      TextSpan(text: text.substring(end)),
    ],
  );
}
