import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_settings/bloc/class_settings_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_settings/bloc/class_settings_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_settings/bloc/class_settings_state.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';

class ClassSettingsScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassSettingsScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DI().sl<ClassSettingsBloc>(),
      child: _ClassSettingsView(classData: classData),
    );
  }
}

class _ClassSettingsView extends StatefulWidget {
  final ClassModel classData;

  const _ClassSettingsView({required this.classData});

  @override
  State<_ClassSettingsView> createState() => _ClassSettingsViewState();
}

class _ClassSettingsViewState extends State<_ClassSettingsView> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late bool _isPublic;
  late bool _requireApproval;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classData.name);
    _descController = TextEditingController(text: widget.classData.description);
    _isPublic = widget.classData.isPublic;
    _requireApproval = widget.classData.requireApproval;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      CustomToast.show(context, CustomToast.danger(message: 'Tên lớp học không được để trống'));
      return;
    }

    context.read<ClassSettingsBloc>().add(
      UpdateClassRequested(
        classId: widget.classData.id,
        name: name,
        description: _descController.text.trim(),
        isPublic: _isPublic,
        requireApproval: _requireApproval,
      ),
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
          "Cài đặt Lớp học",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<ClassSettingsBloc, ClassSettingsState>(
        listener: (context, state) {
          if (state.status == ClassSettingsStatus.success) {
            CustomToast.show(context, CustomToast.success(message: 'Cập nhật lớp học thành công!'));
            Navigator.pop(context, true); // return true to indicate success
          } else if (state.status == ClassSettingsStatus.failure) {
            CustomToast.show(
              context,
              CustomToast.danger(message: state.errorMessage ?? 'Có lỗi xảy ra'),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, "Thông tin cơ bản"),
                const SizedBox(height: 16),
                _buildTextField(
                  context: context,
                  controller: _nameController,
                  label: "Tên lớp học",
                  hint: "VD: Tiếng Anh C2",
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  context: context,
                  controller: _descController,
                  label: "Mô tả",
                  hint: "VD: Nâng cao trình độ",
                  maxLines: 4, // Tăng thêm 1 chút không gian cho mô tả
                ),
                const SizedBox(height: 40),

                _buildSectionTitle(context, "Quyền riêng tư & Tham gia"),
                const SizedBox(height: 16),

                // Gom các switch vào một Card bo góc chuẩn iOS/Bento style
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        context: context,
                        title: "Công khai lớp học",
                        subtitle: "Ai cũng có thể tìm thấy và xem thông tin lớp này",
                        value: _isPublic,
                        icon: CupertinoIcons.globe,
                        iconColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            _isPublic = val;
                          });
                        },
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                        indent: 64,
                        endIndent: 16,
                      ),
                      _buildSwitchTile(
                        context: context,
                        title: "Yêu cầu phê duyệt",
                        subtitle: "Học viên cần được bạn đồng ý mới có thể vào lớp",
                        value: _requireApproval,
                        icon: CupertinoIcons.lock_shield_fill,
                        iconColor: Colors.orange,
                        onChanged: (val) {
                          setState(() {
                            _requireApproval = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: state.status == ClassSettingsStatus.loading ? null : _submit,
                    child: state.status == ClassSettingsStatus.loading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Cập nhật",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(value: value, activeColor: colorScheme.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}
