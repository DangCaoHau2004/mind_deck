import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'widgets/select_folders_tab.dart';
import 'widgets/select_tags_tab.dart';
import 'widgets/select_decks_tab.dart';

class AddSourceScreen extends StatefulWidget {
  final List<DeckModel> initialSelectedDecks;
  final List<FolderModel> initialSelectedFolders;
  final List<TagModel> initialSelectedTags;

  const AddSourceScreen({
    super.key,
    required this.initialSelectedDecks,
    required this.initialSelectedFolders,
    required this.initialSelectedTags,
  });

  @override
  State<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends State<AddSourceScreen> {
  bool _isLoading = true;
  String? _error;

  List<DeckModel> _decks = [];
  List<FolderModel> _folders = [];
  List<TagModel> _tags = [];

  late List<DeckModel> _selectedDecks;
  late List<FolderModel> _selectedFolders;
  late List<TagModel> _selectedTags;

  String _activeTab = 'folders'; // 'folders', 'tags', 'decks'

  @override
  void initState() {
    super.initState();
    _selectedDecks = List.from(widget.initialSelectedDecks);
    _selectedFolders = List.from(widget.initialSelectedFolders);
    _selectedTags = List.from(widget.initialSelectedTags);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        DI().sl<DeckRepository>().getDecks(limit: 100),
        DI().sl<FolderRepository>().getFolders(limit: 100),
      ]);
      final decksResp = results[0] as ApiListResponse<DeckModel>;
      final foldersResp = results[1] as ApiListResponse<FolderModel>;

      final Map<String, TagModel> uniqueTags = {};
      for (final deck in decksResp.data) {
        if (deck.tags != null) {
          for (final tag in deck.tags!) {
            if (tag.id.isNotEmpty) {
              uniqueTags[tag.id] = tag;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _decks = decksResp.data;
          _folders = foldersResp.data;
          _tags = uniqueTags.values.toList();
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
    Navigator.of(context).pop({
      'decks': _selectedDecks,
      'folders': _selectedFolders,
      'tags': _selectedTags,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm nguồn học'),
        actions: [TextButton(onPressed: _onDone, child: const Text('Xong'))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildTabBtn('folders', 'Thư mục', colorScheme),
                      _buildTabBtn('tags', 'Nhãn dán', colorScheme),
                      _buildTabBtn('decks', 'Bộ thẻ', colorScheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildTabContent(),
    );
  }

  Widget _buildTabBtn(String id, String label, ColorScheme colorScheme) {
    final isActive = id == _activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_activeTab == 'folders') {
      return SelectFoldersTab(
        folders: _folders,
        selectedFolders: _selectedFolders,
        onFolderToggled: (folder) {
          setState(() {
            if (_selectedFolders.any((f) => f.id == folder.id)) {
              _selectedFolders.removeWhere((f) => f.id == folder.id);
            } else {
              _selectedFolders.add(folder);
            }
          });
        },
      );
    } else if (_activeTab == 'tags') {
      return SelectTagsTab(
        tags: _tags,
        selectedTags: _selectedTags,
        onTagToggled: (tag) {
          setState(() {
            if (_selectedTags.any((t) => t.id == tag.id)) {
              _selectedTags.removeWhere((t) => t.id == tag.id);
            } else {
              _selectedTags.add(tag);
            }
          });
        },
      );
    } else {
      return SelectDecksTab(
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
      );
    }
  }
}
