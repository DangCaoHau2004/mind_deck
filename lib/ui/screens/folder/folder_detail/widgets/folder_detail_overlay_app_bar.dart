import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';
import 'share_folder_dialog.dart';

class FolderDetailOverlayAppBar extends StatelessWidget {
  final FolderModel folder;
  final String folderId;
  final String? token;
  final Color contentColor;
  final bool isLight;
  final bool isFolderOwner;
  final VoidCallback onDeleteFolder;
  final VoidCallback onCloneFolder;

  const FolderDetailOverlayAppBar({
    super.key,
    required this.folder,
    required this.folderId,
    this.token,
    required this.contentColor,
    required this.isLight,
    required this.isFolderOwner,
    required this.onDeleteFolder,
    required this.onCloneFolder,
  });

  Widget _buildCircleButton({required Widget child, required bool isLight}) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      right: 16,
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            _buildCircleButton(
              isLight: isLight,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: contentColor),
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(10),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),

            // More Options Popup Menu
            _buildCircleButton(
              isLight: isLight,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: contentColor),
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                offset: const Offset(0, 50),
                onSelected: (value) {
                  if (value == 'edit') {
                    context
                        .pushNamed(
                          AppRoute.folderEdit.name,
                          pathParameters: {'id': folderId},
                          extra: folder.toJson(),
                        )
                        .then((result) {
                          if (result != null && result is String && context.mounted) {
                            CustomToast.show(
                              context,
                              CustomToast.success(message: result),
                            );
                            context.read<FolderDetailBloc>().add(
                              FolderDetailRefreshed(folderId),
                            );
                          }
                        });
                  } else if (value == 'delete') {
                    onDeleteFolder();
                  } else if (value == 'share') {
                    ShareFolderDialog.show(
                      context,
                      folder: folder,
                      isOwner: isFolderOwner,
                    );
                  } else if (value == 'clone') {
                    onCloneFolder();
                  }
                },
                itemBuilder: (context) => [
                  if (folder.canClone)
                    PopupMenuItem(
                      value: 'clone',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.copy_all_rounded,
                            color: Colors.black87,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text('Nhân bản', style: theme.textTheme.titleSmall),
                        ],
                      ),
                    ),
                  if (isFolderOwner) ...[
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, color: Colors.black87, size: 22),
                          const SizedBox(width: 12),
                          Text('Chỉnh sửa', style: theme.textTheme.titleSmall),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Xóa thư mục',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.share_rounded,
                            color: Colors.black87,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text('Chia sẻ', style: theme.textTheme.titleSmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
