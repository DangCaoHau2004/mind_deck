import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_state.dart';
import 'package:mind_deck/ui/screens/deck/widgets/deck_item_widget.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'widgets/folder_detail_action_buttons.dart';
import 'widgets/folder_detail_decks_header.dart';
import 'widgets/folder_detail_overlay_app_bar.dart';
import 'widgets/folder_detail_selection_bar.dart';
import 'widgets/folder_dialog_helper.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  final FolderModel? initialFolder;
  final String? token;

  const FolderDetailScreen({super.key, required this.folderId, this.initialFolder, this.token});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late FolderModel? currentFolder;

  @override
  void initState() {
    super.initState();
    currentFolder = widget.initialFolder;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<FolderDetailBloc>();
      if (currentFolder == null) {
        bloc.add(FolderDetailLoaded(widget.folderId, token: widget.token));
      } else {
        bloc.add(FolderDetailRefreshed(widget.folderId, token: widget.token));
      }
    });
  }

  void _handleDeleteFolder() async {
    final folderDeckCount = currentFolder?.deckCount ?? currentFolder?.decks?.length ?? 0;
    final deleteOption = await FolderDialogHelper.showDeleteFolder(
      context,
      folder: currentFolder,
      deckCount: folderDeckCount,
    );
    if (deleteOption != null && mounted) {
      final bloc = context.read<FolderDetailBloc>();
      if (deleteOption == 0) {
        bloc.add(FolderDeleted(id: widget.folderId, keepDecks: false));
      } else if (deleteOption == 1) {
        bloc.add(FolderDeleted(id: widget.folderId, keepDecks: true));
      }
    }
  }

  void _handleCloneFolder(FolderModel folder) async {
    final confirmed = await FolderDialogHelper.showCloneFolder(context, folder: folder);
    if (confirmed == true && mounted) {
      context.read<FolderDetailBloc>().add(
        FolderDetailCloned(widget.folderId, token: widget.token),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<FolderDetailBloc, FolderDetailState>(
      listener: (context, state) {
        if (state.toastTriggerTime != null) {
          if (state.errorMessage != null) {
            CustomToast.show(context, CustomToast.danger(message: state.errorMessage!));
          } else if (state.successMessage != null) {
            if (state.clonedFolderId != null) {
              CustomToast.show(
                context,
                CustomToast.success(
                  message: state.successMessage!,
                  actionLabel: 'XEM',
                  onAction: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.pushNamed(
                      AppRoute.folderDetail.name,
                      pathParameters: {'id': state.clonedFolderId!},
                    );
                  },
                ),
              );
            } else {
              CustomToast.show(context, CustomToast.success(message: state.successMessage!));
            }
          }
        }
        if (state.status == FolderDetailStatus.deleted) {
          context.pop(state.successMessage);
        }
      },
      listenWhen: (previous, current) =>
          previous.toastTriggerTime != current.toastTriggerTime ||
          previous.status != current.status,
      builder: (context, state) {
        final realFolder = state.folder ?? currentFolder;
        if (realFolder == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
        final isFolderOwner =
            realFolder.isOwner || (currentUserId != null && realFolder.userId == currentUserId);

        final folderName = realFolder.name;
        final folderDeckCount = realFolder.deckCount ?? realFolder.decks?.length ?? 0;

        final themeColor = ColorUtils.parseHex(realFolder.color);
        final bool isLight = ColorUtils.isLightColor(themeColor);
        final Color contentColor = ColorUtils.getContrastColor(themeColor);
        final Color subTextColor = isLight ? Colors.black54 : Colors.white.withValues(alpha: 0.85);

        IconData folderIcon = AppIcons.getIconFromKey(realFolder.icon);
        final folderDecks = realFolder.decks ?? [];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // --- PULL TO REFRESH & SCROLLABLE CONTENT ---
              CommonRefresh(
                onRefresh: () async {
                  final bloc = context.read<FolderDetailBloc>();
                  bloc.add(FolderDetailRefreshed(widget.folderId, token: widget.token));
                  await bloc.stream.firstWhere((FolderDetailState s) => !s.isRefreshing);
                },
                slivers: [
                  // --- HEADER CONTAINER (Trôi hoàn toàn lên trên khi cuộn) ---
                  SliverToBoxAdapter(
                    child: Container(
                      height: 240.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [themeColor.withValues(alpha: 0.85), themeColor],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Icon(
                              folderIcon,
                              size: 250,
                              color: contentColor.withValues(alpha: 0.15),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 24,
                            right: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isLight
                                        ? Colors.black.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(folderIcon, color: contentColor, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  folderName,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: contentColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$folderDeckCount bộ thẻ',
                                  style: theme.textTheme.titleSmall?.copyWith(color: subTextColor),
                                ),
                                if (realFolder.authorName != null &&
                                    realFolder.authorName!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black.withValues(alpha: 0.1),
                                        child: Icon(Icons.person, size: 14, color: contentColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tác giả: ${realFolder.authorName}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: contentColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- ACTIONS BARS ---
                  SliverToBoxAdapter(
                    child: FolderDetailActionButtons(
                      folder: realFolder,
                      themeColor: themeColor,
                      contentColor: contentColor,
                      isLight: isLight,
                      isFolderOwner: isFolderOwner,
                    ),
                  ),

                  // --- BỘ THẺ ---
                  if (folderDecks.isNotEmpty) ...[
                    FolderDetailDecksHeader(
                      title: 'Bộ thẻ trong thư mục',
                      folderId: widget.folderId,
                      isFolderOwner: isFolderOwner,
                    ),
                    SliverList.builder(
                      itemCount: folderDecks.length,
                      itemBuilder: (context, index) {
                        final deck = folderDecks[index];
                        final isSelected = state.selectedDeckIds.contains(deck.id);

                        final card = DeckItemWidget(
                          deck: deck,
                          isSelected: isSelected,
                          isSelectionMode: state.isSelectionMode,
                          onLongPress: isFolderOwner
                              ? () {
                                  context.read<FolderDetailBloc>().add(
                                    FolderDetailSelectionToggled(deck.id),
                                  );
                                }
                              : null,
                          onTap: () async {
                            if (state.isSelectionMode && isFolderOwner) {
                              context.read<FolderDetailBloc>().add(
                                FolderDetailSelectionToggled(deck.id),
                              );
                            } else {
                              final result = await context.pushNamed(
                                AppRoute.deckDetail.name,
                                pathParameters: {'id': deck.id},
                                extra: deck.toJson(),
                              );
                              if (result != null && context.mounted) {
                                context.read<FolderDetailBloc>().add(
                                  FolderDetailRefreshed(widget.folderId),
                                );
                              }
                            }
                          },
                        );

                        if (!isFolderOwner || state.isSelectionMode) return card;

                        return Dismissible(
                          key: ValueKey(deck.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final confirmed = await FolderDialogHelper.showRemoveDeckFromFolder(
                              context,
                              deckName: deck.name,
                            );
                            return confirmed == true;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 32),
                            margin: const EdgeInsets.only(top: 16, bottom: 12),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          onDismissed: (direction) {
                            context.read<FolderDetailBloc>().add(
                              FolderRemoveDecks(folderId: widget.folderId, deckIds: [deck.id]),
                            );
                          },
                          child: card,
                        );
                      },
                    ),
                  ] else if (state.folder == null) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ] else ...[
                    FolderDetailDecksHeader(
                      title: 'Bộ thẻ trong thư mục',
                      folderId: widget.folderId,
                      isFolderOwner: isFolderOwner,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Thư mục này chưa có bộ thẻ nào',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),

              // --- FIXED OVERLAY APP BAR BUTTONS ---
              FolderDetailOverlayAppBar(
                folder: realFolder,
                folderId: widget.folderId,
                token: widget.token,
                contentColor: contentColor,
                isLight: isLight,
                isFolderOwner: isFolderOwner,
                onDeleteFolder: _handleDeleteFolder,
                onCloneFolder: () => _handleCloneFolder(realFolder),
              ),

              // --- BATCH SELECTION BAR ---
              if (state.isSelectionMode)
                FolderDetailSelectionBar(
                  folderId: widget.folderId,
                  selectedDeckIds: state.selectedDeckIds,
                ),
            ],
          ),
        );
      },
    );
  }
}
