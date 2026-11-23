import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/class_folder_decks_screen.dart';

String _fmtDateTime(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

/// Thông tin cần biết TRƯỚC khi làm bài rồi mới bắt đầu (học viên).
/// Bài kiểm tra: Start có tác dụng phụ (tạo / ghi đè phiên) nên chỉ gọi khi người dùng bấm "Bắt đầu".
Future<void> showAssignmentStartSheet(
  BuildContext context, {
  required ClassModel classData,
  required ClassAssignmentModel assignment,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StartSheet(
      classData: classData,
      assignment: assignment,
      onChanged: onChanged,
      parentContext: context,
    ),
  );
}

class _StartSheet extends StatefulWidget {
  final ClassModel classData;
  final ClassAssignmentModel assignment;
  final VoidCallback onChanged;
  final BuildContext parentContext;

  const _StartSheet({
    required this.classData,
    required this.assignment,
    required this.onChanged,
    required this.parentContext,
  });

  @override
  State<_StartSheet> createState() => _StartSheetState();
}

class _StartSheetState extends State<_StartSheet> {
  final Map<String, String> _names = {};

  /// `canClone` theo từng học liệu (BE tính theo quyền lớp), để màn chi tiết deck hiện nút clone đúng.
  final Map<String, bool> _canClone = {};

  ClassAssignmentModel get a => widget.assignment;

  @override
  void initState() {
    super.initState();
    if (!a.isTest && a.sources.isNotEmpty) _loadNames();
  }

  /// `sources` chỉ có `{type, id}`: tra tên từ học liệu của lớp.
  Future<void> _loadNames() async {
    try {
      for (var page = 1; page <= 50; page++) {
        final res = await DI().sl<ClassRepository>().getMaterials(
          widget.classData.id,
          page: page,
          limit: 100,
        );
        for (final i in res.items) {
          _names[i.id] = i.name;
          _canClone[i.id] = i.canClone;
        }
        if (!res.hasMore) break;
      }
      if (mounted) setState(() {});
    } on Failure {
      // Hiển thị tên mặc định.
    }
  }

  Future<void> _startTest() async {
    final navigator = Navigator.of(context);
    final router = GoRouter.of(widget.parentContext);
    navigator.pop();
    final result = await router.pushNamed<bool>(
      AppRoute.classTest.name,
      pathParameters: {
        'classId': widget.classData.id,
        'assignmentId': a.id,
        'testId': a.testId ?? a.test?.id ?? '',
      },
    );
    if (result == true) widget.onChanged();
  }

  void _openSource(AssignmentSource s) {
    final router = GoRouter.of(widget.parentContext);
    final navigator = Navigator.of(context);
    navigator.pop();
    if (s.isFolder) {
      Navigator.of(widget.parentContext).push(
        MaterialPageRoute(
          builder: (_) => ClassFolderDecksScreen(
            classData: widget.classData,
            folder: ClassMaterialItem(
              type: ClassMaterialItem.typeFolder,
              id: s.id,
              name: _names[s.id] ?? 'Thư mục',
            ),
          ),
        ),
      );
    } else {
      // Mở bằng id BẢN SAO trong lớp; `extra` cho màn học biết đang làm bài giao nào.
      router.pushNamed(
        AppRoute.deckDetail.name,
        pathParameters: {'id': s.id},
        extra: {
          'classId': widget.classData.id,
          'assignmentId': a.id,
          'canEditClassCopy': widget.classData.isTeacher,
          'canCloneClassCopy': _canClone[s.id] ?? widget.classData.canCloneMaterials,
        },
      );
    }
  }

  Widget _row(IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _testRows() {
    final test = a.test;
    final s = test?.settings;
    final mine = a.my;
    final allowed = mine?.attemptsAllowed ?? s?.attempts;
    final used = mine?.attemptsCount ?? 0;

    final questionText = test == null
        ? '—'
        : (test.questionCount != null
              ? '${test.questionCount} câu'
              : 'Tối đa ~${test.cardCount} câu (ghép cặp gom nhiều thẻ vào một câu)');

    return [
      _row(Icons.quiz_rounded, 'Số câu', questionText),
      if (s != null)
        _row(
          Icons.timer_outlined,
          'Giới hạn thời gian',
          s.timeLimitEnabled
              ? '${s.timeLimitMinutes ?? '?'} phút (có thể ngắn hơn nếu bài sắp hết hạn)'
              : 'Không giới hạn trong bài (vẫn phải nộp trước hạn)',
        ),
      if (allowed != null)
        _row(
          Icons.replay_circle_filled_rounded,
          'Số lượt làm',
          'Đã làm $used/$allowed lượt'
              '${allowed > 1 && s != null ? ' · Điểm bài tính theo: ${s.scorePolicyLabel.toLowerCase()}' : ''}',
        ),
      if (s != null) ...[
        _row(
          Icons.shuffle_rounded,
          'Thứ tự câu hỏi',
          s.shuffle ? 'Đảo ngẫu nhiên mỗi lần làm' : 'Giữ nguyên',
        ),
        _row(
          Icons.grade_rounded,
          'Kết quả sau khi nộp',
          s.showScore
              ? (s.showAnswers ? 'Xem điểm và đáp án chi tiết' : 'Xem điểm (không xem đáp án)')
              : 'Không xem điểm — điểm do giảng viên công bố',
        ),
        if (s.showAnswerInstantly)
          _row(Icons.fact_check_rounded, 'Trong lúc làm', 'Hiện đúng/sai ngay từng câu'),
      ],
      _row(Icons.event_busy_rounded, 'Hạn nộp', _fmtDateTime(a.endAt)),
      _row(
        Icons.psychology_rounded,
        'Lịch ôn tập (FSRS)',
        'Kết quả được tính vào lịch ôn tập của bạn (câu giảng viên tự viết không gắn thẻ thì không tính).',
      ),
    ];
  }

  List<Widget> _missionRows() {
    final mine = a.my;
    final target = mine?.targetCount ?? a.targetCount;
    final modeText = a.mode == AssignmentMode.newOnly ? 'Chỉ thẻ mới' : 'Tất cả thẻ';
    final progress = mine == null
        ? '—'
        : (target == null ? '${mine.progress} thẻ' : '${mine.clampedProgress}/$target thẻ');

    return [
      _row(Icons.flag_rounded, 'Mục tiêu của bạn', target == null ? 'Toàn bộ thẻ' : '$target thẻ'),
      _row(Icons.timelapse_rounded, 'Tiến độ', progress),
      _row(Icons.tune_rounded, 'Chế độ', modeText),
      _row(
        Icons.schedule_rounded,
        'Thời gian tính tiến độ',
        '${a.startAt == null ? 'Từ lúc giao' : _fmtDateTime(a.startAt!)} → ${_fmtDateTime(a.endAt)}',
      ),
      _row(
        Icons.info_outline_rounded,
        'Lưu ý',
        a.mode == AssignmentMode.newOnly
            ? 'Chỉ thẻ trong lớp chưa ôn trước giờ bắt đầu mới được tính.'
            : 'Chỉ ôn thẻ trong học liệu của lớp, trong khoảng thời gian trên mới được tính.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
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
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                children: [
                  Text(
                    a.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (a.description != null && a.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(a.description!, style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 12),
                  ...(a.isTest ? _testRows() : _missionRows()),
                  if (!a.isTest && a.sources.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Nguồn thẻ — chọn để học',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    for (final s in a.sources)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: cs.primaryContainer.withValues(alpha: 0.35),
                        child: ListTile(
                          leading: Icon(s.isFolder ? Icons.folder_rounded : Icons.style_rounded),
                          title: Text(
                            _names[s.id] ?? (s.isFolder ? 'Thư mục' : 'Bộ thẻ'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openSource(s),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (a.isTest)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: FilledButton(
                  onPressed: _startTest,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    (a.my?.attemptsCount ?? 0) > 0 ? 'LÀM LẠI' : 'BẮT ĐẦU LÀM BÀI',
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
