import 'package:flutter/material.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/ui/commons/widgets/select_folders_tab.dart';
import 'package:mind_deck/ui/commons/widgets/select_decks_tab.dart';

/// Kết quả chọn: id NGUỒN (thư viện cá nhân) để gửi `POST /classes/:id/materials`.
class MaterialPickResult {
  final List<String> deckIds;
  final List<String> folderIds;

  const MaterialPickResult({required this.deckIds, required this.folderIds});

  bool get isEmpty => deckIds.isEmpty && folderIds.isEmpty;
}

/// Chọn bộ thẻ / thư mục từ thư viện cá nhân để thêm vào lớp.
///
/// - Chọn thư mục = chọn luôn các bộ thẻ con; bỏ bớt một bộ thẻ thì thư mục chuyển sang trạng thái
///   "một phần" (dấu −) và chỉ các bộ thẻ còn chọn được thêm lẻ.
/// - Mục đã có trong lớp được đánh dấu bằng `POST /classes/:id/materials/check` (so theo id NGUỒN,
///   không so với id bản sao trong lớp).
class AddMaterialScreen extends StatefulWidget {
  final String classId;

  const AddMaterialScreen({super.key, required this.classId});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  bool _isLoading = true;
  String? _error;

  List<DeckModel> _decks = [];
  List<FolderModel> _folders = [];

  /// Chỉ giữ các bộ thẻ được chọn; trạng thái thư mục được suy ra từ bộ thẻ con.
  final Set<String> _selectedDeckIds = {};

  /// Thư mục RỖNG (không có bộ thẻ con) được chọn riêng.
  final Set<String> _selectedEmptyFolderIds = {};

  Set<String> _existingSourceIds = const {};

  String _activeTab = 'folders'; // 'folders', 'decks'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// Cỡ trang tối đa BE cho phép.
  static const int _pageSize = 100;

  /// Chặn vòng lặp nếu BE trả sai phân trang (tối đa 5.000 mục mỗi loại).
  static const int _maxPages = 50;

  /// Tải HẾT thư viện (không chỉ trang đầu): thư mục được tính trạng thái từ bộ thẻ con,
  /// thiếu bộ thẻ nào thì trạng thái "đủ / một phần" của thư mục sai theo.
  Future<List<T>> _fetchAll<T>(Future<List<T>> Function(int page) fetchPage) async {
    final all = <T>[];
    for (var page = 1; page <= _maxPages; page++) {
      final items = await fetchPage(page);
      all.addAll(items);
      if (items.length < _pageSize) break;
    }
    return all;
  }

  Future<void> _fetchData() async {
    try {
      final results = await (
        _fetchAll<DeckModel>(
          (page) async =>
              (await DI().sl<DeckRepository>().getDecks(page: page, limit: _pageSize)).data,
        ),
        _fetchAll<FolderModel>(
          (page) async =>
              (await DI().sl<FolderRepository>().getFolders(page: page, limit: _pageSize)).data,
        ),
      ).wait;

      final decks = results.$1;
      final folders = results.$2;

      // Đánh dấu mục đã có trong lớp. Lỗi ở bước này không chặn việc chọn.
      Set<String> existing = const {};
      if (decks.isNotEmpty || folders.isNotEmpty) {
        try {
          final check = await DI().sl<ClassRepository>().checkMaterials(
            widget.classId,
            deckIds: [for (final d in decks) d.id],
            folderIds: [for (final f in folders) f.id],
          );
          existing = check.data?.duplicateSourceIds ?? const {};
        } on Failure {
          existing = const {};
        }
      }

      if (mounted) {
        setState(() {
          _decks = decks;
          _folders = folders;
          _existingSourceIds = existing;
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

  List<DeckModel> _childDecks(FolderModel folder) =>
      _decks.where((d) => d.folderIds.contains(folder.id)).toList();

  /// none | partial | full
  String _folderState(FolderModel folder) {
    final children = _childDecks(folder);
    if (children.isEmpty) {
      return _selectedEmptyFolderIds.contains(folder.id) ? 'full' : 'none';
    }
    final selected = children.where((d) => _selectedDeckIds.contains(d.id)).length;
    if (selected == 0) return 'none';
    return selected == children.length ? 'full' : 'partial';
  }

  void _toggleFolder(FolderModel folder) {
    final children = _childDecks(folder);
    setState(() {
      if (children.isEmpty) {
        if (!_selectedEmptyFolderIds.remove(folder.id)) _selectedEmptyFolderIds.add(folder.id);
        return;
      }
      if (_folderState(folder) == 'full') {
        _selectedDeckIds.removeAll(children.map((d) => d.id));
      } else {
        _selectedDeckIds.addAll(children.map((d) => d.id));
      }
    });
  }

  void _toggleDeck(DeckModel deck) {
    setState(() {
      if (!_selectedDeckIds.remove(deck.id)) _selectedDeckIds.add(deck.id);
    });
  }

  /// Thư mục chọn đủ -> gửi cả thư mục (BE sao chép toàn bộ). Chọn một phần -> chỉ gửi các bộ thẻ lẻ.
  MaterialPickResult _buildResult() {
    final fullFolders = _folders.where((f) => _folderState(f) == 'full').toList();
    final fullFolderIds = {for (final f in fullFolders) f.id};
    return MaterialPickResult(
      folderIds: [for (final f in fullFolders) f.id],
      deckIds: [
        for (final d in _decks)
          // Bộ thẻ nằm trong thư mục đã chọn đủ thì đã được sao chép cùng thư mục, không gửi lẻ nữa
          if (_selectedDeckIds.contains(d.id) && !d.folderIds.any(fullFolderIds.contains)) d.id,
      ],
    );
  }

  int get _selectedCount {
    final r = _buildResult();
    return r.deckIds.length + r.folderIds.length;
  }

  void _onDone() {
    Navigator.of(context).pop(_buildResult());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = _selectedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm học liệu'),
        actions: [
          TextButton(
            onPressed: count == 0 ? null : _onDone,
            child: Text(count == 0 ? 'Xong' : 'Thêm ($count)'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildTabBtn('folders', 'Thư mục', colorScheme),
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
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
        selectedFolders: [
          for (final f in _folders)
            if (_folderState(f) == 'full') f,
        ],
        partialIds: {
          for (final f in _folders)
            if (_folderState(f) == 'partial') f.id,
        },
        existingIds: _existingSourceIds,
        onFolderToggled: _toggleFolder,
      );
    }
    return SelectDecksTab(
      decks: _decks,
      selectedDecks: [
        for (final d in _decks)
          if (_selectedDeckIds.contains(d.id)) d,
      ],
      existingIds: _existingSourceIds,
      onDeckToggled: _toggleDeck,
    );
  }
}
