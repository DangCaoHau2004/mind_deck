import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/commons/deck_illustration.dart';
import 'package:mind_deck/ui/commons/goal_type_pill.dart';
import 'package:mind_deck/ui/commons/info_chip.dart';
import 'deck_detail_expandable_tags.dart';
import 'deck_detail_folders.dart';

/// Phần đầu màn chi tiết bộ thẻ: nền nhạt theo màu bộ thẻ, hình bộ thẻ và tên, các viên thông tin
/// (công khai, số thẻ, mục tiêu), tag, thư mục chứa bộ thẻ (chỉ chủ sở hữu) và tác giả.
class DeckDetailHeader extends StatelessWidget {
  final DeckModel deck;
  final Color themeColor;
  final bool isOwner;

  const DeckDetailHeader({
    super.key,
    required this.deck,
    required this.themeColor,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardCount = deck.cardCount ?? deck.flashcards?.length ?? 0;
    final author = deck.authorName;
    final tags = deck.tags ?? const [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
        24,
        24,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(themeColor.withValues(alpha: 0.14), Colors.white),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DeckIllustration(
                color: themeColor,
                icon: AppIcons.getIconFromKey(deck.icon),
                size: 84,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    deck.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InfoChip(
                icon: deck.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                text: deck.isPublic
                    ? 'deck_public_saved'.tr.replaceAll('{count}', '${deck.savedCount}')
                    : 'library_private'.tr,
              ),
              InfoChip(text: 'deck_card_count'.tr.replaceAll('{count}', '$cardCount')),
              GoalTypePill(goalType: deck.goalType),
              if (deck.goalType == GoalType.shortTerm && deck.deadline != null)
                InfoChip(
                  icon: Icons.event_rounded,
                  text: DateFormat('dd/MM/yyyy').format(deck.deadline!),
                ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            DeckDetailExpandableTags(tags: tags, maxVisible: 3),
          ],
          // Chỉ chủ sở hữu có danh sách thư mục chứa bộ thẻ
          if (isOwner) ...[const SizedBox(height: 16), DeckDetailFolders(folders: deck.folders)],
          if (author != null && author.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: themeColor.withValues(alpha: 0.15),
                  child: Icon(Icons.person, size: 14, color: themeColor),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Tác giả: $author',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
