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
  @override
  void initState() {
    super.initState();
    if (widget.initialJoinCode != null && widget.initialJoinCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showJoinModal(context, initialCode: widget.initialJoinCode);
      });
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
              child: BlocBuilder<ClassListBloc, ClassListState>(
                builder: (context, state) {
                  Widget buildRefreshable(Widget child) {
                    return CommonRefresh(
                      onRefresh: () async {
                        final bloc = context.read<ClassListBloc>();
                        bloc.add(ClassListLoaded());
                        await bloc.stream.firstWhere((s) => s.status != ClassListStatus.loading);
                      },
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

                  if (state.classes.isEmpty) {
                    return buildRefreshable(
                      const CommonEmpty(title: "Bạn chưa tham gia lớp học nào."),
                    );
                  }

                  return CommonRefresh(
                    onRefresh: () async {
                      final bloc = context.read<ClassListBloc>();
                      bloc.add(ClassListLoaded());
                      await bloc.stream.firstWhere((s) => s.status != ClassListStatus.loading);
                    },
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 90),
                        sliver: SliverList.builder(
                          itemCount: state.classes.length,
                          itemBuilder: (context, index) {
                            final classModel = state.classes[index];
                            return ClassItemCard(
                              classModel: classModel,
                              onTap: () {
                                context.pushNamed(
                                  AppRoute.classroomDetail.name,
                                  pathParameters: {'id': classModel.id},
                                  extra: classModel.toJson(),
                                );
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
