import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/constants/app_icons.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_event.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_state.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'widgets/deck_detail_action_buttons.dart';
import 'widgets/deck_detail_expandable_tags.dart';
import 'widgets/deck_detail_flashcard_item.dart';
import 'widgets/deck_detail_fsrs_summary.dart';
import 'widgets/deck_detail_meta_header.dart';
import 'widgets/deck_detail_overlay_app_bar.dart';

class DeckDetailScreen extends StatefulWidget {
  final String deckId;
  final DeckModel? initialDeck;
  final String? token;
  final String? classId;
  final String? assignmentId;

  const DeckDetailScreen({
    super.key,
    required this.deckId,
    this.initialDeck,
    this.token,
    this.classId,
    this.assignmentId,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  late DeckModel? currentDeck;

  @override
  void initState() {
    super.initState();
    currentDeck = widget.initialDeck;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<DeckDetailBloc>();
      if (currentDeck == null) {
        bloc.add(DeckDetailLoaded(widget.deckId, token: widget.token));
      } else {
        bloc.add(DeckDetailRefreshed(widget.deckId, token: widget.token));
      }
    });
  }

  void _handleDeleteDeck(DeckModel deck) async {
    final bloc = context.read<DeckDetailBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa học phần'),
          content: Text(
            'Bạn có chắc chắn muốn xóa học phần "${deck.name}" không? Thao tác này không thể hoàn tác.',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      bloc.add(DeckDeleted(widget.deckId));
    }
  }

  void _handleCloneDeck(DeckModel deck) async {
    final bloc = context.read<DeckDetailBloc>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Nhân bản bộ thẻ'),
          content: Text(
            'Bạn có chắc chắn muốn tạo bản sao của bộ thẻ "${deck.name}" vào thư viện của bạn không?',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nhân bản'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      bloc.add(DeckDetailCloned(deck.id, token: widget.token));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<DeckDetailBloc, DeckDetailState>(
      listener: (context, state) {
        if (state.toastTriggerTime != null) {
          if (state.errorMessage != null) {
            CustomToast.show(context, CustomToast.danger(message: state.errorMessage!));
          } else if (state.successMessage != null) {
            if (state.clonedDeckId != null) {
              CustomToast.show(
                context,
                CustomToast.success(
                  message: state.successMessage!,
                  actionLabel: 'XEM',
                  onAction: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.pushNamed(
                      AppRoute.deckDetail.name,
                      pathParameters: {'id': state.clonedDeckId!},
                    );
                  },
                ),
              );
            } else {
              CustomToast.show(context, CustomToast.success(message: state.successMessage!));
            }
          }
        }
        if (state.status == DeckDetailStatus.deleted) {
          context.pop(state.successMessage);
        }
      },
      listenWhen: (previous, current) =>
          previous.toastTriggerTime != current.toastTriggerTime ||
          previous.status != current.status,
      builder: (context, state) {
        final realDeck = state.deck ?? currentDeck;
        if (realDeck == null) {
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainer,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        DeckModel deck = realDeck;

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
        final isDeckOwner = deck.isOwner || (currentUserId != null && deck.userId == currentUserId);

        final themeColor = ColorUtils.parseHex(deck.color);
        final bool isLight = ColorUtils.isLightColor(themeColor);
        final Color contentColor = ColorUtils.getContrastColor(themeColor);
        final IconData deckIcon = AppIcons.getIconFromKey(deck.icon);

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainer,
          body: Stack(
            children: [
              CommonRefresh(
                onRefresh: () async {
                  final bloc = context.read<DeckDetailBloc>();
                  bloc.add(DeckDetailRefreshed(widget.deckId, token: widget.token));
                  await bloc.stream.firstWhere((DeckDetailState s) => !s.isRefreshing);
                },
                slivers: [
                  // HEADER CONTAINER (Trôi hoàn toàn lên trên khi cuộn, không bị ghim vệt màu tím ở đỉnh)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 240.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [themeColor.withValues(alpha: 0.8), themeColor],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Transform.rotate(
                              angle: 0.2,
                              child: Icon(
                                deckIcon,
                                size: 250,
                                color: Colors.white.withValues(alpha: isLight ? 0.08 : 0.15),
                              ),
                            ),
                          ),
                          // Tiêu đề lớn (fontSize: 30), trôi theo màn hình khi cuộn
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 24,
                            child: Text(
                              deck.name,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: contentColor,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // BODY CONTENT
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // METADATA ROW & GOAL & AUTHOR
                          DeckDetailMetaHeader(deck: deck, mainThemeColor: themeColor),
                          const SizedBox(height: 16),

                          // EXPANDABLE TAGS
                          DeckDetailExpandableTags(tags: deck.tags ?? [], maxVisible: 3),
                          const SizedBox(height: 24),

                          // FSRS PROGRESS SUMMARY
                          DeckDetailFsrsSummary(deck: deck),
                          const SizedBox(height: 24),

                          // ACTION BUTTONS (KIỂM TRA & FLASHCARD)
                          DeckDetailActionButtons(
                            deck: deck,
                            mainThemeColor: themeColor,
                            classId: widget.classId,
                            assignmentId: widget.assignmentId,
                          ),
                          const SizedBox(height: 32),

                          // LIST CARD HEADER
                          Text(
                            'Danh sách Flashcard',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // FLASHCARD SLIVER LIST
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            DeckDetailFlashcardItem(cardData: deck.flashcards![index]),
                        childCount: deck.flashcards?.length ?? 0,
                      ),
                    ),
                  ),
                ],
              ),

              // FIXED OVERLAY APP BAR BUTTONS
              DeckDetailOverlayAppBar(
                deck: deck,
                realDeck: realDeck,
                isLight: isLight,
                contentColor: contentColor,
                isDeckOwner: isDeckOwner,
                deckId: widget.deckId,
                token: widget.token,
                onDeleteDeck: () => _handleDeleteDeck(deck),
                onCloneDeck: () => _handleCloneDeck(deck),
              ),
            ],
          ),
        );
      },
    );
  }
}
