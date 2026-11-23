import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/utils/color_utils.dart';

class SelectDecksTab extends StatefulWidget {
  final List<DeckModel> decks;
  final List<DeckModel> selectedDecks;
  final Function(DeckModel) onDeckToggled;

  /// Id bộ thẻ đã có trong đích (vd lớp học) -> hiện nhãn "Đã có trong lớp".
  final Set<String> existingIds;

  const SelectDecksTab({
    super.key,
    required this.decks,
    required this.selectedDecks,
    required this.onDeckToggled,
    this.existingIds = const {},
  });

  @override
  State<SelectDecksTab> createState() => _SelectDecksTabState();
}

class _SelectDecksTabState extends State<SelectDecksTab> {
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

    final filteredDecks = widget.decks
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Search Bar specific to Decks
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Tìm kiếm bộ thẻ...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
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
          child: filteredDecks.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? 'Không có bộ thẻ nào' : 'Không tìm thấy bộ thẻ phù hợp',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredDecks.length,
                  itemBuilder: (ctx, i) {
                    final deck = filteredDecks[i];
                    final isSelected = widget.selectedDecks.any((d) => d.id == deck.id);

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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () => widget.onDeckToggled(deck),
                        leading: Icon(
                          isSelected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        title: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: ColorUtils.parseHex(deck.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                deck.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(left: 24.0),
                          child: Text(
                            '${deck.cardCount ?? 0} thẻ'
                            '${widget.existingIds.contains(deck.id) ? ' · Đã có trong lớp' : ''}',
                            style: widget.existingIds.contains(deck.id)
                                ? TextStyle(color: Colors.orange.shade800)
                                : null,
                          ),
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
