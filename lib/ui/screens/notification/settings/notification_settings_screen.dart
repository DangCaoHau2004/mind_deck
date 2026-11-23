import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/user_notification_settings_model.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'package:mind_deck/ui/commons/state_screens/common_loading.dart';
import 'package:mind_deck/ui/screens/notification/settings/bloc/notification_settings_bloc.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<NotificationSettingsBloc>()..add(const NotificationSettingsLoadStarted()),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: BlocConsumer<NotificationSettingsBloc, NotificationSettingsState>(
        listenWhen: (prev, curr) =>
            curr is NotificationSettingsLoaded &&
            curr.notice != null &&
            (prev is! NotificationSettingsLoaded || prev.noticeId != curr.noticeId),
        listener: (context, state) {
          final notice = (state as NotificationSettingsLoaded).notice;
          if (notice != null) CustomToast.show(context, CustomToast.danger(message: notice));
        },
        builder: (context, state) {
          if (state is NotificationSettingsLoading || state is NotificationSettingsInitial) {
            return const CommonLoading();
          }
          if (state is NotificationSettingsFailure) {
            return CommonFailure(errorMessage: state.error);
          }
          if (state is NotificationSettingsLoaded) {
            return _SettingsList(settings: state.settings);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  final UserNotificationSettingsModel settings;
  const _SettingsList({required this.settings});

  void _change(
    BuildContext context,
    Map<String, dynamic> changes,
    UserNotificationSettingsModel optimistic,
  ) {
    context.read<NotificationSettingsBloc>().add(
      NotificationSettingsChanged(changes: changes, optimistic: optimistic),
    );
  }

  TimeOfDay _parse(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _label(String value) {
    final t = _parse(value);
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(
    BuildContext context, {
    required String current,
    required void Function(String hhmm) onPicked,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: _parse(current));
    if (picked == null) return;
    onPicked(
      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = settings.isAllNotificationsEnabled;
    final classAll = settings.isAllClassNotificationsEnabled;
    final types = settings.classNotificationTypes;

    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Nhận thông báo'),
          subtitle: const Text('Công tắc tổng cho mọi loại thông báo'),
          value: all,
          onChanged: (v) => _change(context, {
            'isAllNotificationsEnabled': v,
          }, settings.copyWith(isAllNotificationsEnabled: v)),
        ),
        _section(context, 'NHẮC HỌC'),
        SwitchListTile(
          title: const Text('Động lực buổi sáng'),
          subtitle: Text('Gửi lúc ${_label(settings.morningTime)}'),
          value: settings.isMorningMotivationEnabled,
          onChanged: all
              ? (v) => _change(context, {
                  'isMorningMotivationEnabled': v,
                }, settings.copyWith(isMorningMotivationEnabled: v))
              : null,
        ),
        ListTile(
          enabled: all && settings.isMorningMotivationEnabled,
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: const Text('Giờ nhận buổi sáng'),
          trailing: Text(_label(settings.morningTime)),
          onTap: () => _pickTime(
            context,
            current: settings.morningTime,
            onPicked: (hhmm) =>
                _change(context, {'morningTime': hhmm}, settings.copyWith(morningTime: '$hhmm:00')),
          ),
        ),
        SwitchListTile(
          title: const Text('Thẻ đến hạn ôn'),
          subtitle: const Text('Nhắc cố định lúc 20:00 theo giờ máy'),
          value: settings.isSrsDueEnabled,
          onChanged: all
              ? (v) =>
                    _change(context, {'isSrsDueEnabled': v}, settings.copyWith(isSrsDueEnabled: v))
              : null,
        ),
        SwitchListTile(
          title: const Text('Hẹn giờ học mỗi ngày'),
          subtitle: Text(
            settings.isStudyReminderEnabled
                ? 'Nhắc lúc ${_label(settings.studyTime)} (gộp cả thẻ đến hạn)'
                : 'Tắt',
          ),
          value: settings.isStudyReminderEnabled,
          onChanged: all
              ? (v) => _change(context, {
                  'isStudyReminderEnabled': v,
                }, settings.copyWith(isStudyReminderEnabled: v))
              : null,
        ),
        ListTile(
          enabled: all && settings.isStudyReminderEnabled,
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: const Text('Giờ học'),
          trailing: Text(_label(settings.studyTime)),
          onTap: () => _pickTime(
            context,
            current: settings.studyTime,
            onPicked: (hhmm) =>
                _change(context, {'studyTime': hhmm}, settings.copyWith(studyTime: '$hhmm:00')),
          ),
        ),
        SwitchListTile(
          title: const Text('Cảnh báo sắp mất chuỗi'),
          subtitle: const Text('Nhắc cố định lúc 21:00 khi hôm nay chưa học'),
          value: settings.isStreakWarningEnabled,
          onChanged: all
              ? (v) => _change(context, {
                  'isStreakWarningEnabled': v,
                }, settings.copyWith(isStreakWarningEnabled: v))
              : null,
        ),
        _section(context, 'LỚP HỌC'),
        SwitchListTile(
          title: const Text('Thông báo từ lớp học'),
          subtitle: const Text('Áp dụng cho tất cả các lớp'),
          value: classAll,
          onChanged: all
              ? (v) => _change(context, {
                  'isAllClassNotificationsEnabled': v,
                }, settings.copyWith(isAllClassNotificationsEnabled: v))
              : null,
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: const Text('Bài tập & kiểm tra'),
          value: types.assignment,
          onChanged: all && classAll
              ? (v) => _change(context, {
                  'classNotificationTypes': {'assignment': v},
                }, settings.copyWith(classNotificationTypes: types.copyWith(assignment: v)))
              : null,
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: const Text('Thông báo chung của lớp'),
          value: types.announcement,
          onChanged: all && classAll
              ? (v) => _change(context, {
                  'classNotificationTypes': {'announcement': v},
                }, settings.copyWith(classNotificationTypes: types.copyWith(announcement: v)))
              : null,
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: const Text('Yêu cầu vào lớp'),
          value: types.joinRequest,
          onChanged: all && classAll
              ? (v) => _change(context, {
                  'classNotificationTypes': {'joinRequest': v},
                }, settings.copyWith(classNotificationTypes: types.copyWith(joinRequest: v)))
              : null,
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: const Text('Được duyệt vào lớp'),
          value: types.joinApproved,
          onChanged: all && classAll
              ? (v) => _change(context, {
                  'classNotificationTypes': {'joinApproved': v},
                }, settings.copyWith(classNotificationTypes: types.copyWith(joinApproved: v)))
              : null,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
