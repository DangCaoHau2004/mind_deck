import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';

import 'folder_dialog_helper.dart';

class FolderDetailSelectionBar extends StatelessWidget {
  final String folderId;
  final List<String> selectedDeckIds;

  const FolderDetailSelectionBar({
    super.key,
    required this.folderId,
    required this.selectedDeckIds,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                context.read<FolderDetailBloc>().add(
                  const FolderDetailSelectionCleared(),
                );
              },
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Đã chọn ${selectedDeckIds.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                if (selectedDeckIds.isEmpty) return;
                final confirmed = await FolderDialogHelper.showRemoveMultipleDecksFromFolder(
                  context,
                  count: selectedDeckIds.length,
                );
                if (confirmed == true && context.mounted) {
                  context.read<FolderDetailBloc>().add(
                    FolderRemoveDecks(
                      folderId: folderId,
                      deckIds: selectedDeckIds,
                    ),
                  );
                  context.read<FolderDetailBloc>().add(
                    const FolderDetailSelectionCleared(),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
