import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/custom_test_model.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/screens/classroom/class_tests/bloc/class_tests_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_tests/class_test_editor_screen.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/coin_models.dart';
import 'package:mind_deck/data/repositories/coin_repository.dart';
import 'package:mind_deck/ui/commons/ads/watch_video_coin_button.dart';

/// Kho đề của lớp (giảng viên): danh sách đề, tạo đề tự động / tự soạn, xem & sửa đề.
class ClassTestsScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassTestsScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DI().sl<ClassTestsBloc>()..add(ClassTestsLoaded(classData.id)),
      child: _ClassTestsView(classData: classData),
    );
  }
}

class _ClassTestsView extends StatefulWidget {
  final ClassModel classData;

  const _ClassTestsView({required this.classData});

  @override
  State<_ClassTestsView> createState() => _ClassTestsViewState();
}

class _ClassTestsViewState extends State<_ClassTestsView> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  String get _classId => widget.classData.id;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<ClassTestsBloc>().add(ClassTestsLoadMore(_classId));
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Đề tự soạn tốn xu khi BE có đặt giá cho tính năng này (`features.custom_test`); chưa có giá thì
  /// không chặn. Thiếu xu thì cho xem video rồi hỏi lại. Trả false nếu người dùng hủy.
  Future<bool> _confirmCoinCost(BuildContext context) async {
    final CoinInfo info;
    try {
      info = await DI().sl<CoinRepository>().getCoins();
    } on Failure {
      return true; // Không đọc được giá thì để BE quyết định khi tạo.
    }
    final price = info.features[CoinFeatureKeys.customTest]?.price?.priceFor(1);
    if (price == null || price <= 0) return true;
    if (!context.mounted) return false;

    final enough = info.balance >= price;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đề tự soạn'),
        content: Text('Tạo đề tự soạn tốn $price xu, bạn đang có ${info.balance} xu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          if (enough)
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tiếp tục'),
            )
          else
            WatchVideoForCoinButton(
              placement: 'class_custom_test',
              onRewarded: (_) => Navigator.pop(dialogContext),
            ),
        ],
      ),
    );
    if (!context.mounted) return false;
    // Đóng hộp thoại sau khi xem video (result null): hỏi lại với số dư mới.
    return result ?? await _confirmCoinCost(context);
  }

  Future<void> _open(BuildContext context, {String? testId, String? kind}) async {
    if (testId == null && kind == 'manual' && !await _confirmCoinCost(context)) return;
    if (!context.mounted) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassTestEditorScreen(
          classData: widget.classData,
          testId: testId,
          initialKind: kind ?? 'auto',
        ),
      ),
    );
    if (changed == true && context.mounted) {
      context.read<ClassTestsBloc>().add(ClassTestsLoaded(_classId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocConsumer<ClassTestsBloc, ClassTestsState>(
      listenWhen: (p, c) => !p.isForbidden && c.isForbidden,
      listener: (context, state) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        Widget body;
        if (state.status == ClassTestsStatus.loading && state.items.isEmpty) {
          body = const Center(child: CircularProgressIndicator());
        } else if (state.status == ClassTestsStatus.failure && state.items.isEmpty) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Có lỗi xảy ra', style: TextStyle(color: cs.error)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.read<ClassTestsBloc>().add(ClassTestsLoaded(_classId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        } else if (state.items.isEmpty) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                state.query.isEmpty
                    ? 'Kho đề trống. Bấm + để tạo đề đầu tiên cho lớp.'
                    : 'Không tìm thấy đề phù hợp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          );
        } else {
          body = CommonRefresh(
            onRefresh: () async {
              final bloc = context.read<ClassTestsBloc>();
              bloc.add(ClassTestsLoaded(_classId));
              await bloc.stream.firstWhere((s) => s.status != ClassTestsStatus.loading);
            },
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.separated(
                  itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _TestTile(
                      test: state.items[i],
                      onTap: () => _open(context, testId: state.items[i].id),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(CupertinoIcons.back, color: cs.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Kho đề', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Tạo đề mới',
                icon: Icon(Icons.add_circle_rounded, color: cs.primary, size: 28),
                onSelected: (kind) => _open(context, kind: kind),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'auto',
                    child: ListTile(
                      leading: Icon(Icons.auto_awesome_rounded),
                      title: Text('Đề tự động'),
                      subtitle: Text('Mỗi học viên một bộ câu ngẫu nhiên'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'manual',
                    child: ListTile(
                      leading: Icon(Icons.edit_note_rounded),
                      title: Text('Đề tự soạn'),
                      subtitle: Text('Cả lớp làm cùng một bộ câu cố định'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Tìm đề theo tên...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) => context.read<ClassTestsBloc>().add(
                    ClassTestsSearchChanged(_classId, v.trim()),
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

class _TestTile extends StatelessWidget {
  final CustomTestModel test;
  final VoidCallback onTap;

  const _TestTile({required this.test, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = test.questionCount != null
        ? '${test.questionCount} câu'
        : 'tối đa ~${test.cardCount ?? 0} câu';
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  test.isManual ? Icons.edit_note_rounded : Icons.auto_awesome_rounded,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${test.isManual ? 'Tự soạn' : 'Tự động'} · $count'
                      '${test.assignmentCount > 0 ? ' · ${test.assignmentCount} bài giao' : ''}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
