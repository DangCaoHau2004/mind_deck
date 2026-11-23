import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/skeleton_back_button.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mind_deck/data/models/flashcard_model.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_event.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_state.dart';
import 'package:mind_deck/utils/color_utils.dart';
import 'widgets/deck_detail_action_buttons.dart';
import 'widgets/deck_detail_card_filter.dart';
import 'widgets/deck_detail_flashcard_item.dart';
import 'widgets/deck_detail_header.dart';
import 'widgets/deck_detail_fsrs_summary.dart';
import 'widgets/deck_detail_overlay_app_bar.dart';
import 'package:mind_deck/constants/ad_units.dart';
import 'package:mind_deck/ui/commons/ads/native_ad_slot.dart';

class DeckDetailScreen extends StatefulWidget {
  final String deckId;
  final DeckModel? initialDeck;
  final String? token;
  final String? classId;
  final String? assignmentId;

  /// Bản sao lớp: chỉ giảng viên được sửa; clone theo quyền của lớp (không dùng `deck.canClone`).
  final bool canEditClassCopy;
  final bool canCloneClassCopy;

  const DeckDetailScreen({
    super.key,
    required this.deckId,
    this.initialDeck,
    this.token,
    this.classId,
    this.assignmentId,
    this.canEditClassCopy = false,
    this.canCloneClassCopy = false,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  late DeckModel? currentDeck;
  final ScrollController _scrollController = ScrollController();

  // Tìm và lọc thẻ chạy trên máy (BE trả đủ mọi thẻ)
  final TextEditingController _cardSearchController = TextEditingController();
  String _cardQuery = '';
  CardState? _cardStateFilter;

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

  @override
  void dispose() {
    _scrollController.dispose();
    _cardSearchController.dispose();
    super.dispose();
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

  /// Skeleton [count] thẻ flashcard.
  Widget _cardSkeletons(int count) {
    return Skeletonizer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            DeckDetailFlashcardItem(cardData: FlashcardModel.placeholder()),
        ],
      ),
    );
  }

  /// Skeleton cả trang khi chưa có chút dữ liệu nào về bộ thẻ (mở từ chip hoặc link chia sẻ).
  Widget _buildPageSkeleton(ColorScheme colorScheme) {
    final placeholder = DeckModel.placeholder();
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Skeletonizer(
              child: Column(
                children: [
                  DeckDetailHeader(
                    deck: placeholder,
                    themeColor: Colors.blueGrey.shade200,
                    isOwner: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      children: [
                        DeckDetailFsrsSummary(deck: placeholder),
                        const SizedBox(height: 16),
                        Skeleton.leaf(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: _cardSkeletons(4),
                  ),
                ],
              ),
            ),
          ),
          const SkeletonBackButton(),
        ],
      ),
    );
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
                    CustomToast.dismiss();
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
        if (realDeck == null) return _buildPageSkeleton(colorScheme);
        // Dữ liệu đầy đủ chưa về mà người dùng đã bấm sao thì hiển thị theo lựa chọn đó
        final DeckModel deck = state.deck == null && state.starOverride != null
            ? realDeck.copyWith(isStarred: state.starOverride)
            : realDeck;

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
        final isDeckOwner = deck.isOwner || (currentUserId != null && deck.userId == currentUserId);

        final themeColor = ColorUtils.parseHex(deck.color);

        // Tìm theo mặt trước/mặt sau (không phân biệt hoa thường và dấu) rồi lọc theo trạng thái học
        final allCards = deck.flashcards ?? const [];
        final query = _cardQuery.trim().withoutDiacritics;
        final cards = allCards.where((c) {
          final state = c.progress?.state ?? CardState.newCard;
          if (_cardStateFilter != null && state != _cardStateFilter) return false;
          if (query.isEmpty) return true;
          return c.frontText.withoutDiacritics.contains(query) ||
              c.backText.withoutDiacritics.contains(query);
        }).toList();
        final stateCounts = <CardState, int>{};
        for (final c in allCards) {
          final state = c.progress?.state ?? CardState.newCard;
          stateCounts[state] = (stateCounts[state] ?? 0) + 1;
        }

        // Chưa có phản hồi API (đang dùng dữ liệu của màn danh sách, chưa có các thẻ): phần số liệu và danh
        // sách thẻ hiện skeleton. Số skeleton bằng số thẻ đã biết, tối đa 8.
        final bool cardsLoading = state.deck == null;
        final int cardSkeletonCount = (deck.cardCount ?? 4).clamp(0, 8);

        // Back bình thường: nếu đã đổi sao so với lúc mở từ danh sách thì trả bộ thẻ mới nhất về để danh sách
        // cập nhật tại chỗ; không đổi gì thì trả null như trước.
        final initialStarred = widget.initialDeck?.isStarred;
        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            context.pop(initialStarred != null && deck.isStarred != initialStarred ? deck : null);
          },
          child: Scaffold(
            backgroundColor: colorScheme.surfaceContainer,
            body: Stack(
              children: [
                // 1. LAYER 1: DANH SÁCH CUỘN VÀ NỘI DUNG (Hero Banner + Metadata + Flashcards)
                CommonRefresh(
                  controller: _scrollController,
                  onRefresh: () async {
                    final bloc = context.read<DeckDetailBloc>();
                    bloc.add(DeckDetailRefreshed(widget.deckId, token: widget.token));
                    await bloc.stream.firstWhere((DeckDetailState s) => !s.isRefreshing);
                  },
                  slivers: [
                    // PHẦN ĐẦU: hình, tên, thông tin, tag, thư mục chứa bộ thẻ, tác giả
                    SliverToBoxAdapter(
                      child: DeckDetailHeader(
                        deck: deck,
                        themeColor: themeColor,
                        isOwner: isDeckOwner,
                      ),
                    ),

                    // Trạng thái ghi nhớ (FSRS) và nút Kiểm tra / Flashcard
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Column(
                          children: [
                            Skeletonizer(
                              enabled: cardsLoading,
                              child: DeckDetailFsrsSummary(deck: deck),
                            ),
                            const SizedBox(height: 16),
                            DeckDetailActionButtons(
                              deck: deck,
                              classId: widget.classId,
                              assignmentId: widget.assignmentId,
                              isOwner: isDeckOwner,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quảng cáo: một ô giữa phần thông tin/nút hành động và danh sách thẻ, không chen vào danh sách
                    SliverList(
                      delegate: SliverChildListDelegate([
                        const NativeAdSlot(
                          unit: AdUnit.nativeDeckDetail,
                          margin: EdgeInsets.fromLTRB(24, 8, 24, 8),
                        ),
                      ]),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'deck_cards_title'.tr.replaceAll(
                                '{count}',
                                '${deck.cardCount ?? allCards.length}',
                              ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Skeletonizer(
                              enabled: cardsLoading,
                              child: DeckDetailCardFilter(
                                controller: _cardSearchController,
                                onQueryChanged: (v) => setState(() => _cardQuery = v),
                                counts: stateCounts,
                                total: allCards.length,
                                selected: _cardStateFilter,
                                onSelected: (v) => setState(() => _cardStateFilter = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // DANH SÁCH FLASHCARD
                    if (cardsLoading)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                        sliver: SliverToBoxAdapter(child: _cardSkeletons(cardSkeletonCount)),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => DeckDetailFlashcardItem(cardData: cards[index]),
                            childCount: cards.length,
                          ),
                        ),
                      ),
                  ],
                ),

                // CỤM NÚT ĐIỀU HƯỚNG CỐ ĐỊNH Ở ĐỈNH
                DeckDetailOverlayAppBar(
                  deck: deck,
                  realDeck: realDeck,
                  isDeckOwner: isDeckOwner,
                  canEditClassCopy: widget.canEditClassCopy,
                  canCloneClassCopy: widget.canCloneClassCopy,
                  deckId: widget.deckId,
                  token: widget.token,
                  onDeleteDeck: () => _handleDeleteDeck(deck),
                  onCloneDeck: () => _handleCloneDeck(deck),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
