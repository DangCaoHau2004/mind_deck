import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/resolved_source_deck_model.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/utils/color_utils.dart';

class CustomizeCardsScreen extends StatelessWidget {
  const CustomizeCardsScreen({super.key});

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
        final total = _getTotalCardsCount(configState);
        final isAllSelected = configState.selectedCardIds.length == total;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tuỳ chỉnh thẻ học'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Xong')),
            ],
          ),
          body: Column(
            children: [
              // Select All header
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã chọn: ${configState.selectedCardIds.length} / $total thẻ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<TestSetupBloc>().add(
                            TestSetupAllCardsToggled(!isAllSelected),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAllSelected ? 'Bỏ chọn hết' : 'Chọn tất cả',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isAllSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                          ],
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

  int _getTotalCardsCount(TestSetupConfigState state) {
    int total = 0;
    for (final deck in state.resolvedSourceDecks) {
      total += deck.cards.length;
    }
    return total;
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
                children: folderDecks.map((deck) {
                  return _buildDeckCard(context, state, deck, theme, colorScheme);
                }).toList(),
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

    if (remainingDecks.isNotEmpty) {
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

      for (final deck in remainingDecks) {
        children.add(_buildDeckCard(context, state, deck, theme, colorScheme));
      }
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _buildDeckCard(
    BuildContext context,
    TestSetupConfigState state,
    ResolvedSourceDeck deck,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final String? deckColorHex = state.selectedDecks
        .where((d) => d.id == deck.deckId)
        .map((d) => d.color)
        .firstOrNull;
    final deckColor = ColorUtils.parseHex(deckColorHex ?? '#4A90E2');

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: Text(
                    deck.deckName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: deckColor,
                    ),
                  ),
                ),
                Text(
                  '${deck.cards.length} thẻ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: deckColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Card lists inside this deck
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deck.cards.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.05)),
            itemBuilder: (cardCtx, cardIdx) {
              final card = deck.cards[cardIdx];
              final isChecked = state.selectedCardIds.contains(card.id);

              return CheckboxListTile(
                value: isChecked,
                activeColor: colorScheme.primary,
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) {
                  context.read<TestSetupBloc>().add(TestSetupCardToggled(card.id));
                },
                title: Text(
                  card.frontText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
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
