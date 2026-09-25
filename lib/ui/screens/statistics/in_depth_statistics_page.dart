import 'package:flutter/material.dart';

import 'widgets/chart_card.dart';
import 'widgets/daily_accuracy_chart.dart';
import 'widgets/difficult_words_list.dart';
import 'widgets/forgetting_curve_chart.dart';
import 'widgets/future_reviews_bar_chart.dart';
import 'widgets/overview_cards.dart';
import 'widgets/study_heatmap.dart';

class InDepthStatisticsPage extends StatelessWidget {
  const InDepthStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thống kê chuyên sâu',
          style: theme.textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OverviewCards(),
            const SizedBox(height: 24),

            const ChartCard(
              title: 'Đường cong quên lãng',
              subtitle: 'Khả năng truy xuất (R) theo thời gian',
              child: ForgettingCurveChart(),
            ),
            const SizedBox(height: 24),

            const ChartCard(
              title: 'Dự đoán ôn tập',
              subtitle: 'Thẻ đến hạn (Due cards) 7 ngày tới',
              child: FutureReviewsBarChart(),
            ),
            const SizedBox(height: 24),

            const ChartCard(
              title: 'Độ chính xác',
              subtitle: 'Tỷ lệ bấm Good/Easy so với Again',
              child: DailyAccuracyChart(),
            ),
            const SizedBox(height: 24),

            const ChartCard(
              title: 'Tần suất học tập',
              subtitle: 'Hoạt động trong 10 tuần qua',
              child: StudyHeatmap(),
            ),
            const SizedBox(height: 24),

            const DifficultWordsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
