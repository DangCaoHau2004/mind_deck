import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/data/models/resolved_source_deck_model.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/utils/color_utils.dart';

class CustomizeCardsScreen extends StatefulWidget {
  const CustomizeCardsScreen({super.key});

  @override
  State<CustomizeCardsScreen> createState() => _CustomizeCardsScreenState();
}

class _CustomizeCardsScreenState extends State<CustomizeCardsScreen> {
  String _searchQuery = '';
  String _filterMode = 'all'; // 'all' | 'due' | 'selected'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<TestSetupBloc, TestSetupState>(
      builder: (context, state) {
        if (state is! TestSetupConfigState) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final configState = state;
        final total = configState.totalCards;
        final totalDue = configState.totalDueCards;
        final selectedCount = configState.selectedCardIds.length;
        final isAllSelected = total > 0 && selectedCount == total;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tuỳ chỉnh thẻ học'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                ),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm thẻ...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick filter chips & Actions
                    Row(
                      children: [
                        _buildFilterChip('all', 'Tất cả ($total)', colorScheme.primary),
                        const SizedBox(width: 8),
                        if (totalDue > 0) ...[
                          _buildFilterChip(
                            'due',
                            '⚡ Đến hạn ($totalDue)',
                            Colors.amber.shade800,
                            isAccent: true,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildFilterChip(
                          'selected',
                          'Đã chọn ($selectedCount)',
                          colorScheme.primary,
                        ),
                        const Spacer(),
                        // Quick toggle popup
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz_rounded, color: colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (action) {
                            if (action == 'select_all') {
                              context.read<TestSetupBloc>().add(
                                const TestSetupAllCardsToggled(true),
                              );
                            } else if (action == 'deselect_all') {
                              context.read<TestSetupBloc>().add(
                                const TestSetupAllCardsToggled(false),
                              );
                            } else if (action == 'select_due') {
                              context.read<TestSetupBloc>().add(
                                const TestSetupOnlyDueCardsToggled(true),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'select_all',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Chọn tất cả'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'deselect_all',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.remove_done_rounded,
                                    size: 18,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Bỏ chọn tất cả'),
                                ],
                              ),
                            ),
                            if (totalDue > 0)
                              PopupMenuItem(
                                value: 'select_due',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 18,
                                      color: Colors.amber.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Chỉ chọn thẻ đến hạn'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // ⚡ Only Due Cards Switch Banner
                    if (totalDue > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              (configState.onlyDueCards
                                      ? Colors.amber
                                      : colorScheme.surfaceContainerHighest)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: configState.onlyDueCards
                                ? Colors.amber.shade700.withValues(alpha: 0.35)
                                : colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bolt_rounded,
                                color: Colors.amber.shade800,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚡ Chỉ chọn thẻ tới hạn',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Tự động chọn $totalDue thẻ đã đến lịch ôn tập',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: configState.onlyDueCards,
                              activeThumbColor: Colors.amber.shade700,
                              activeTrackColor: Colors.amber.withValues(alpha: 0.4),
                              onChanged: (val) {
                                context.read<TestSetupBloc>().add(
                                  TestSetupOnlyDueCardsToggled(val),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã chọn: $selectedCount / $total thẻ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.read<TestSetupBloc>().add(TestSetupAllCardsToggled(!isAllSelected));
                      },
                      icon: Icon(
                        isAllSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isAllSelected ? 'Bỏ chọn hết' : 'Chọn tất cả',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(child: _buildCardsChecklist(context, configState, theme, colorScheme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String mode, String label, Color activeColor, {bool isAccent = false}) {
    final isSelected = _filterMode == mode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAccent
                    ? Colors.amber.withValues(alpha: 0.2)
                    : activeColor.withValues(alpha: 0.12))
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isAccent ? Colors.amber.shade700 : activeColor)
                : colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isAccent ? Colors.amber.shade900 : activeColor)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  List<FlashcardModel> _filterCards(List<FlashcardModel> cards, Set<String> selectedCardIds) {
    return cards.where((card) {
      if (_searchQuery.isNotEmpty) {
        final matchesFront = card.frontText.toLowerCase().contains(_searchQuery);
        final matchesBack = card.backText.toLowerCase().contains(_searchQuery);
        if (!matchesFront && !matchesBack) return false;
      }
      if (_filterMode == 'due' && !card.isDueCard) return false;
      if (_filterMode == 'selected' && !selectedCardIds.contains(card.id)) return false;
      return true;
    }).toList();
  }

  Widget _buildCardsChecklist(
    BuildContext context,
    TestSetupConfigState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.resolvedSourceDecks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn nguồn để tải danh sách thẻ.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final List<Widget> children = [];

    // All resolved deck IDs that belong to any folder
    final folderDeckIds = state.selectedFolders
        .expand((f) => f.decks?.map((d) => d.id) ?? <String>[])
        .toSet();

    // 1. Render Folder Groupings
    for (final folder in state.selectedFolders) {
      final folderDecks = state.resolvedSourceDecks.where((rd) {
        return folder.decks?.any((d) => d.id == rd.deckId) ?? false;
      }).toList();

      if (folderDecks.isEmpty) continue;

      final List<Widget> deckWidgets = [];
      for (final deck in folderDecks) {
        final filteredCards = _filterCards(deck.cards, state.selectedCardIds);
        if (filteredCards.isNotEmpty || (_searchQuery.isEmpty && _filterMode == 'all')) {
          deckWidgets.add(_buildDeckCard(context, state, deck, filteredCards, theme, colorScheme));
        }
      }

      if (deckWidgets.isEmpty) continue;

      final folderColor = ColorUtils.parseHex(folder.color);

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: folderColor.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: folderColor.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: Icon(Icons.folder_rounded, color: folderColor, size: 28),
                title: Text(
                  folder.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: folderColor,
                  ),
                ),
                subtitle: Text(
                  'Thư mục • ${folderDecks.length} bộ thẻ',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                children: deckWidgets,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Render remaining decks (not in any selected folder)
    final remainingDecks = state.resolvedSourceDecks.where((rd) {
      return !folderDeckIds.contains(rd.deckId);
    }).toList();

    final List<Widget> remainingDeckWidgets = [];
    for (final deck in remainingDecks) {
      final filteredCards = _filterCards(deck.cards, state.selectedCardIds);
      if (filteredCards.isNotEmpty || (_searchQuery.isEmpty && _filterMode == 'all')) {
        remainingDeckWidgets.add(
          _buildDeckCard(context, state, deck, filteredCards, theme, colorScheme),
        );
      }
    }

    if (remainingDeckWidgets.isNotEmpty) {
      if (state.selectedFolders.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
            child: Row(
              children: [
                Icon(Icons.style_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bộ thẻ đơn lẻ & Nhãn dán',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      children.addAll(remainingDeckWidgets);
    }

    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy thẻ phù hợp bộ lọc.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _buildDeckCard(
    BuildContext context,
    TestSetupConfigState state,
    ResolvedSourceDeck deck,
    List<FlashcardModel> displayCards,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final String? deckColorHex = state.selectedDecks
        .where((d) => d.id == deck.deckId)
        .map((d) => d.color)
        .firstOrNull;
    final deckColor = ColorUtils.parseHex(deckColorHex ?? deck.color ?? '#4A90E2');
    final deckDueCount = deck.cards.where((c) => c.isDueCard).length;

    // Check if all cards in this deck are selected
    final allDeckCardIds = deck.cards.map((c) => c.id).toSet();
    final selectedDeckCardIds = state.selectedCardIds.intersection(allDeckCardIds);
    final isDeckAllSelected =
        allDeckCardIds.isNotEmpty && selectedDeckCardIds.length == allDeckCardIds.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deck Header Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: deckColor.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: deckColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.deckName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: deckColor,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${selectedDeckCardIds.length}/${deck.cards.length} thẻ được chọn',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (deckDueCount > 0) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                            ),
                            Text(
                              '⚡ $deckDueCount đến hạn',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Toggle all in this deck button
                IconButton(
                  tooltip: isDeckAllSelected ? 'Bỏ chọn bộ này' : 'Chọn cả bộ này',
                  onPressed: () {
                    for (final cid in allDeckCardIds) {
                      if (isDeckAllSelected && state.selectedCardIds.contains(cid)) {
                        context.read<TestSetupBloc>().add(TestSetupCardToggled(cid));
                      } else if (!isDeckAllSelected && !state.selectedCardIds.contains(cid)) {
                        context.read<TestSetupBloc>().add(TestSetupCardToggled(cid));
                      }
                    }
                  },
                  icon: Icon(
                    isDeckAllSelected
                        ? Icons.check_box_rounded
                        : (selectedDeckCardIds.isNotEmpty
                              ? Icons.indeterminate_check_box_rounded
                              : Icons.check_box_outline_blank_rounded),
                    color: deckColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Card lists inside this deck
          if (displayCards.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Không có thẻ nào trong bộ này khớp với bộ lọc.',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayCards.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.05)),
              itemBuilder: (cardCtx, cardIdx) {
                final card = displayCards[cardIdx];
                final isChecked = state.selectedCardIds.contains(card.id);
                final isDue = card.isDueCard;

                return CheckboxListTile(
                  value: isChecked,
                  activeColor: colorScheme.primary,
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (_) {
                    context.read<TestSetupBloc>().add(TestSetupCardToggled(card.id));
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.frontText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isDue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 12, color: Colors.amber.shade800),
                              const SizedBox(width: 2),
                              Text(
                                'Đến hạn',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: card.backText.isNotEmpty
                      ? Text(
                          card.backText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                );
              },
            ),
        ],
      ),
    );
  }
}
