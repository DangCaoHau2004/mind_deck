import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_content_model.dart';
import 'bloc/discover_popular_bloc.dart';
import 'bloc/discover_popular_event.dart';
import 'bloc/discover_popular_state.dart';

class DiscoverPopularScreen extends StatefulWidget {
  const DiscoverPopularScreen({super.key});

  @override
  State<DiscoverPopularScreen> createState() => _DiscoverPopularScreenState();
}

class _DiscoverPopularScreenState extends State<DiscoverPopularScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<DiscoverPopularBloc>().add(DiscoverPopularLoaded(page: 1));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<DiscoverPopularBloc>().state;
      if (!state.hasReachedMax &&
          state.status != DiscoverPopularStatus.loading) {
        context.read<DiscoverPopularBloc>().add(
          DiscoverPopularLoaded(page: state.currentPage + 1),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: const Text(
          'Nội dung thịnh hành',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<DiscoverPopularBloc, DiscoverPopularState>(
        builder: (context, state) {
          if (state.status == DiscoverPopularStatus.loading &&
              state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == DiscoverPopularStatus.failure &&
              state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? 'Có lỗi xảy ra',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  TextButton(
                    onPressed: () => context.read<DiscoverPopularBloc>().add(
                      DiscoverPopularLoaded(page: 1),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return CommonRefresh(
            controller: _scrollController,
            onRefresh: () async {
              final bloc = context.read<DiscoverPopularBloc>();
              bloc.add(DiscoverPopularRefreshed());
              await bloc.stream.firstWhere((s) => !s.isRefreshing);
            },
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildTrendingListItem(
                        state.items[index],
                        colorScheme,
                        textTheme,
                      );
                    },
                    childCount: state.hasReachedMax
                        ? state.items.length
                        : state.items.length + 1,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrendingListItem(
    DiscoverySuggestedContentModel item,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isFolder = item.type == 'folder';
    // For simplicity, generate a color from id
    final colorVal = item.id.hashCode & 0xFFFFFF;
    final itemColor = Color(colorVal).withAlpha(255);

    return InkWell(
      onTap: () {
        if (isFolder) {
          context.pushNamed(
            AppRoute.folderDetail.name,
            pathParameters: {'id': item.id},
          );
        } else {
          context.pushNamed(
            AppRoute.deckDetail.name,
            pathParameters: {'id': item.id},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: itemColor.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isFolder ? Icons.folder_copy_rounded : Icons.style_rounded,
                color: itemColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.edit_document,
                        size: 12,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.ownerName ?? 'Ẩn danh',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "•",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline.withAlpha(100),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${isFolder ? '${item.deckCount ?? 0} bộ thẻ' : '${item.cardCount ?? 0} thẻ'} • ${item.savedCount} lưu",
                          style: textTheme.bodySmall?.copyWith(
                            color: itemColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: itemColor.withAlpha(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.bookmark_add_outlined,
                  color: itemColor,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
