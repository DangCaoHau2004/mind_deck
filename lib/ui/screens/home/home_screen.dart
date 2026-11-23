import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/home/home_data_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/ads/native_ad_slot.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/home/bloc/home_bloc.dart';
import 'package:mind_deck/ui/screens/home/bloc/home_event.dart';
import 'package:mind_deck/ui/screens/home/bloc/home_state.dart';
import 'package:mind_deck/ui/screens/home/widgets/accuracy_chart_card.dart';
import 'package:mind_deck/ui/screens/home/widgets/classroom_card.dart';
import 'package:mind_deck/ui/screens/home/widgets/continue_learning_list.dart';
import 'package:mind_deck/ui/screens/home/widgets/home_header.dart';
import 'package:mind_deck/ui/screens/home/widgets/home_section_header.dart';
import 'package:mind_deck/ui/screens/home/widgets/recent_learning_list.dart';
import 'package:mind_deck/ui/screens/home/widgets/review_today_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          // Mỗi lần gọi BE lỗi thì báo bằng toast; màn vẫn giữ skeleton hoặc dữ liệu cũ.
          listenWhen: (previous, current) => current.failureCount != previous.failureCount,
          listener: (context, state) {
            final failure = state.failure;
            if (failure == null) return;
            CustomToast.show(context, CustomToast.danger(message: failure.displayMessage));
          },
          builder: (context, state) {
            // Chưa có dữ liệu (đang tải lần đầu hoặc tải lỗi): dựng giao diện bằng dữ liệu khuôn
            // rồi phủ skeleton; kéo để làm mới vẫn dùng được.
            final data = state.data;
            return _buildContent(
              context,
              data ?? HomeDataModel.placeholder(),
              loading: data == null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeDataModel data, {required bool loading}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<HomeBloc>();
        bloc.add(const HomeRefreshed());
        await bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Skeletonizer(
                enabled: loading,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHeader(user: data.user),
                    const SizedBox(height: 20),
                    ReviewTodayCard(stats: data.fsrsStats),
                    const SizedBox(height: 16),
                    AccuracyChartCard(stats: data.fsrsStats),
                  ],
                ),
              ),
              NativeAdSlot(
                unit: AdUnit.nativeHome,
                margin: const EdgeInsets.only(top: 20),
                visible: !loading,
              ),
              Skeletonizer(
                enabled: loading,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.continueSessions.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      HomeSectionHeader(title: 'home_continue_title'.tr),
                      const SizedBox(height: 12),
                      ContinueLearningList(items: data.continueSessions),
                    ],
                    const SizedBox(height: 28),
                    HomeSectionHeader(title: 'home_recent_title'.tr),
                    const SizedBox(height: 12),
                    RecentLearningList(items: data.recentDecks),
                    const SizedBox(height: 28),
                    HomeSectionHeader(
                      title: 'home_classes_title'.tr,
                      actionLabel: data.hasMoreClasses
                          ? 'home_see_all_count'.tr.replaceAll('{count}', '${data.classesTotal}')
                          : 'home_see_all'.tr,
                      onTap: () => context.pushNamed(AppRoute.classrooms.name),
                    ),
                    const SizedBox(height: 12),
                    if (data.classes.isEmpty)
                      Text(
                        'home_classes_empty'.tr,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                      )
                    else
                      for (final room in data.classes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClassroomCard(room: room),
                        ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
