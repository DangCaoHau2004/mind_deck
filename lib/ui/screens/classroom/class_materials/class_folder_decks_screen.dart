import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/class_error_messages.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/repositories/class_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/widgets/class_material_tile.dart';

/// Các bộ thẻ bên trong một thư mục của lớp (`GET /classes/:id/materials/folders/:folderId/decks`).
/// Danh sách học liệu chỉ hiện folder + deck lẻ nên deck con chỉ thấy khi mở folder.
class ClassFolderDecksScreen extends StatefulWidget {
  final ClassModel classData;
  final ClassMaterialItem folder;

  const ClassFolderDecksScreen({super.key, required this.classData, required this.folder});

  @override
  State<ClassFolderDecksScreen> createState() => _ClassFolderDecksScreenState();
}

class _ClassFolderDecksScreenState extends State<ClassFolderDecksScreen> {
  static const int _pageSize = 20;

  final ScrollController _scroll = ScrollController();
  final List<ClassMaterialItem> _decks = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _busy = false;
  int _page = 1;
  String? _error;
  ClassMaterialItem? _folderInfo;

  ClassRepository get _repo => DI().sl<ClassRepository>();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) _loadMore();
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.getFolderDecks(
        widget.classData.id,
        widget.folder.id,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _decks
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _page = 1;
        _folderInfo = page.folder;
        _loading = false;
      });
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _error = ClassErrorMessages.of(f);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.getFolderDecks(
        widget.classData.id,
        widget.folder.id,
        page: _page + 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      final known = {for (final d in _decks) d.id};
      setState(() {
        _decks.addAll(page.items.where((d) => !known.contains(d.id)));
        _hasMore = page.hasMore;
        _page += 1;
        _loadingMore = false;
      });
    } on Failure {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _toast(String message, {bool error = false}) {
    CustomToast.show(
      context,
      error ? CustomToast.danger(message: message) : CustomToast.success(message: message),
    );
  }

  Future<void> _clone(ClassMaterialItem deck) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repo.cloneClassMaterials(
        widget.classData.id,
        targetType: ClassMaterialItem.typeDeck,
        targetId: deck.id,
      );
      if (mounted) _toast('Đã sao chép bộ thẻ về thư viện của bạn');
    } on Failure catch (f) {
      if (mounted) _toast(ClassErrorMessages.of(f), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(ClassMaterialItem deck) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gỡ bộ thẻ khỏi lớp?'),
        content: Text(
          'Chỉ gỡ "${deck.name}" khỏi thư mục này. Tiến trình học của lớp trên bộ thẻ này sẽ không còn.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Gỡ', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      // Id BẢN SAO của deck trong lớp.
      await _repo.deleteMaterials(widget.classData.id, folderIds: const [], deckIds: [deck.id]);
      if (!mounted) return;
      _toast('Đã gỡ bộ thẻ khỏi lớp');
      await _load();
    } on Failure catch (f) {
      if (mounted) _toast(ClassErrorMessages.of(f), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final folder = _folderInfo ?? widget.folder;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    } else if (_decks.isEmpty) {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'Thư mục này chưa có bộ thẻ nào.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: _decks.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= _decks.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final deck = _decks[index];
            return ClassMaterialTile(
              item: deck,
              onTap: () => context.pushNamed(
                AppRoute.deckDetail.name,
                pathParameters: {'id': deck.id},
                extra: {
                  'canEditClassCopy': widget.classData.isTeacher,
                  'canCloneClassCopy': deck.canClone,
                },
              ),
              onLongPress: widget.classData.isTeacher ? () => _remove(deck) : null,
              onClone: deck.canClone ? () => _clone(deck) : null,
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: widget.classData.isTeacher
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Giữ lâu một bộ thẻ để gỡ khỏi lớp',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          body,
          if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x33000000))),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
