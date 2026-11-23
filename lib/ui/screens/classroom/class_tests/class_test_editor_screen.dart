import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/resolved_source_deck_model.dart';
import 'package:mind_deck/data/models/test_question_model.dart';
import 'package:mind_deck/data/models/test_settings_model.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_tests/widgets/question_editor_sheet.dart';
import 'package:mind_deck/ui/screens/classroom/class_tests/widgets/test_settings_form.dart';

/// Tạo / xem / sửa một đề của lớp.
/// - Đề AUTO: chọn thẻ bản sao của lớp + dạng câu; mỗi học viên được sinh một bộ câu ngẫu nhiên lúc Start.
/// - Đề MANUAL: soạn tay 1–200 câu (5 dạng), cả lớp làm cùng một bộ; có thể lấy câu từ "xem thử".
/// - Đề đã có người làm (`locked`): chỉ đổi được tên.
class ClassTestEditorScreen extends StatefulWidget {
  final ClassModel classData;
  final String? testId;
  final String initialKind;

  const ClassTestEditorScreen({
    super.key,
    required this.classData,
    this.testId,
    this.initialKind = 'auto',
  });

  @override
  State<ClassTestEditorScreen> createState() => _ClassTestEditorScreenState();
}

class _ClassTestEditorScreenState extends State<ClassTestEditorScreen> {
  static const int _maxCards = 200;
  static const int _maxQuestions = 200;

  final _nameCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _working = false; // đang gọi xem thử / tải nguồn thẻ
  String? _loadError;

  late String _kind = widget.initialKind;
  TestSettings _settings = const TestSettings();
  bool _locked = false;

  // Đề auto
  final Set<String> _cardIds = {};
  final Set<TestQuestionType> _types = {
    TestQuestionType.multipleChoice,
    TestQuestionType.trueFalse,
    TestQuestionType.fillInTheBlank,
  };
  List<ResolvedSourceDeck>? _decks;

  // Đề manual
  final List<TestQuestionModel> _questions = [];

  bool get _isEdit => widget.testId != null;
  bool get _isAuto => _kind == 'auto';
  String get _classId => widget.classData.id;
  TestRepository get _repo => DI().sl<TestRepository>();

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = true}) {
    if (!mounted) return;
    CustomToast.show(
      context,
      error ? CustomToast.danger(message: message) : CustomToast.success(message: message),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await _repo.getTestDetail(widget.testId!);
      final t = res.data;
      if (t == null || !mounted) return;
      setState(() {
        _kind = t.kind;
        _nameCtrl.text = t.name;
        _settings = t.testSettings;
        _locked = t.locked;
        _cardIds
          ..clear()
          ..addAll(t.cardIds);
        final types = [
          for (final s in t.questionTypes) TestQuestionType.fromString(s),
        ].where(kTestQuestionTypes.contains);
        if (types.isNotEmpty) {
          _types
            ..clear()
            ..addAll(types);
        }
        _questions
          ..clear()
          ..addAll(t.questions);
        _loading = false;
      });
    } on Failure catch (f) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = ClassErrorMessages.of(f);
        });
      }
    }
  }

  // ---- Nguồn thẻ (đề auto / lấy câu từ xem thử) ----
  Future<void> _ensureDecks() async {
    if (_decks != null) return;
    setState(() => _working = true);
    try {
      // `classIds` lấy mọi bản sao học liệu của lớp (kể cả trong folder).
      final res = await _repo.resolveSources(classIds: [_classId]);
      if (mounted) setState(() => _decks = res.data);
    } on Failure catch (f) {
      _toast(ClassErrorMessages.of(f));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pickCards() async {
    await _ensureDecks();
    final decks = _decks;
    if (decks == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final cs = Theme.of(ctx).colorScheme;
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, controller) => Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
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
                            'Thẻ nguồn: ${_cardIds.length}/$_maxCards',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _cardIds.length > _maxCards ? cs.error : null,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Xong'),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                  Expanded(
                    child: decks.isEmpty
                        ? Center(
                            child: Text(
                              'Lớp chưa có học liệu. Hãy thêm học liệu trước.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            controller: controller,
                            itemCount: decks.length,
                            itemBuilder: (ctx, i) {
                              final d = decks[i];
                              final ids = d.cards.map((c) => c.id).toList();
                              final selectedCount = ids.where(_cardIds.contains).length;
                              final all = ids.isNotEmpty && selectedCount == ids.length;
                              return CheckboxListTile(
                                tristate: true,
                                value: all ? true : (selectedCount == 0 ? false : null),
                                title: Text(
                                  d.deckName,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text('${ids.length} thẻ · đã chọn $selectedCount'),
                                onChanged: (_) {
                                  setSheet(() {
                                    if (all) {
                                      _cardIds.removeAll(ids);
                                    } else {
                                      _cardIds.addAll(ids);
                                    }
                                  });
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final t in kTestQuestionTypes)
          FilterChip(
            label: Text(questionTypeLabel(t)),
            selected: _types.contains(t),
            onSelected: _locked
                ? null
                : (v) => setState(() {
                    if (v) {
                      _types.add(t);
                    } else {
                      _types.remove(t);
                    }
                  }),
          ),
      ],
    );
  }

  String? _checkSource() {
    if (_cardIds.isEmpty) return 'Vui lòng chọn ít nhất một thẻ nguồn';
    if (_cardIds.length > _maxCards) return 'Tối đa $_maxCards thẻ cho một đề';
    if (_types.isEmpty) return 'Vui lòng chọn ít nhất một dạng câu hỏi';
    return null;
  }

  Map<String, dynamic> _settingsJson() => _settings.toJson();

  // ---- Xem thử (không lưu, ngẫu nhiên mỗi lần) ----
  Future<List<TestQuestionModel>?> _runPreview() async {
    final error = _checkSource();
    if (error != null) {
      _toast(error);
      return null;
    }
    setState(() => _working = true);
    try {
      final res = await _repo.previewTest(
        classId: _classId,
        cardIds: _cardIds.toList(),
        questionTypes: [for (final t in _types) t.value],
        settings: {'questionSide': _settings.questionSide},
      );
      return res.data?.questions ?? const [];
    } on Failure catch (f) {
      _toast(ClassErrorMessages.of(f));
      return null;
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showPreview() async {
    final questions = await _runPreview();
    if (questions == null || !mounted) return;
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, controller) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Xem thử · ${questions.length} câu (ngẫu nhiên, không lưu)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
              Expanded(
                child: questions.isEmpty
                    ? const Center(child: Text('Không sinh được câu nào từ các thẻ đã chọn.'))
                    : ListView.separated(
                        controller: controller,
                        itemCount: questions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                          title: Text(
                            _snippet(questions[i]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(questionTypeLabel(questions[i].questionType)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Đề manual: lấy các câu từ xem thử vào danh sách để chỉnh sửa tiếp.
  Future<void> _addFromCards() async {
    await _pickCards();
    if (_cardIds.isEmpty || !mounted) return;
    final picked = await _runPreview();
    if (picked == null || !mounted) return;
    setState(() {
      _questions.addAll(picked);
      if (_questions.length > _maxQuestions)
        _questions.removeRange(_maxQuestions, _questions.length);
    });
    _toast('Đã thêm ${picked.length} câu từ thẻ', error: false);
  }

  Future<void> _addQuestion() async {
    final type = await showModalBottomSheet<TestQuestionType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn dạng câu',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            for (final t in kTestQuestionTypes)
              ListTile(title: Text(questionTypeLabel(t)), onTap: () => Navigator.pop(ctx, t)),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;
    final q = await showQuestionEditor(context, type: type);
    if (q != null && mounted) setState(() => _questions.add(q));
  }

  Future<void> _editQuestion(int i) async {
    final q = await showQuestionEditor(
      context,
      type: _questions[i].questionType,
      initial: _questions[i],
    );
    if (q != null && mounted) setState(() => _questions[i] = q);
  }

  String _snippet(TestQuestionModel q) {
    switch (q.questionType) {
      case TestQuestionType.dictation:
        return q.questionData['audioText']?.toString() ?? '';
      case TestQuestionType.matching:
        return '${q.leftColumn.length} cặp ghép';
      case TestQuestionType.trueFalse:
        return '${q.prompt} → ${q.statement}';
      default:
        return q.prompt;
    }
  }

  bool _linked(TestQuestionModel q) => q.cardId != null || (q.cardIds?.isNotEmpty ?? false);

  // ---- Lưu ----
  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (!_locked) {
      if (_settings.timeLimitEnabled && (_settings.timeLimitMinutes ?? 0) < 1) {
        return _toast('Giới hạn thời gian phải từ 1 đến 600 phút');
      }
      if (_isAuto) {
        final error = _checkSource();
        if (error != null) return _toast(error);
      } else if (_questions.isEmpty) {
        return _toast('Đề cần ít nhất một câu hỏi');
      } else if (_questions.length > _maxQuestions) {
        return _toast('Tối đa $_maxQuestions câu cho một đề');
      }
    }

    setState(() => _saving = true);
    try {
      CustomTestModel? saved;
      if (_isEdit) {
        final res = await _repo.updateTest(
          widget.testId!,
          name: name,
          // Đề đã có người làm: BE từ chối mọi trường ngoài `name` (403 TEST_EDIT_LOCKED).
          settings: _locked ? null : _settingsJson(),
          cardIds: !_locked && _isAuto ? _cardIds.toList() : null,
          questionTypes: !_locked && _isAuto ? [for (final t in _types) t.value] : null,
          questions: !_locked && !_isAuto ? [for (final q in _questions) q.toApiJson()] : null,
        );
        saved = res.data;
      } else {
        final res = await _repo.generateTest(
          classId: _classId,
          kind: _kind,
          name: name.isEmpty ? null : name,
          cardIds: _isAuto ? _cardIds.toList() : null,
          questionTypes: _isAuto ? [for (final t in _types) t.value] : null,
          questions: _isAuto ? null : [for (final q in _questions) q.toApiJson()],
          settings: _settingsJson(),
        );
        saved = res.data;
      }

      // Đề manual: dùng `questions` server trả về làm nguồn sự thật và báo câu nào vừa mất liên kết thẻ.
      if (!_isAuto && !_locked && saved != null) {
        final before = List<TestQuestionModel>.of(_questions);
        final after = saved.questions;
        var lost = 0;
        if (after.length == before.length) {
          for (var i = 0; i < before.length; i++) {
            if (_linked(before[i]) && !_linked(after[i])) lost++;
          }
        }
        if (mounted) {
          setState(() {
            _questions
              ..clear()
              ..addAll(after);
          });
          if (lost > 0) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Một số câu không còn gắn với thẻ'),
                content: Text(
                  '$lost câu đã bị gỡ liên kết thẻ vì nội dung câu hỏi hoặc đáp án đúng khác với thẻ gốc. '
                  'Những câu này chỉ tính điểm, KHÔNG tính vào lịch ôn tập (FSRS) của học viên.',
                ),
                actions: [
                  FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
                ],
              ),
            );
          }
        }
      }

      if (mounted) {
        _toast(_isEdit ? 'Đã lưu đề' : 'Đã tạo đề', error: false);
        Navigator.pop(context, true);
      }
    } on Failure catch (f) {
      _toast(ClassErrorMessages.of(f));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                style: TextStyle(color: cs.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_locked)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đề đã có học viên làm bài nên chỉ đổi được tên. Muốn đổi nội dung hãy tạo đề mới.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          section('Thông tin', [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Tên đề',
                hintText: 'Bài kiểm tra',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isAuto
                  ? 'Đề TỰ ĐỘNG: mỗi học viên nhận một bộ câu ngẫu nhiên khi bắt đầu.'
                  : 'Đề TỰ SOẠN: cả lớp làm cùng một bộ câu cố định.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ]),
          if (_isAuto)
            section('Nguồn câu hỏi', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.style_rounded),
                title: Text(
                  _cardIds.isEmpty
                      ? 'Chọn thẻ từ học liệu của lớp'
                      : '${_cardIds.length} thẻ đã chọn',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Tối đa 200 thẻ; chỉ thẻ bản sao của lớp'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _locked ? null : _pickCards,
              ),
              const SizedBox(height: 8),
              const Text('Dạng câu hỏi', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _typeChips(),
              const SizedBox(height: 4),
              Text(
                'Số câu và dạng thực tế có thể lệch: thiếu đáp án nhiễu thì trắc nghiệm / đúng sai '
                'hạ thành điền từ; ghép cặp gom 2–5 thẻ/câu.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              if (!_locked) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _working ? null : _showPreview,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Xem thử (ngẫu nhiên)'),
                ),
              ],
            ])
          else
            section('Câu hỏi (${_questions.length}/$_maxQuestions)', [
              if (_questions.isEmpty)
                Text('Chưa có câu nào.', style: TextStyle(color: cs.onSurfaceVariant))
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: !_locked,
                  itemCount: _questions.length,
                  onReorder: (from, to) {
                    if (_locked) return;
                    setState(() {
                      if (to > from) to -= 1;
                      _questions.insert(to, _questions.removeAt(from));
                    });
                  },
                  itemBuilder: (ctx, i) {
                    final q = _questions[i];
                    return Card(
                      key: ObjectKey(q),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                        title: Text(_snippet(q), maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(questionTypeLabel(q.questionType)),
                            if (!_linked(q))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Không tính FSRS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: _locked ? null : () => _editQuestion(i),
                        trailing: _locked
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                                    onPressed: () => setState(() => _questions.removeAt(i)),
                                  ),
                                  const SizedBox(width: 24),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              if (!_locked) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _questions.length >= _maxQuestions ? null : _addQuestion,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm câu'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _working || _questions.length >= _maxQuestions
                          ? null
                          : _addFromCards,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Lấy câu từ thẻ'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Câu không gắn thẻ (hoặc bạn sửa câu hỏi / đáp án đúng) chỉ tính điểm, không tính lịch ôn FSRS.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ]),
          section('Cài đặt đề', [
            TestSettingsForm(
              settings: _settings,
              isAuto: _isAuto,
              enabled: !_locked,
              onChanged: (s) => setState(() => _settings = s),
            ),
          ]),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _isEdit ? 'LƯU ĐỀ' : 'TẠO ĐỀ',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Chi tiết đề' : (_isAuto ? 'Tạo đề tự động' : 'Tạo đề tự soạn'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          body,
          if (_working) const Positioned.fill(child: ColoredBox(color: Color(0x33000000))),
          if (_working) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
