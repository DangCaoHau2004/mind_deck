import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_class_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';

class DiscoverClassroomCard extends StatelessWidget {
  final DiscoverySuggestedClassModel item;

  const DiscoverClassroomCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final colorVal = item.id.hashCode & 0xFFFFFF;
    final classColor = Color(colorVal).withValues(alpha: 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: () {
            if (item.isJoined) {
              context.pushNamed(AppRoute.classroomDetail.name, pathParameters: {'id': item.id});
            } else {
              context.pushNamed(AppRoute.classJoin.name, queryParameters: {'code': item.joinCode});
            }
          },
          child: Container(
            width: 280,
            margin: const EdgeInsets.only(right: 14, bottom: 6),
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 160 / 255),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: classColor.withValues(alpha: 60 / 255), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  classColor.withValues(alpha: 20 / 255),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isJoined)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: classColor.withValues(alpha: 20 / 255),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: classColor.withValues(alpha: 50 / 255)),
                        ),
                        child: Text(
                          'Đã tham gia',
                          style: textTheme.labelSmall?.copyWith(
                            color: classColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Divider(color: colorScheme.outline.withValues(alpha: 30 / 255), height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.ownerName ?? 'Ẩn danh',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_alt_outlined, size: 16, color: classColor),
                        const SizedBox(width: 4),
                        Text(
                          '${item.memberCount}',
                          style: textTheme.labelSmall?.copyWith(
                            color: classColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
