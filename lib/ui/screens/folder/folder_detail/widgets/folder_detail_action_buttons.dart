import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'add_decks_to_folder_screen.dart';

/// Nút "Ôn tập thư mục" (kèm số thẻ đến hạn hôm nay) và nút "+" thêm bộ thẻ vào thư mục.
class FolderDetailActionButtons extends StatelessWidget {
  final FolderModel folder;
  final Color themeColor;
  final Color contentColor;

  /// Có quyền sửa thư mục (chủ sở hữu): được thêm/gỡ bộ thẻ và ôn tập.
  final bool isFolderOwner;

  const FolderDetailActionButtons({
    super.key,
    required this.folder,
    required this.themeColor,
    required this.contentColor,
    required this.isFolderOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Đề cá nhân chỉ lấy thẻ của deck cá nhân của chính mình.
    final canMakePersonalTest = isFolderOwner && !folder.isClassCopy;
    final dueCount = folder.dueCount ?? 0;
    if (!canMakePersonalTest) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.pushNamed(
                  AppRoute.testSetup.name,
                  extra: {"type": "folder", "data": folder.toJson()},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: contentColor,
                elevation: 6,
                shadowColor: themeColor.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: contentColor, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'folder_review'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: contentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (dueCount > 0)
                        Text(
                          'folder_due_today'.tr.replaceAll('{count}', '$dueCount'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: contentColor.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (sheetContext) => BlocProvider.value(
                    value: context.read<FolderDetailBloc>(),
                    child: FractionallySizedBox(
                      heightFactor: 0.9,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: AddDecksToFolderScreen(folderId: folder.id),
                      ),
                    ),
                  ),
                );
              },
              icon: Icon(Icons.add_rounded, color: themeColor, size: 28),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
