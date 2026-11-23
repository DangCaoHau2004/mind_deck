import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/test_settings_model.dart';

/// Form cài đặt đề phiên bản 2 (giờ bắt đầu / kết thúc KHÔNG ở đây mà ở bài giao).
/// Ràng buộc: bật `showAnswers` thì `showScore` tự bật; đề auto luôn đảo câu; bật giới hạn giờ cần số phút.
class TestSettingsForm extends StatelessWidget {
  final TestSettings settings;
  final ValueChanged<TestSettings> onChanged;

  /// Đề auto: luôn đảo + có chiều hỏi (`questionSide`).
  final bool isAuto;

  /// Đề đã có người làm: không sửa được cài đặt.
  final bool enabled;

  const TestSettingsForm({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.isAuto,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = settings;

    Widget switchTile(String title, String subtitle, bool value, ValueChanged<bool>? onChange) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        value: value,
        onChanged: enabled ? onChange : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switchTile(
          'Giới hạn thời gian',
          'Hết giờ thì bài tự động được nộp',
          s.timeLimitEnabled,
          (v) => onChanged(
            s.copyWith(
              timeLimitEnabled: v,
              timeLimitMinutes: v ? (s.timeLimitMinutes ?? 15) : null,
            ),
          ),
        ),
        if (s.timeLimitEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('Số phút:'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: enabled && (s.timeLimitMinutes ?? 15) > 1
                      ? () =>
                            onChanged(s.copyWith(timeLimitMinutes: (s.timeLimitMinutes ?? 15) - 1))
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text(
                  '${s.timeLimitMinutes ?? 15}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                IconButton(
                  onPressed: enabled && (s.timeLimitMinutes ?? 15) < 600
                      ? () =>
                            onChanged(s.copyWith(timeLimitMinutes: (s.timeLimitMinutes ?? 15) + 1))
                      : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
                const Text('(1–600)', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: [
            const Expanded(
              child: Text('Số lượt làm tối đa', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            IconButton(
              onPressed: enabled && s.attempts > 1
                  ? () => onChanged(s.copyWith(attempts: s.attempts - 1))
                  : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Text(
              '${s.attempts}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            IconButton(
              onPressed: enabled && s.attempts < 20
                  ? () => onChanged(s.copyWith(attempts: s.attempts + 1))
                  : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        if (s.attempts > 1) ...[
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: s.scorePolicy,
            decoration: const InputDecoration(
              labelText: 'Cách tính điểm bài giao khi làm lại',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: TestSettings.scoreHighest, child: Text('Lần cao nhất')),
              DropdownMenuItem(value: TestSettings.scoreLatest, child: Text('Lần gần nhất')),
              DropdownMenuItem(value: TestSettings.scoreFirst, child: Text('Lần đầu tiên')),
            ],
            onChanged: enabled ? (v) => onChanged(s.copyWith(scorePolicy: v)) : null,
          ),
        ],
        const Divider(),
        switchTile(
          'Hiện đúng/sai ngay từng câu',
          'Học viên biết đáp án sau mỗi câu trong lúc làm',
          s.showAnswerInstantly,
          (v) => onChanged(s.copyWith(showAnswerInstantly: v)),
        ),
        switchTile(
          'Cho xem điểm sau khi nộp',
          s.showAnswers
              ? 'Đang bật vì học viên được xem đáp án'
              : 'Tắt: điểm do giảng viên công bố',
          s.showScore || s.showAnswers,
          s.showAnswers ? null : (v) => onChanged(s.copyWith(showScore: v)),
        ),
        switchTile(
          'Cho xem đáp án chi tiết',
          'Bật sẽ tự bật xem điểm',
          s.showAnswers,
          (v) => onChanged(s.copyWith(showAnswers: v)),
        ),
        if (isAuto) ...[
          const Divider(),
          switchTile('Đảo thứ tự câu', 'Đề tự động luôn được đảo ngẫu nhiên', true, null),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: s.questionSide,
            decoration: const InputDecoration(
              labelText: 'Chiều hỏi',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: TestSettings.sideFront, child: Text('Mặt trước → mặt sau')),
              DropdownMenuItem(value: TestSettings.sideBack, child: Text('Mặt sau → mặt trước')),
              DropdownMenuItem(value: TestSettings.sideMixed, child: Text('Trộn hai chiều')),
            ],
            onChanged: enabled ? (v) => onChanged(s.copyWith(questionSide: v)) : null,
          ),
        ] else
          switchTile(
            'Đảo thứ tự câu và đáp án',
            'Đảo câu, đáp án trắc nghiệm và hai cột ghép cặp (không đảo đúng/sai)',
            s.shuffle,
            (v) => onChanged(s.copyWith(shuffle: v)),
          ),
      ],
    );
  }
}
