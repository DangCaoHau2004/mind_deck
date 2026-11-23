import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mind_deck/ui/commons/widgets/add_tag_sheet.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/folder_illustration.dart';
import 'package:mind_deck/ui/commons/tag_pill.dart';
import 'package:mind_deck/ui/commons/widgets/form_preview_frame.dart';
import 'package:mind_deck/ui/commons/widgets/public_switch_card.dart';
import 'package:mind_deck/ui/commons/widgets/tag_picker.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'package:mind_deck/ui/screens/folder/folder_form/bloc/folder_form_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_form/bloc/folder_form_event.dart';
import 'package:mind_deck/ui/screens/folder/folder_form/bloc/folder_form_state.dart';

// ==========================================
// 1. MÀN HÌNH TẠO MỚI
// ==========================================
class CreateFolderScreen extends StatelessWidget {
  const CreateFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'folder_form_title_new'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: _SharedFolderForm(
        isEdit: false,
        onSubmit: (name, description, color, icon, isPublic, tagIds) {
          context.read<FolderFormBloc>().add(
            FolderFormCreate(
              name: name,
              description: description,
              color: color,
              icon: icon,
              isPublic: isPublic,
              tagIds: tagIds,
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. MÀN HÌNH CHỈNH SỬA
// ==========================================
class EditFolderScreen extends StatelessWidget {
  final FolderModel folder;

  const EditFolderScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chỉnh sửa thư mục',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: _SharedFolderForm(
        isEdit: true,
        initialData: folder,
        onSubmit: (name, description, color, icon, isPublic, tagIds) {
          context.read<FolderFormBloc>().add(
            FolderFormUpdate(
              id: folder.id,
              name: name,
              description: description,
              color: color,
              icon: icon,
              // Chỉ gửi quyền riêng tư khi người dùng đổi, để BE giữ nguyên (vd thư mục chia sẻ qua link)
              isPublic: isPublic != folder.isPublic ? isPublic : null,
              tagIds: tagIds,
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. FORM DÙNG CHUNG (TẠO & SỬA)
// ==========================================
class _SharedFolderForm extends StatefulWidget {
  final bool isEdit;
  final FolderModel? initialData;
  final void Function(
    String name,
    String description,
    String color,
    String icon,
    bool isPublic,
    List<String> tagIds,
  )
  onSubmit;

  const _SharedFolderForm({required this.isEdit, this.initialData, required this.onSubmit});

  @override
  State<_SharedFolderForm> createState() => _SharedFolderFormState();
}

class _SharedFolderFormState extends State<_SharedFolderForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;

  late Color _selectedColor;
  late String _selectedIcon;
  late bool _isPublic;
  List<TagModel> _selectedTags = [];

  final List<Color> _availableColors = [
    const Color(0xFFFFFFFF),
    const Color(0xFF1565C0),
    const Color(0xFF4CAF50),
    const Color(0xFFE91E63),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF00BCD4),
    const Color(0xFF795548),
  ];

  final BorderRadius _disruptiveRadius = const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(16),
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _descController = TextEditingController(text: widget.initialData?.description ?? '');

    _selectedColor = widget.initialData?.color != null
        ? ColorUtils.parseHex(widget.initialData!.color)
        : _availableColors[1];

    _selectedIcon = widget.initialData?.icon ?? AppIcons.availableIconKeys.first;
    _isPublic = widget.initialData?.isPublic ?? false;

    if (widget.initialData != null) {
      _selectedTags = List<TagModel>.from(widget.initialData!.tags ?? []);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FolderFormBloc>().add(const FolderFormLoadTags());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameController.text.trim(),
        _descController.text.trim(),
        ColorUtils.toHex(_selectedColor),
        _selectedIcon,
        _isPublic,
        _selectedTags.map((t) => t.id).toList(),
      );
    }
  }

  // --- CÁC HÀM XÂY DỰNG GIAO DIỆN PHÍA DƯỚI GIỮ NGUYÊN 100% ---

  void _showNativeColorPicker() {
    Color displayColor = _selectedColor;
    double currentHue = HSVColor.fromColor(displayColor).hue;

    TextEditingController hexController = TextEditingController(
      text: ColorUtils.toHex(displayColor).replaceAll('#', ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isLight = ColorUtils.isLightColor(displayColor);

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text(
                'Chọn màu tùy chỉnh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: displayColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: isLight ? Border.all(color: Colors.grey.shade300, width: 1.5) : null,
                      boxShadow: [
                        BoxShadow(
                          color: displayColor.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLight
                            ? Colors.grey.shade100
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ColorUtils.toHex(displayColor),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: displayColor == const Color(0xFFFFFFFF)
                              ? Colors.black87
                              : displayColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: hexController,
                    decoration: InputDecoration(
                      labelText: 'Mã HEX Color',
                      prefixText: '# ',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isLight ? Colors.black87 : displayColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))],
                    onChanged: (value) {
                      String hex = value.trim();
                      if (hex.length == 6) {
                        setStateDialog(() {
                          displayColor = ColorUtils.parseHex(hex);
                          currentHue = HSVColor.fromColor(displayColor).hue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                          Colors.red,
                        ],
                      ),
                    ),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 14,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                          elevation: 5,
                        ),
                      ),
                      child: Slider(
                        min: 0.0,
                        max: 360.0,
                        value: currentHue,
                        onChanged: (value) {
                          setStateDialog(() {
                            currentHue = value;
                            displayColor = HSVColor.fromAHSV(1.0, currentHue, 1.0, 1.0).toColor();
                            hexController.text = ColorUtils.toHex(displayColor).replaceAll('#', '');
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: displayColor == const Color(0xFFFFFFFF)
                        ? Colors.black87
                        : displayColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() => _selectedColor = displayColor);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<FolderFormBloc, FolderFormState>(
      listener: (context, state) {
        if (state.status == FolderFormStatus.success) {
          context.pop(state.successMessage);
        } else if (state.status == FolderFormStatus.failure) {
          CustomToast.show(
            context,
            CustomToast.danger(message: state.errorMessage ?? 'Có lỗi xảy ra'),
          );
        }

        if (state.recentlyAddedTag != null) {
          final isAlreadySelected = _selectedTags.any((t) => t.id == state.recentlyAddedTag!.id);
          if (!isAlreadySelected) {
            setState(() {
              _selectedTags.add(state.recentlyAddedTag!);
            });
          }
        }
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreview(theme),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Tên thư mục',
                      hintText: 'folder_form_name_hint'.tr,
                      isRequired: true,
                      large: true,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Vui lòng nhập tên thư mục'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _descController,
                      label: 'folder_form_desc_label'.tr,
                      hintText: 'folder_form_desc_hint'.tr,
                      maxLines: 3,
                      large: true,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<FolderFormBloc, FolderFormState>(
                      builder: (context, state) => TagPicker(
                        availableTags: state.availableTags,
                        isLoading: state.isLoadingTags,
                        selectedTags: _selectedTags,
                        onToggle: (tag) => setState(() {
                          if (!_selectedTags.any((t) => t.id == tag.id)) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.removeWhere((t) => t.id == tag.id);
                          }
                        }),
                        onAddNew: _showAddTagDialog,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PublicSwitchCard(
                      subtitle: 'folder_public_warning'.tr,
                      value: _isPublic,
                      activeColor: _selectedColor,
                      onChanged: (val) => setState(() => _isPublic = val),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'folder_form_color_title'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        ..._availableColors.map((color) => _buildColorItem(color)),
                        if (!_availableColors.contains(_selectedColor))
                          _buildColorItem(_selectedColor),
                        _buildStaticColorPickerButton(),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Biểu tượng',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: AppIcons.availableIconKeys
                            .map((iconKey) => _buildIconItem(iconKey))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0).copyWith(bottom: 16),
                child: BlocBuilder<FolderFormBloc, FolderFormState>(
                  builder: (context, state) {
                    final isLoading = state.status == FolderFormStatus.loading;
                    final isLightBtn = ColorUtils.isLightColor(_selectedColor);
                    final btnTextColor = ColorUtils.getContrastColor(_selectedColor);

                    // Chưa nhập tên thì nút xám, chưa bấm được
                    return ListenableBuilder(
                      listenable: _nameController,
                      builder: (context, _) => ElevatedButton(
                        onPressed: isLoading || _nameController.text.trim().isEmpty
                            ? null
                            : _submitForm,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(0xFFE3E7F0),
                          disabledForegroundColor: Colors.black45,
                          backgroundColor: _selectedColor,
                          foregroundColor: btnTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 5,
                          minimumSize: const Size(double.infinity, 56),
                          shadowColor: isLightBtn
                              ? Colors.black.withValues(alpha: 0.1)
                              : _selectedColor.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: isLightBtn
                                ? BorderSide(color: Colors.grey.shade300)
                                : BorderSide.none,
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: btnTextColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isEdit ? 'Lưu thay đổi' : 'Tạo thư mục',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _nameController.text.trim().isEmpty ? null : btnTextColor,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorItem(Color color) {
    final isSelected = _selectedColor == color;
    final isLight = ColorUtils.isLightColor(color);
    final checkIconColor = ColorUtils.getContrastColor(color);

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: _disruptiveRadius,
          border: Border.all(
            color: isSelected
                ? checkIconColor
                : (isLight ? Colors.grey.shade300 : Colors.transparent),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isSelected ? Icon(Icons.check_rounded, color: checkIconColor, size: 22) : null,
      ),
    );
  }

  Widget _buildStaticColorPickerButton() {
    return GestureDetector(
      onTap: _showNativeColorPicker,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: _disruptiveRadius,
          gradient: const SweepGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.add_rounded, color: Colors.black87, size: 16),
        ),
      ),
    );
  }

  Widget _buildIconItem(String iconKey) {
    final isSelected = _selectedIcon == iconKey;
    final activeColor = ColorUtils.isLightColor(_selectedColor) ? Colors.black87 : _selectedColor;

    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = iconKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: _disruptiveRadius,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          AppIcons.getIconFromKey(iconKey),
          color: isSelected ? activeColor : Colors.grey.shade600,
          size: 26,
        ),
      ),
    );
  }

  /// Bản xem trước thẻ thư mục theo các lựa chọn hiện tại.
  Widget _buildPreview(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    // Thư mục mới chưa có bộ thẻ nào; khi sửa thì lấy số hiện có
    final deckCount = widget.initialData?.deckCount ?? widget.initialData?.decks?.length ?? 0;

    return FormPreviewFrame(
      color: _selectedColor,
      child: Row(
        children: [
          FolderIllustration(
            color: _selectedColor,
            icon: AppIcons.getIconFromKey(_selectedIcon),
            scale: 1.15,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ListenableBuilder(
              listenable: _nameController,
              builder: (context, _) {
                final name = _nameController.text.trim();
                final status = (_isPublic ? 'library_public' : 'library_private').tr;
                final count = 'folder_deck_count'.tr.replaceAll('{count}', '$deckCount');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'folder_form_untitled'.tr : name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: name.isEmpty
                            ? colorScheme.onSurface.withValues(alpha: 0.45)
                            : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$status · $count',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    if (_selectedTags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        runSpacing: 4,
                        children: [
                          for (final tag in _selectedTags)
                            TagPill(text: '#${tag.name}', hex: tag.color),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTagDialog() async {
    final result = await AddTagSheet.show(
      context,
      availableTags: context.read<FolderFormBloc>().state.availableTags,
    );
    if (result == null || !mounted) return;
    final existing = result.existing;
    if (existing != null) {
      // Tag đã có: dùng luôn, không tạo mới
      if (!_selectedTags.any((t) => t.id == existing.id)) {
        setState(() => _selectedTags.add(existing));
      }
    } else {
      context.read<FolderFormBloc>().add(FolderFormAddTag(name: result.name, color: result.color));
    }
  }
}
