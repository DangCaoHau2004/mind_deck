import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/deck_suggestion_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/data/models/test_source_models.dart';
import 'package:mind_deck/data/repositories/test_repository.dart';
import 'package:mind_deck/ui/screens/folder/widgets/tag_highlight_editing_controller.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'services/test_source_search_history_service.dart';
import 'widgets/source_bottom_bar.dart';
import 'widgets/source_class_tree_item.dart';
import 'widgets/source_deck_item.dart';
import 'widgets/source_filter_bar.dart';
import 'widgets/source_folder_tree_item.dart';
import 'widgets/source_search_suggestions_panel.dart';

class AddSourceScreen extends StatefulWidget {
  final List<DeckModel> initialSelectedDecks;
  final List<FolderModel> initialSelectedFolders;
  final List<TagModel> initialSelectedTags;

  const AddSourceScreen({
    super.key,
    this.initialSelectedDecks = const [],
    this.initialSelectedFolders = const [],
    this.initialSelectedTags = const [],
  });

  @override
  State<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends State<AddSourceScreen> {
  // Tab: 0 = Kho cá nhân (Personal), 1 = Lớp học (Classes)
  int _activeTab = 0;

  // Search & Filter state
  final TagHighlightEditingController _searchController = TagHighlightEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TestSourceSearchHistoryService _historyService = TestSourceSearchHistoryService();

  Timer? _debounceTimer;
  List<TestSourceSearchHistoryItem> _recentSearches = [];
  List<TagModel> _selectedSearchTags = [];
  final Map<String, String> _tagColorMemory = {};
  bool _isSearchFocused = false;
  String _lastSearchText = '';

  String get _fullSearchQuery {
    final tagPart = _selectedSearchTags.map((t) => '#${t.name}').join(' ');
    final textPart = _searchController.text.trim();
    if (tagPart.isEmpty) return textPart;
    if (textPart.isEmpty) return tagPart;
    return '$tagPart $textPart';
  }

  String _selectedFilterType = 'all'; // 'all', 'folder', 'deck'
  bool _onlyDue = false;
  bool _onlyNew = false;
  bool _isStarred = false;
  String _sort = 'recent';
  String _order = 'desc';

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // UI State: Loading & Error
  bool _isLoading = true;
  String? _error;

  // Data
  PersonalSourcesData? _personalData;
  ClassSourcesData? _classData;

  // Expand / Collapse State
  final Set<String> _expandedFolderIds = {};
  final Set<String> _expandedClassIds = {};

  // Selection state
  final Set<String> _selectedFolderIds = {};
  final Set<String> _selectedDeckIds = {};
  final Map<String, SourceFolderModel> _folderModelsMap = {};
  final Map<String, SourceDeckModel> _deckModelsMap = {};
  final Map<String, SourceClassModel> _classModelsMap = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onFocusChanged);
    _searchFocusNode.onKeyEvent = _handleKeyEvent;
    _loadRecentSearches();

    // Hydrate initial selection
    for (final folder in widget.initialSelectedFolders) {
      _selectedFolderIds.add(folder.id);
      _folderModelsMap[folder.id] = SourceFolderModel(
        id: folder.id,
        name: folder.name,
        icon: folder.icon,
        color: folder.color,
        isStarred: folder.isStarred,
        deckCount: folder.deckCount ?? folder.decks?.length ?? 0,
        decks:
            folder.decks
                ?.map(
                  (d) => SourceDeckModel(
                    id: d.id,
                    name: d.name,
                    icon: d.icon,
                    color: d.color,
                    isStarred: d.isStarred,
                    folderId: folder.id,
                    cardCount: d.cardCount ?? 0,
                    dueCount: d.dueCount ?? 0,
                  ),
                )
                .toList() ??
            [],
      );
    }

    for (final deck in widget.initialSelectedDecks) {
      _selectedDeckIds.add(deck.id);
      _deckModelsMap[deck.id] = SourceDeckModel(
        id: deck.id,
        name: deck.name,
        icon: deck.icon,
        color: deck.color,
        isStarred: deck.isStarred,
        folderId: deck.folderId,
        cardCount: deck.cardCount ?? 0,
        dueCount: deck.dueCount ?? 0,
        tags: deck.tags ?? [],
      );
    }

    _fetchCurrentTabData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _searchController.text.isEmpty &&
        _selectedSearchTags.isNotEmpty) {
      setState(() {
        final lastTag = _selectedSearchTags.removeLast();
        final tagText = '#${lastTag.name}';
        _searchController.text = tagText;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: tagText.length),
        );
        _lastSearchText = tagText;
      });
      _executeSearch(_fullSearchQuery);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _loadRecentSearches() async {
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _recentSearches = history;
      });
      for (final item in history) {
        for (final entry in item.tagColors.entries) {
          _tagColorMemory[entry.key] = entry.value;
        }
      }
      _syncColorMemoryToController();
    }
  }

  void _rememberTagColors() {
    if (_personalData != null) {
      for (final tag in _personalData!.activeTags) {
        if (tag.color != null && tag.color!.isNotEmpty) {
          _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
        }
      }
      for (final tag in _personalData!.suggestions?.tags ?? <TagModel>[]) {
        if (tag.color != null && tag.color!.isNotEmpty) {
          _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
        }
      }
      for (final kw in _personalData!.suggestions?.keywords ?? <DeckKeywordSuggestionModel>[]) {
        for (final tag in kw.tags) {
          if (tag.color != null && tag.color!.isNotEmpty) {
            _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
          }
        }
      }
      for (final folder in _personalData!.folders) {
        for (final tag in folder.tags) {
          if (tag.color != null && tag.color!.isNotEmpty) {
            _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
          }
        }
        for (final deck in folder.decks) {
          for (final tag in deck.tags) {
            if (tag.color != null && tag.color!.isNotEmpty) {
              _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
            }
          }
        }
      }
      for (final deck in _personalData!.standaloneDecks) {
        for (final tag in deck.tags) {
          if (tag.color != null && tag.color!.isNotEmpty) {
            _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
          }
        }
      }
    }
    if (_classData != null) {
      for (final tag in _classData!.activeTags) {
        if (tag.color != null && tag.color!.isNotEmpty) {
          _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
        }
      }
      for (final tag in _classData!.suggestions?.tags ?? <TagModel>[]) {
        if (tag.color != null && tag.color!.isNotEmpty) {
          _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
        }
      }
      for (final kw in _classData!.suggestions?.keywords ?? <DeckKeywordSuggestionModel>[]) {
        for (final tag in kw.tags) {
          if (tag.color != null && tag.color!.isNotEmpty) {
            _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
          }
        }
      }
    }
    for (final tag in _selectedSearchTags) {
      if (tag.color != null && tag.color!.isNotEmpty) {
        _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
      }
    }
  }

  void _syncColorMemoryToController() {
    final Map<String, Color> colorMap = {};
    for (final entry in _tagColorMemory.entries) {
      try {
        colorMap[entry.key] = ColorUtils.parseHex(entry.value);
      } catch (_) {}
    }
    _searchController.addTagColors(colorMap);
  }

  void _onFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore || !_hasMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      _loadMoreData();
    }
  }

  Future<void> _fetchCurrentTabData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });

    final effectiveSearch = _fullSearchQuery;

    try {
      final repo = DI().sl<TestRepository>();

      if (_activeTab == 0) {
        // Fetch Personal Sources
        final response = await repo.getPersonalSources(
          page: 1,
          limit: _limit,
          search: effectiveSearch.isNotEmpty ? effectiveSearch : null,
          filterType: _selectedFilterType != 'all' ? _selectedFilterType : null,
          onlyDue: _onlyDue ? true : null,
          onlyNew: _onlyNew ? true : null,
          isStarred: _isStarred ? true : null,
          sort: _sort,
          order: _order,
        );

        final data = response.data;
        if (data != null) {
          for (final item in data.items) {
            if (item is SourceFolderModel) {
              _folderModelsMap[item.id] = item;
              for (final d in item.decks) {
                _deckModelsMap[d.id] = d;
              }
            } else if (item is SourceDeckModel) {
              _deckModelsMap[item.id] = item;
            }
          }
          for (final f in data.folders) {
            _folderModelsMap[f.id] = f;
            for (final d in f.decks) {
              _deckModelsMap[d.id] = d;
            }
          }
          for (final d in data.standaloneDecks) {
            _deckModelsMap[d.id] = d;
          }

          // Automatically expand folders that contain selected decks
          for (final folder in data.folders) {
            if (folder.decks.any((d) => _selectedDeckIds.contains(d.id))) {
              _expandedFolderIds.add(folder.id);
            }
          }
          for (final item in data.items) {
            if (item is SourceFolderModel &&
                item.decks.any((d) => _selectedDeckIds.contains(d.id))) {
              _expandedFolderIds.add(item.id);
            }
          }
        }

        if (mounted) {
          setState(() {
            _personalData = data;
            _hasMore = data?.hasMore ?? false;
            _isLoading = false;
          });
          _rememberTagColors();
          _syncColorMemoryToController();
        }
      } else {
        // Fetch Class Sources
        final response = await repo.getClassSources(
          page: 1,
          limit: _limit,
          search: effectiveSearch.isNotEmpty ? effectiveSearch : null,
          filterType: _selectedFilterType != 'all' ? _selectedFilterType : null,
          onlyDue: _onlyDue ? true : null,
          onlyNew: _onlyNew ? true : null,
          isStarred: _isStarred ? true : null,
          sort: _sort,
          order: _order,
        );

        final data = response.data;
        if (data != null) {
          for (final c in data.classes) {
            _classModelsMap[c.classId] = c;
            for (final item in c.items) {
              if (item is SourceFolderModel) {
                _folderModelsMap[item.id] = item;
                for (final d in item.decks) {
                  _deckModelsMap[d.id] = d;
                }
              } else if (item is SourceDeckModel) {
                _deckModelsMap[item.id] = item;
              }
            }
            for (final f in c.folders) {
              _folderModelsMap[f.id] = f;
              for (final d in f.decks) {
                _deckModelsMap[d.id] = d;
              }
            }
            for (final d in c.standaloneDecks) {
              _deckModelsMap[d.id] = d;
            }
          }

          for (final c in data.classes) {
            final hasSelected =
                c.standaloneDecks.any((d) => _selectedDeckIds.contains(d.id)) ||
                c.folders.any(
                  (f) =>
                      _selectedFolderIds.contains(f.id) ||
                      f.decks.any((d) => _selectedDeckIds.contains(d.id)),
                ) ||
                c.items.any((item) {
                  if (item is SourceFolderModel) {
                    return _selectedFolderIds.contains(item.id) ||
                        item.decks.any((d) => _selectedDeckIds.contains(d.id));
                  } else if (item is SourceDeckModel) {
                    return _selectedDeckIds.contains(item.id);
                  }
                  return false;
                });
            if (hasSelected) {
              _expandedClassIds.add(c.classId);
            }
          }
        }

        if (mounted) {
          setState(() {
            _classData = data;
            _hasMore = data?.hasMore ?? false;
            _isLoading = false;
          });
          _rememberTagColors();
          _syncColorMemoryToController();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải danh sách tài nguyên: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _page + 1;
    final effectiveSearch = _fullSearchQuery;

    try {
      final repo = DI().sl<TestRepository>();

      if (_activeTab == 0) {
        final response = await repo.getPersonalSources(
          page: nextPage,
          limit: _limit,
          search: effectiveSearch.isNotEmpty ? effectiveSearch : null,
          filterType: _selectedFilterType != 'all' ? _selectedFilterType : null,
          onlyDue: _onlyDue ? true : null,
          onlyNew: _onlyNew ? true : null,
          isStarred: _isStarred ? true : null,
          sort: _sort,
          order: _order,
        );

        final newData = response.data;
        if (newData != null) {
          for (final item in newData.items) {
            if (item is SourceFolderModel) {
              _folderModelsMap[item.id] = item;
              for (final d in item.decks) {
                _deckModelsMap[d.id] = d;
              }
            } else if (item is SourceDeckModel) {
              _deckModelsMap[item.id] = item;
            }
          }
          for (final f in newData.folders) {
            _folderModelsMap[f.id] = f;
            for (final d in f.decks) {
              _deckModelsMap[d.id] = d;
            }
          }
          for (final d in newData.standaloneDecks) {
            _deckModelsMap[d.id] = d;
          }

          final existingItems = _personalData?.items ?? [];
          final existingItemIds = existingItems
              .map((i) => i is SourceFolderModel ? i.id : (i as SourceDeckModel).id)
              .toSet();
          final newItems = newData.items.where((i) {
            final id = i is SourceFolderModel ? i.id : (i as SourceDeckModel).id;
            return !existingItemIds.contains(id);
          }).toList();

          final existingFolders = _personalData?.folders ?? [];
          final existingFolderIds = existingFolders.map((f) => f.id).toSet();
          final newFolders = newData.folders
              .where((f) => !existingFolderIds.contains(f.id))
              .toList();

          final existingDecks = _personalData?.standaloneDecks ?? [];
          final existingDeckIds = existingDecks.map((d) => d.id).toSet();
          final newDecks = newData.standaloneDecks
              .where((d) => !existingDeckIds.contains(d.id))
              .toList();

          final mergedItems = [...existingItems, ...newItems];
          final mergedFolders = [...existingFolders, ...newFolders];
          final mergedDecks = [...existingDecks, ...newDecks];

          final totalFetched = newItems.isNotEmpty
              ? newItems.length
              : (newFolders.length + newDecks.length);
          final hasMore = newData.hasMore && (totalFetched > 0);

          if (mounted) {
            setState(() {
              _page = nextPage;
              _hasMore = hasMore;
              _personalData = PersonalSourcesData(
                activeTags: newData.activeTags.isNotEmpty
                    ? newData.activeTags
                    : (_personalData?.activeTags ?? []),
                suggestions: newData.suggestions ?? _personalData?.suggestions,
                items: mergedItems,
                folders: mergedFolders,
                standaloneDecks: mergedDecks,
                total: newData.total,
                page: nextPage,
                limit: _limit,
                totalPages: newData.totalPages,
                hasMore: hasMore,
              );
              _isLoadingMore = false;
            });
            _rememberTagColors();
            _syncColorMemoryToController();
          }
        } else {
          if (mounted) {
            setState(() {
              _hasMore = false;
              _isLoadingMore = false;
            });
          }
        }
      } else {
        final response = await repo.getClassSources(
          page: nextPage,
          limit: _limit,
          search: effectiveSearch.isNotEmpty ? effectiveSearch : null,
          filterType: _selectedFilterType != 'all' ? _selectedFilterType : null,
          onlyDue: _onlyDue ? true : null,
          onlyNew: _onlyNew ? true : null,
          isStarred: _isStarred ? true : null,
          sort: _sort,
          order: _order,
        );

        final newData = response.data;
        if (newData != null) {
          for (final c in newData.classes) {
            _classModelsMap[c.classId] = c;
            for (final item in c.items) {
              if (item is SourceFolderModel) {
                _folderModelsMap[item.id] = item;
                for (final d in item.decks) {
                  _deckModelsMap[d.id] = d;
                }
              } else if (item is SourceDeckModel) {
                _deckModelsMap[item.id] = item;
              }
            }
            for (final f in c.folders) {
              _folderModelsMap[f.id] = f;
              for (final d in f.decks) {
                _deckModelsMap[d.id] = d;
              }
            }
            for (final d in c.standaloneDecks) {
              _deckModelsMap[d.id] = d;
            }
          }

          final existingClasses = _classData?.classes ?? [];
          final existingClassIds = existingClasses.map((c) => c.classId).toSet();
          final newClasses = newData.classes
              .where((c) => !existingClassIds.contains(c.classId))
              .toList();

          final mergedClasses = [...existingClasses, ...newClasses];
          final hasMore = newData.hasMore && (newClasses.isNotEmpty);

          if (mounted) {
            setState(() {
              _page = nextPage;
              _hasMore = hasMore;
              _classData = ClassSourcesData(
                activeTags: newData.activeTags.isNotEmpty
                    ? newData.activeTags
                    : (_classData?.activeTags ?? []),
                suggestions: newData.suggestions ?? _classData?.suggestions,
                classes: mergedClasses,
                total: newData.total,
                page: nextPage,
                limit: _limit,
                totalPages: newData.totalPages,
                hasMore: hasMore,
              );
              _isLoadingMore = false;
            });
            _rememberTagColors();
            _syncColorMemoryToController();
          }
        } else {
          if (mounted) {
            setState(() {
              _hasMore = false;
              _isLoadingMore = false;
            });
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String text) {
    if (text == _lastSearchText) return;
    _lastSearchText = text;

    // Khi người dùng nhấn phím Space kết thúc một #tag (vd: "#abc ") -> Đóng gói thành viên thuốc Tag
    final tagRegex = RegExp(r'#([^\s]+)\s');
    final match = tagRegex.firstMatch(text);
    if (match != null) {
      final tagName = match.group(1)!;
      final remaining = text.replaceFirst(tagRegex, '');

      _rememberTagColors();

      final hex = _tagColorMemory[tagName.toLowerCase()];
      final newTag = TagModel(id: '', name: tagName, color: hex);

      if (!_selectedSearchTags.any((t) => t.name.toLowerCase() == tagName.toLowerCase())) {
        _selectedSearchTags.add(newTag);
      }

      _searchController.text = remaining;
      _lastSearchText = remaining;
      _executeSearch(_fullSearchQuery);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchCurrentTabData();
    });
    setState(() {});
  }

  void _executeSearch(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();
    if (clean.isNotEmpty) {
      _rememberTagColors();
      _historyService.addSearch(clean, tagColors: _tagColorMemory).then((updated) {
        if (mounted) setState(() => _recentSearches = updated);
      });
    }
    _fetchCurrentTabData();
  }

  void _onRemoveSearchTag(TagModel tag) {
    setState(() {
      _selectedSearchTags.removeWhere((t) => t.name.toLowerCase() == tag.name.toLowerCase());
    });
    _executeSearch(_fullSearchQuery);
  }

  void _onClearSearch() {
    setState(() {
      _selectedSearchTags.clear();
      _searchController.clear();
      _lastSearchText = '';
    });
    _executeSearch('');
  }

  void _onSelectKeyword(DeckKeywordSuggestionModel keyword) {
    for (final tag in keyword.tags) {
      if (tag.color != null && tag.color!.isNotEmpty) {
        _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
      }
    }
    _syncColorMemoryToController();

    setState(() {
      _selectedSearchTags = List<TagModel>.from(keyword.tags);
      if (keyword.displayText.isNotEmpty && keyword.displayText != keyword.query) {
        _searchController.text = keyword.displayText;
      } else {
        final nonTagWords = keyword.query
            .split(RegExp(r'\s+'))
            .where((t) => !t.startsWith('#'))
            .join(' ');
        _searchController.text = nonTagWords;
      }
      _lastSearchText = _searchController.text;
    });
    _searchFocusNode.unfocus();
    _executeSearch(keyword.query);
  }

  void _onSelectRecent(TestSourceSearchHistoryItem item) {
    for (final entry in item.tagColors.entries) {
      _tagColorMemory[entry.key] = entry.value;
    }
    _syncColorMemoryToController();

    final tokens = item.query.trim().split(RegExp(r'\s+'));
    final tags = <TagModel>[];
    final words = <String>[];

    for (final token in tokens) {
      if (token.startsWith('#') && token.length > 1) {
        final tagName = token.substring(1);
        final hex = _tagColorMemory[tagName.toLowerCase()];
        tags.add(TagModel(id: '', name: tagName, color: hex));
      } else if (token.isNotEmpty) {
        words.add(token);
      }
    }

    setState(() {
      _selectedSearchTags = tags;
      _searchController.text = words.join(' ');
      _lastSearchText = _searchController.text;
    });
    _searchFocusNode.unfocus();
    _executeSearch(item.query);
  }

  void _onSelectTag(TagModel tag) {
    if (tag.color != null && tag.color!.isNotEmpty) {
      _tagColorMemory[tag.name.toLowerCase()] = tag.color!;
      _syncColorMemoryToController();
    }

    final currentText = _searchController.text;
    final tagPattern = RegExp(r'#[^\s]*$');
    final cleaned = currentText.replaceAll(tagPattern, '').trim();

    setState(() {
      if (!_selectedSearchTags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase())) {
        _selectedSearchTags.add(tag);
      }
      _searchController.text = cleaned;
      _lastSearchText = cleaned;
    });

    _searchFocusNode.requestFocus();
    _executeSearch(_fullSearchQuery);
  }

  void _onRemoveRecent(String query) async {
    final updated = await _historyService.removeSearch(query);
    if (mounted) {
      setState(() {
        _recentSearches = updated;
      });
    }
  }

  void _onClearAllRecent() async {
    await _historyService.clearHistory();
    if (mounted) {
      setState(() {
        _recentSearches = [];
      });
    }
  }

  // --- Folder Selection Logic ---
  void _toggleFolder(SourceFolderModel folder) {
    setState(() {
      _folderModelsMap[folder.id] = folder;
      for (final d in folder.decks) {
        _deckModelsMap[d.id] = d;
      }

      final allDecksSelected =
          folder.decks.isNotEmpty && folder.decks.every((d) => _selectedDeckIds.contains(d.id));

      if (allDecksSelected || _selectedFolderIds.contains(folder.id)) {
        // Deselect folder and all child decks
        _selectedFolderIds.remove(folder.id);
        for (final deck in folder.decks) {
          _selectedDeckIds.remove(deck.id);
        }
      } else {
        // Select folder and all child decks
        _selectedFolderIds.add(folder.id);
        for (final deck in folder.decks) {
          _selectedDeckIds.add(deck.id);
        }
      }
    });
  }

  // --- Deck Selection Logic ---
  void _toggleDeck(SourceDeckModel deck) {
    setState(() {
      _deckModelsMap[deck.id] = deck;

      if (_selectedDeckIds.contains(deck.id)) {
        _selectedDeckIds.remove(deck.id);

        // If part of a folder, uncheck the folder
        if (deck.folderId != null) {
          _selectedFolderIds.remove(deck.folderId);
        }
      } else {
        _selectedDeckIds.add(deck.id);

        // Check if all decks in parent folder are now selected
        if (deck.folderId != null && _folderModelsMap.containsKey(deck.folderId)) {
          final parentFolder = _folderModelsMap[deck.folderId]!;
          if (parentFolder.decks.isNotEmpty &&
              parentFolder.decks.every((d) => _selectedDeckIds.contains(d.id))) {
            _selectedFolderIds.add(parentFolder.id);
          }
        }
      }
    });
  }

  // --- Class Selection Logic ---
  void _toggleClass(SourceClassModel classItem) {
    setState(() {
      _classModelsMap[classItem.classId] = classItem;

      final allDecks = <SourceDeckModel>[];
      final allFolders = <SourceFolderModel>[];

      for (final f in classItem.folders) {
        if (!allFolders.any((x) => x.id == f.id)) allFolders.add(f);
        _folderModelsMap[f.id] = f;
        for (final d in f.decks) {
          if (!allDecks.any((x) => x.id == d.id)) allDecks.add(d);
          _deckModelsMap[d.id] = d;
        }
      }
      for (final d in classItem.standaloneDecks) {
        if (!allDecks.any((x) => x.id == d.id)) allDecks.add(d);
        _deckModelsMap[d.id] = d;
      }
      for (final item in classItem.items) {
        if (item is SourceFolderModel) {
          if (!allFolders.any((x) => x.id == item.id)) allFolders.add(item);
          _folderModelsMap[item.id] = item;
          for (final d in item.decks) {
            if (!allDecks.any((x) => x.id == d.id)) allDecks.add(d);
            _deckModelsMap[d.id] = d;
          }
        } else if (item is SourceDeckModel) {
          if (!allDecks.any((x) => x.id == item.id)) allDecks.add(item);
          _deckModelsMap[item.id] = item;
        }
      }

      final allSelected =
          allDecks.isNotEmpty && allDecks.every((d) => _selectedDeckIds.contains(d.id));

      if (allSelected) {
        // Deselect all folders and decks in this class
        for (final f in allFolders) {
          _selectedFolderIds.remove(f.id);
        }
        for (final d in allDecks) {
          _selectedDeckIds.remove(d.id);
        }
      } else {
        // Select all folders and decks in this class
        for (final f in allFolders) {
          _selectedFolderIds.add(f.id);
        }
        for (final d in allDecks) {
          _selectedDeckIds.add(d.id);
        }
      }
    });
  }

  // --- Calculations for Bottom Bar ---
  int _calculateTotalCards() {
    int total = 0;
    for (final deckId in _selectedDeckIds) {
      if (_deckModelsMap.containsKey(deckId)) {
        total += _deckModelsMap[deckId]!.cardCount;
      }
    }
    return total;
  }

  int _calculateTotalDueCards() {
    int total = 0;
    for (final deckId in _selectedDeckIds) {
      if (_deckModelsMap.containsKey(deckId)) {
        total += _deckModelsMap[deckId]!.dueCount;
      }
    }
    return total;
  }

  void _clearAllSelections() {
    setState(() {
      _selectedFolderIds.clear();
      _selectedDeckIds.clear();
    });
  }

  void _onDone() {
    final List<DeckModel> resolvedDecks = [];
    final List<FolderModel> resolvedFolders = [];

    for (final folderId in _selectedFolderIds) {
      if (_folderModelsMap.containsKey(folderId)) {
        resolvedFolders.add(_folderModelsMap[folderId]!.toFolderModel());
      }
    }

    for (final deckId in _selectedDeckIds) {
      if (_deckModelsMap.containsKey(deckId)) {
        resolvedDecks.add(_deckModelsMap[deckId]!.toDeckModel());
      }
    }

    Navigator.of(
      context,
    ).pop({'decks': resolvedDecks, 'folders': resolvedFolders, 'tags': <TagModel>[]});
  }

  /// Lấy danh sách tài nguyên cá nhân: Ưu tiên danh sách `items` đã được BE sắp xếp sẵn
  List<dynamic> _getSortedPersonalItems() {
    final data = _personalData;
    if (data == null) return [];

    if (data.items.isNotEmpty) {
      return data.items;
    }

    // Fallback nếu BE trả về format cũ (folders + standaloneDecks riêng rẽ)
    final List<dynamic> items = [];
    if (_selectedFilterType != 'deck') {
      items.addAll(data.folders);
    }
    if (_selectedFilterType != 'folder') {
      items.addAll(data.standaloneDecks);
    }

    items.sort((a, b) {
      if (_sort == 'name') {
        final nameA = (a is SourceFolderModel ? a.name : (a as SourceDeckModel).name).toLowerCase();
        final nameB = (b is SourceFolderModel ? b.name : (b as SourceDeckModel).name).toLowerCase();
        final comp = nameA.compareTo(nameB);
        return _order == 'asc' ? comp : -comp;
      } else if (_sort == 'due_desc' || _sort == 'due') {
        final dueA = a is SourceFolderModel ? a.dueCount : (a as SourceDeckModel).dueCount;
        final dueB = b is SourceFolderModel ? b.dueCount : (b as SourceDeckModel).dueCount;
        final comp = dueA.compareTo(dueB);
        return _order == 'desc' ? -comp : comp;
      } else {
        final rawDateA = a is SourceFolderModel
            ? (a.updatedAt ?? a.createdAt)
            : (a is SourceDeckModel ? (a.updatedAt ?? a.createdAt) : null);
        final rawDateB = b is SourceFolderModel
            ? (b.updatedAt ?? b.createdAt)
            : (b is SourceDeckModel ? (b.updatedAt ?? b.createdAt) : null);

        final dateA = rawDateA != null
            ? (DateTime.tryParse(rawDateA) ?? DateTime.fromMillisecondsSinceEpoch(0))
            : DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = rawDateB != null
            ? (DateTime.tryParse(rawDateB) ?? DateTime.fromMillisecondsSinceEpoch(0))
            : DateTime.fromMillisecondsSinceEpoch(0);

        final comp = dateA.compareTo(dateB);
        return _order == 'desc' ? -comp : comp;
      }
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Chọn tài nguyên học',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_isSearchFocused) {
            _searchFocusNode.unfocus();
          }
        },
        child: Column(
          children: [
            // Segmented Tab Switch: Kho cá nhân vs Lớp học
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildSegmentBtn(
                      index: 0,
                      icon: Icons.person_rounded,
                      label: 'Kho cá nhân',
                      colorScheme: colorScheme,
                    ),
                    _buildSegmentBtn(
                      index: 1,
                      icon: Icons.school_rounded,
                      label: 'Lớp học',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),

            // Thanh tìm kiếm và bộ lọc nâng cao
            SourceFilterBar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchQuery: _searchController.text,
              selectedSearchTags: _selectedSearchTags,
              tagColorMap: _tagColorMemory,
              onRemoveSearchTag: _onRemoveSearchTag,
              onSearchChanged: _onSearchChanged,
              onSearchSubmitted: (val) => _executeSearch(_fullSearchQuery),
              onClearSearch: _onClearSearch,
              selectedFilterType: _selectedFilterType,
              onFilterTypeChanged: (type) {
                setState(() {
                  _selectedFilterType = type;
                });
                _fetchCurrentTabData();
              },
              onlyDue: _onlyDue,
              onOnlyDueChanged: (val) {
                setState(() {
                  _onlyDue = val;
                });
                _fetchCurrentTabData();
              },
              onlyNew: _onlyNew,
              onOnlyNewChanged: (val) {
                setState(() {
                  _onlyNew = val;
                });
                _fetchCurrentTabData();
              },
              isStarred: _isStarred,
              onStarredChanged: (val) {
                setState(() {
                  _isStarred = val;
                });
                _fetchCurrentTabData();
              },
              currentSort: _sort,
              currentOrder: _order,
              onSortChanged: (sort, order) {
                setState(() {
                  _sort = sort;
                  _order = order;
                });
                _fetchCurrentTabData();
              },
            ),

            // Khung Gợi ý tìm kiếm & Lịch sử
            SourceSearchSuggestionsPanel(
              isVisible: _isSearchFocused,
              currentQuery: _searchController.text,
              activeTagNames: _selectedSearchTags.map((t) => t.name).toSet(),
              recentSearches: _recentSearches,
              suggestions: _activeTab == 0 ? _personalData?.suggestions : _classData?.suggestions,
              activeTags: _activeTab == 0
                  ? (_personalData?.activeTags ?? [])
                  : (_classData?.activeTags ?? []),
              onSelectKeyword: _onSelectKeyword,
              onSelectRecent: _onSelectRecent,
              onSelectTag: _onSelectTag,
              onRemoveRecent: _onRemoveRecent,
              onClearAllRecent: _onClearAllRecent,
              onClose: () => _searchFocusNode.unfocus(),
            ),

            const SizedBox(height: 4),

            // Body Content (Danh sách tài nguyên)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _fetchCurrentTabData,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _activeTab == 0
                  ? _buildPersonalTabContent()
                  : _buildClassTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SourceBottomBar(
        selectedFoldersCount: _selectedFolderIds.length,
        selectedDecksCount: _selectedDeckIds.length,
        totalCards: _calculateTotalCards(),
        totalDueCards: _calculateTotalDueCards(),
        onConfirm: _onDone,
        onClearAll: _clearAllSelections,
      ),
    );
  }

  Widget _buildSegmentBtn({
    required int index,
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeTab != index) {
            setState(() {
              _activeTab = index;
            });
            _fetchCurrentTabData();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Content: Personal Sources Tab ---
  Widget _buildPersonalTabContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = _personalData;

    if (data == null ||
        (data.items.isEmpty && data.folders.isEmpty && data.standaloneDecks.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_rounded, size: 56, color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                _fullSearchQuery.isNotEmpty
                    ? 'Không tìm thấy thư mục hoặc bộ thẻ nào'
                    : 'Kho cá nhân của bạn đang trống',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _fullSearchQuery.isNotEmpty
                    ? 'Hãy thử tìm kiếm với từ khóa khác'
                    : 'Hãy tạo thư mục hoặc bộ thẻ mới để bắt đầu ôn tập',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _getSortedPersonalItems();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final item = items[index];
        if (item is SourceFolderModel) {
          final isFolderExpanded = _expandedFolderIds.contains(item.id);
          final allDecksSelected =
              item.decks.isNotEmpty && item.decks.every((d) => _selectedDeckIds.contains(d.id));
          final someDecksSelected = item.decks.any((d) => _selectedDeckIds.contains(d.id));
          final isFolderSelected = _selectedFolderIds.contains(item.id) || allDecksSelected;
          final isFolderIndeterminate = !allDecksSelected && someDecksSelected;

          return SourceFolderTreeItem(
            folder: item,
            isExpanded: isFolderExpanded,
            onToggleExpand: () {
              setState(() {
                if (isFolderExpanded) {
                  _expandedFolderIds.remove(item.id);
                } else {
                  _expandedFolderIds.add(item.id);
                }
              });
            },
            isSelected: isFolderSelected,
            isIndeterminate: isFolderIndeterminate,
            onToggleFolder: () => _toggleFolder(item),
            selectedDeckIds: _selectedDeckIds,
            onDeckToggled: _toggleDeck,
          );
        } else if (item is SourceDeckModel) {
          final isDeckSelected = _selectedDeckIds.contains(item.id);
          return SourceDeckItem(
            deck: item,
            isSelected: isDeckSelected,
            onToggle: () => _toggleDeck(item),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // --- Content: Class Sources Tab ---
  Widget _buildClassTabContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = _classData;

    if (data == null || data.classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 56, color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text(
                _fullSearchQuery.isNotEmpty
                    ? 'Không tìm thấy lớp học nào'
                    : 'Bạn chưa tham gia lớp học nào',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _fullSearchQuery.isNotEmpty
                    ? 'Hãy thử tìm kiếm với từ khóa khác'
                    : 'Tài liệu từ các lớp học của bạn sẽ hiển thị ở đây',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: data.classes.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= data.classes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final classItem = data.classes[index];
        final isClassExpanded = _expandedClassIds.contains(classItem.classId);

        // Check selection state for class
        final allDecks = <SourceDeckModel>[];
        for (final f in classItem.folders) {
          for (final d in f.decks) {
            if (!allDecks.any((x) => x.id == d.id)) allDecks.add(d);
          }
        }
        for (final d in classItem.standaloneDecks) {
          if (!allDecks.any((x) => x.id == d.id)) allDecks.add(d);
        }
        for (final item in classItem.items) {
          if (item is SourceFolderModel) {
            for (final d in item.decks) {
              if (!allDecks.any((x) => x.id == d.id)) allDecks.add(d);
            }
          } else if (item is SourceDeckModel) {
            if (!allDecks.any((x) => x.id == item.id)) allDecks.add(item);
          }
        }

        final selectedCount = allDecks.where((d) => _selectedDeckIds.contains(d.id)).length;
        final isClassSelected = allDecks.isNotEmpty && selectedCount == allDecks.length;
        final isClassIndeterminate = selectedCount > 0 && selectedCount < allDecks.length;

        return SourceClassTreeItem(
          classItem: classItem,
          isExpanded: isClassExpanded,
          onToggleExpand: () {
            setState(() {
              if (isClassExpanded) {
                _expandedClassIds.remove(classItem.classId);
              } else {
                _expandedClassIds.add(classItem.classId);
              }
            });
          },
          isSelected: isClassSelected,
          isIndeterminate: isClassIndeterminate,
          onToggleClass: () => _toggleClass(classItem),
          expandedFolderIds: _expandedFolderIds,
          onToggleFolderExpand: (folderId) {
            setState(() {
              if (_expandedFolderIds.contains(folderId)) {
                _expandedFolderIds.remove(folderId);
              } else {
                _expandedFolderIds.add(folderId);
              }
            });
          },
          selectedFolderIds: _selectedFolderIds,
          selectedDeckIds: _selectedDeckIds,
          onToggleFolder: _toggleFolder,
          onToggleDeck: _toggleDeck,
        );
      },
    );
  }
}
