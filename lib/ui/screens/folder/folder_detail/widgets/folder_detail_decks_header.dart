import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'add_decks_to_folder_screen.dart';

class FolderDetailDecksHeader extends StatelessWidget {
  final String title;
  final String folderId;
  final bool isFolderOwner;

  const FolderDetailDecksHeader({
    super.key,
    required this.title,
    required this.folderId,
    required this.isFolderOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isFolderOwner)
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (sheetContext) => BlocProvider.value(
                      value: context.read<FolderDetailBloc>(),
                      child: FractionallySizedBox(
                        heightFactor: 0.9,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: AddDecksToFolderScreen(folderId: folderId),
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87),
              ),
          ],
        ),
      ),
    );
  }
}
