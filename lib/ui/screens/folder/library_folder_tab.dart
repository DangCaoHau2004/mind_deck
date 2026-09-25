import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_bloc.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_event.dart';
import 'package:mind_deck/ui/screens/folder/bloc/library_folder_state.dart';
import 'package:mind_deck/ui/screens/folder/widgets/folder_item_widget.dart';

class LibraryFolderTab extends StatefulWidget {
  const LibraryFolderTab({super.key});

  @override
  State<LibraryFolderTab> createState() => _LibraryFolderTabState();
}

class _LibraryFolderTabState extends State<LibraryFolderTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<LibraryFolderBloc, LibraryFolderState>(
      listener: (context, state) {
        if (state.toastTriggerTime != null) {
          if (state.isToastError) {
            CustomToast.show(
              context,
              CustomToast.danger(
                message: state.toastMessage ?? 'Có lỗi xảy ra',
              ),
            );
          } else {
            CustomToast.show(
              context,
              CustomToast.success(message: state.toastMessage ?? 'Thành công'),
            );
          }
        }
      },
      listenWhen: (previous, current) =>
          previous.toastTriggerTime != current.toastTriggerTime,
      builder: (context, state) {
        final bool isInitialLoading =
            (state.status == LibraryFolderStatus.initial ||
                state.status == LibraryFolderStatus.loading) &&
            state.folders.isEmpty;
        final bool isInitialError =
            state.status == LibraryFolderStatus.failure &&
            state.folders.isEmpty;

        return Column(
          children: [
            // Gọi thanh Action Bar mới ở đây
            _buildActionBar(context, theme, state),
            Expanded(
              child: CommonRefresh(
                onRefresh: () async {
                  final bloc = context.read<LibraryFolderBloc>();
                  bloc.add(LibraryFolderRefreshed());
                  await bloc.stream.firstWhere(
                    (LibraryFolderState s) => !s.isRefreshing,
                  );
                },
                slivers: [
                  if (isInitialLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (isInitialError)
                    SliverFillRemaining(
                      child: Center(
                        child: CommonFailure(
                          errorMessage: state.toastMessage ?? 'Có lỗi xảy ra',
                        ),
                      ),
                    )
                  else if (state.folders.isEmpty)
                    const SliverFillRemaining(child: CommonEmpty())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 0, bottom: 80),
                      sliver: SliverList.builder(
                        itemCount:
                            state.folders.length +
                            (state.status == LibraryFolderStatus.loading &&
                                    state.folders.isNotEmpty
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.folders.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final folder = state.folders[index];
                          final isSelected = state.selectedIds.contains(
                            folder.id,
                          );

                          return FolderItemWidget(
                            folder: folder,
                            isSelected: isSelected,
                            isSelectionMode: state.isSelectionMode,
                            onLongPress: () {
                              context.read<LibraryFolderBloc>().add(
                                LibraryFolderSelectionToggled(folder.id),
                              );
                            },
                            onTap: () async {
                              if (state.isSelectionMode) {
                                context.read<LibraryFolderBloc>().add(
                                  LibraryFolderSelectionToggled(folder.id),
                                );
                              } else {
                                final result = await context.pushNamed(
                                  AppRoute.folderDetail.name,
                                  pathParameters: {'id': folder.id},
                                  extra: folder.toJson(),
                                );
                                if (result != null && context.mounted) {
                                  if (result is String) {
                                    CustomToast.show(
                                      context,
                                      CustomToast.success(message: result),
                                    );
                                  }
                                  final bloc = context
                                      .read<LibraryFolderBloc>();
                                  bloc.add(LibraryFolderRefreshed());
                                }
                              }
                            },
                            onStarTap: () {
                              context.read<LibraryFolderBloc>().add(
                                LibraryFolderStarToggled(folder.id),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // GIAO DIỆN ACTION BAR MỚI (Vừa khít viền)
  Widget _buildActionBar(
    BuildContext context,
    ThemeData theme,
    LibraryFolderState state,
  ) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      context.read<LibraryFolderBloc>().add(
                        LibraryFolderFilterChanged(search: val),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm thư mục...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      contentPadding: const EdgeInsets.only(
                        left: 20,
                        top: 14,
                        bottom: 14,
                      ),

                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nút Xóa (chỉ hiện khi có chữ)
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<LibraryFolderBloc>().add(
                                  const LibraryFolderFilterChanged(search: ''),
                                );
                                FocusScope.of(context).unfocus();
                              },
                            ),

                          // SỬA ĐỔI: NÚT TÌM KIẾM VỪA KHÍT
                          Container(
                            height: 50, // Cùng chiều cao với khung ngoài
                            width: 54, // Đủ rộng để click thoải mái
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.search_rounded,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                context.read<LibraryFolderBloc>().add(
                                  LibraryFolderFilterChanged(
                                    search: _searchController.text,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. NÚT THÊM THƯ MỤC
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () async {
                    final result = await context.pushNamed(
                      AppRoute.folderCreate.name,
                    );
                    if (result != null && result is String && context.mounted) {
                      CustomToast.show(
                        context,
                        CustomToast.success(message: result),
                      );
                      context.read<LibraryFolderBloc>().add(
                        LibraryFolderRefreshed(),
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.create_new_folder_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bộ lọc & Sắp xếp dạng CustomDropdown đẹp và đồng bộ
          Row(
            children: [
              CustomDropdown<String>(
                value: state.isStarred == true ? 'starred' : 'all',
                items: const ['all', 'starred'],
                itemLabelBuilder: (val) =>
                    val == 'all' ? 'folder_filter_all'.tr : 'deck_filter_starred'.tr,
                onChanged: (val) {
                  if (val == 'starred') {
                    context.read<LibraryFolderBloc>().add(
                      const LibraryFolderFilterChanged(isStarred: true),
                    );
                  } else {
                    context.read<LibraryFolderBloc>().add(
                      const LibraryFolderFilterChanged(clearIsStarred: true),
                    );
                  }
                },
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              const SizedBox(width: 10),
              CustomDropdown<String>(
                value: state.sort,
                items: const ['recent', 'name'],
                itemLabelBuilder: (val) {
                  final isCurrent = val == state.sort;
                  final currentOrder = isCurrent ? state.order : 'desc';
                  if (val == 'recent') {
                    return currentOrder == 'desc'
                        ? 'deck_sort_recent'.tr
                        : 'deck_sort_least_recent'.tr;
                  }
                  final nameOrder = isCurrent ? state.order : 'asc';
                  return nameOrder == 'asc'
                      ? 'deck_sort_name_asc'.tr
                      : 'deck_sort_name_desc'.tr;
                },
                onChanged: (val) {
                  String newOrder = 'desc';
                  if (val == 'name') {
                    newOrder = 'asc';
                  }
                  if (val == state.sort) {
                    newOrder = state.order == 'desc' ? 'asc' : 'desc';
                  }
                  context.read<LibraryFolderBloc>().add(
                    LibraryFolderFilterChanged(sort: val, order: newOrder),
                  );
                },
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
