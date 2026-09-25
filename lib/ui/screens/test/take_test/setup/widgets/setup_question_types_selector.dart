import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_bloc.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_event.dart';
import 'package:mind_deck/ui/screens/test/take_test/bloc/test_setup_state.dart';

class SetupQuestionTypesSelector extends StatelessWidget {
  final TestSetupConfigState state;

  const SetupQuestionTypesSelector({super.key, required this.state});

  IconData _getIcon(TestQuestionType type) {
    switch (type) {
      case TestQuestionType.flashcard:
        return Icons.style_outlined;
      case TestQuestionType.multipleChoice:
        return Icons.checklist;
      case TestQuestionType.trueFalse:
        return Icons.fact_check_outlined;
      case TestQuestionType.fillInTheBlank:
        return Icons.edit_note;
      case TestQuestionType.dictation:
        return Icons.headphones_outlined;
      case TestQuestionType.matching:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final types = TestQuestionType.values;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final t = types[index];
        final isSelected = state.selectedQuestionTypes.contains(t);

        final activeColor = colorScheme.primary;
        final defaultColor = colorScheme.onSurface;
        final defaultIconColor = colorScheme.onSurfaceVariant;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final updated = Set<TestQuestionType>.from(state.selectedQuestionTypes);
              if (!isSelected) {
                updated.add(t);
              } else {
                updated.remove(t);
              }
              context.read<TestSetupBloc>().add(TestSetupQuestionTypesChanged(updated));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.08) : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? activeColor : colorScheme.outline.withValues(alpha: 0.15),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(t),
                    color: isSelected ? activeColor : defaultIconColor,
                    size: 26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? activeColor : defaultColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: defaultIconColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
