import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_bloc.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_event.dart';
import 'package:mind_deck/ui/screens/deck/bloc/library_deck_state.dart';
import 'package:mind_deck/ui/screens/deck/widgets/deck_item_widget.dart';

class LibraryDeckTab extends StatefulWidget {
  const LibraryDeckTab({super.key});
  @override
  State<LibraryDeckTab> createState() => _LibraryDeckTabState();
}

class _LibraryDeckTabState extends State<LibraryDeckTab> {
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  bool _isActionBarVisible = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.offset <= 0) {
      if (!_isActionBarVisible) {
        setState(() {
          _isActionBarVisible = true;
        });
      }
      return;
    }

    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      if (_isActionBarVisible) {
        setState(() {
          _isActionBarVisible = false;
        });
      }
    } else if (direction == ScrollDirection.forward) {
      if (!_isActionBarVisible) {
        setState(() {
          _isActionBarVisible = true;
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LibraryDeckBloc, LibraryDeckState>(
      listener: (context, state) {
        if (state.toastTriggerTime != null) {
          if (state.isToastError) {
            CustomToast.show(
              context,
              CustomToast.danger(message: state.toastMessage ?? 'common_error_occurred'.tr),
            );
          } else {
            CustomToast.show(
              context,
              CustomToast.success(message: state.toastMessage ?? 'common_success'.tr),
            );
          }
        }
      },
      listenWhen: (previous, current) => previous.toastTriggerTime != current.toastTriggerTime,
      builder: (context, state) {
        final bool isInitialLoading =
            (state.status == LibraryDeckStatus.initial ||
                state.status == LibraryDeckStatus.loading) &&
            state.decks.isEmpty;
        final bool isInitialError =
            state.status == LibraryDeckStatus.failure && state.decks.isEmpty;

        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              child: _isActionBarVisible
                  ? _buildActionBar(context, state: state, theme: Theme.of(context))
                  : const SizedBox(width: double.infinity, height: 0),
            ),
            Expanded(
              child: CommonRefresh(
                controller: _scrollController,
                onRefresh: () async {
                  final bloc = context.read<LibraryDeckBloc>();
                  bloc.add(LibraryDeckRefreshed());
                  await bloc.stream.firstWhere((LibraryDeckState s) => !s.isRefreshing);
                },
                slivers: [
                  if (isInitialLoading)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  else if (isInitialError)
                    SliverFillRemaining(
                      child: Center(
                        child: CommonFailure(
                          errorMessage: state.toastMessage ?? 'common_error_occurred'.tr,
                        ),
                      ),
                    )
                  else if (state.decks.isEmpty)
                    const SliverFillRemaining(child: CommonEmpty())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 0, bottom: 80),
                      sliver: SliverList.builder(
                        itemCount:
                            state.decks.length +
                            (state.status == LibraryDeckStatus.loading && state.decks.isNotEmpty
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.decks.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final deck = state.decks[index];
                          final isSelected = state.selectedIds.contains(deck.id);

                          return DeckItemWidget(
                            deck: deck,
                            isSelected: isSelected,
                            isSelectionMode: state.isSelectionMode,
                            onLongPress: () {
                              context.read<LibraryDeckBloc>().add(
                                LibraryDeckSelectionToggled(deck.id),
                              );
                            },
                            onTap: () async {
                              if (state.isSelectionMode) {
                                context.read<LibraryDeckBloc>().add(
                                  LibraryDeckSelectionToggled(deck.id),
                                );
                              } else {
                                final result = await context.pushNamed(
                                  AppRoute.deckDetail.name,
                                  pathParameters: {'id': deck.id},
                                  extra: deck.toJson(),
                                );
                                if (result != null && context.mounted) {
                                  context.read<LibraryDeckBloc>().add(LibraryDeckRefreshed());
                                }
                              }
                            },
                            onStarTap: () {
                              context.read<LibraryDeckBloc>().add(LibraryDeckStarToggled(deck.id));
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

  // Action Bar đồng nhất với tab Folder
  Widget _buildActionBar(
    BuildContext context, {
    required LibraryDeckState state,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      context.read<LibraryDeckBloc>().add(LibraryDeckFilterChanged(search: val));
                    },
                    decoration: InputDecoration(
                      hintText: 'deck_search_hint'.tr,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      contentPadding: const EdgeInsets.only(left: 20, top: 14, bottom: 14),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nút Xóa (chỉ hiện khi có chữ)
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<LibraryDeckBloc>().add(
                                  const LibraryDeckFilterChanged(search: ''),
                                );
                                FocusScope.of(context).unfocus();
                              },
                            ),

                          // Nút Tìm Kiếm vừa khít
                          Container(
                            height: 50,
                            width: 54,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.all(Radius.circular(50)),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.search_rounded,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                context.read<LibraryDeckBloc>().add(
                                  LibraryDeckFilterChanged(search: _searchController.text),
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

              // NÚT THÊM HỌC PHẦN
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () async {
                    final result = await context.pushNamed(AppRoute.deckCreate.name);
                    if (result != null && context.mounted) {
                      if (result is String) {
                        CustomToast.show(context, CustomToast.success(message: result));
                      }
                      context.read<LibraryDeckBloc>().add(LibraryDeckRefreshed());
                    }
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
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
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
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
                value: state.filter ?? 'all',
                items: const ['all', 'starred'],
                itemLabelBuilder: (val) =>
                    val == 'all' ? 'deck_filter_all'.tr : 'deck_filter_starred'.tr,
                onChanged: (val) {
                  context.read<LibraryDeckBloc>().add(LibraryDeckFilterChanged(filter: val));
                },
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              const SizedBox(width: 10),
              CustomDropdown<String>(
                value: state.sort ?? 'created',
                items: const ['created', 'recent', 'name'],
                itemLabelBuilder: (val) {
                  final isCurrent = val == (state.sort ?? 'created');
                  final currentOrder = isCurrent ? (state.order ?? 'desc') : 'desc';
                  if (val == 'created') {
                    return currentOrder == 'desc' ? 'deck_sort_newest'.tr : 'deck_sort_oldest'.tr;
                  }
                  if (val == 'recent') {
                    return currentOrder == 'desc'
                        ? 'deck_sort_recent'.tr
                        : 'deck_sort_least_recent'.tr;
                  }
                  final nameOrder = isCurrent ? (state.order ?? 'asc') : 'asc';
                  return nameOrder == 'asc' ? 'deck_sort_name_asc'.tr : 'deck_sort_name_desc'.tr;
                },
                onChanged: (val) {
                  String newOrder = 'desc';
                  if (val == 'name') {
                    newOrder = 'asc';
                  }
                  if (val == (state.sort ?? 'created')) {
                    final currentOrder = state.order ?? 'desc';
                    newOrder = currentOrder == 'desc' ? 'asc' : 'desc';
                  }
                  context.read<LibraryDeckBloc>().add(
                    LibraryDeckFilterChanged(sort: val, order: newOrder),
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
