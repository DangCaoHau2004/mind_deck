import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

class DeckDetailExpandableTags extends StatefulWidget {
  final List<TagModel> tags;
  final int maxVisible;

  const DeckDetailExpandableTags({super.key, required this.tags, this.maxVisible = 3});

  @override
  State<DeckDetailExpandableTags> createState() => _DeckDetailExpandableTagsState();
}

class _DeckDetailExpandableTagsState extends State<DeckDetailExpandableTags> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tags.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final totalTags = widget.tags.length;
    final hasHiddenTags = totalTags > widget.maxVisible;

    final displayedTags = _isExpanded || !hasHiddenTags
        ? widget.tags
        : widget.tags.sublist(0, widget.maxVisible);

    final hiddenCount = totalTags - widget.maxVisible;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...displayedTags.map((tag) {
          final tagColor = ColorUtils.parseHex(tag.color ?? '#1565C0');
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tagColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              '#${tag.name}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tagColor,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          );
        }),
        if (!_isExpanded && hasHiddenTags)
          _buildActionButton(
            text: '+$hiddenCount',
            theme: theme,
            onTap: () => setState(() => _isExpanded = true),
          ),
        if (_isExpanded && hasHiddenTags)
          _buildActionButton(
            icon: Icons.expand_less_rounded,
            theme: theme,
            onTap: () => setState(() => _isExpanded = false),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    String? text,
    IconData? icon,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16, color: theme.colorScheme.primary),
            if (text != null)
              Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
