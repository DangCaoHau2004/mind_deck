import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/tag_model.dart';

class SelectTagsTab extends StatefulWidget {
  final List<TagModel> tags;
  final List<TagModel> selectedTags;
  final Function(TagModel) onTagToggled;

  const SelectTagsTab({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onTagToggled,
  });

  @override
  State<SelectTagsTab> createState() => _SelectTagsTabState();
}

class _SelectTagsTabState extends State<SelectTagsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredTags = widget.tags
        .where((t) => t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Search Bar specific to Tags
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Tìm kiếm nhãn dán...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: filteredTags.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty
                        ? 'Không có nhãn dán nào'
                        : 'Không tìm thấy nhãn dán phù hợp',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredTags.length,
                  itemBuilder: (ctx, i) {
                    final tag = filteredTags[i];
                    final isSelected = widget.selectedTags.any(
                      (t) => t.id == tag.id,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.05)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onTap: () => widget.onTagToggled(tag),
                        leading: Icon(
                          isSelected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.tag_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tag.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
