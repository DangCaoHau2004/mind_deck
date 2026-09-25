import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/repositories/stats_repository.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/commons/state_screens/common_loading.dart';
import 'package:mind_deck/ui/screens/profile/stats_overview/bloc/stats_overview_bloc.dart';
import 'package:mind_deck/ui/screens/profile/stats_overview/bloc/stats_overview_event.dart';
import 'package:mind_deck/ui/screens/profile/stats_overview/bloc/stats_overview_state.dart';
import 'package:mind_deck/ui/screens/profile/stats_overview/widgets/stats_widgets.dart';

class StatsOverviewScreen extends StatelessWidget {
  const StatsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StatsOverviewBloc(repository: DI().sl<StatsRepository>())
            ..add(const StatsOverviewLoadStarted()),
      child: const _StatsOverviewView(),
    );
  }
}

class _StatsOverviewView extends StatelessWidget {
  const _StatsOverviewView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Thống kê tổng quan',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: CommonRefresh(
        onRefresh: () async {
          final bloc = context.read<StatsOverviewBloc>();
          bloc.add(const StatsOverviewLoadStarted());
          await bloc.stream.firstWhere((s) => s is! StatsOverviewLoading);
        },
        slivers: [
          BlocBuilder<StatsOverviewBloc, StatsOverviewState>(
            builder: (context, state) {
              if (state is StatsOverviewLoading) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: CommonLoading(),
                );
              }

              if (state is StatsOverviewFailure) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: CommonFailure(errorMessage: state.errorMessage),
                );
              }

              if (state is StatsOverviewSuccess) {
                final data = state.stats;

                if (data.heatmap.isEmpty &&
                    data.futureReviews.isEmpty &&
                    data.difficultCards.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: CommonEmpty(title: 'Chưa có đủ dữ liệu học tập'),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(12.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      StreakSection(streak: data.streak),
                      const SizedBox(height: 24),
                      HeatmapSection(data: data.heatmap),
                      const SizedBox(height: 24),
                      AccuracySection(data: data.accuracy),
                      const SizedBox(height: 24),
                      FutureReviewsSection(data: data.futureReviews),
                      const SizedBox(height: 24),
                      DifficultCardsSection(data: data.difficultCards),
                    ]),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }
}
