import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/ui/commons/widgets/deck_picker_screen.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';

/// Chọn các bộ thẻ của bạn để thêm vào thư mục (bộ thẻ đã nằm trong thư mục này thì không hiện).
class AddDecksToFolderScreen extends StatelessWidget {
  final String folderId;

  const AddDecksToFolderScreen({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return DeckPickerScreen(
      title: 'folder_add_decks_title'.tr,
      excludeFolderId: folderId,
      onDone: (decks) {
        if (decks.isEmpty) return;
        context.read<FolderDetailBloc>().add(
          FolderAddDecks(folderId: folderId, deckIds: decks.map((d) => d.id).toList()),
        );
      },
    );
  }
}
