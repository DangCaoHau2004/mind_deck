import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItem({super.key, required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Icon based on type
    IconData getIcon() {
      switch (notification.type.value) {
        case 'class_invite':
        case 'class_invite_response':
        case 'class_join_request':
        case 'class_join_approved':
          return Icons.group_add_rounded;
        case 'class_member_left':
          return Icons.person_remove_rounded;
        case 'class_assignment':
          return Icons.assignment_rounded;
        case 'class_test_start':
          return Icons.quiz_rounded;
        case 'class_announcement':
          return Icons.campaign_rounded;
        case 'class_submission':
          return Icons.task_alt_rounded;
        case 'class_update':
          return Icons.school_rounded;
        case 'srs_due':
          return Icons.style_rounded;
        case 'daily_study_time':
          return Icons.alarm_rounded;
        case 'report_resolved':
          return Icons.mark_chat_read_rounded;
        case 'streak_warning':
          return Icons.local_fire_department_rounded;
        case 'morning_motivation':
          return Icons.wb_sunny_rounded;
        case 'system':
          return Icons.system_update_rounded;
        default:
          return Icons.notifications_rounded;
      }
    }

    // Color based on type
    Color getIconColor() {
      switch (notification.type.value) {
        case 'class_invite':
        case 'class_invite_response':
        case 'class_join_request':
        case 'class_join_approved':
          return Colors.green;
        case 'class_member_left':
          return Colors.red;
        case 'class_assignment':
        case 'class_test_start':
        case 'class_submission':
          return Colors.blue;
        case 'class_announcement':
        case 'class_update':
          return Colors.purple;
        case 'srs_due':
        case 'daily_study_time':
        case 'streak_warning':
          return Colors.orange;
        default:
          return colorScheme.primary;
      }
    }

    return Opacity(
      opacity: notification.isClassUnavailable ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: notification.isRead
              ? Colors.transparent
              : colorScheme.primary.withValues(alpha: 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: getIconColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(getIcon(), color: getIconColor(), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6, left: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
