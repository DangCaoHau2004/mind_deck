import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/shimmer_sweep.dart';
import 'package:mind_deck/ui/commons/skeleton_back_button.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/ui/commons/state_screens/common_empty.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_state.dart';
import 'package:mind_deck/ui/screens/deck/widgets/deck_item_widget.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'widgets/folder_detail_action_buttons.dart';
import 'widgets/folder_detail_decks_header.dart';
import 'widgets/folder_detail_header.dart';
import 'widgets/folder_detail_overlay_app_bar.dart';
import 'widgets/folder_detail_selection_bar.dart';
import 'widgets/folder_dialog_helper.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/native_ad_slot.dart';

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
  final ScrollController _scrollController = ScrollController();

  /// Chỉ báo "đang tìm" (vệt sáng + vòng xoay) chỉ hiện khi chờ quá 300ms để khỏi nháy khi mạng nhanh.
  static const Duration _searchIndicatorDelay = Duration(milliseconds: 300);
  Timer? _searchIndicatorTimer;
  bool _showSearchIndicator = false;
  int _lastListVersion = 0;

  @override
  void initState() {
    super.initState();
    currentFolder = widget.initialFolder;
    _scrollController.addListener(_onScroll);
    // Có sẵn thông tin thư mục từ danh sách thì phần đầu hiện ngay, danh sách bộ thẻ vẫn phải tải theo sắp xếp hiện tại
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FolderDetailBloc>().add(
        FolderDetailLoaded(widget.folderId, token: widget.token),
      );
    });
  }

  /// Gần cuối danh sách thì tải trang tiếp (bloc tự bỏ qua khi đang tải hoặc đã hết).
  void _onScroll() {
    if (_scrollController.position.extentAfter < 600) {
      context.read<FolderDetailBloc>().add(const FolderDetailDecksLoadMore());
    }
  }

  @override
  void dispose() {
    _searchIndicatorTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDeleteFolder() async {
    final confirmed = await FolderDialogHelper.showDeleteFolder(context, folder: currentFolder);
    if (confirmed == true && mounted) {
      context.read<FolderDetailBloc>().add(FolderDeleted(id: widget.folderId));
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

  /// Skeleton [count] thẻ bộ thẻ (tối thiểu 1, tối đa một trang 20).
  Widget _deckSkeletons(int count) {
    return Skeletonizer(
      child: Column(
        children: [
          for (var i = 0; i < count.clamp(1, 20); i++)
            DeckItemWidget(
              deck: DeckModel.placeholder(),
              showFolder: false,
              isSelected: false,
              isSelectionMode: false,
            ),
        ],
      ),
    );
  }

  /// Skeleton cả trang khi chưa có chút dữ liệu nào về thư mục (mở từ chip hoặc link chia sẻ).
  Widget _buildPageSkeleton() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                Skeletonizer(
                  child: FolderDetailHeader(
                    folder: FolderModel.placeholder(),
                    themeColor: Colors.blueGrey.shade200,
                    deckCount: 0,
                    actions: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Skeleton.leaf(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Ô tìm thật (không bị skeleton hóa), giống các tab Thư viện
                const FolderDetailDecksHeader(sort: 'due', showSpinner: false),
                _deckSkeletons(4),
              ],
            ),
          ),
          const SkeletonBackButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FolderDetailBloc, FolderDetailState>(
      listener: (context, state) {
        if (state.isSearching) {
          _searchIndicatorTimer ??= Timer(_searchIndicatorDelay, () {
            if (mounted) setState(() => _showSearchIndicator = true);
          });
        } else {
          _searchIndicatorTimer?.cancel();
          _searchIndicatorTimer = null;
          if (_showSearchIndicator) setState(() => _showSearchIndicator = false);
        }

        // Kết quả tìm/sắp xếp mới thay danh sách: cuộn nhẹ về đầu danh sách bộ thẻ
        if (state.listVersion != _lastListVersion) {
          _lastListVersion = state.listVersion;
          if (_scrollController.hasClients && _scrollController.offset > 0) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }

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
                    CustomToast.dismiss();
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
          previous.status != current.status ||
          previous.isSearching != current.isSearching ||
          previous.listVersion != current.listVersion,
      builder: (context, state) {
        final realFolder = state.folder ?? currentFolder;
        if (realFolder == null) return _buildPageSkeleton();

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
        // Đã tải chi tiết thì BE quyết định quyền sửa (canEdit); chưa thì suy từ thông tin sẵn có.
        final isFolderOwner = state.folder != null
            ? state.folder!.canEdit
            : (realFolder.isOwner || (currentUserId != null && realFolder.userId == currentUserId));

        final folderDeckCount = realFolder.deckCount ?? realFolder.decks?.length ?? 0;
        final themeColor = ColorUtils.parseHex(realFolder.color);
        final Color contentColor = ColorUtils.getContrastColor(themeColor);
        final folderDecks = state.decks;
        final bloc = context.read<FolderDetailBloc>();

        // Back bình thường trả về thông tin thư mục mới nhất để danh sách bên ngoài cập nhật tại chỗ
        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.pop(state.folder);
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // --- PULL TO REFRESH & SCROLLABLE CONTENT ---
                ShimmerScope(
                  active: _showSearchIndicator,
                  child: CommonRefresh(
                    controller: _scrollController,
                    onRefresh: () async {
                      bloc.add(FolderDetailRefreshed(widget.folderId, token: widget.token));
                      await bloc.stream.firstWhere((FolderDetailState s) => !s.isRefreshing);
                    },
                    slivers: [
                      // --- HEADER + NÚT HÀNH ĐỘNG (trôi lên khi cuộn) ---
                      SliverToBoxAdapter(
                        child: FolderDetailHeader(
                          folder: realFolder,
                          themeColor: themeColor,
                          deckCount: folderDeckCount,
                          actions: FolderDetailActionButtons(
                            folder: realFolder,
                            themeColor: themeColor,
                            contentColor: contentColor,
                            isFolderOwner: isFolderOwner,
                          ),
                        ),
                      ),

                      // Quảng cáo: một ô giữa nút hành động và danh sách bộ thẻ, không chen vào danh sách
                      SliverList(
                        delegate: SliverChildListDelegate([
                          const NativeAdSlot(
                            unit: AdUnit.nativeFolderDetail,
                            margin: EdgeInsets.fromLTRB(24, 0, 24, 8),
                          ),
                        ]),
                      ),

                      // --- BỘ THẺ ---
                      // Chưa có danh sách: skeleton đúng số bộ thẻ đã biết từ màn trước (tối đa một trang).
                      // Đã biết thư mục trống thì vào thẳng màn trống, không có gì để chờ.
                      // Tiêu đề, sắp xếp và ô tìm luôn hiện (kể cả lúc tải lần đầu), giống các tab Thư viện
                      SliverToBoxAdapter(
                        child: FolderDetailDecksHeader(
                          sort: state.sort,
                          showSpinner: _showSearchIndicator,
                        ),
                      ),
                      if (state.folder == null && currentFolder?.deckCount != 0)
                        SliverToBoxAdapter(child: _deckSkeletons(currentFolder?.deckCount ?? 4))
                      else ...[
                        if (folderDecks.isEmpty && state.isSearching && _showSearchIndicator)
                          // Danh sách trống mà đang tìm lại quá 300ms: skeleton (trước đó giữ màn trống)
                          SliverToBoxAdapter(child: _deckSkeletons(4))
                        else if (folderDecks.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: state.search.isNotEmpty
                                ? CommonEmpty.search(
                                    title: 'deck_empty_search_title'.tr,
                                    subtitle: 'deck_empty_search_subtitle'.tr,
                                  )
                                : CommonEmpty(
                                    icon: Icons.folder_open_rounded,
                                    title: 'folder_detail_empty_title'.tr,
                                    subtitle: isFolderOwner
                                        ? 'folder_detail_empty_subtitle'.tr
                                        : null,
                                  ),
                          )
                        else
                          SliverList.builder(
                            itemCount: folderDecks.length + (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= folderDecks.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final deck = folderDecks[index];
                              final isSelected = state.selectedDeckIds.contains(deck.id);

                              final card = ShimmerSweep(
                                child: DeckItemWidget(
                                  deck: deck,
                                  showFolder: false,
                                  isSelected: isSelected,
                                  isSelectionMode: state.isSelectionMode,
                                  onLongPress: isFolderOwner
                                      ? () => bloc.add(FolderDetailSelectionToggled(deck.id))
                                      : null,
                                  onTap: () async {
                                    if (state.isSelectionMode && isFolderOwner) {
                                      bloc.add(FolderDetailSelectionToggled(deck.id));
                                    } else {
                                      final result = await context.pushNamed(
                                        AppRoute.deckDetail.name,
                                        pathParameters: {'id': deck.id},
                                        extra: deck.toJson(),
                                      );
                                      if (result != null && context.mounted) {
                                        bloc.add(FolderDetailRefreshed(widget.folderId));
                                      }
                                    }
                                  },
                                ),
                              );

                              if (!isFolderOwner || state.isSelectionMode) return card;

                              return Dismissible(
                                key: ValueKey(deck.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  final confirmed =
                                      await FolderDialogHelper.showRemoveDeckFromFolder(
                                        context,
                                        deckName: deck.name,
                                      );
                                  return confirmed == true;
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 32),
                                  margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  bloc.add(
                                    FolderRemoveDecks(
                                      folderId: widget.folderId,
                                      deckIds: [deck.id],
                                    ),
                                  );
                                },
                                child: card,
                              );
                            },
                          ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),

                // --- FIXED OVERLAY APP BAR BUTTONS ---
                FolderDetailOverlayAppBar(
                  folder: realFolder,
                  folderId: widget.folderId,
                  token: widget.token,
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
          ),
        );
      },
    );
  }
}
