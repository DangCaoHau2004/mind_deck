import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/add_material_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/bloc/class_materials_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/bloc/class_materials_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/bloc/class_materials_state.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/class_folder_decks_screen.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/widgets/class_material_tile.dart';

class ClassMaterialsScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassMaterialsScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DI().sl<ClassMaterialsBloc>()..add(ClassMaterialsLoaded(classData.id)),
      child: _ClassMaterialsView(classData: classData),
    );
  }
}

class _ClassMaterialsView extends StatefulWidget {
  final ClassModel classData;

  const _ClassMaterialsView({required this.classData});

  @override
  State<_ClassMaterialsView> createState() => _ClassMaterialsViewState();
}

class _ClassMaterialsViewState extends State<_ClassMaterialsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ClassMaterialsBloc>().add(ClassMaterialsLoadMore(widget.classData.id));
    }
  }

  /// Chọn học liệu từ thư viện cá nhân rồi gửi lên (BE tạo BẢN SAO trong lớp).
  Future<void> _openAddScreen(BuildContext context) async {
    final result = await Navigator.push<MaterialPickResult>(
      context,
      MaterialPageRoute(builder: (_) => AddMaterialScreen(classId: widget.classData.id)),
    );
    if (result == null || result.isEmpty || !context.mounted) return;

    context.read<ClassMaterialsBloc>().add(
      ClassMaterialAdded(
        classId: widget.classData.id,
        deckIds: result.deckIds,
        folderIds: result.folderIds,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ClassMaterialsState state) async {
    final selected = state.selectedItems;
    final folders = selected.where((i) => i.isFolder).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gỡ ${selected.length} học liệu khỏi lớp?'),
        content: Text(
          folders > 0
              ? 'Gỡ thư mục sẽ gỡ luôn TẤT CẢ bộ thẻ bên trong và làm mất tiến trình học của lớp trên các bộ thẻ đó. '
                    'Dữ liệu được giữ 90 ngày rồi xóa hẳn, không có cách khôi phục.'
              : 'Tiến trình học của lớp trên các bộ thẻ này sẽ không còn. Dữ liệu được giữ 90 ngày rồi xóa hẳn.',
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
    if (ok == true && context.mounted) {
      context.read<ClassMaterialsBloc>().add(ClassMaterialsDeleted(widget.classData.id));
    }
  }

  /// BE báo có học liệu đã có trong lớp: hỏi cách xử lý rồi gửi lại cùng body kèm `duplicatePolicy`.
  Future<void> _askDuplicatePolicy(BuildContext context, PendingMaterialAdd pending) async {
    final bloc = context.read<ClassMaterialsBloc>();
    final cs = Theme.of(context).colorScheme;
    final names = pending.duplicates.map((d) => d.name).toSet().toList();

    final policy = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${names.length} học liệu đã có trong lớp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final name in names.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $name', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              if (names.length > 6) Text('… và ${names.length - 6} mục khác'),
              const SizedBox(height: 12),
              Text(
                'Chọn cách xử lý:',
                style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              const Text('• Bỏ qua: chỉ thêm các mục chưa có (khuyên dùng).'),
              const Text('• Vẫn thêm: tạo thêm bản trùng, tiến trình học tách riêng.'),
              if (pending.canMerge)
                const Text('• Gộp: chuyển bộ thẻ lẻ đã có vào thư mục mới, giữ tiến trình.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'add_anyway'),
            child: const Text('Vẫn thêm'),
          ),
          if (pending.canMerge)
            TextButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: const Text('Gộp')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'skip'), child: const Text('Bỏ qua')),
        ],
      ),
    );

    if (policy == null) {
      bloc.add(ClassMaterialDuplicateDismissed());
      return;
    }
    bloc.add(
      ClassMaterialAdded(
        classId: pending.classId,
        deckIds: pending.deckIds,
        folderIds: pending.folderIds,
        duplicatePolicy: policy,
      ),
    );
  }

  void _openItem(BuildContext context, ClassMaterialItem item) {
    if (item.isFolder) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassFolderDecksScreen(classData: widget.classData, folder: item),
        ),
      );
    } else {
      // Mở bằng id BẢN SAO; màn chi tiết tự tải lại từ BE.
      context.pushNamed(
        AppRoute.deckDetail.name,
        pathParameters: {'id': item.id},
        extra: {'canEditClassCopy': widget.classData.isTeacher, 'canCloneClassCopy': item.canClone},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Giảng viên (owner/admin/tutor) thêm / gỡ học liệu; mọi thành viên xem được.
    final bool isTeacher = widget.classData.isTeacher;

    return BlocConsumer<ClassMaterialsBloc, ClassMaterialsState>(
      listenWhen: (p, c) =>
          p.noticeId != c.noticeId || p.pendingAdd != c.pendingAdd || (!p.isGone && c.isGone),
      listener: (context, state) {
        final notice = state.notice;
        if (notice != null) {
          CustomToast.show(
            context,
            state.noticeIsError
                ? CustomToast.danger(message: notice)
                : CustomToast.success(message: notice),
          );
        }
        final pending = state.pendingAdd;
        if (pending != null) _askDuplicatePolicy(context, pending);
        // Không còn là thành viên của lớp: quay về.
        if (state.isGone) Navigator.of(context).maybePop();
      },
      builder: (context, state) {
        final isInitialLoading =
            (state.status == ClassMaterialsStatus.initial ||
                state.status == ClassMaterialsStatus.loading) &&
            state.items.isEmpty;

        PreferredSizeWidget appBar;
        if (state.isSelectionMode) {
          appBar = AppBar(
            leading: IconButton(
              icon: Icon(Icons.close, color: cs.onSurface),
              onPressed: () =>
                  context.read<ClassMaterialsBloc>().add(ClassMaterialsSelectionCleared()),
            ),
            title: Text("${state.selectedIds.length} đã chọn"),
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: state.selectedIds.isNotEmpty && !state.isProcessing
                    ? () => _confirmDelete(context, state)
                    : null,
              ),
            ],
          );
        } else {
          appBar = AppBar(
            leading: IconButton(
              icon: Icon(CupertinoIcons.back, color: cs.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Học liệu"),
            elevation: 1,
            actions: [
              if (isTeacher)
                IconButton(
                  tooltip: 'Thêm học liệu',
                  icon: Icon(Icons.add, color: cs.primary),
                  onPressed: state.isProcessing ? null : () => _openAddScreen(context),
                ),
            ],
          );
        }

        return Scaffold(
          appBar: appBar,
          body: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm học liệu...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (value) {
                        context.read<ClassMaterialsBloc>().add(
                          ClassMaterialsSearchChanged(widget.classData.id, value.trim()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonRefresh(
                      onRefresh: () async {
                        final bloc = context.read<ClassMaterialsBloc>();
                        bloc.add(ClassMaterialsRefreshed(widget.classData.id));
                        await bloc.stream.firstWhere((ClassMaterialsState s) => !s.isRefreshing);
                      },
                      slivers: [
                        if (isInitialLoading)
                          const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.status == ClassMaterialsStatus.failure &&
                            state.items.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.errorMessage ?? 'Có lỗi xảy ra',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: cs.error),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => context.read<ClassMaterialsBloc>().add(
                                        ClassMaterialsLoaded(widget.classData.id),
                                      ),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else if (state.items.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Text(
                                state.searchQuery.isEmpty
                                    ? "Lớp chưa có học liệu nào."
                                    : "Không tìm thấy học liệu phù hợp.",
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList.separated(
                              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index >= state.items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final item = state.items[index];
                                final bloc = context.read<ClassMaterialsBloc>();
                                return ClassMaterialTile(
                                  item: item,
                                  isSelectionMode: state.isSelectionMode,
                                  isSelected: state.selectedIds.contains(item.id),
                                  onTap: () {
                                    if (state.isSelectionMode) {
                                      bloc.add(ClassMaterialSelectionToggled(item.id));
                                    } else {
                                      _openItem(context, item);
                                    }
                                  },
                                  onLongPress: isTeacher && !state.isSelectionMode
                                      ? () {
                                          bloc.add(const ClassMaterialsSelectionModeToggled(true));
                                          bloc.add(ClassMaterialSelectionToggled(item.id));
                                        }
                                      : null,
                                  // Học viên chỉ sao chép được khi lớp cho phép (`canClone` từ BE).
                                  onClone: item.canClone && !state.isSelectionMode
                                      ? () => bloc.add(
                                          ClassMaterialCloned(
                                            classId: widget.classData.id,
                                            item: item,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.isProcessing) ...[
                const Positioned.fill(child: ColoredBox(color: Color(0x33000000))),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        );
      },
    );
  }
}
