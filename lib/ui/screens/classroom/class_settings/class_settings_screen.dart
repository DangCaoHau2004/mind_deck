import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_settings_model.dart';
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
      create: (context) => DI().sl<ClassSettingsBloc>()
        ..add(
          ClassSettingsInitialized(
            settings: classData.settings ?? const ClassSettings(),
            mySettings: classData.myNotifySettings ?? const MyNotifySettings(),
          ),
        ),
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

/// Mô tả hiển thị của từng loại thông báo lớp.
typedef _NotifyInfo = ({String type, String title, String subtitle, IconData icon, Color color});

class _ClassSettingsViewState extends State<_ClassSettingsView> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late bool _isPublic;
  late bool _requireApproval;

  static const List<_NotifyInfo> _notifyTypes = [
    (
      type: ClassNotifyTypes.assignment,
      title: 'Bài tập',
      subtitle: 'Bài học mới, thay đổi hoặc bị xóa',
      icon: Icons.assignment_rounded,
      color: Colors.orange,
    ),
    (
      type: ClassNotifyTypes.test,
      title: 'Bài kiểm tra',
      subtitle: 'Bài kiểm tra mới, thay đổi hoặc bị xóa',
      icon: Icons.quiz_rounded,
      color: Colors.deepPurple,
    ),
    (
      type: ClassNotifyTypes.announcement,
      title: 'Thông báo chung',
      subtitle: 'Thông báo từ giảng viên của lớp',
      icon: Icons.campaign_rounded,
      color: Colors.blue,
    ),
    (
      type: ClassNotifyTypes.materialAdded,
      title: 'Học liệu mới',
      subtitle: 'Khi giảng viên thêm bộ thẻ hoặc thư mục',
      icon: Icons.library_books_rounded,
      color: Colors.teal,
    ),
    (
      type: ClassNotifyTypes.joinRequest,
      title: 'Yêu cầu tham gia',
      subtitle: 'Có người xin vào lớp (chủ lớp, quản trị viên)',
      icon: Icons.person_add_alt_1_rounded,
      color: Colors.green,
    ),
    (
      type: ClassNotifyTypes.submission,
      title: 'Học viên nộp bài',
      subtitle: 'Lần nộp bài kiểm tra đầu tiên (giảng viên)',
      icon: Icons.task_alt_rounded,
      color: Colors.indigo,
    ),
    (
      type: ClassNotifyTypes.memberLeft,
      title: 'Thành viên rời lớp',
      subtitle: 'Có người rời khỏi lớp (chủ lớp, quản trị viên)',
      icon: Icons.logout_rounded,
      color: Colors.red,
    ),
  ];

  /// Loại thông báo mà vai trò hiện tại thực sự nhận được (ẩn các công tắc vô nghĩa).
  bool _receivable(String type) {
    final c = widget.classData;
    return switch (type) {
      ClassNotifyTypes.joinRequest || ClassNotifyTypes.memberLeft => c.isAdminOrOwner,
      ClassNotifyTypes.submission => c.isTeacher,
      _ => true,
    };
  }

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
    final classId = widget.classData.id;
    final canEditClass = widget.classData.isAdminOrOwner;

    return BlocConsumer<ClassSettingsBloc, ClassSettingsState>(
      listenWhen: (p, c) => p.status != c.status || p.noticeId != c.noticeId,
      listener: (context, state) {
        if (state.status == ClassSettingsStatus.success) {
          CustomToast.show(context, CustomToast.success(message: 'Cập nhật lớp học thành công!'));
          Navigator.pop(context, true); // return true to indicate success
        } else if (state.status == ClassSettingsStatus.failure) {
          CustomToast.show(
            context,
            CustomToast.danger(message: state.errorMessage ?? 'Có lỗi xảy ra'),
          );
        } else if (state.notice != null) {
          CustomToast.show(context, CustomToast.danger(message: state.notice!));
        }
      },
      builder: (context, state) {
        final settings = state.settings;
        final mine = state.mySettings;

        return PopScope(
          // Trả về `true` nếu đã đổi cài đặt để màn hub tải lại `permissions`.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.pop(context, state.hasChanges);
          },
          child: Scaffold(
            backgroundColor: colorScheme.background,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context, state.hasChanges),
              ),
              title: Text(
                "Cài đặt Lớp học",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
              scrolledUnderElevation: 0,
              elevation: 0,
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canEditClass) ...[
                    _buildSectionTitle(context, "Thông tin cơ bản"),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context: context,
                      controller: _nameController,
                      label: "Tên lớp học",
                      hint: "VD: Tiếng Anh C2",
                      maxLength: 255, // BE: tên lớp tối đa 255 ký tự (CLASS_NAME_TOO_LONG)
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      context: context,
                      controller: _descController,
                      label: "Mô tả",
                      hint: "VD: Nâng cao trình độ",
                      maxLines: 4,
                    ),
                    const SizedBox(height: 40),

                    _buildSectionTitle(context, "Quyền riêng tư & Tham gia"),
                    const SizedBox(height: 16),
                    _buildCard(
                      context,
                      children: [
                        _buildSwitchTile(
                          context: context,
                          title: "Công khai lớp học",
                          subtitle: "Ai cũng có thể tìm thấy và xem thông tin lớp này",
                          value: _isPublic,
                          icon: CupertinoIcons.globe,
                          iconColor: Colors.green,
                          onChanged: (val) => setState(() => _isPublic = val),
                        ),
                        _divider(colorScheme),
                        _buildSwitchTile(
                          context: context,
                          title: "Yêu cầu phê duyệt",
                          subtitle: "Học viên cần được bạn đồng ý mới có thể vào lớp",
                          value: _requireApproval,
                          icon: CupertinoIcons.lock_shield_fill,
                          iconColor: Colors.orange,
                          onChanged: (val) => setState(() => _requireApproval = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                                "Cập nhật thông tin",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildSectionTitle(context, "Quyền của học viên"),
                    const SizedBox(height: 4),
                    _buildHint(context, "Các thay đổi dưới đây được lưu ngay."),
                    const SizedBox(height: 12),
                    _buildCard(
                      context,
                      children: [
                        _buildSwitchTile(
                          context: context,
                          title: "Cho phép học viên mời thành viên",
                          subtitle: "Học viên có thể mời bằng email (người được mời tự chấp nhận)",
                          value: settings.allowMemberAdd,
                          icon: CupertinoIcons.person_add_solid,
                          iconColor: Colors.blue,
                          onChanged: (v) => context.read<ClassSettingsBloc>().add(
                            ClassSettingToggled(
                              classId: classId,
                              key: ClassSettingKey.allowMemberAdd,
                              value: v,
                            ),
                          ),
                        ),
                        _divider(colorScheme),
                        _buildSwitchTile(
                          context: context,
                          title: "Cho phép học viên sao chép học liệu",
                          subtitle:
                              "Học viên có thể sao chép bộ thẻ, thư mục của lớp về thư viện riêng",
                          value: settings.allowMemberClone,
                          icon: CupertinoIcons.doc_on_doc_fill,
                          iconColor: Colors.teal,
                          onChanged: (v) => context.read<ClassSettingsBloc>().add(
                            ClassSettingToggled(
                              classId: classId,
                              key: ClassSettingKey.allowMemberClone,
                              value: v,
                            ),
                          ),
                        ),
                        _divider(colorScheme),
                        _buildSwitchTile(
                          context: context,
                          title: "Hiện bảng xếp hạng cho học viên",
                          subtitle: "Tắt thì chỉ giảng viên xem được bảng xếp hạng",
                          value: settings.showLeaderboard,
                          icon: Icons.workspace_premium_rounded,
                          iconColor: Colors.amber.shade800,
                          onChanged: (v) => context.read<ClassSettingsBloc>().add(
                            ClassSettingToggled(
                              classId: classId,
                              key: ClassSettingKey.showLeaderboard,
                              value: v,
                            ),
                          ),
                        ),
                        _divider(colorScheme),
                        _buildSwitchTile(
                          context: context,
                          title: "Hiện email thành viên cho học viên",
                          subtitle: "Mặc định chỉ giảng viên thấy email của thành viên",
                          value: settings.showMemberEmails,
                          icon: CupertinoIcons.mail_solid,
                          iconColor: Colors.purple,
                          onChanged: (v) => context.read<ClassSettingsBloc>().add(
                            ClassSettingToggled(
                              classId: classId,
                              key: ClassSettingKey.showMemberEmails,
                              value: v,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    _buildSectionTitle(context, "Thông báo của lớp"),
                    const SizedBox(height: 4),
                    _buildHint(
                      context,
                      "Loại thông báo nào được phép gửi trong lớp. Mỗi thành viên vẫn có thể tắt riêng.",
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      context,
                      children: [
                        for (var i = 0; i < _notifyTypes.length; i++) ...[
                          if (i > 0) _divider(colorScheme),
                          _buildSwitchTile(
                            context: context,
                            title: _notifyTypes[i].title,
                            subtitle: _notifyTypes[i].subtitle,
                            value: settings.notifyEnabled(_notifyTypes[i].type),
                            icon: _notifyTypes[i].icon,
                            iconColor: _notifyTypes[i].color,
                            onChanged: (v) => context.read<ClassSettingsBloc>().add(
                              ClassNotifyToggled(
                                classId: classId,
                                type: _notifyTypes[i].type,
                                value: v,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],

                  _buildSectionTitle(context, "Thông báo của tôi"),
                  const SizedBox(height: 4),
                  _buildHint(
                    context,
                    "Chỉ áp dụng cho bạn trong lớp này. Các thay đổi được lưu ngay.",
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    context,
                    children: [
                      _buildSwitchTile(
                        context: context,
                        title: "Tắt tất cả thông báo của lớp",
                        subtitle: "Không nhận bất kỳ thông báo nào từ lớp học này",
                        value: mine.muted,
                        icon: CupertinoIcons.bell_slash_fill,
                        iconColor: Colors.grey,
                        onChanged: (v) => context.read<ClassSettingsBloc>().add(
                          MyNotifyToggled(classId: classId, value: v),
                        ),
                      ),
                      for (final info in _notifyTypes.where((i) => _receivable(i.type))) ...[
                        _divider(colorScheme),
                        Opacity(
                          opacity: mine.muted ? 0.45 : 1,
                          child: _buildSwitchTile(
                            context: context,
                            title: info.title,
                            subtitle: info.subtitle,
                            value: mine.enabled(info.type),
                            icon: info.icon,
                            iconColor: info.color,
                            onChanged: mine.muted
                                ? null
                                : (v) => context.read<ClassSettingsBloc>().add(
                                    MyNotifyToggled(classId: classId, type: info.type, value: v),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider(ColorScheme colorScheme) => Divider(
    height: 1,
    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
    indent: 64,
    endIndent: 16,
  );

  /// Gom các switch vào một Card bo góc chuẩn iOS/Bento style
  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildHint(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    int? maxLength,
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
          inputFormatters: [if (maxLength != null) LengthLimitingTextInputFormatter(maxLength)],
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
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
    required ValueChanged<bool>? onChanged,
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
              color: iconColor.withValues(alpha: 0.15),
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
          CupertinoSwitch(
            value: value,
            activeTrackColor: colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
