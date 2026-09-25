import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/add_source/widgets/select_decks_tab.dart';

class AddDecksToFolderScreen extends StatefulWidget {
  final String folderId;

  const AddDecksToFolderScreen({super.key, required this.folderId});

  @override
  State<AddDecksToFolderScreen> createState() => _AddDecksToFolderScreenState();
}

class _AddDecksToFolderScreenState extends State<AddDecksToFolderScreen> {
  bool _isLoading = true;
  String? _error;

  List<DeckModel> _decks = [];
  final List<DeckModel> _selectedDecks = [];

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  Future<void> _fetchDecks() async {
    try {
      final response = await DI().sl<DeckRepository>().getDecks(limit: 100);

      // Lọc bỏ những bộ thẻ đã nằm trong folder hiện tại
      // Hoặc để user chọn lại cũng được, API sẽ tự handle.
      // Ở đây ta cứ hiển thị tất cả bộ thẻ user có.
      if (mounted) {
        setState(() {
          _decks = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onDone() {
    if (_selectedDecks.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Gửi event để Bloc gọi api thêm deck
    context.read<FolderDetailBloc>().add(
      FolderAddDecks(folderId: widget.folderId, deckIds: _selectedDecks.map((d) => d.id).toList()),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm bộ thẻ vào thư mục',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _onDone,
            child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _decks.isEmpty
          ? const Center(child: Text('Bạn chưa có bộ thẻ nào.'))
          : SelectDecksTab(
              decks: _decks,
              selectedDecks: _selectedDecks,
              onDeckToggled: (deck) {
                setState(() {
                  if (_selectedDecks.any((d) => d.id == deck.id)) {
                    _selectedDecks.removeWhere((d) => d.id == deck.id);
                  } else {
                    _selectedDecks.add(deck);
                  }
                });
              },
            ),
    );
  }
}
