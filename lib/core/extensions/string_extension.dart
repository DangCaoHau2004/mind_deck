import 'package:mind_deck/core/services/localization_service.dart';

// Bảng đổi chữ tiếng Việt có dấu về chữ không dấu (dùng cho tìm kiếm trên máy).
const _viGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};
final Map<String, String> _viMap = {
  for (final entry in _viGroups.entries)
    for (final ch in entry.value.split('')) ch: entry.key,
};

extension StringExtension on String {
  String get tr {
    return LocalizationService().getString(this);
  }

  String get capitalizeFirst {
    if (trim().isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String get capitalizeWords {
    if (trim().isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
        })
        .join(' ');
  }

  /// Chữ thường, bỏ dấu tiếng Việt (`đ` thành `d`): "Lập trình" thành "lap trinh". Dùng để so khớp khi tìm kiếm.
  String get withoutDiacritics {
    final buffer = StringBuffer();
    for (final ch in toLowerCase().split('')) {
      buffer.write(_viMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Tên tag sẽ lưu: chữ thường, bỏ dấu tiếng Việt, mọi khoảng trắng/ký tự đặc biệt thành một dấu `-`.
  /// "Tiếng Anh giao tiếp" thành "tieng-anh-giao-tiep". Chữ ngoài tiếng Việt (Trung, Nhật, Hàn...)
  /// được giữ nguyên chữ. Không bao giờ dài hơn chuỗi gốc.
  String get asTagName => withoutDiacritics
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
