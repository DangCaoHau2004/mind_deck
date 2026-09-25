import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/ui/commons/app_date_picker.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_assignments/bloc/class_assignments_event.dart';

class CreateEditAssignmentScreen extends StatefulWidget {
  final String classId;
  final ClassAssignmentModel? existingAssignment;

  const CreateEditAssignmentScreen({super.key, required this.classId, this.existingAssignment});

  @override
  State<CreateEditAssignmentScreen> createState() => _CreateEditAssignmentScreenState();
}

class _CreateEditAssignmentScreenState extends State<CreateEditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late AssignmentType _selectedType;
  DateTime? _selectedDeadline;

  DeckModel? _selectedDeck;
  CustomTestModel? _selectedTest;

  bool _isLoadingSources = false;
  List<DeckModel> _availableDecks = [];
  List<CustomTestModel> _availableTests = [];

  bool get isEditMode => widget.existingAssignment != null;

  @override
  void initState() {
    super.initState();
    final asg = widget.existingAssignment;
    _titleController = TextEditingController(text: asg?.title ?? '');
    _descriptionController = TextEditingController(text: asg?.description ?? '');
    _selectedType = asg?.type ?? AssignmentType.studyMission;
    _selectedDeadline = asg?.deadline;

    if (!isEditMode) {
      _fetchSources();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchSources() async {
    setState(() => _isLoadingSources = true);
    try {
      final results = await Future.wait([
        DI().sl<DeckRepository>().getDecks(limit: 50),
        DI().sl<TestRepository>().getTests(limit: 50),
      ]);
      if (mounted) {
        setState(() {
          _availableDecks = results[0].data as List<DeckModel>;
          _availableTests = results[1].data as List<CustomTestModel>;
        });
      }
    } catch (e) {
      debugPrint("Error loading sources: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSources = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời hạn (Deadline)')));
      return;
    }

    if (!isEditMode) {
      if (_selectedType == AssignmentType.studyMission && _selectedDeck == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn bộ thẻ (Deck)')));
        return;
      }
      if (_selectedType == AssignmentType.gradedTest && _selectedTest == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn bài kiểm tra')));
        return;
      }

      context.read<ClassAssignmentsBloc>().add(
        ClassAssignmentCreated(
          classId: widget.classId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          deadline: _selectedDeadline!.toIso8601String(),
          deckId: _selectedType == AssignmentType.studyMission ? _selectedDeck!.id : null,
          testId: _selectedType == AssignmentType.gradedTest ? _selectedTest!.id : null,
        ),
      );
    } else {
      context.read<ClassAssignmentsBloc>().add(
        ClassAssignmentUpdated(
          classId: widget.classId,
          assignmentId: widget.existingAssignment!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: _selectedDeadline!.toIso8601String(),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _selectDeadline() async {
    final dateTime = await AppDatePicker.pickDeadlineDateTime(
      context,
      initialDateTime: _selectedDeadline,
    );
    if (dateTime != null && mounted) {
      setState(() {
        _selectedDeadline = dateTime;
      });
    }
  }

  void _showSourceSelectionBottomSheet() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            final isMission = _selectedType == AssignmentType.studyMission;
            final itemsCount = isMission ? _availableDecks.length : _availableTests.length;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle chuẩn iOS
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isMission ? Icons.style_rounded : Icons.assignment_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isMission ? 'Chọn bộ thẻ' : 'Chọn bài kiểm tra',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                  if (itemsCount == 0)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_empty_rounded,
                              size: 64,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có dữ liệu.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: itemsCount,
                        itemBuilder: (ctx, index) {
                          if (isMission) {
                            final deck = _availableDecks[index];
                            return _buildSheetItem(
                              title: deck.name,
                              subtitle: '${deck.cardCount ?? 0} thẻ',
                              icon: Icons.layers_rounded,
                              color: Colors.blue,
                              onTap: () {
                                setState(() => _selectedDeck = deck);
                                Navigator.pop(ctx);
                              },
                            );
                          } else {
                            final test = _availableTests[index];
                            return _buildSheetItem(
                              title: test.name,
                              subtitle: '${test.questions.length} câu hỏi',
                              icon: Icons.quiz_rounded,
                              color: Colors.orange,
                              onTap: () {
                                setState(() => _selectedTest = test);
                                Navigator.pop(ctx);
                              },
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget con hỗ trợ BottomSheet
  Widget _buildSheetItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.shade500.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color.shade600),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.outlineVariant),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingSources
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Thông tin cơ bản",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onBackground,
                      ),
                    ),
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

                    Text(
                      "Cấu hình giao bài",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionCard(
                      title: 'Thời hạn (Deadline) *',
                      subtitle: _selectedDeadline == null
                          ? 'Bấm để chọn hạn chót'
                          : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year} ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}',
                      icon: Icons.calendar_month_rounded,
                      iconColor: Colors.redAccent,
                      onTap: _selectDeadline,
                    ),
                    const SizedBox(height: 24),

                    if (!isEditMode) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Loại bài tập *',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonFormField<AssignmentType>(
                          value: _selectedType,
                          icon: Icon(Icons.expand_more_rounded, color: colorScheme.primary),
                          decoration: const InputDecoration(
                            border: InputBorder.none, // Bỏ viền mặc định của Dropdown
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            fontFamily: 'SF Pro Display', // Đồng bộ font
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: AssignmentType.studyMission,
                              child: Text('Nhiệm vụ học (Study Mission)'),
                            ),
                            DropdownMenuItem(
                              value: AssignmentType.gradedTest,
                              child: Text('Bài kiểm tra (Graded Test)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSelectionCard(
                        title: _selectedType == AssignmentType.studyMission
                            ? 'Bộ thẻ *'
                            : 'Bài kiểm tra *',
                        subtitle: _selectedType == AssignmentType.studyMission
                            ? (_selectedDeck?.name ?? 'Bấm để chọn bộ thẻ')
                            : (_selectedTest?.name ?? 'Bấm để chọn bài kiểm tra'),
                        icon: _selectedType == AssignmentType.studyMission
                            ? Icons.style_rounded
                            : Icons.assignment_rounded,
                        iconColor: colorScheme.primary,
                        onTap: _showSourceSelectionBottomSheet,
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      // Edit mode warning được thiết kế lại thành Alert Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: colorScheme.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Không thể thay đổi loại bài tập, bộ thẻ, hoặc bài kiểm tra sau khi đã tạo.',
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Nút Submit
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditMode ? 'LƯU THAY ĐỔI' : 'TẠO BÀI TẬP',
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
    );
  }

  // Widget hỗ trợ vẽ TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
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

  // Widget hỗ trợ vẽ thẻ Bento Selection (chọn Ngày/Nguồn)
  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
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
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
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
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}
