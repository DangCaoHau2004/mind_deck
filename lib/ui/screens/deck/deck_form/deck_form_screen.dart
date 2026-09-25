import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'widgets/import_modal.dart';
import 'widgets/editable_card_widget.dart';
import 'package:mind_deck/ui/commons/app_date_picker.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/bloc/deck_form_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/bloc/deck_form_event.dart';
import 'package:mind_deck/ui/screens/deck/deck_form/bloc/deck_form_state.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/utils/color_utils.dart';

// TODO: cái phần này nó cần lưu ý logic của cái ảnh có nghĩa là khi mà nó hết hạn thì be sẽ xóa ảnh đó khỏi temp
// nếu user đó treo máy thì sao cần hướng giải quyết
// ==========================================
// 1. MÀN HÌNH TẠO MỚI (CREATE)
// ==========================================
class CreateDeckScreen extends StatelessWidget {
  const CreateDeckScreen({super.key});

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
          'Tạo bộ thẻ mới',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
      ),
      body: const _SharedDeckForm(isEdit: false),
    );
  }
}

// ==========================================
// 2. MÀN HÌNH CHỈNH SỬA (EDIT)
// ==========================================
class EditDeckScreen extends StatelessWidget {
  final DeckModel deck;

  const EditDeckScreen({super.key, required this.deck});

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
          'Chỉnh sửa bộ thẻ',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
      ),
      body: _SharedDeckForm(isEdit: true, initialData: deck),
    );
  }
}

// ==========================================
// 3. WIDGET DECK FORM CHUNG (SHARED FORM)
// ==========================================
class DeckFormScreen extends StatelessWidget {
  final DeckModel? deck;

  const DeckFormScreen({super.key, this.deck});

  @override
  Widget build(BuildContext context) {
    if (deck != null) {
      return EditDeckScreen(deck: deck!);
    }
    return const CreateDeckScreen();
  }
}

class _SharedDeckForm extends StatefulWidget {
  final bool isEdit;
  final DeckModel? initialData;

  const _SharedDeckForm({required this.isEdit, this.initialData});

  @override
  State<_SharedDeckForm> createState() => _SharedDeckFormState();
}

class _SharedDeckFormState extends State<_SharedDeckForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<TagModel> _selectedTags = [];
  bool _isPublic = false;
  GoalType _goalType = GoalType.longTerm;
  DateTime? _deadline;
  List<FlashcardModel> _flashcards = [];

  bool _isTagsExpanded = false;

  late Color _selectedColor;
  late String _selectedIcon;

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
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!.name;
      _selectedTags = List<TagModel>.from(widget.initialData!.tags ?? []);
      _isPublic = widget.initialData!.isPublic;
      _goalType = widget.initialData!.goalType;
      _deadline = widget.initialData!.deadline;

      if (widget.initialData!.flashcards != null) {
        _flashcards = List<FlashcardModel>.from(widget.initialData!.flashcards!);
      }

      _selectedColor = ColorUtils.parseHex(widget.initialData!.color);
      _selectedIcon = widget.initialData!.icon;
    } else {
      _selectedColor = _availableColors[1];
      _selectedIcon = AppIcons.availableIconKeys.first;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckFormBloc>().add(const DeckFormLoadTags());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showImportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 1,
          expand: false,
          builder: (context, scrollController) {
            return ImportModal(
              scrollController: scrollController,
              onImport: (parsedCards) {
                setState(() {
                  final newCards = parsedCards.map((c) {
                    return FlashcardModel(
                      id: 'card-${DateTime.now().microsecondsSinceEpoch}-${_flashcards.length}',
                      deckId: widget.initialData?.id ?? 'temp-deck-id',
                      frontText: c['front'] ?? '',
                      backText: c['back'] ?? '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                  }).toList();
                  _flashcards.addAll(newCards);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    content: Text(
                      'Đã nhập thành công ${parsedCards.length} flashcard vào danh sách!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _addCardManually() {
    setState(() {
      _flashcards.add(
        FlashcardModel(
          id: 'card-${DateTime.now().microsecondsSinceEpoch}-${_flashcards.length}',
          deckId: widget.initialData?.id ?? 'temp-deck-id',
          frontText: '',
          backText: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void _removeCard(int index) {
    setState(() {
      _flashcards.removeAt(index);
    });
  }

  Future<void> _selectDeadline() async {
    final picked = await AppDatePicker.pickDeadlineDate(context, initialDate: _deadline);

    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

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

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_flashcards.isEmpty || _flashcards.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Bộ thẻ phải có ít nhất 2 flashcard để tạo!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    if (_goalType == GoalType.shortTerm && _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Vui lòng chọn ngày Deadline cho mục tiêu Trí nhớ ngắn hạn!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'icon': _selectedIcon,
      'color': ColorUtils.toHex(_selectedColor),
      'goalType': _goalType.toJson(),
      'isPublic': _isPublic,
      'tagIds': _selectedTags.map((t) => t.id).toList(),
      'cards': _flashcards.map((e) => e.toJson()).toList(),
    };

    if (widget.isEdit && widget.initialData != null) {
      context.read<DeckFormBloc>().add(DeckFormUpdate(widget.initialData!.id, data));
    } else {
      context.read<DeckFormBloc>().add(DeckFormCreate(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditMode = widget.isEdit;

    return BlocListener<DeckFormBloc, DeckFormState>(
      listener: (context, state) {
        if (state.status == DeckFormStatus.success) {
          context.pop(state.successMessage ?? 'Thành công');
        } else if (state.status == DeckFormStatus.failure) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadataSection(colorScheme, theme),
                    const SizedBox(height: 24),
                    _buildStyleSection(colorScheme, theme),
                    const SizedBox(height: 24),
                    _buildGoalSection(colorScheme, theme),
                    const SizedBox(height: 24),
                    _buildCardListSection(colorScheme, theme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0).copyWith(top: 0),
              child: BlocBuilder<DeckFormBloc, DeckFormState>(
                builder: (context, state) {
                  final isLoading = state.status == DeckFormStatus.loading;
                  final isLightBtn = ColorUtils.isLightColor(_selectedColor);
                  final btnTextColor = ColorUtils.getContrastColor(_selectedColor);

                  return ElevatedButton(
                    onPressed: isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
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
                            child: CircularProgressIndicator(color: btnTextColor, strokeWidth: 2),
                          )
                        : Text(
                            isEditMode ? 'Lưu thay đổi' : 'Tạo bộ thẻ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: btnTextColor,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Thông tin chung',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _nameController,
            label: 'Tên bộ thẻ',
            isRequired: true,
            hintText: 'Nhập tên bộ thẻ (Ví dụ: IELTS Vocab...)',
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Tên bộ thẻ không được để trống';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          BlocBuilder<DeckFormBloc, DeckFormState>(
            builder: (context, state) {
              return _buildTagsSection(colorScheme, theme, state.availableTags);
            },
          ),
          const SizedBox(height: 20),
          Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quyền riêng tư bộ thẻ',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPublic
                        ? 'Bộ thẻ hiển thị công khai cho mọi người'
                        : 'Bộ thẻ chỉ hiển thị với riêng bạn',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isPublic,
                activeColor: colorScheme.onPrimary,
                activeTrackColor: colorScheme.primary,
                inactiveThumbColor: colorScheme.onSurface.withValues(alpha: 0.4),
                inactiveTrackColor: colorScheme.surfaceContainer,
                onChanged: (val) {
                  setState(() {
                    _isPublic = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(ColorScheme colorScheme, ThemeData theme, List<TagModel> availableTags) {
    final showExpandButton = availableTags.length > 3;
    final List<TagModel> tagsToShow = _isTagsExpanded
        ? availableTags
        : availableTags.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhãn dán (Tags):',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tagsToShow.map((tag) {
              final isSelected = _selectedTags.any((t) => t.id == tag.id);
              final tagColor = ColorUtils.parseHex(tag.color ?? '#8B5CF6');

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.removeWhere((t) => t.id == tag.id);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tagColor.withValues(alpha: 0.18)
                        : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? tagColor : colorScheme.outline.withValues(alpha: 0.15),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    '#${tag.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? tagColor : colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
            if (showExpandButton)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isTagsExpanded = !_isTagsExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTagsExpanded ? Icons.remove_rounded : Icons.add_rounded,
                        color: colorScheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isTagsExpanded ? 'Thu gọn' : '${availableTags.length - 3} nhãn khác',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            GestureDetector(
              onTap: _showAddTagDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: colorScheme.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Tự nhập tag...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddTagDialog() {
    final textController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Thêm Tag Mới',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: CustomTextField(
            controller: textController,
            label: 'Tên nhãn dán',
            hintText: 'Nhập tên nhãn (ví dụ: IELTS, Math...)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  context.read<DeckFormBloc>().add(DeckFormAddTag(name: name, color: '#8B5CF6'));
                }
                Navigator.pop(context);
              },
              child: const Text(
                'Thêm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStyleSection(ColorScheme colorScheme, ThemeData theme) {
    final buttonColor = ColorUtils.isLightColor(_selectedColor) ? Colors.black87 : _selectedColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: buttonColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Màu sắc & Biểu tượng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Màu sắc chủ đạo',
            style: theme.textTheme.titleSmall?.copyWith(
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
              if (!_availableColors.contains(_selectedColor)) _buildColorItem(_selectedColor),
              _buildStaticColorPickerButton(),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Biểu tượng học phần',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
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

  Widget _buildGoalSection(ColorScheme colorScheme, ThemeData theme) {
    final isShortTerm = _goalType == GoalType.shortTerm;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Mục tiêu học tập & Ghi nhớ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _goalType = GoalType.longTerm;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: !isShortTerm
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !isShortTerm
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.15),
                        width: !isShortTerm ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.all_inclusive_rounded,
                          color: !isShortTerm
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 26,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Trí nhớ vĩnh cửu',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thuật toán FSRS tiêu chuẩn giãn cách dài lâu.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _goalType = GoalType.shortTerm;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isShortTerm
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isShortTerm
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.15),
                        width: isShortTerm ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: isShortTerm
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 26,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Trí nhớ ngắn hạn',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nhồi nhét trước kỳ thi, cần nhập Deadline.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isShortTerm) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDeadline,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày thi cử / Deadline:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _deadline == null
                                ? 'Chọn ngày thi của bạn...'
                                : DateFormat('dd/MM/yyyy (EEEE)').format(_deadline!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardListSection(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.style_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Thẻ ôn tập (${_flashcards.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              if (_flashcards.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _flashcards.clear();
                    });
                  },
                  child: const Text(
                    'Xóa hết',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainer,
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: _addCardManually,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  label: Text(
                    'Thêm thẻ thủ công',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: _showImportModal,
                  icon: const Icon(Icons.cloud_download_rounded, size: 18),
                  label: Text(
                    'Import hàng loạt',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _flashcards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.layers_clear_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có flashcard nào trong bộ thẻ.\nChọn Import hàng loạt hoặc Thêm thẻ thủ công!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _flashcards.length,
                  itemBuilder: (context, index) {
                    final card = _flashcards[index];
                    return EditableCardWidget(
                      key: ValueKey(card.id),
                      index: index + 1,
                      card: card,
                      onDelete: () => _removeCard(index),
                      onChanged: (front, back, imageUrl) {
                        _flashcards[index] = card.copyWith(
                          frontText: front,
                          backText: back,
                          frontImageUrl: imageUrl,
                          updatedAt: DateTime.now(),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
