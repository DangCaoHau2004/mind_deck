import 'package:flutter/material.dart';

class OverviewCards extends StatelessWidget {
  const OverviewCards({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _SmallStatCard(
            icon: Icons.local_fire_department_rounded,
            value: '14 Ngày',
            label: 'Streak',
            iconColor: Colors.orange.shade700,
            bgColor: Colors.orange.shade50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SmallStatCard(
            icon: Icons.psychology_rounded,
            value: '87%',
            label: 'Ghi nhớ',
            iconColor: colorScheme.primary,
            bgColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color bgColor;

  const _SmallStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
