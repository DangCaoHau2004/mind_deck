import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/widgets/setup_question_types_selector.dart';

class SetupSettingsCard extends StatefulWidget {
  final TestSetupConfigState state;

  const SetupSettingsCard({super.key, required this.state});

  @override
  State<SetupSettingsCard> createState() => _SetupSettingsCardState();
}

class _SetupSettingsCardState extends State<SetupSettingsCard> {
  late final TextEditingController _timeLimitController;
  late final FocusNode _timeLimitFocusNode;

  @override
  void initState() {
    super.initState();
    _timeLimitController = TextEditingController(text: '${widget.state.timeLimitMinutes}');
    _timeLimitFocusNode = FocusNode();
    _timeLimitFocusNode.addListener(() {
      if (!_timeLimitFocusNode.hasFocus) {
        _submitTimeLimit();
      }
    });
  }

  void _submitTimeLimit() {
    final val = int.tryParse(_timeLimitController.text) ?? 15;
    if (val < 1) {
      _timeLimitController.text = '1';
      context.read<TestSetupBloc>().add(const TestSetupSettingsChanged(timeLimitMinutes: 1));
    } else {
      context.read<TestSetupBloc>().add(TestSetupSettingsChanged(timeLimitMinutes: val));
    }
  }

  @override
  void didUpdateWidget(covariant SetupSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_timeLimitFocusNode.hasFocus &&
        _timeLimitController.text != '${widget.state.timeLimitMinutes}') {
      _timeLimitController.text = '${widget.state.timeLimitMinutes}';
    }
  }

  @override
  void dispose() {
    _timeLimitController.dispose();
    _timeLimitFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = widget.state;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Time Limit
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giới hạn thời gian',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Thời gian làm cho toàn bài thi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.timeLimitEnabled,
                activeThumbColor: colorScheme.primary,
                onChanged: (val) {
                  context.read<TestSetupBloc>().add(
                    TestSetupSettingsChanged(timeLimitEnabled: val),
                  );
                },
              ),
            ],
          ),
          if (state.timeLimitEnabled) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: state.timeLimitMinutes > 1
                      ? () {
                          final newVal = state.timeLimitMinutes - 1;
                          _timeLimitController.text = '$newVal';
                          context.read<TestSetupBloc>().add(
                            TestSetupSettingsChanged(timeLimitMinutes: newVal),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    _timeLimitFocusNode.requestFocus();
                  },
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _timeLimitFocusNode.hasFocus
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _timeLimitController,
                          focusNode: _timeLimitFocusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onSubmitted: (val) => _submitTimeLimit(),
                          onChanged: (val) {
                            final newVal = int.tryParse(val);
                            if (newVal != null && newVal >= 1) {
                              context.read<TestSetupBloc>().add(
                                TestSetupSettingsChanged(timeLimitMinutes: newVal),
                              );
                            }
                          },
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phút',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  onPressed: () {
                    final newVal = state.timeLimitMinutes + 1;
                    _timeLimitController.text = '$newVal';
                    context.read<TestSetupBloc>().add(
                      TestSetupSettingsChanged(timeLimitMinutes: newVal),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],

          const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Divider()),

          // 2. Question Side Selector
          Text(
            'Chiều câu hỏi',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildQuestionSideSelector(context, state, theme, colorScheme),

          const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Divider()),

          // 3. Instant feedback switch
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hiển thị đáp án ngay',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Hiển thị giải thích/đáp án sau mỗi câu',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.showAnswerInstantly,
                activeThumbColor: colorScheme.primary,
                onChanged: (val) {
                  context.read<TestSetupBloc>().add(
                    TestSetupSettingsChanged(showAnswerInstantly: val),
                  );
                },
              ),
            ],
          ),

          const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Divider()),

          // 4. Question types selector
          Text(
            'Dạng câu hỏi',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SetupQuestionTypesSelector(state: state),
        ],
      ),
    );
  }

  Widget _buildQuestionSideSelector(
    BuildContext context,
    TestSetupConfigState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final sides = [
      {'key': 'front', 'label': 'Hỏi Mặt trước', 'desc': 'Hiện Mặt trước -> Tìm Mặt sau'},
      {'key': 'back', 'label': 'Hỏi Mặt sau', 'desc': 'Hiện Mặt sau -> Tìm Mặt trước'},
      {'key': 'mixed', 'label': 'Hỗn hợp', 'desc': 'Mặt trước và Mặt sau ngẫu nhiên'},
    ];

    return Column(
      children: sides.map((s) {
        final isSelected = state.questionSide == s['key'];
        // ignore: deprecated_member_use
        return RadioListTile<String>(
          value: s['key']!,
          // ignore: deprecated_member_use
          groupValue: state.questionSide,
          activeColor: colorScheme.primary,
          contentPadding: EdgeInsets.zero,
          title: Text(
            s['label']!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            s['desc']!,
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          // ignore: deprecated_member_use
          onChanged: (val) {
            if (val != null) {
              context.read<TestSetupBloc>().add(TestSetupSettingsChanged(questionSide: val));
            }
          },
        );
      }).toList(),
    );
  }
}
