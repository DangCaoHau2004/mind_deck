import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

/// Kết quả hộp "Tag mới": dùng luôn tag đã có ([existing]) hoặc tạo tag mới ([name], [color]).
class AddTagResult {
  final TagModel? existing;

  /// Tên đã chuẩn hóa (vd `tieng-anh-giao-tiep`), chỉ có khi tạo mới.
  final String name;

  /// Mã màu `#RRGGBB`, chỉ có khi tạo mới.
  final String color;

  const AddTagResult.existing(TagModel tag) : existing = tag, name = '', color = '';
  const AddTagResult.create({required this.name, required this.color}) : existing = null;
}

/// Hộp "Tag mới" dùng chung cho form bộ thẻ và form thư mục: nhập tên (tự chuẩn hóa), chọn màu,
/// gợi ý tag đã có hoặc na ná để dùng luôn.
class AddTagSheet extends StatefulWidget {
  final List<TagModel> availableTags;

  /// Tối đa ký tự người dùng gõ (chuỗi lưu không bao giờ dài hơn).
  static const int maxLength = 30;

  static const List<Color> presetColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF00695C),
    Color(0xFFC2185B),
    Color(0xFFEF6C00),
    Color(0xFF7B1FA2),
    Color(0xFFD84315),
  ];

  const AddTagSheet({super.key, required this.availableTags});

  static Future<AddTagResult?> show(BuildContext context, {required List<TagModel> availableTags}) {
    return showModalBottomSheet<AddTagResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTagSheet(availableTags: availableTags),
    );
  }

  @override
  State<AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<AddTagSheet> {
  final TextEditingController _controller = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final FocusNode _nameFocus = FocusNode();
  Color _color = AddTagSheet.presetColors.first;

  /// Độ cao (tỉ lệ màn hình) lúc mở, và tối đa khi kéo lên / khi bàn phím mở. Do thiết kế chọn, chưa đo.
  static const double _initialSize = 0.6;
  static const double _maxSize = 0.92;

  @override
  void initState() {
    super.initState();
    // Gõ tên (bàn phím mở) thì mở rộng tối đa để nút "Tạo và chọn" không bị bàn phím che
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetController.isAttached) {
          _sheetController.animateTo(
            _maxSize,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameFocus.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomColor() async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _CustomColorSheet(initial: _color),
    );
    if (picked != null) setState(() => _color = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final slug = _controller.text.asTagName;

    TagModel? exact;
    final similar = <TagModel>[];
    if (slug.isNotEmpty) {
      for (final tag in widget.availableTags) {
        final tagSlug = tag.name.asTagName;
        if (tagSlug.isEmpty) continue;
        if (tagSlug == slug) {
          exact = tag;
        } else if (tagSlug.contains(slug) || slug.contains(tagSlug)) {
          similar.add(tag);
        }
      }
    }
    final suggestions = [?exact, ...similar.take(4)];
    final isCustom = !AddTagSheet.presetColors.contains(_color);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _initialSize,
      minChildSize: 0.35,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_initialSize],
      expand: false,
      builder: (context, scrollController) => Material(
        color: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo (nằm trong vùng cuộn để kéo được cả sheet)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'tag_new_title'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'tag_name_label'.tr,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                focusNode: _nameFocus,
                autofocus: true,
                inputFormatters: [LengthLimitingTextInputFormatter(AddTagSheet.maxLength)],
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'tag_name_hint'.tr,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      '#',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_controller.text.length}/${AddTagSheet.maxLength}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                      ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(_controller.clear),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                        )
                      else
                        const SizedBox(width: 12),
                    ],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
              if (slug.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${'tag_will_save_as'.tr} '),
                            TextSpan(
                              text: '#$slug',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'tag_color_label'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _TagPill(text: '#${slug.isEmpty ? 'tag' : slug}', color: _color),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final color in AddTagSheet.presetColors)
                    Expanded(
                      child: _Swatch(
                        color: color,
                        selected: _color == color,
                        onTap: () => setState(() => _color = color),
                      ),
                    ),
                  Expanded(
                    child: _Swatch(
                      color: _color,
                      selected: isCustom,
                      rainbow: !isCustom,
                      onTap: _pickCustomColor,
                    ),
                  ),
                ],
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  exact != null ? 'tag_existing_exact'.tr : 'tag_existing_similar'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in suggestions)
                      GestureDetector(
                        onTap: () => Navigator.pop(context, AddTagResult.existing(tag)),
                        child: _TagPill(
                          text: '#${tag.name}',
                          color: ColorUtils.parseHex(tag.color ?? '#8B5CF6'),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: slug.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          exact != null
                              ? AddTagResult.existing(exact)
                              : AddTagResult.create(name: slug, color: ColorUtils.toHex(_color)),
                        ),
                  child: Text(
                    exact != null ? 'tag_select_existing'.tr : 'tag_create_and_select'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Viên tên tag theo màu (nền nhạt, chữ màu đậm).
class _TagPill extends StatelessWidget {
  final String text;
  final Color color;

  const _TagPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Ô chọn màu tròn; [rainbow] là ô "màu tự chọn" (cầu vồng, dấu +).
class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final bool rainbow;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.rainbow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: onTap,
          child: rainbow
              ? Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Color(0xFFFF5252),
                        Color(0xFFFFEB3B),
                        Color(0xFF69F0AE),
                        Color(0xFF40C4FF),
                        Color(0xFF7C4DFF),
                        Color(0xFFFF4081),
                        Color(0xFFFF5252),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, size: 16, color: Colors.black87),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: selected ? color : color.withValues(alpha: 0.35),
                      width: selected ? 3 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: selected
                        ? Icon(Icons.check_rounded, size: 18, color: color)
                        : Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Bảng chọn màu tự viết: sắc độ, độ đậm, độ sáng.
class _CustomColorSheet extends StatefulWidget {
  final Color initial;

  const _CustomColorSheet({required this.initial});

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _hsv.toColor();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'tag_custom_color_title'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                ColorUtils.toHex(color),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GradientSlider(
            value: _hsv.hue,
            max: 360,
            colors: [
              for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
            ],
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          const SizedBox(height: 12),
          _GradientSlider(
            value: _hsv.saturation,
            max: 1,
            colors: [_hsv.withSaturation(0).toColor(), _hsv.withSaturation(1).toColor()],
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          const SizedBox(height: 12),
          _GradientSlider(
            value: _hsv.value,
            max: 1,
            colors: [Colors.black, _hsv.withValue(1).toColor()],
            onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context, color),
              child: Text('tag_custom_color_apply'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh trượt có nền chuyển màu.
class _GradientSlider extends StatelessWidget {
  final double value;
  final double max;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  const _GradientSlider({
    required this.value,
    required this.max,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: LinearGradient(colors: colors),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 14,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: Colors.black12,
            ),
            child: Slider(value: value.clamp(0, max), max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
