import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/ui/commons/widgets/select_decks_tab.dart';

/// Màn chọn nhiều bộ thẻ của người dùng (tải hết các trang). Bấm "Xong" gọi [onDone] với các bộ thẻ
/// đã chọn rồi đóng màn.
class DeckPickerScreen extends StatefulWidget {
  final String title;

  /// Bỏ các bộ thẻ đã nằm trong thư mục này (không cần chọn lại).
  final String? excludeFolderId;
  final List<DeckModel> initialSelected;
  final void Function(List<DeckModel> selected) onDone;

  const DeckPickerScreen({
    super.key,
    required this.title,
    required this.onDone,
    this.excludeFolderId,
    this.initialSelected = const [],
  });

  @override
  State<DeckPickerScreen> createState() => _DeckPickerScreenState();
}

class _DeckPickerScreenState extends State<DeckPickerScreen> {
  bool _isLoading = true;
  String? _error;
  List<DeckModel> _decks = [];
  late final List<DeckModel> _selectedDecks = [...widget.initialSelected];

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  Future<void> _fetchDecks() async {
    try {
      // Lấy hết các trang (mỗi trang tối đa 100 bộ thẻ)
      final repository = DI().sl<DeckRepository>();
      final all = <DeckModel>[];
      for (var page = 1; ; page++) {
        final response = await repository.getDecks(page: page, limit: 100);
        all.addAll(response.data);
        if (response.data.length < 100) break;
      }
      if (!mounted) return;
      setState(() {
        _decks = all.where((d) => !d.folderIds.contains(widget.excludeFolderId)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onDone(_selectedDecks);
              Navigator.pop(context);
            },
            child: Text('common_done'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _decks.isEmpty
          ? Center(child: Text('folder_add_decks_empty'.tr))
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
