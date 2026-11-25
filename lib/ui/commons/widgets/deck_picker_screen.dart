import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/widgets/select_decks_tab.dart';

/// Màn chọn nhiều bộ thẻ của người dùng: tải từng trang khi cuộn, tìm bằng API. Bấm "Xong" gọi [onDone] với
/// các bộ thẻ đã chọn rồi đóng màn.
class DeckPickerScreen extends StatefulWidget {
  final String title;

  /// Bộ thẻ đã nằm trong thư mục này vẫn hiện nhưng mờ, đã đánh dấu và không chọn lại được.
  final String? existingInFolderId;
  final List<DeckModel> initialSelected;
  final void Function(List<DeckModel> selected) onDone;

  const DeckPickerScreen({
    super.key,
    required this.title,
    required this.onDone,
    this.existingInFolderId,
    this.initialSelected = const [],
  });

  @override
  State<DeckPickerScreen> createState() => _DeckPickerScreenState();
}

class _DeckPickerScreenState extends State<DeckPickerScreen> {
  static const int _pageSize = 20;
  // Chờ người dùng ngừng gõ rồi mới gọi API, con số do thiết kế chọn, chưa đo.
  static const Duration _debounce = Duration(milliseconds: 400);

  final DeckRepository _repository = DI().sl<DeckRepository>();
  late final List<DeckModel> _selectedDecks = [...widget.initialSelected];

  List<DeckModel> _decks = [];
  String _query = '';
  int _page = 1;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  Timer? _timer;

  // Tăng mỗi lần đổi từ khóa để bỏ kết quả của lượt gọi cũ về muộn.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
    });
    try {
      final response = await _repository.getDecks(limit: _pageSize, search: _query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _decks = response.data;
        _page = 1;
        _hasMore = response.data.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e is Failure ? e.displayMessage : e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final generation = _generation;
    setState(() => _isLoadingMore = true);
    try {
      final response = await _repository.getDecks(
        page: _page + 1,
        limit: _pageSize,
        search: _query,
      );
      if (!mounted || generation != _generation) return;
      final known = _decks.map((d) => d.id).toSet();
      setState(() {
        _decks = [..._decks, ...response.data.where((d) => !known.contains(d.id))];
        _page++;
        _hasMore = response.data.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _isLoadingMore = false);
      CustomToast.show(
        context,
        CustomToast.danger(message: e is Failure ? e.displayMessage : e.toString()),
      );
    }
  }

  void _onSearchChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      final query = value.trim();
      if (!mounted || query == _query) return;
      _query = query;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final folderId = widget.existingInFolderId;
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
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: Text('common_retry'.tr)),
                  ],
                ),
              ),
            )
          : SelectDecksTab(
              decks: _decks,
              selectedDecks: _selectedDecks,
              existingIds: {
                if (folderId != null)
                  for (final d in _decks)
                    if (d.folderIds.contains(folderId)) d.id,
              },
              existingLabel: 'folder_picker_in_folder'.tr,
              lockExisting: true,
              isLoading: _isLoading,
              onSearchChanged: _onSearchChanged,
              onLoadMore: _loadMore,
              isLoadingMore: _isLoadingMore,
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
