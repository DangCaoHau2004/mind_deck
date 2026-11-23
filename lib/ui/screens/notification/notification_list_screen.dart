import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/repositories/notification_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/screens/notification/bloc/notification_list_bloc.dart';
import 'package:mind_deck/ui/screens/notification/bloc/notification_list_event.dart';
import 'package:mind_deck/ui/screens/notification/bloc/notification_list_state.dart';
import 'package:mind_deck/ui/screens/notification/widgets/notification_item.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/banner_ad_slot.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NotificationListBloc(notificationRepository: DI().sl<NotificationRepository>())
            ..add(const NotificationListLoadStarted()),
      child: const _NotificationListView(),
    );
  }
}

class _NotificationListView extends StatefulWidget {
  const _NotificationListView();

  @override
  State<_NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<_NotificationListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<NotificationListBloc>().add(const NotificationListLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Cài đặt thông báo',
            onPressed: () => context.pushNamed(AppRoute.notificationSettings.name),
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () {
              context.read<NotificationListBloc>().add(const NotificationMarkAllAsRead());
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_read') _confirmDeleteAllRead(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete_read', child: Text('Xóa tất cả đã đọc')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdSlot(unit: AdUnit.bannerNotificationList),
      body: BlocListener<NotificationListBloc, NotificationListState>(
        listenWhen: (prev, curr) =>
            curr is NotificationListSuccess &&
            curr.notice != null &&
            (prev is! NotificationListSuccess || prev.noticeId != curr.noticeId),
        listener: (context, state) {
          final notice = (state as NotificationListSuccess).notice;
          if (notice != null) CustomToast.show(context, CustomToast.general(message: notice));
        },
        child: BlocBuilder<NotificationListBloc, NotificationListState>(
          builder: (context, state) {
            if (state is NotificationListInitial || state is NotificationListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationListFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.error, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<NotificationListBloc>().add(
                        const NotificationListLoadStarted(),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationListSuccess) {
              final notifications = state.notifications;

              if (notifications.isEmpty) {
                return const Center(child: Text('Bạn chưa có thông báo nào.'));
              }

              return CommonRefresh(
                onRefresh: () async {
                  final bloc = context.read<NotificationListBloc>();
                  bloc.add(const NotificationListLoadStarted());
                  await bloc.stream.firstWhere((s) => s is! NotificationListLoading);
                },
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final notification = notifications[index];
                        return Column(
                          children: [
                            Dismissible(
                              key: ValueKey(notification.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) => context.read<NotificationListBloc>().add(
                                NotificationDeleted(notification.id),
                              ),
                              child: NotificationItem(
                                notification: notification,
                                onTap: () {
                                  if (!notification.isRead) {
                                    context.read<NotificationListBloc>().add(
                                      NotificationMarkAsRead(notification.id),
                                    );
                                  }
                                  // Tạm thời: chưa có đích (hoặc lớp không còn truy cập được) thì về Home.
                                  final route = notification.targetRoute;
                                  if (route != null) {
                                    context.push(route);
                                  } else {
                                    context.go(AppRoute.home.path);
                                  }
                                },
                              ),
                            ),
                            if (index < notifications.length - 1) const Divider(height: 1),
                          ],
                        );
                      },
                      childCount: state.hasReachedMax
                          ? notifications.length
                          : notifications.length + 1,
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAllRead(BuildContext context) async {
    final bloc = context.read<NotificationListBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thông báo đã đọc?'),
        content: const Text('Tất cả thông báo đã đọc sẽ bị xóa và không thể khôi phục.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) bloc.add(const NotificationDeleteAllRead());
  }
}
