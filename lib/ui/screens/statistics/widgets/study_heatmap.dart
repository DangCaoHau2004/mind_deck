import 'package:flutter/material.dart';

class StudyHeatmap extends StatelessWidget {
  const StudyHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 14,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 70,
      itemBuilder: (context, index) {
        final intensity = (index % 5) + (index % 3);
        Color boxColor;

        if (intensity == 0) {
          boxColor = colorScheme.surfaceContainer;
        } else if (intensity < 3) {
          boxColor = colorScheme.primary.withValues(alpha: 0.3);
        } else if (intensity < 6) {
          boxColor = colorScheme.primary.withValues(alpha: 0.6);
        } else {
          boxColor = colorScheme.primary;
        }

        return Container(
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
