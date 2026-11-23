import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Map<String, dynamic> _localizedStrings = {};
  String _currentLanguageCode = 'vi';

  String get currentLanguageCode => _currentLanguageCode;

  /// Luôn trả về Locale đảm bảo format ngày là dd/mm/yyyy
  /// vi: Locale('vi', 'VN')
  /// en: Locale('en', 'GB') (chuẩn Anh/quốc tế sử dụng dd/mm/yyyy)
  Locale get currentLocale =>
      _currentLanguageCode == 'vi' ? const Locale('vi', 'VN') : const Locale('en', 'GB');

  Future<void> load(String languageCode) async {
    _currentLanguageCode = languageCode;
    try {
      String jsonString = await rootBundle.loadString('assets/langs/$languageCode.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
    } catch (e) {
      debugPrint('Lỗi tải file ngôn ngữ: $e');
      _localizedStrings = {};
    }
  }

  String getString(String key, {String? defaultText}) {
    if (_localizedStrings.containsKey(key)) {
      return _localizedStrings[key].toString();
    }
    return defaultText ?? key;
  }
}
