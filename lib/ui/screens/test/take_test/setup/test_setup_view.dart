import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/widgets/setup_source_selector.dart';
import 'package:mind_deck/ui/screens/test/take_test/setup/widgets/setup_settings_card.dart';

class TestSetupView extends StatefulWidget {
  final TestSetupConfigState state;

  const TestSetupView({super.key, required this.state});

  @override
  State<TestSetupView> createState() => _TestSetupViewState();
}

class _TestSetupViewState extends State<TestSetupView> {
  final TextEditingController _testNameController = TextEditingController();

  @override
  void dispose() {
    _testNameController.dispose();
    super.dispose();
  }

  void _showTestNameInputDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    _testNameController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tên bài ôn tập'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nhập tên bài ôn tập (Để trống để tự tạo tên theo thời gian):',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _testNameController,
                decoration: InputDecoration(
                  hintText: 'VD: Ôn tập từ vựng Unit 1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _testNameController.text.trim();
                Navigator.of(dialogContext).pop();
                context.read<TestSetupBloc>().add(
                  TestSetupGenerateRequested(name: name.isEmpty ? null : name),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Bắt đầu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = widget.state;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // 1. QUESTION SOURCE SELECTOR
        SetupSourceSelector(state: state),
        const SizedBox(height: 32),

        // 2. TEST CONFIGURATION
        Row(
          children: [
            Icon(Icons.settings_suggest_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cấu hình bài thi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SetupSettingsCard(state: state),
        const SizedBox(height: 32),

        // 3. ACTION BUTTON
        _buildSubmitButton(context, state, theme, colorScheme),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    TestSetupConfigState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isGenerating = state.isGenerating;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: isGenerating ? null : () => _showTestNameInputDialog(context),
        child: isGenerating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'BẮT ĐẦU ÔN TẬP',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
