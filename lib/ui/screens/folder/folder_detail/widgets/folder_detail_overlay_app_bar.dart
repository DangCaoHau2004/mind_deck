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
  final bool isFolderOwner;
  final VoidCallback onDeleteFolder;
  final VoidCallback onCloneFolder;

  const FolderDetailOverlayAppBar({
    super.key,
    required this.folder,
    required this.folderId,
    this.token,
    required this.isFolderOwner,
    required this.onDeleteFolder,
    required this.onCloneFolder,
  });

  Widget _buildCircleButton({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
    const iconColor = Colors.white;

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
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: iconColor),
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(10),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),

            // Chia sẻ + menu tuỳ chọn
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bản sao lớp không chia sẻ được (BE từ chối)
                if (!folder.isClassCopy) ...[
                  _buildCircleButton(
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: iconColor),
                      iconSize: 18,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(10),
                      onPressed: () =>
                          ShareFolderDialog.show(context, folder: folder, isOwner: isFolderOwner),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildCircleButton(
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: iconColor),
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
                                CustomToast.show(context, CustomToast.success(message: result));
                                context.read<FolderDetailBloc>().add(
                                  FolderDetailRefreshed(folderId, token: token),
                                );
                              }
                            });
                      } else if (value == 'delete') {
                        onDeleteFolder();
                      } else if (value == 'clone') {
                        onCloneFolder();
                      }
                    },
                    itemBuilder: (context) => [
                      if (folder.canClone && !folder.isClassCopy)
                        PopupMenuItem(
                          value: 'clone',
                          child: Row(
                            children: [
                              const Icon(Icons.copy_all_rounded, color: Colors.black87, size: 22),
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
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
