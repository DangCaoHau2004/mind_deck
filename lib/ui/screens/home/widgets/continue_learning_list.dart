import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/theme/app_styles.dart';
import 'package:mind_deck/data/models/home/home_continue_session_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_dialog.dart';
import 'package:mind_deck/ui/screens/home/bloc/home_bloc.dart';
import 'package:mind_deck/ui/screens/home/bloc/home_event.dart';
import 'package:mind_deck/utils/study_flow_helper.dart';

/// Khối "Đang học dở": tối đa 3 phiên flashcard / bài kiểm tra bỏ dở, bấm để học tiếp.
/// Phiên flashcard có nút bỏ phiên.
class ContinueLearningList extends StatelessWidget {
  final List<HomeContinueSession> items;

  const ContinueLearningList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ContinueCard(item: item),
          ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final HomeContinueSession item;

  const _ContinueCard({required this.item});

  void _open(BuildContext context) {
    final study = item.study;
    if (study != null) {
      // Theo bộ thẻ: `start` tự tiếp tục phiên dở; nhiều nguồn: mở lại đúng phiên đó.
      StudyFlowHelper.start(
        context: context,
        deckId: study.isDeck ? study.deckId : null,
        sessionId: study.isDeck ? null : study.sessionId,
      );
      return;
    }
    final test = item.test!;
    if (test.isAssignment) {
      context.pushNamed(
        AppRoute.classTest.name,
        pathParameters: {
          'classId': test.classId ?? '',
          'assignmentId': test.assignmentId ?? '',
          'testId': test.testId,
        },
      );
    } else {
      context.pushNamed(
        AppRoute.testSetup.name,
        extra: {'resumeSessionId': test.sessionId, 'resumeTestId': test.testId},
      );
    }
  }

  Future<void> _confirmDismiss(BuildContext context) async {
    final bloc = context.read<HomeBloc>();
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await CustomDialog.show<bool>(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: colorScheme.error,
      iconBackgroundColor: colorScheme.error.withValues(alpha: 0.1),
      title: 'home_continue_dismiss_title'.tr,
      description: 'home_continue_dismiss_desc'.tr,
      cancelText: 'home_continue_dismiss_cancel'.tr,
      confirmText: 'home_continue_dismiss_confirm'.tr,
      confirmButtonColor: colorScheme.error,
      confirmTextColor: Colors.white,
    );
    if (confirmed == true) bloc.add(HomeContinueSessionDismissed(item.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final study = item.study;
    final test = item.test;

    final String title;
    final String kind;
    final String count;
    final double progress;
    if (study != null) {
      title = study.isDeck
          ? (study.deckName ?? '')
          : 'home_continue_review_cards'.tr.replaceAll('{count}', '${study.totalCards}');
      kind = 'home_continue_kind_flashcard'.tr;
      count = 'home_continue_count_cards'.tr
          .replaceAll('{learned}', '${study.learnedCount}')
          .replaceAll('{total}', '${study.totalCards}');
      progress = study.progress;
    } else {
      title = test!.displayName;
      final className = test.className;
      kind = test.isAssignment && className != null && className.isNotEmpty
          ? className
          : 'home_continue_kind_test'.tr;
      count = 'home_continue_count_questions'.tr
          .replaceAll('{answered}', '${test.answeredCount}')
          .replaceAll('{total}', '${test.totalQuestions}');
      progress = test.progress;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppStyles.cardShadow(colorScheme),
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _open(context),
          // Phiên flashcard: nhấn giữ để bỏ phiên (card không còn chỗ cho nút riêng).
          onLongPress: study != null ? () => _confirmDismiss(context) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          color: colorScheme.primary,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$kind · '),
                            TextSpan(
                              text: count,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'home_continue_action'.tr,
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
