import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

class SelectFoldersTab extends StatefulWidget {
  final List<FolderModel> folders;
  final List<FolderModel> selectedFolders;
  final Function(FolderModel) onFolderToggled;

  const SelectFoldersTab({
    super.key,
    required this.folders,
    required this.selectedFolders,
    required this.onFolderToggled,
  });

  @override
  State<SelectFoldersTab> createState() => _SelectFoldersTabState();
}

class _SelectFoldersTabState extends State<SelectFoldersTab> {
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

    final filteredFolders = widget.folders
        .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Search Bar specific to Folders
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Tìm kiếm thư mục...',
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
          child: filteredFolders.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty
                        ? 'Không có thư mục nào'
                        : 'Không tìm thấy thư mục phù hợp',
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
                  itemCount: filteredFolders.length,
                  itemBuilder: (ctx, i) {
                    final folder = filteredFolders[i];
                    final isSelected = widget.selectedFolders.any(
                      (f) => f.id == folder.id,
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
                        onTap: () => widget.onFolderToggled(folder),
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
                              Icons.folder_rounded,
                              color: ColorUtils.parseHex(folder.color),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                folder.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Text('${folder.deckCount ?? 0} học phần'),
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
