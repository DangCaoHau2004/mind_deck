import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestSourceSearchHistoryItem {
  final String query;
  final Map<String, String> tagColors;
  final DateTime? timestamp;

  const TestSourceSearchHistoryItem({
    required this.query,
    this.tagColors = const {},
    this.timestamp,
  });

  factory TestSourceSearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return TestSourceSearchHistoryItem(
      query: json['query'] as String? ?? '',
      tagColors:
          (json['tagColors'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k.toLowerCase(), v.toString()),
          ) ??
          const {},
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'tagColors': tagColors,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSourceSearchHistoryItem &&
          runtimeType == other.runtimeType &&
          query.toLowerCase() == other.query.toLowerCase();

  @override
  int get hashCode => query.toLowerCase().hashCode;
}

class TestSourceSearchHistoryService {
  static const String _historyKey = 'test_source_search_history_v1';
  static const int maxHistory = 10;

  final SharedPreferences? _prefsInstance;

  TestSourceSearchHistoryService({SharedPreferences? prefs}) : _prefsInstance = prefs;

  SharedPreferences get _prefs => _prefsInstance ?? GetIt.instance<SharedPreferences>();

  Future<List<TestSourceSearchHistoryItem>> getHistory() async {
    try {
      final rawList = _prefs.getStringList(_historyKey);
      if (rawList != null && rawList.isNotEmpty) {
        return rawList.map((str) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is Map<String, dynamic>) {
              return TestSourceSearchHistoryItem.fromJson(decoded);
            }
            return TestSourceSearchHistoryItem(query: str);
          } catch (_) {
            return TestSourceSearchHistoryItem(query: str);
          }
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<TestSourceSearchHistoryItem>> addSearch(
    String query, {
    Map<String, String>? tagColors,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty || clean.length < 2) {
      return getHistory();
    }

    try {
      final currentList = await getHistory();
      final updatedList = List<TestSourceSearchHistoryItem>.from(currentList);

      // Xóa từ khóa cũ nếu trùng lặp
      updatedList.removeWhere((item) => item.query.toLowerCase() == clean.toLowerCase());

      // Thêm mục mới nhất lên đầu
      updatedList.insert(
        0,
        TestSourceSearchHistoryItem(
          query: clean,
          tagColors: tagColors ?? const {},
          timestamp: DateTime.now(),
        ),
      );

      // Giới hạn số lượng tối đa
      if (updatedList.length > maxHistory) {
        updatedList.removeRange(maxHistory, updatedList.length);
      }

      // Lưu lại vào SharedPreferences
      final encodedList = updatedList.map((item) => jsonEncode(item.toJson())).toList();
      await _prefs.setStringList(_historyKey, encodedList);

      return updatedList;
    } catch (_) {
      return getHistory();
    }
  }

  Future<List<TestSourceSearchHistoryItem>> removeSearch(String query) async {
    try {
      final currentList = await getHistory();
      final updatedList = List<TestSourceSearchHistoryItem>.from(currentList);

      updatedList.removeWhere((item) => item.query.toLowerCase() == query.trim().toLowerCase());

      final encodedList = updatedList.map((item) => jsonEncode(item.toJson())).toList();
      await _prefs.setStringList(_historyKey, encodedList);

      return updatedList;
    } catch (_) {
      return getHistory();
    }
  }

  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (_) {}
  }
}
