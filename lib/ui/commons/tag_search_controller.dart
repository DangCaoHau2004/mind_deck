import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/screens/folder/widgets/tag_highlight_editing_controller.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Trạng thái của một ô tìm kiếm có "viên thuốc" #tag: danh sách tag đã chốt,
/// phần chữ đang gõ và bảng nhớ màu tag. UI chỉ việc lắng nghe controller này.
///
/// - Gõ `#abc` + dấu cách => `abc` được chốt thành pill.
/// - [fullQuery] ghép pill + chữ thành chuỗi `#a #b text` đúng định dạng BE đọc.
class TagSearchController extends ChangeNotifier {
  TagSearchController() {
    text.addListener(_onTextChanged);
  }

  static final RegExp _completedTag = RegExp(r'#([^\s#]+)\s');

  final TagHighlightEditingController text = TagHighlightEditingController();
  final Map<String, String> _colorHex = {};
  final List<TagModel> _tags = [];
  String _lastText = '';

  List<TagModel> get tags => List.unmodifiable(_tags);

  Set<String> get tagNames => _tags.map((t) => t.name.toLowerCase()).toSet();

  bool get isEmpty => _tags.isEmpty && text.text.isEmpty;

  /// Chuỗi gửi cho BE (suggest): giữ nguyên dấu cách cuối để BE biết tag đã gõ xong.
  String get fullQuery {
    final tagPart = _tags.map((t) => '#${t.name}').join(' ');
    final textPart = text.text.trimLeft();
    if (tagPart.isEmpty) return textPart;
    // Dấu cách cuối báo cho BE biết tag cuối đã gõ xong (không phải tag đang gõ dở).
    if (textPart.isEmpty) return '$tagPart ';
    return '$tagPart $textPart';
  }

  /// Chuỗi dùng khi submit tìm kiếm.
  String get submitQuery => fullQuery.trim();

  /// Màu (hex) đã biết của một tag, để dùng cho lịch sử/ gợi ý.
  Color? colorOf(String tagName) {
    final hex = _colorHex[tagName.toLowerCase()];
    if (hex == null || hex.isEmpty) return null;
    return ColorUtils.parseHex(hex);
  }

  void rememberColors(Iterable<TagModel> tags) {
    var changed = false;
    for (final tag in tags) {
      final hex = tag.color;
      if (hex == null || hex.isEmpty) continue;
      final key = tag.name.toLowerCase();
      if (_colorHex[key] != hex) {
        _colorHex[key] = hex;
        changed = true;
      }
    }
    if (changed) {
      _syncColors();
      notifyListeners();
    }
  }

  void _syncColors() {
    text.addTagColors({for (final e in _colorHex.entries) e.key: ColorUtils.parseHex(e.value)});
  }

  TagModel _resolve(TagModel tag) => tag.color != null && tag.color!.isNotEmpty
      ? tag
      : tag.copyWith(color: _colorHex[tag.name.toLowerCase()]);

  void addTag(TagModel tag) {
    rememberColors([tag]);
    if (_tags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase())) return;
    _tags.add(_resolve(tag));
    notifyListeners();
  }

  void removeTag(String name) {
    _tags.removeWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    notifyListeners();
  }

  /// Backspace khi ô chữ trống: đưa pill cuối về dạng chữ `#tag` để sửa tiếp.
  bool popLastTagToText() {
    if (_tags.isEmpty || text.text.isNotEmpty) return false;
    final last = _tags.removeLast();
    final raw = '#${last.name}';
    _lastText = raw;
    text.value = TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    );
    notifyListeners();
    return true;
  }

  /// Dựng lại ô tìm kiếm từ một chuỗi `chữ #tag1 #tag2` (lịch sử, keyword gợi ý).
  void setFromQuery(String query, {Iterable<TagModel> knownTags = const []}) {
    rememberColors(knownTags);
    final words = <String>[];
    _tags.clear();
    for (final token in query.trim().split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      if (token.startsWith('#') && token.length > 1) {
        final name = token.substring(1);
        if (!_tags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
          _tags.add(_resolve(TagModel(id: '', name: name)));
        }
      } else {
        words.add(token);
      }
    }
    final remaining = words.join(' ');
    _lastText = remaining;
    text.value = TextEditingValue(
      text: remaining,
      selection: TextSelection.collapsed(offset: remaining.length),
    );
    notifyListeners();
  }

  void clear() {
    _tags.clear();
    _lastText = '';
    text.clear();
    notifyListeners();
  }

  void _onTextChanged() {
    final current = text.text;
    if (current == _lastText) return;
    _lastText = current;

    final match = _completedTag.firstMatch(current);
    if (match != null) {
      final name = match.group(1)!;
      if (!_tags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
        _tags.add(_resolve(TagModel(id: '', name: name)));
      }
      final remaining = current.replaceFirst(_completedTag, '');
      _lastText = remaining;
      text.value = TextEditingValue(
        text: remaining,
        selection: TextSelection.collapsed(offset: remaining.length),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    text.removeListener(_onTextChanged);
    text.dispose();
    super.dispose();
  }
}
