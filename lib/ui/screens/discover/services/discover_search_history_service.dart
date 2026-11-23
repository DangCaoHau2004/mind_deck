import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoverSearchHistoryService {
  static const String _historyKey = 'discover_search_history';
  static const int maxHistory = 5;

  final SharedPreferences? _prefsInstance;

  DiscoverSearchHistoryService({SharedPreferences? prefs}) : _prefsInstance = prefs;

  SharedPreferences get _prefs => _prefsInstance ?? GetIt.instance<SharedPreferences>();

  Future<List<String>> getHistory() async {
    try {
      final list = _prefs.getStringList(_historyKey);
      return list ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> addSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      return getHistory();
    }

    try {
      final currentList = await getHistory();
      final updatedList = List<String>.from(currentList);

      // Xóa nếu đã tồn tại để đưa lên đầu (không phân biệt hoa/thường)
      updatedList.removeWhere((item) => item.trim().toLowerCase() == clean.toLowerCase());

      // Chèn lên đầu danh sách
      updatedList.insert(0, clean);

      // Giới hạn tối đa 5 mục
      final finalResult = updatedList.length > maxHistory
          ? updatedList.sublist(0, maxHistory)
          : updatedList;

      await _prefs.setStringList(_historyKey, finalResult);
      return finalResult;
    } catch (_) {
      return getHistory();
    }
  }

  Future<List<String>> removeSearch(String query) async {
    try {
      final currentList = await getHistory();
      final updatedList = List<String>.from(currentList);
      final clean = query.trim().toLowerCase();

      updatedList.removeWhere((item) => item.trim().toLowerCase() == clean);

      await _prefs.setStringList(_historyKey, updatedList);
      return updatedList;
    } catch (_) {
      return getHistory();
    }
  }

  Future<void> clearAll() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (_) {
      // Ignore
    }
  }
}
