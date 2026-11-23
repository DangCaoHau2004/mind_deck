import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/test_source_models.dart';
import 'source_deck_item.dart';
import 'source_folder_tree_item.dart';

class SourceClassTreeItem extends StatelessWidget {
  final SourceClassModel classItem;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final bool isSelected;
  final bool isIndeterminate;
  final VoidCallback onToggleClass;
  final Set<String> expandedFolderIds;
  final Function(String folderId) onToggleFolderExpand;
  final Set<String> selectedFolderIds;
  final Set<String> selectedDeckIds;
  final Function(SourceFolderModel) onToggleFolder;
  final Function(SourceDeckModel) onToggleDeck;

  const SourceClassTreeItem({
    super.key,
    required this.classItem,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.isSelected,
    required this.isIndeterminate,
    required this.onToggleClass,
    required this.expandedFolderIds,
    required this.onToggleFolderExpand,
    required this.selectedFolderIds,
    required this.selectedDeckIds,
    required this.onToggleFolder,
    required this.onToggleDeck,
  });

  bool get _hasContent =>
      classItem.items.isNotEmpty ||
      classItem.folders.isNotEmpty ||
      classItem.standaloneDecks.isNotEmpty;

  int get _folderCount {
    if (classItem.folders.isNotEmpty) return classItem.folders.length;
    return classItem.items.whereType<SourceFolderModel>().length;
  }

  int get _deckCount {
    if (classItem.standaloneDecks.isNotEmpty) return classItem.standaloneDecks.length;
    return classItem.items.whereType<SourceDeckModel>().length;
  }

  String _buildSubtitle() {
    final fCount = _folderCount;
    final dCount = _deckCount;
    final parts = <String>[];
    if (fCount > 0) parts.add('$fCount thư mục');
    if (dCount > 0) parts.add('$dCount bộ thẻ');
    if (parts.isEmpty && classItem.totalCards == 0) {
      return 'Chưa có tài liệu';
    }
    parts.add('${classItem.totalCards} thẻ');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasDue = classItem.dueCount > 0;
    final hasContent = _hasContent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected || isIndeterminate
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected || isIndeterminate ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected || isIndeterminate
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Lớp học (Bấm vào header để SỔ RA / THU VÀO)
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(15),
              bottom: isExpanded ? Radius.zero : const Radius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.07)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  // Checkbox chọn nhanh toàn bộ Lớp học
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggleClass,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: isSelected ? true : (isIndeterminate ? null : false),
                          tristate: true,
                          onChanged: (_) => onToggleClass(),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          activeColor: colorScheme.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Avatar / Icon Lớp học
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),

                  // Tên Lớp học & Thông tin số lượng
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                classItem.className,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (classItem.role != null && classItem.role!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  classItem.role!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _buildSubtitle(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Due Badge
                  if (hasDue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${classItem.dueCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Nút mũi tên mở rộng / thu gọn
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: isExpanded ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nội dung Lớp học khi mở rộng (Sổ danh sách Thư mục & Bộ thẻ)
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: hasContent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildClassContent(),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Lớp học này chưa có tài liệu nào',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildClassContent() {
    final List<Widget> widgets = [];
    final itemsToRender = classItem.items.isNotEmpty
        ? classItem.items
        : [...classItem.folders, ...classItem.standaloneDecks];

    for (final item in itemsToRender) {
      if (item is SourceFolderModel) {
        final isFolderExp = expandedFolderIds.contains(item.id);
        final allDecksSelected =
            item.decks.isNotEmpty && item.decks.every((d) => selectedDeckIds.contains(d.id));
        final someDecksSelected = item.decks.any((d) => selectedDeckIds.contains(d.id));
        final isFolderSel = selectedFolderIds.contains(item.id) || allDecksSelected;
        final isFolderIndet = !allDecksSelected && someDecksSelected;

        widgets.add(
          SourceFolderTreeItem(
            folder: item,
            isExpanded: isFolderExp,
            onToggleExpand: () => onToggleFolderExpand(item.id),
            isSelected: isFolderSel,
            isIndeterminate: isFolderIndet,
            onToggleFolder: () => onToggleFolder(item),
            selectedDeckIds: selectedDeckIds,
            onDeckToggled: onToggleDeck,
          ),
        );
      } else if (item is SourceDeckModel) {
        final isDeckSel = selectedDeckIds.contains(item.id);
        widgets.add(
          SourceDeckItem(deck: item, isSelected: isDeckSel, onToggle: () => onToggleDeck(item)),
        );
      }
    }
    return widgets;
  }
}
