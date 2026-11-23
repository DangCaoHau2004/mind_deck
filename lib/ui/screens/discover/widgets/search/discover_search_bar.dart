import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/ui/commons/tag_search_controller.dart';
import 'package:mind_deck/ui/screens/discover/widgets/search/discover_tag_pill.dart';

/// Thanh tìm kiếm của trang Khám phá.
/// - Chưa submit: chỉ có nút "Hủy" bên phải.
/// - Đã submit ([isResultMode]): nút back hiện bên trái (thanh co lại), "Hủy" đổi mượt thành icon Lọc.
/// Pill #tag nằm bên trái hộp, ô nhập chiếm phần còn lại (căn trái).
class DiscoverSearchBar extends StatelessWidget {
  final TagSearchController controller;
  final FocusNode focusNode;
  final bool isResultMode;
  final bool hasActiveSort;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onFilter;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const DiscoverSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isResultMode,
    required this.hasActiveSort,
    required this.onBack,
    required this.onCancel,
    required this.onFilter,
    required this.onSubmit,
    required this.onClear,
  });

  static const _animation = Duration(milliseconds: 220);

  /// Gán vào `focusNode.onKeyEvent`: Backspace khi ô trống sẽ trả pill cuối về dạng chữ.
  /// (Phải gán trực tiếp lên FocusNode vì Shortcuts của TextField xử lý Backspace trước Focus cha.)
  static KeyEventResult handleBackspace(TagSearchController controller, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        controller.popLastTagToText()) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        AnimatedSize(
          duration: _animation,
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: isResultMode
              ? IconButton(
                  icon: const BackButtonIcon(),
                  color: colorScheme.onSurface,
                  onPressed: onBack,
                )
              : const SizedBox(width: 16),
        ),
        Expanded(child: _buildBox(context)),
        AnimatedSize(
          duration: _animation,
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerRight,
          child: AnimatedSwitcher(
            duration: _animation,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: isResultMode
                ? Padding(
                    key: const ValueKey('filter'),
                    padding: const EdgeInsets.only(left: 8, right: 12),
                    child: _FilterButton(active: hasActiveSort, onPressed: onFilter),
                  )
                : Padding(
                    key: const ValueKey('cancel'),
                    padding: const EdgeInsets.only(left: 4, right: 8),
                    child: TextButton(
                      onPressed: onCancel,
                      child: Text(
                        'common_cancel'.tr,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBox(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final tags = controller.tags;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: focusNode.requestFocus,
          child: Container(
            height: 48,
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focusNode.hasFocus
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: focusNode.hasFocus ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                if (tags.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, _) {
                      final maxWidth = MediaQuery.sizeOf(context).width * 0.45;
                      return ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final tag in tags)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: DiscoverTagPill(
                                    name: tag.name,
                                    color: controller.colorOf(tag.name),
                                    onRemove: () => controller.removeTag(tag.name),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: TextField(
                    controller: controller.text,
                    focusNode: focusNode,
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.start,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSubmit(),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: tags.isEmpty
                          ? 'discover_search_hint'.tr
                          : 'discover_search_hint_more'.tr,
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                if (!controller.isEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    onPressed: onClear,
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const _FilterButton({required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.tune_rounded, color: colorScheme.onPrimary),
            ),
          ),
        ),
        if (active)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
