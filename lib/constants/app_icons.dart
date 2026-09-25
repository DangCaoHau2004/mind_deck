import 'package:flutter/material.dart';

class AppIcons {
  /// Hàm chuyển đổi từ String Key (nhận từ Backend) sang IconData
  static IconData getIconFromKey(String key) {
    switch (key) {
      // Hệ thống
      case 'star':
        return Icons.star_rounded;
      case 'flash':
        return Icons.bolt_rounded;
      case 'target':
        return Icons.track_changes_rounded;
      case 'default_deck':
        return Icons.layers_rounded;

      // Ngôn ngữ & Văn
      case 'language':
        return Icons.translate_rounded;
      case 'alphabet':
        return Icons.sort_by_alpha_rounded;
      case 'book':
        return Icons.book_rounded;

      // Tự nhiên & Công nghệ
      case 'math':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'biology':
        return Icons.biotech_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'code':
        return Icons.code_rounded;

      // Xã hội & Đời sống
      case 'geography':
        return Icons.public_rounded;
      case 'history':
        return Icons.history_edu_rounded;
      case 'law':
        return Icons.gavel_rounded;
      case 'art':
        return Icons.palette_rounded;
      case 'music':
        return Icons.music_note_rounded;

      // Chuyên ngành
      case 'medical':
        return Icons.medical_services_rounded;
      case 'finance':
        return Icons.payments_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      // Mặc định cho Folder
      case 'default_folder':
      default:
        return Icons.folder_rounded;
    }
  }

  /// Danh sách toàn bộ các Key để build giao diện GridView/ListView
  /// cho người dùng chọn khi tạo mới Thư mục/Bộ thẻ
  static const List<String> availableIconKeys = [
    'default_folder',
    'star',
    'flash',
    'target',
    'language',
    'alphabet',
    'book',
    'math',
    'science',
    'biology',
    'computer',
    'code',
    'geography',
    'history',
    'law',
    'art',
    'music',
    'medical',
    'finance',
    'business',
    'sports',
    'food',
  ];
}
