import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/test_question_model.dart';

/// Soạn / sửa MỘT câu hỏi của đề tự soạn (5 dạng). Trả về câu đã chuẩn hóa theo `questionData` của BE.
///
/// Giữ nguyên `qid` khi sửa. `cardId` / `cardIds` được giữ để BE xác nhận lại liên kết thẻ:
/// sửa câu hỏi hoặc đáp án ĐÚNG thì BE tự gỡ liên kết (câu chỉ tính điểm, không tính FSRS).
Future<TestQuestionModel?> showQuestionEditor(
  BuildContext context, {
  required TestQuestionType type,
  TestQuestionModel? initial,
}) {
  return showModalBottomSheet<TestQuestionModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuestionEditor(type: type, initial: initial),
  );
}

/// Nhãn tiếng Việt cho 5 dạng câu được hỗ trợ (không có `flashcard`).
String questionTypeLabel(TestQuestionType t) => switch (t) {
  TestQuestionType.multipleChoice => 'Trắc nghiệm',
  TestQuestionType.trueFalse => 'Đúng / Sai',
  TestQuestionType.fillInTheBlank => 'Điền từ',
  TestQuestionType.dictation => 'Chính tả',
  TestQuestionType.matching => 'Ghép cặp',
  TestQuestionType.flashcard => 'Flashcard',
};

/// 5 dạng câu dùng được trong đề của lớp.
const List<TestQuestionType> kTestQuestionTypes = [
  TestQuestionType.multipleChoice,
  TestQuestionType.trueFalse,
  TestQuestionType.fillInTheBlank,
  TestQuestionType.dictation,
  TestQuestionType.matching,
];

class _QuestionEditor extends StatefulWidget {
  final TestQuestionType type;
  final TestQuestionModel? initial;

  const _QuestionEditor({required this.type, this.initial});

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  final _prompt = TextEditingController();
  final _statement = TextEditingController();
  final _expected = TextEditingController();
  final _audio = TextEditingController();
  final List<TextEditingController> _options = [];
  final List<TextEditingController> _left = [];
  final List<TextEditingController> _right = [];
  int _correct = 0;
  bool _isCorrect = true;
  String? _error;

  TestQuestionType get type => widget.type;

  @override
  void initState() {
    super.initState();
    final q = widget.initial;
    final d = q?.questionData ?? const <String, dynamic>{};

    switch (type) {
      case TestQuestionType.multipleChoice:
        _prompt.text = q?.prompt ?? '';
        final opts = q?.options ?? const [];
        for (final o in opts) {
          _options.add(TextEditingController(text: o is Map ? (o['text']?.toString() ?? '') : ''));
        }
        while (_options.length < 2) {
          _options.add(TextEditingController());
        }
        final correctId = q?.correctOptionId;
        final idx = opts.indexWhere((o) => o is Map && o['id']?.toString() == correctId);
        _correct = idx < 0 ? 0 : idx;
      case TestQuestionType.trueFalse:
        _prompt.text = q?.prompt ?? '';
        _statement.text = q?.statement ?? '';
        _isCorrect = q?.isTrueFalseExpected ?? true;
      case TestQuestionType.fillInTheBlank:
        _prompt.text = q?.prompt ?? '';
        _expected.text = q?.expectedText ?? '';
      case TestQuestionType.dictation:
        _audio.text = d['audioText']?.toString() ?? '';
        _expected.text = q?.expectedText ?? '';
      case TestQuestionType.matching:
        final lefts = q?.leftColumn ?? const [];
        final rights = q?.rightColumn ?? const [];
        final rightById = {
          for (final r in rights)
            if (r is Map) r['id'].toString(): r['text']?.toString() ?? '',
        };
        for (final l in lefts) {
          if (l is! Map) continue;
          _left.add(TextEditingController(text: l['text']?.toString() ?? ''));
          _right.add(TextEditingController(text: rightById[l['id'].toString()] ?? ''));
        }
        while (_left.length < 2) {
          _left.add(TextEditingController());
          _right.add(TextEditingController());
        }
      case TestQuestionType.flashcard:
        break;
    }
  }

  @override
  void dispose() {
    for (final c in [_prompt, _statement, _expected, _audio, ..._options, ..._left, ..._right]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    String norm(TextEditingController c) => c.text.trim();
    bool tooLong(Iterable<TextEditingController> cs, int max) =>
        cs.any((c) => c.text.trim().length > max);

    switch (type) {
      case TestQuestionType.multipleChoice:
        if (norm(_prompt).isEmpty) return 'Nhập nội dung câu hỏi';
        if (_options.any((c) => norm(c).isEmpty)) return 'Đáp án không được để trống';
        final texts = _options
            .map((c) => norm(c).toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
            .toList();
        if (texts.toSet().length != texts.length) return 'Các đáp án không được trùng nhau';
        if (tooLong(_options, 500)) return 'Mỗi đáp án tối đa 500 ký tự';
      case TestQuestionType.trueFalse:
        if (norm(_prompt).isEmpty) return 'Nhập nội dung câu hỏi';
        if (norm(_statement).isEmpty) return 'Nhập phát biểu cần đánh giá đúng/sai';
      case TestQuestionType.fillInTheBlank:
        if (norm(_prompt).isEmpty) return 'Nhập nội dung câu hỏi';
        if (norm(_expected).isEmpty) return 'Nhập đáp án đúng';
        if (tooLong([_expected], 500)) return 'Đáp án tối đa 500 ký tự';
      case TestQuestionType.dictation:
        if (norm(_audio).isEmpty) return 'Nhập đoạn văn bản sẽ được đọc';
        if (norm(_expected).isEmpty) return 'Nhập đáp án đúng';
        if (tooLong([_audio, _expected], 500)) return 'Tối đa 500 ký tự';
      case TestQuestionType.matching:
        if (_left.any((c) => norm(c).isEmpty) || _right.any((c) => norm(c).isEmpty)) {
          return 'Điền đủ cả hai cột';
        }
        final rights = _right.map((c) => norm(c).toLowerCase()).toList();
        if (rights.toSet().length != rights.length)
          return 'Các mục ở cột phải không được trùng nhau';
      case TestQuestionType.flashcard:
        return 'Dạng câu này không dùng cho đề của lớp';
    }
    return null;
  }

  TestQuestionModel _build() {
    final q = widget.initial;
    late final Map<String, dynamic> data;
    switch (type) {
      case TestQuestionType.multipleChoice:
        data = {
          'promptText': _prompt.text.trim(),
          'promptImageUrl': q?.promptImageUrl,
          'options': [
            for (var i = 0; i < _options.length; i++)
              {'id': 'o${i + 1}', 'text': _options[i].text.trim()},
          ],
          'correctOptionId': 'o${_correct + 1}',
        };
      case TestQuestionType.trueFalse:
        data = {
          'promptText': _prompt.text.trim(),
          'statementText': _statement.text.trim(),
          'statementCardId': null,
          'isCorrect': _isCorrect,
        };
      case TestQuestionType.fillInTheBlank:
        data = {
          'promptText': _prompt.text.trim(),
          'promptImageUrl': q?.promptImageUrl,
          'expectedText': _expected.text.trim(),
        };
      case TestQuestionType.dictation:
        data = {
          'audioText': _audio.text.trim(),
          'audioUrl': null,
          'expectedText': _expected.text.trim(),
        };
      case TestQuestionType.matching:
        data = {
          'leftColumn': [
            for (var i = 0; i < _left.length; i++)
              {'id': 'p${i + 1}', 'text': _left[i].text.trim()},
          ],
          'rightColumn': [
            for (var i = 0; i < _right.length; i++)
              {'id': 'p${i + 1}', 'text': _right[i].text.trim()},
          ],
        };
      case TestQuestionType.flashcard:
        data = const {};
    }
    return TestQuestionModel(
      qid: q?.qid,
      cardId: q?.cardId,
      cardIds: q?.cardIds,
      questionType: type,
      questionData: data,
    );
  }

  void _save() {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _build());
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        minLines: 1,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (type) {
      case TestQuestionType.multipleChoice:
        return [
          _field(_prompt, 'Câu hỏi *'),
          const Text('Đáp án (chọn đáp án đúng)', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < _options.length; i++)
            Row(
              children: [
                Radio<int>(
                  value: i,
                  groupValue: _correct,
                  onChanged: (v) => setState(() => _correct = v ?? 0),
                ),
                Expanded(child: _field(_options[i], 'Đáp án ${i + 1}', maxLines: 1)),
                IconButton(
                  onPressed: _options.length > 2
                      ? () => setState(() {
                          _options.removeAt(i).dispose();
                          if (_correct >= _options.length) _correct = _options.length - 1;
                        })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ],
            ),
          if (_options.length < 8)
            TextButton.icon(
              onPressed: () => setState(() => _options.add(TextEditingController())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm đáp án'),
            ),
        ];
      case TestQuestionType.trueFalse:
        return [
          _field(_prompt, 'Câu hỏi / thuật ngữ *'),
          _field(_statement, 'Phát biểu cần đánh giá *'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Phát biểu là ĐÚNG', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Nghĩa là phát biểu là đáp án đúng cho câu hỏi'),
            value: _isCorrect,
            onChanged: (v) => setState(() => _isCorrect = v),
          ),
        ];
      case TestQuestionType.fillInTheBlank:
        return [_field(_prompt, 'Câu hỏi *'), _field(_expected, 'Đáp án đúng *', maxLines: 1)];
      case TestQuestionType.dictation:
        return [
          _field(_audio, 'Văn bản sẽ được đọc *'),
          _field(_expected, 'Đáp án đúng *', maxLines: 1),
        ];
      case TestQuestionType.matching:
        return [
          const Text(
            'Các cặp ghép (cột trái ↔ cột phải)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _left.length; i++)
            Row(
              children: [
                Expanded(child: _field(_left[i], 'Trái ${i + 1}', maxLines: 1)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12, left: 6, right: 6),
                  child: Icon(Icons.swap_horiz_rounded),
                ),
                Expanded(child: _field(_right[i], 'Phải ${i + 1}', maxLines: 1)),
                IconButton(
                  onPressed: _left.length > 2
                      ? () => setState(() {
                          _left.removeAt(i).dispose();
                          _right.removeAt(i).dispose();
                        })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ],
            ),
          if (_left.length < 10)
            TextButton.icon(
              onPressed: () => setState(() {
                _left.add(TextEditingController());
                _right.add(TextEditingController());
              }),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm cặp'),
            ),
        ];
      case TestQuestionType.flashcard:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.initial == null ? 'Thêm' : 'Sửa'} câu · ${questionTypeLabel(type)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  FilledButton(onPressed: _save, child: const Text('Xong')),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: cs.error, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ..._body(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
