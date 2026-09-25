import 'package:hive/hive.dart';

abstract class StudyLocalDataSource {
  Future<void> saveSession(String deckId, Map<String, dynamic> sessionData);
  Map<String, dynamic>? getSession(String deckId);
  Future<void> deleteSession(String deckId);
  Future<void> clearAll();
  List<Map<String, dynamic>> getAllPendingSessions();
}

class StudyLocalDataSourceImpl implements StudyLocalDataSource {
  final Box studyBox;

  StudyLocalDataSourceImpl({required this.studyBox});

  @override
  Future<void> saveSession(String deckId, Map<String, dynamic> sessionData) async {
    await studyBox.put(deckId, sessionData);
  }

  @override
  Map<String, dynamic>? getSession(String deckId) {
    final rawData = studyBox.get(deckId);
    if (rawData == null) return null;

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }
    return null;
  }

  @override
  Future<void> deleteSession(String deckId) async {
    await studyBox.delete(deckId);
  }

  @override
  Future<void> clearAll() async {
    await studyBox.clear();
  }

  @override
  List<Map<String, dynamic>> getAllPendingSessions() {
    final List<Map<String, dynamic>> sessions = [];
    for (final key in studyBox.keys) {
      final session = getSession(key.toString());
      if (session != null) {
        sessions.add(session);
      }
    }
    return sessions;
  }
}
