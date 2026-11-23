import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/add_source/add_source_screen.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/widgets/customize_cards_screen.dart';import 'package:mind_deck/utils/color_utils.dart';

class SetupSourceSelector extends StatelessWidget {
  final TestSetupConfigState state;

  const SetupSourceSelector({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> sources = [
      ...state.selectedFolders.map(
        (f) => {'type': TestSourceType.folder, 'id': f.id, 'name': f.name, 'color': f.color},
      ),
      ...state.selectedTags.map(
        (t) => {'type': TestSourceType.tag, 'id': t.id, 'name': t.name, 'color': null},
      ),
      ...state.selectedDecks.map(
        (d) => {'type': TestSourceType.deck, 'id': d.id, 'name': d.name, 'color': d.color},
      ),
    ];

    final hasSources = sources.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.layers_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Nguồn tài liệu (${sources.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<Map<String, dynamic>>(
                  MaterialPageRoute(
                    builder: (_) => AddSourceScreen(
                      initialSelectedDecks: state.selectedDecks,
                      initialSelectedFolders: state.selectedFolders,
                      initialSelectedTags: state.selectedTags,
                    ),
                  ),
                );

                if (result != null && context.mounted) {
                  context.read<TestSetupBloc>().add(
                    TestSetupSourcesChanged(
                      decks: result['decks'] as List<DeckModel>,
                      folders: result['folders'] as List<FolderModel>,
                      tags: result['tags'] as List<TagModel>,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm Nguồn'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sources Container
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasSources)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Chưa có nguồn nào được chọn.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: sources.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      final TestSourceType type = source['type'] as TestSourceType;
                      final String id = source['id'] as String;
                      final String name = source['name'] as String;
                      final String? colorHex = source['color'] as String?;

                      Widget leadingIcon;
                      switch (type) {
                        case TestSourceType.folder:
                          leadingIcon = Icon(
                            Icons.folder_rounded,
                            color: colorHex != null
                                ? ColorUtils.parseHex(colorHex)
                                : colorScheme.primary,
                            size: 20,
                          );
                          break;
                        case TestSourceType.tag:
                          leadingIcon = Icon(
                            Icons.tag_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          );
                          break;
                        case TestSourceType.deck:
                          leadingIcon = Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorHex != null
                                  ? ColorUtils.parseHex(colorHex)
                                  : colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          );
                          break;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            leadingIcon,
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                context.read<TestSetupBloc>().add(
                                  TestSetupSourceRemoved(type: type, id: id),
                                );
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: colorScheme.error,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              if (hasSources)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(
                      top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã chọn: ${state.selectedCardIds.length} / ${state.totalCards} thẻ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (state.totalDueCards > 0) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.bolt_rounded, size: 14, color: Colors.amber.shade800),
                                  const SizedBox(width: 2),
                                  Text(
                                    state.onlyDueCards
                                        ? 'Đang chỉ ôn ${state.selectedDueCardsCount} thẻ tới hạn'
                                        : '${state.selectedDueCardsCount}/${state.totalDueCards} thẻ tới hạn được chọn',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<TestSetupBloc>(),
                                child: const CustomizeCardsScreen(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Tùy chỉnh thẻ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.surface,
                          foregroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
