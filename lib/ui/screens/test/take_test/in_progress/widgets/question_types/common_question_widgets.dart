import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mind_deck/utils/image_url_utils.dart';
import 'package:mind_deck/data/models/image_search_model.dart';
import 'package:mind_deck/ui/commons/image_screens/image_credit_line.dart';

Widget buildPromptContainer(
  BuildContext context,
  String prompt,
  String? imageUrl, [
  ImageCredit? imageCredit,
]) {
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
                child: Icon(Icons.image_not_supported_rounded, color: colorScheme.outline),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ImageCreditLine(credit: imageCredit, textAlign: TextAlign.center),
          const SizedBox(height: 16),
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
