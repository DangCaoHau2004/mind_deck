import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/widgets/share_qr_widget.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_state.dart';

class ShareFolderDialog extends StatelessWidget {
  final FolderModel folder;
  final bool isOwner;

  const ShareFolderDialog({super.key, required this.folder, required this.isOwner});

  static Future<void> show(
    BuildContext context, {
    required FolderModel folder,
    required bool isOwner,
  }) {
    final bloc = context.read<FolderDetailBloc>();

    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ShareFolderDialog(folder: folder, isOwner: isOwner),
      ),
    );
  }

  static int getShareModeIndex(FolderModel folder) {
    final mode = folder.shareMode.toLowerCase();
    if (mode == 'private') {
      return 0; // Riêng tư
    }
    if (mode == 'restricted') {
      return 1; // Bất kỳ ai có liên kết
    }
    if (mode == 'public' || folder.isPublic) {
      return 2; // Công khai
    }
    if (folder.shareToken != null && folder.shareToken!.isNotEmpty) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FolderDetailBloc, FolderDetailState>(
      builder: (context, state) {
        final currentFolder = state.folder ?? folder;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final selectedValue = getShareModeIndex(currentFolder);
        final showQrSection =
            currentFolder.shareToken != null && currentFolder.shareToken!.isNotEmpty;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chia sẻ thư mục',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (isOwner) ...[
                    _ShareAccessOptions(currentFolder: currentFolder, selectedValue: selectedValue),
                    const SizedBox(height: 16),
                  ],

                  if (showQrSection)
                    _ShareQrSection(currentFolder: currentFolder)
                  else if (!isOwner)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Thư mục này không có liên kết chia sẻ.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccessOptionItem {
  final int value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _AccessOptionItem({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class _ShareAccessOptions extends StatelessWidget {
  final FolderModel currentFolder;
  final int selectedValue;

  const _ShareAccessOptions({required this.currentFolder, required this.selectedValue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      const _AccessOptionItem(
        value: 0,
        title: 'Riêng tư',
        subtitle: 'Chỉ bạn và những người được cấp quyền mới có thể truy cập',
        icon: Icons.lock_outline_rounded,
        iconColor: Color(0xFFE65100),
        iconBgColor: Color(0xFFFFF3E0),
      ),
      const _AccessOptionItem(
        value: 1,
        title: 'Bất kỳ ai có liên kết',
        subtitle: 'Bất kỳ ai có liên kết đều có thể truy cập',
        icon: Icons.link_rounded,
        iconColor: Color(0xFF1976D2),
        iconBgColor: Color(0xFFE3F2FD),
      ),
      const _AccessOptionItem(
        value: 2,
        title: 'Công khai',
        subtitle: 'Công khai với mọi người và xuất hiện trong mục Khám phá',
        icon: Icons.public_rounded,
        iconColor: Color(0xFF2E7D32),
        iconBgColor: Color(0xFFE8F5E9),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quyền truy cập',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...options.map((item) {
          final isSelected = selectedValue == item.value;
          return _buildOptionCard(
            context,
            item: item,
            isSelected: isSelected,
            onTap: () {
              String targetAccessLevel = 'private';
              if (item.value == 1) {
                targetAccessLevel = 'restricted';
              } else if (item.value == 2) {
                targetAccessLevel = 'public';
              }

              context.read<FolderDetailBloc>().add(
                FolderShareUpdated(
                  id: currentFolder.id,
                  accessLevel: targetAccessLevel,
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required _AccessOptionItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: item.iconBgColor, shape: BoxShape.circle),
                  child: Icon(item.icon, size: 20, color: item.iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareQrSection extends StatelessWidget {
  final FolderModel currentFolder;

  const _ShareQrSection({required this.currentFolder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (currentFolder.shareToken == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Center(
          child: Text(
            'Mã QR chia sẻ',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ShareQrWidget(
            targetType: 'folder',
            targetId: currentFolder.id,
            shareToken: currentFolder.shareToken!,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final String shareableLink =
                "minddeck://minddeck.com/library/folder/${currentFolder.id}?token=${currentFolder.shareToken}";

            Clipboard.setData(ClipboardData(text: shareableLink));
            CustomToast.show(context, CustomToast.success(message: 'Đã sao chép liên kết!'));
          },
          icon: Icon(Icons.copy_rounded, color: colorScheme.primary),
          label: Text(
            'Sao chép liên kết',
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
