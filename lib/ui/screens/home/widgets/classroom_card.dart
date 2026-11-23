import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/home/home_class_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/core/theme/app_styles.dart';

/// Thẻ một lớp học kèm hoạt động nổi bật (bài tập / bộ thẻ mới / không có).
class ClassroomCard extends StatelessWidget {
  final HomeClassModel room;

  const ClassroomCard({super.key, required this.room});

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final a = room.activity;

    final IconData icon;
    final Color color;
    final String text;
    String? detail;
    Color? detailColor;
    switch (a.type) {
      case HomeActivityType.assignment:
        icon = Icons.assignment_outlined;
        color = colorScheme.primary;
        text = a.title.isEmpty
            ? 'home_class_assignment_untitled'.tr
            : 'home_class_assignment'.tr.replaceAll('{title}', a.title);
        final end = a.endAt;
        if (end != null) {
          final time = '${_two(end.hour)}:${_two(end.minute)}';
          if (a.endsToday) {
            detail = 'home_class_ends_today'.tr.replaceAll('{time}', time);
            detailColor = colorScheme.error;
          } else {
            detail = 'home_class_deadline'.tr.replaceAll(
              '{date}',
              '$time ${_two(end.day)}/${_two(end.month)}',
            );
            detailColor = colorScheme.outline;
          }
        }
      case HomeActivityType.newDecks:
        icon = Icons.library_add_outlined;
        color = colorScheme.tertiary;
        text = 'home_class_new_decks'.tr.replaceAll('{count}', '${a.count}');
      case HomeActivityType.none:
        icon = Icons.schedule_rounded;
        color = colorScheme.outline;
        text = 'home_class_no_activity'.tr;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyles.cardShadow(colorScheme),
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              context.pushNamed(AppRoute.classroomDetail.name, pathParameters: {'id': room.id}),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.groups_rounded, color: colorScheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(icon, size: 18, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              text,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Luôn chừa dòng hạn (để trống khi không có) để mọi thẻ lớp cao bằng nhau.
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          detail ?? ' ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: detailColor,
                            fontWeight: a.endsToday ? FontWeight.w600 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
