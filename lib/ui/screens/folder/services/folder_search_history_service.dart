import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderSearchHistoryItem {
  final String query;
  final Map<String, String> tagColors; // e.g. {"lap-trinh": "#02569B"}
  final DateTime? timestamp;

  const FolderSearchHistoryItem({required this.query, this.tagColors = const {}, this.timestamp});

  factory FolderSearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return FolderSearchHistoryItem(
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
      other is FolderSearchHistoryItem &&
          runtimeType == other.runtimeType &&
          query.toLowerCase() == other.query.toLowerCase();

  @override
  int get hashCode => query.toLowerCase().hashCode;
}

class FolderSearchHistoryService {
  static const String _historyKey = 'folder_search_history_v2';
  static const String _legacyHistoryKey = 'folder_search_history';
  static const int maxHistory = 10;

  final SharedPreferences? _prefsInstance;

  FolderSearchHistoryService({SharedPreferences? prefs}) : _prefsInstance = prefs;

  SharedPreferences get _prefs => _prefsInstance ?? GetIt.instance<SharedPreferences>();

  Future<List<FolderSearchHistoryItem>> getHistory() async {
    try {
      final rawList = _prefs.getStringList(_historyKey);
      if (rawList != null && rawList.isNotEmpty) {
        return rawList.map((str) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is Map<String, dynamic>) {
              return FolderSearchHistoryItem.fromJson(decoded);
            }
            return FolderSearchHistoryItem(query: str);
          } catch (_) {
            return FolderSearchHistoryItem(query: str);
          }
        }).toList();
      }

      // Hỗ trợ đọc migration từ key cũ nếu có
      final legacyList = _prefs.getStringList(_legacyHistoryKey);
      if (legacyList != null && legacyList.isNotEmpty) {
        return legacyList.map((q) => FolderSearchHistoryItem(query: q)).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<FolderSearchHistoryItem>> addSearch(
    String query, {
    Map<String, String>? tagColors,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty || clean.length < 2) {
      return getHistory();
    }

    try {
      final currentList = await getHistory();
      final updatedList = List<FolderSearchHistoryItem>.from(currentList);

      // Tìm kiếm item cũ nếu đã có để kế thừa màu sắc nếu hiện tại không có màu
      Map<String, String> finalTagColors = Map<String, String>.from(tagColors ?? {});

      final existingIndex = updatedList.indexWhere(
        (item) => item.query.toLowerCase() == clean.toLowerCase(),
      );

      if (existingIndex != -1) {
        final existingItem = updatedList[existingIndex];
        // Merge: giữ lại màu cũ cho các tag chưa được truyền mới
        for (final entry in existingItem.tagColors.entries) {
          if (!finalTagColors.containsKey(entry.key)) {
            finalTagColors[entry.key] = entry.value;
          }
        }
        updatedList.removeAt(existingIndex);
      }

      // Chèn lên đầu danh sách
      final newItem = FolderSearchHistoryItem(
        query: clean,
        tagColors: finalTagColors,
        timestamp: DateTime.now(),
      );
      updatedList.insert(0, newItem);

      // Giới hạn số lượng tối đa
      final finalResult = updatedList.length > maxHistory
          ? updatedList.sublist(0, maxHistory)
          : updatedList;

      final stringList = finalResult.map((item) => jsonEncode(item.toJson())).toList();
      await _prefs.setStringList(_historyKey, stringList);

      return finalResult;
    } catch (_) {
      return getHistory();
    }
  }

  Future<List<FolderSearchHistoryItem>> removeSearch(String query) async {
    try {
      final currentList = await getHistory();
      final updatedList = List<FolderSearchHistoryItem>.from(currentList);
      final clean = query.trim().toLowerCase();
      updatedList.removeWhere((item) => item.query.trim().toLowerCase() == clean);

      final stringList = updatedList.map((item) => jsonEncode(item.toJson())).toList();
      await _prefs.setStringList(_historyKey, stringList);

      return updatedList;
    } catch (_) {
      return getHistory();
    }
  }

  Future<void> clearAll() async {
    try {
      await _prefs.remove(_historyKey);
      await _prefs.remove(_legacyHistoryKey);
    } catch (_) {
      // Ignore
    }
  }
}
