/// So khớp đáp án gõ tay theo ĐÚNG quy tắc server chấm: trim + gộp khoảng trắng + chữ thường,
/// rồi chấp nhận lệch đúng 1 ký tự (đáp án ≥ 3 ký tự) hoặc lệch ≤ 20% độ dài.
/// Không bỏ dấu, không bỏ dấu câu. Chỉ dùng để hiện đúng/sai tức thì; điểm chính thức do server chấm.
class TextMatch {
  TextMatch._();

  static String normalize(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = cur[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        cur[j] = [del, ins, sub].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// `true` nếu câu trả lời được coi là đúng với đáp án mong đợi.
  static bool isNearMatch(String answer, String expected) {
    final a = normalize(answer);
    final e = normalize(expected);
    if (e.isEmpty) return false;
    if (a == e) return true;
    final distance = levenshtein(a, e);
    if (e.length >= 3 && distance <= 1) return true;
    return distance <= e.length * 0.2;
  }
}
