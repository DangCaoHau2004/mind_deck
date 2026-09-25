import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'share_folder_dialog.dart';

class FolderDetailActionButtons extends StatelessWidget {
  final FolderModel folder;
  final Color themeColor;
  final Color contentColor;
  final bool isLight;
  final bool isFolderOwner;

  const FolderDetailActionButtons({
    super.key,
    required this.folder,
    required this.themeColor,
    required this.contentColor,
    required this.isLight,
    required this.isFolderOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.pushNamed(
                  AppRoute.testSetup.name,
                  extra: {"type": "folder", "data": folder.toJson()},
                );
              },
              icon: Icon(Icons.play_arrow_rounded, color: contentColor),
              label: const Text('Ôn tập thư mục'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: contentColor,
                elevation: isLight ? 1 : 2,
                side: isLight ? BorderSide(color: Colors.grey.shade300, width: 1) : null,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.05)
                  : themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: isLight ? Border.all(color: Colors.grey.shade300, width: 1) : null,
            ),
            child: IconButton(
              onPressed: () {
                ShareFolderDialog.show(
                  context,
                  folder: folder,
                  isOwner: isFolderOwner,
                );
              },
              icon: Icon(
                Icons.share_rounded,
                color: isLight ? Colors.black87 : themeColor,
                size: 28,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
