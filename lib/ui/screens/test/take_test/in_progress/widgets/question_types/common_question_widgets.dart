import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

String getImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final baseUrl = ApiEndpoints.url;
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return '$baseUrl$cleanPath';
}

Widget buildPromptContainer(
  BuildContext context,
  String prompt,
  String? imageUrl,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: getImageUrl(imageUrl),
              height: 140,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 140,
                color: colorScheme.surfaceContainer,
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: colorScheme.outline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          prompt,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
