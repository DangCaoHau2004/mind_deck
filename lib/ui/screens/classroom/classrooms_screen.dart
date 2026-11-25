import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/commons/state_screens/common_loading.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_event.dart';
import 'package:mind_deck/ui/screens/classroom/bloc/class_list_state.dart';
import 'package:mind_deck/ui/screens/classroom/widgets/class_item_card.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/widgets/class_invitation_card.dart';
import 'package:mind_deck/ui/screens/classroom/widgets/join_class_modal.dart';
export 'package:mind_deck/ui/screens/classroom/widgets/class_item_card.dart';
export 'package:mind_deck/ui/screens/classroom/widgets/join_class_modal.dart';
export 'package:mind_deck/ui/screens/classroom/widgets/slide_right_route.dart';

class ClassRoomsScreen extends StatefulWidget {
  final String? initialJoinCode;
  const ClassRoomsScreen({super.key, this.initialJoinCode});

  @override
  State<ClassRoomsScreen> createState() => _ClassRoomsScreenState();
}

class _ClassRoomsScreenState extends State<ClassRoomsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialJoinCode != null && widget.initialJoinCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showJoinModal(context, initialCode: widget.initialJoinCode);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Gần cuối danh sách thì tải thêm lớp (bloc tự bỏ qua khi hết trang hoặc đang tải).
  void _onScroll() {
    if (_scrollController.hasClients && _scrollController.position.extentAfter < 600) {
      context.read<ClassListBloc>().add(ClassListMoreLoaded());
    }
  }

  void _showJoinModal(BuildContext context, {String? initialCode}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ClassListBloc>(),
        child: JoinClassModal(initialCode: initialCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          "Lớp học",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BlocConsumer<ClassListBloc, ClassListState>(
                // Toast cho thao tác chấp nhận / từ chối lời mời từ danh sách.
                listenWhen: (prev, current) => prev.noticeId != current.noticeId,
                listener: (context, state) {
                  final notice = state.notice;
                  if (notice == null) return;
                  CustomToast.show(
                    context,
                    state.noticeIsError
                        ? CustomToast.danger(message: notice)
                        : CustomToast.success(message: notice),
                  );
                },
                builder: (context, state) {
                  Future<void> onRefresh() async {
                    final bloc = context.read<ClassListBloc>();
                    bloc.add(ClassListLoaded());
                    await bloc.stream.firstWhere((s) => s.status != ClassListStatus.loading);
                  }

                  Widget buildRefreshable(Widget child) {
                    return CommonRefresh(
                      onRefresh: onRefresh,
                      slivers: [SliverFillRemaining(child: child)],
                    );
                  }

                  if (state.status == ClassListStatus.loading) {
                    return buildRefreshable(const Center(child: CommonLoading()));
                  }
                  if (state.status == ClassListStatus.failure) {
                    return buildRefreshable(
                      CommonFailure(errorMessage: state.errorMessage ?? "Có lỗi xảy ra"),
                    );
                  }

                  // Lời mời đang chờ trả lời luôn nằm trên cùng, kể cả khi chưa có lớp nào.
                  final invitations = state.invitations;
                  final invitationsSliver = invitations.isEmpty
                      ? null
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          sliver: SliverList.list(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10, left: 4),
                                child: Text(
                                  "Lời mời tham gia (${invitations.length}${state.invitationsPage.hasMore ? '+' : ''})",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              for (final invitation in invitations)
                                ClassInvitationCard(
                                  invitation: invitation,
                                  busy:
                                      state.isProcessing &&
                                      state.respondingClassId == invitation.classId,
                                  onAccept: () => context.read<ClassListBloc>().add(
                                    ClassInvitationResponded(
                                      classId: invitation.classId,
                                      accept: true,
                                      notify: true,
                                    ),
                                  ),
                                  onDecline: () => context.read<ClassListBloc>().add(
                                    ClassInvitationResponded(
                                      classId: invitation.classId,
                                      accept: false,
                                      notify: true,
                                    ),
                                  ),
                                ),
                              if (state.invitationsPage.hasMore)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: state.invitationsPage.isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: () => context.read<ClassListBloc>().add(
                                            ClassInvitationsMoreLoaded(),
                                          ),
                                          child: const Text('Tải thêm lời mời'),
                                        ),
                                ),
                            ],
                          ),
                        );

                  if (state.classes.isEmpty) {
                    if (invitationsSliver == null) {
                      return buildRefreshable(
                        const CommonEmpty(title: "Bạn chưa tham gia lớp học nào."),
                      );
                    }
                    return CommonRefresh(
                      onRefresh: onRefresh,
                      slivers: [
                        invitationsSliver,
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: CommonEmpty(title: "Bạn chưa tham gia lớp học nào."),
                        ),
                      ],
                    );
                  }

                  return CommonRefresh(
                    onRefresh: onRefresh,
                    controller: _scrollController,
                    slivers: [
                      ?invitationsSliver,
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 90),
                        sliver: SliverList.builder(
                          itemCount:
                              state.classes.length + (state.classesPage.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.classes.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                              );
                            }
                            final classModel = state.classes[index];
                            return ClassItemCard(
                              classModel: classModel,
                              onTap: () async {
                                await context.pushNamed(
                                  AppRoute.classroomDetail.name,
                                  pathParameters: {'id': classModel.id},
                                  extra: classModel.toJson(),
                                );
                                // Có thể đã rời / xóa lớp bên trong: làm mới danh sách khi quay lại.
                                if (context.mounted) {
                                  context.read<ClassListBloc>().add(ClassListLoaded());
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        height: 62,
        child: ElevatedButton.icon(
          onPressed: () => _showJoinModal(context),
          icon: const Icon(CupertinoIcons.add_circled_solid, color: Colors.white, size: 22),
          label: Text(
            "Nhập mã Tham gia Lớp",
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            elevation: 8,
            shadowColor: colorScheme.primary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
        ),
      ),
    );
  }
}
