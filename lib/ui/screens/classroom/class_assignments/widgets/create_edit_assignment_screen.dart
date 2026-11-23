import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/ui/commons/app_date_picker.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_state.dart';
import 'package:mind_deck/ui/screens/classroom/class_tests/class_tests_screen.dart';
import 'package:mind_deck/data/models/class/class_model.dart';

/// Tạo / sửa bài giao.
/// - Bài học: nguồn là học liệu BẢN SAO của lớp (không dùng deck cá nhân), chế độ `mode × scope`.
/// - Bài kiểm tra: chọn đề trong kho đề của lớp.
/// - `startAt` bỏ trống = giao ngay; `endAt` bắt buộc và phải ở tương lai.
class CreateEditAssignmentScreen extends StatefulWidget {
  final ClassModel classData;
  final ClassAssignmentModel? existingAssignment;

  const CreateEditAssignmentScreen({super.key, required this.classData, this.existingAssignment});

  @override
  State<CreateEditAssignmentScreen> createState() => _CreateEditAssignmentScreenState();
}

class _CreateEditAssignmentScreenState extends State<CreateEditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _countController;

  late AssignmentType _selectedType;
  DateTime? _startAt;
  DateTime? _endAt;

  String _mode = AssignmentMode.allCards;
  String _scope = AssignmentScope.all;

  /// Nguồn đã chọn: id bản sao -> nguồn; tên hiển thị tra theo [_names].
  final Map<String, AssignmentSource> _selectedSources = {};
  final Map<String, String> _names = {};

  String? _selectedTestId;
  String? _selectedTestName;

  bool _loadingLookups = false;

  String get _classId => widget.classData.id;
  ClassAssignmentModel? get _existing => widget.existingAssignment;
  bool get isEditMode => _existing != null;

  /// Bài đã kích hoạt: BE chỉ cho đổi `startAt` khi còn `scheduled`.
  bool get _startLocked => isEditMode && _existing!.phase != AssignmentPhase.scheduled;

  @override
  void initState() {
    super.initState();
    final asg = _existing;
    _titleController = TextEditingController(text: asg?.title ?? '');
    _descriptionController = TextEditingController(text: asg?.description ?? '');
    _selectedType = asg?.type ?? AssignmentType.studyMission;
    _startAt = asg?.startAt;
    _endAt = asg?.endAt;
    _mode = asg?.mode ?? AssignmentMode.allCards;
    _scope = asg?.scope ?? AssignmentScope.all;
    _countController = TextEditingController(text: asg?.targetCount?.toString() ?? '');
    for (final s in asg?.sources ?? const <AssignmentSource>[]) {
      _selectedSources[s.id] = s;
    }
    _selectedTestId = asg?.testId;
    _selectedTestName = asg?.test?.name;

    // Tên nguồn không có trong response bài giao: tra từ học liệu của lớp.
    if (isEditMode && _selectedSources.isNotEmpty) _resolveSourceNames();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _countController.dispose();
    super.dispose();
  }

  ClassRepository get _classRepo => DI().sl<ClassRepository>();

  /// Tải hết học liệu cấp cao của lớp (tối đa 5 trang × 100) để chọn / tra tên.
  Future<List<ClassMaterialItem>> _loadAllMaterials() async {
    final all = <ClassMaterialItem>[];
    for (var page = 1; page <= 50; page++) {
      final res = await _classRepo.getMaterials(_classId, page: page, limit: 100);
      all.addAll(res.items);
      if (!res.hasMore) break;
    }
    return all;
  }

  Future<void> _resolveSourceNames() async {
    try {
      final items = await _loadAllMaterials();
      if (!mounted) return;
      setState(() {
        for (final i in items) {
          _names[i.id] = i.name;
        }
      });
    } on Failure {
      // Không tra được tên thì hiển thị tạm theo loại.
    }
  }

  String _sourceLabel(AssignmentSource s) =>
      _names[s.id] ?? (s.isFolder ? 'Thư mục đã chọn' : 'Bộ thẻ đã chọn');

  void _toast(String message, {bool error = true}) {
    CustomToast.show(
      context,
      error ? CustomToast.danger(message: message) : CustomToast.success(message: message),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final endAt = _endAt;
    if (endAt == null) return _toast('Vui lòng chọn hạn nộp');
    // BE chỉ đòi hạn nộp ở tương lai khi TẠO hoặc khi ĐỔI hạn; sửa tiêu đề / mô tả của bài đã
    // hết hạn thì gửi lại đúng hạn cũ là hợp lệ.
    final endChanged = !isEditMode || !_existing!.endAt.isAtSameMomentAs(endAt);
    if (endChanged && !endAt.isAfter(DateTime.now())) return _toast('Hạn nộp phải ở tương lai');
    final startAt = _startAt;
    if (startAt != null && !startAt.isBefore(endAt)) {
      return _toast('Giờ bắt đầu phải trước hạn nộp');
    }

    int? targetCount;
    if (_selectedType == AssignmentType.studyMission) {
      if (_selectedSources.isEmpty) return _toast('Vui lòng chọn ít nhất một bộ thẻ / thư mục');
      if (_scope == AssignmentScope.count) {
        targetCount = int.tryParse(_countController.text.trim());
        if (targetCount == null || targetCount <= 0) return _toast('Số thẻ phải lớn hơn 0');
      }
    } else if (_selectedTestId == null) {
      return _toast('Vui lòng chọn bài kiểm tra');
    }

    final isMission = _selectedType == AssignmentType.studyMission;
    final draft = AssignmentDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      // Bài đã kích hoạt: gửi lại đúng giá trị cũ (khác đi sẽ bị 403 LOCKED).
      startAt: _startAt,
      endAt: endAt,
      mode: isMission ? _mode : null,
      scope: isMission ? _scope : null,
      targetCount: isMission ? targetCount : null,
      sources: isMission ? _selectedSources.values.toList() : const [],
      testId: isMission ? null : _selectedTestId,
    );

    final bloc = context.read<ClassAssignmentsBloc>();
    if (isEditMode) {
      bloc.add(
        ClassAssignmentUpdated(classId: _classId, assignmentId: _existing!.id, draft: draft),
      );
    } else {
      bloc.add(ClassAssignmentCreated(classId: _classId, draft: draft));
    }
  }

  Future<void> _pickEnd() async {
    final dt = await AppDatePicker.pickDeadlineDateTime(context, initialDateTime: _endAt);
    if (dt != null && mounted) setState(() => _endAt = dt);
  }

  Future<void> _pickStart() async {
    final dt = await AppDatePicker.pickDeadlineDateTime(context, initialDateTime: _startAt);
    if (dt != null && mounted) setState(() => _startAt = dt);
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ---- Chọn nguồn thẻ (học liệu bản sao của lớp) ----
  Future<void> _pickSources() async {
    setState(() => _loadingLookups = true);
    List<ClassMaterialItem> items;
    try {
      items = await _loadAllMaterials();
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _loadingLookups = false);
        _toast(ClassErrorMessages.of(f));
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadingLookups = false;
      for (final i in items) {
        _names[i.id] = i.name;
      }
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SourcePickerSheet(
        classId: _classId,
        items: items,
        selected: Map.of(_selectedSources),
        onChanged: (selected, names) {
          setState(() {
            _selectedSources
              ..clear()
              ..addAll(selected);
            _names.addAll(names);
          });
        },
      ),
    );
  }

  // ---- Chọn đề kiểm tra (kho đề của lớp) ----
  Future<void> _pickTest() async {
    setState(() => _loadingLookups = true);
    List<CustomTestModel> tests = [];
    try {
      for (var page = 1; page <= 50; page++) {
        final res = await DI().sl<TestRepository>().getTests(
          classId: _classId,
          page: page,
          limit: 100,
        );
        tests.addAll(res.data);
        if (res.data.length < 100) break;
      }
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _loadingLookups = false);
        _toast(ClassErrorMessages.of(f));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _loadingLookups = false);

    final colorScheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<CustomTestModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, controller) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chọn bài kiểm tra',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        // Mở kho đề để tạo đề mới rồi chọn lại.
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClassTestsScreen(classData: widget.classData),
                          ),
                        );
                        if (mounted) _pickTest();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Kho đề'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              Expanded(
                child: tests.isEmpty
                    ? Center(
                        child: Text(
                          'Lớp chưa có đề nào. Vào "Kho đề" để tạo đề kiểm tra.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: tests.length,
                        itemBuilder: (ctx, i) {
                          final t = tests[i];
                          final count = t.questionCount != null
                              ? '${t.questionCount} câu'
                              : 'tối đa ~${t.cardCount ?? 0} câu';
                          return ListTile(
                            leading: Icon(
                              t.isManual ? Icons.edit_note_rounded : Icons.auto_awesome_rounded,
                              color: Colors.orange.shade600,
                            ),
                            title: Text(
                              t.name,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text('${t.isManual ? 'Tự soạn' : 'Tự động'} · $count'),
                            selected: t.id == _selectedTestId,
                            onTap: () => Navigator.pop(ctx, t),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTestId = picked.id;
        _selectedTestName = picked.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMission = _selectedType == AssignmentType.studyMission;

    return BlocConsumer<ClassAssignmentsBloc, ClassAssignmentsState>(
      listenWhen: (p, c) => p.savedId != c.savedId || p.formErrorId != c.formErrorId,
      listener: (context, state) {
        if (state.formError != null) _toast(state.formError!);
      },
      builder: (context, state) {
        return BlocListener<ClassAssignmentsBloc, ClassAssignmentsState>(
          // Lưu thành công -> đóng form (danh sách đã được bloc tải lại).
          listenWhen: (p, c) => p.savedId != c.savedId,
          listener: (context, _) => Navigator.of(context).maybePop(),
          child: Scaffold(
            backgroundColor: colorScheme.background,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                isEditMode ? 'Sửa bài tập' : 'Giao bài tập mới',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
              scrolledUnderElevation: 0,
              elevation: 0,
              centerTitle: true,
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("Thông tin cơ bản"),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _titleController,
                          label: 'Tiêu đề *',
                          hint: 'Nhập tiêu đề bài tập',
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Bắt buộc nhập' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Mô tả (tùy chọn)',
                          hint: 'Nhập hướng dẫn hoặc ghi chú thêm',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 32),

                        _sectionTitle("Thời gian"),
                        const SizedBox(height: 16),
                        _buildSelectionCard(
                          title: 'Giờ bắt đầu (tùy chọn)',
                          subtitle: _startAt == null
                              ? 'Giao ngay'
                              : '${_fmt(_startAt!)}${_startLocked ? ' (đã bắt đầu)' : ''}',
                          icon: Icons.play_circle_outline_rounded,
                          iconColor: Colors.green,
                          onTap: _startLocked ? null : _pickStart,
                          trailing: _startAt != null && !_startLocked
                              ? IconButton(
                                  tooltip: 'Giao ngay',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() => _startAt = null),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildSelectionCard(
                          title: 'Hạn nộp *',
                          subtitle: _endAt == null ? 'Bấm để chọn hạn chót' : _fmt(_endAt!),
                          icon: Icons.calendar_month_rounded,
                          iconColor: Colors.redAccent,
                          onTap: _pickEnd,
                        ),
                        const SizedBox(height: 32),

                        if (!isEditMode) ...[
                          _sectionTitle("Loại bài tập"),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoSlidingSegmentedControl<AssignmentType>(
                              groupValue: _selectedType,
                              children: const {
                                AssignmentType.studyMission: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Nhiệm vụ học'),
                                ),
                                AssignmentType.gradedTest: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Bài kiểm tra'),
                                ),
                              },
                              onValueChanged: (v) {
                                if (v != null) setState(() => _selectedType = v);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          _lockedNote(colorScheme),
                          const SizedBox(height: 24),
                        ],

                        if (isMission) ..._missionSection(colorScheme) else ..._testSection(),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: state.isProcessing ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: state.isProcessing
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : Text(
                                    isEditMode ? 'LƯU THAY ĐỔI' : 'GIAO BÀI',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (_loadingLookups)
                  const Positioned.fill(child: ColoredBox(color: Color(0x33000000))),
                if (_loadingLookups) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _lockedNote(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Không đổi được loại bài. Khi đã có người làm, chỉ sửa được tiêu đề, mô tả và hạn nộp; '
              'nội dung (nguồn thẻ, chế độ, đề) và giờ bắt đầu sẽ bị khóa.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _missionSection(ColorScheme colorScheme) {
    return [
      _sectionTitle("Cách học"),
      const SizedBox(height: 12),
      _label('Chế độ'),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Tất cả thẻ'),
            selected: _mode == AssignmentMode.allCards,
            onSelected: (_) => setState(() => _mode = AssignmentMode.allCards),
          ),
          ChoiceChip(
            label: const Text('Chỉ thẻ mới'),
            selected: _mode == AssignmentMode.newOnly,
            onSelected: (_) => setState(() => _mode = AssignmentMode.newOnly),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _label('Khối lượng'),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Toàn bộ'),
            selected: _scope == AssignmentScope.all,
            onSelected: (_) => setState(() => _scope = AssignmentScope.all),
          ),
          ChoiceChip(
            label: const Text('Số thẻ cụ thể'),
            selected: _scope == AssignmentScope.count,
            onSelected: (_) => setState(() => _scope = AssignmentScope.count),
          ),
        ],
      ),
      if (_scope == AssignmentScope.count) ...[
        const SizedBox(height: 12),
        _buildTextField(
          controller: _countController,
          label: 'Số thẻ mỗi học viên *',
          hint: 'VD: 20',
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            return n == null || n <= 0 ? 'Nhập số nguyên lớn hơn 0' : null;
          },
        ),
      ],
      const SizedBox(height: 8),
      Text(
        _mode == AssignmentMode.newOnly
            ? 'Mục tiêu của mỗi học viên được tính riêng lúc bài bắt đầu (chỉ thẻ chưa ôn). '
                  'Học viên không còn thẻ phù hợp sẽ không được giao.'
            : 'Mục tiêu của mỗi học viên được tính riêng lúc bài bắt đầu. Chỉ ôn thẻ trong khoảng '
                  'bắt đầu – hạn nộp mới được tính.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 24),
      _sectionTitle("Nguồn thẻ"),
      const SizedBox(height: 12),
      _buildSelectionCard(
        title: 'Bộ thẻ / thư mục của lớp *',
        subtitle: _selectedSources.isEmpty
            ? 'Bấm để chọn từ học liệu của lớp'
            : '${_selectedSources.length} mục đã chọn',
        icon: Icons.style_rounded,
        iconColor: colorScheme.primary,
        onTap: _pickSources,
      ),
      if (_selectedSources.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final s in _selectedSources.values)
              InputChip(
                avatar: Icon(s.isFolder ? Icons.folder_rounded : Icons.style_rounded, size: 16),
                label: Text(_sourceLabel(s)),
                onDeleted: () => setState(() => _selectedSources.remove(s.id)),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _testSection() {
    final cs = Theme.of(context).colorScheme;
    return [
      _sectionTitle("Đề kiểm tra"),
      const SizedBox(height: 12),
      _buildSelectionCard(
        title: 'Bài kiểm tra *',
        subtitle: _selectedTestName ?? 'Bấm để chọn đề trong kho đề của lớp',
        icon: Icons.assignment_rounded,
        iconColor: cs.primary,
        onTap: _pickTest,
      ),
      const SizedBox(height: 8),
      Text(
        'Số lượt làm, giới hạn giờ, cách tính điểm và quyền xem đáp án được đặt trong từng đề (Kho đề).',
        style: TextStyle(fontSize: 12, height: 1.4, color: cs.onSurfaceVariant),
      ),
    ];
  }

  Widget _sectionTitle(String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _label(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          validator: validator,
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing ??
                  (onTap == null
                      ? const SizedBox.shrink()
                      : Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colorScheme.outlineVariant,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chọn nguồn thẻ cho bài học: folder / deck lẻ của lớp, hoặc từng deck bên trong một folder.
class _SourcePickerSheet extends StatefulWidget {
  final String classId;
  final List<ClassMaterialItem> items;
  final Map<String, AssignmentSource> selected;
  final void Function(Map<String, AssignmentSource> selected, Map<String, String> names) onChanged;

  const _SourcePickerSheet({
    required this.classId,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_SourcePickerSheet> createState() => _SourcePickerSheetState();
}

class _SourcePickerSheetState extends State<_SourcePickerSheet> {
  late final Map<String, AssignmentSource> _selected = Map.of(widget.selected);
  final Map<String, String> _names = {};

  /// Deck con của từng folder đã mở rộng (tải khi mở).
  final Map<String, List<ClassMaterialItem>> _children = {};
  final Set<String> _expanded = {};
  final Set<String> _loadingFolders = {};

  void _toggle(ClassMaterialItem item) {
    setState(() {
      _names[item.id] = item.name;
      if (_selected.remove(item.id) == null) {
        _selected[item.id] = AssignmentSource(type: item.type, id: item.id);
      }
    });
    widget.onChanged(Map.of(_selected), Map.of(_names));
  }

  Future<void> _toggleExpand(ClassMaterialItem folder) async {
    if (_expanded.remove(folder.id)) {
      setState(() {});
      return;
    }
    _expanded.add(folder.id);
    if (_children.containsKey(folder.id)) {
      setState(() {});
      return;
    }
    setState(() => _loadingFolders.add(folder.id));
    try {
      final page = await DI().sl<ClassRepository>().getFolderDecks(
        widget.classId,
        folder.id,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _children[folder.id] = page.items;
        _loadingFolders.remove(folder.id);
      });
    } on Failure {
      if (mounted) setState(() => _loadingFolders.remove(folder.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row(ClassMaterialItem item, {double indent = 0, bool folderRow = false}) {
      final checked = _selected.containsKey(item.id);
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: ListTile(
          dense: indent > 0,
          leading: Checkbox(value: checked, onChanged: (_) => _toggle(item)),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            item.isFolder ? '${item.deckCount ?? 0} bộ thẻ' : '${item.cardCount ?? 0} thẻ',
          ),
          trailing: folderRow
              ? IconButton(
                  tooltip: 'Chọn từng bộ thẻ trong thư mục',
                  icon: _loadingFolders.contains(item.id)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _expanded.contains(item.id)
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                        ),
                  onPressed: () => _toggleExpand(item),
                )
              : null,
          onTap: () => _toggle(item),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nguồn thẻ (${_selected.length})',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xong')),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            Expanded(
              child: widget.items.isEmpty
                  ? Center(
                      child: Text(
                        'Lớp chưa có học liệu. Hãy thêm học liệu trước.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView(
                      controller: controller,
                      children: [
                        for (final item in widget.items) ...[
                          row(item, folderRow: item.isFolder),
                          if (item.isFolder && _expanded.contains(item.id))
                            for (final child in _children[item.id] ?? const <ClassMaterialItem>[])
                              row(child, indent: 32),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
