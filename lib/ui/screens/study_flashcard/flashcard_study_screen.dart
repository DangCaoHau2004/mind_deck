import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/ui/screens/study_flashcard/bloc/flashcard_study_bloc.dart';
import 'package:mind_deck/ui/screens/study_flashcard/bloc/flashcard_study_event.dart';
import 'package:mind_deck/ui/screens/study_flashcard/bloc/flashcard_study_state.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/state_screens/common_loading.dart';
import 'package:mind_deck/ui/commons/state_screens/common_failure.dart';
import 'widgets/flashcard_study_card_view.dart';
import 'widgets/flashcard_study_progress_badge.dart';
import 'widgets/flashcard_study_settings_modal.dart';
import 'widgets/flashcard_study_completed_view.dart';
import 'package:mind_deck/utils/study_flow_helper.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  const FlashcardStudyScreen({super.key, this.onCompleted});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> with WidgetsBindingObserver {
  bool _isFlipped = false;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (mounted) {
        context.read<FlashcardStudyBloc>().add(SyncProgressEvent(immediate: true));
      }
    }
  }

  void _flipCard() => setState(() => _isFlipped = !_isFlipped);

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    final threshold = MediaQuery.of(context).size.width * 0.3;

    if (_dragPosition.dx > threshold) {
      _performSwipe(direction: 1);
    } else if (_dragPosition.dx < -threshold) {
      _performSwipe(direction: -1);
    } else {
      setState(() => _dragPosition = Offset.zero);
    }
  }

  void _performSwipe({required int direction}) {
    final bloc = context.read<FlashcardStudyBloc>();
    setState(() => _dragPosition = Offset(direction * 800.0, 0));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      bloc.add(SwipeCardEvent(direction));
      setState(() {
        _isFlipped = false;
        _dragPosition = Offset.zero;
      });
    });
  }

  void _handleUndo() {
    context.read<FlashcardStudyBloc>().add(UndoSwipeEvent());
    setState(() {
      _isFlipped = false;
      _dragPosition = Offset.zero;
    });
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tạm dừng phiên học?'),
        content: const Text(
          'Tiến trình học của bạn đã được tự động lưu. Bạn có chắc chắn muốn thoát?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text('Tiếp tục học', style: TextStyle(color: theme.colorScheme.outline)),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<FlashcardStudyBloc, FlashcardStudyState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == StudyStatus.completed && widget.onCompleted != null) {
          widget.onCompleted!();
        } else if (state.status == StudyStatus.error && state.errorMessage != null) {
          CustomToast.show(context, CustomToast.danger(message: state.errorMessage!));
        }
      },
      builder: (context, state) {
        if (state.status == StudyStatus.loading || state.status == StudyStatus.initial) {
          return const Scaffold(body: CommonLoading());
        }

        if (state.status == StudyStatus.error) {
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CommonFailure(errorMessage: state.errorMessage),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state.status == StudyStatus.completed) {
          return FlashcardStudyCompletedView(
            cards: state.cards,
            onRetry: () {
              final deckId = state.cards.firstOrNull?.deckId;
              if (deckId != null && deckId.isNotEmpty) {
                StudyFlowHelper.start(context: context, deckId: deckId, replace: true);
              } else {
                final cardIds = state.cards.map((c) => c.id).toList();
                StudyFlowHelper.start(context: context, cardIds: cardIds, replace: true);
              }
            },
            onBack: () => context.pop(),
          );
        }

        final currentCard = state.currentCard;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _showExitConfirmationDialog(context);
            if (shouldPop && context.mounted) {
              context.read<FlashcardStudyBloc>().add(SyncProgressEvent(immediate: true));
              context.pop();
            }
          },
          child: Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainer,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
                onPressed: () async {
                  final shouldPop = await _showExitConfirmationDialog(context);
                  if (shouldPop && context.mounted) {
                    context.read<FlashcardStudyBloc>().add(SyncProgressEvent(immediate: true));
                    context.pop();
                  }
                },
              ),
              title: Column(
                children: [
                  Text(
                    'Ôn tập Flashcard',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.currentIndex + 1} / ${state.currentRoundCards.length}',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_rounded, color: theme.colorScheme.onSurface),
                  onPressed: () {
                    context.read<FlashcardStudyBloc>().add(SyncProgressEvent(immediate: true));
                    FlashcardStudySettingsModal.show(
                      context,
                      isShuffleMode: state.isShuffleMode,
                      showBackFirst: state.showBackFirst,
                      onShuffleChanged: (val) =>
                          context.read<FlashcardStudyBloc>().add(ToggleShuffleEvent(val)),
                      onShowBackFirstChanged: (val) =>
                          context.read<FlashcardStudyBloc>().add(ToggleShowBackFirstEvent(val)),
                      onResetCards: () => context.read<FlashcardStudyBloc>().add(ResetCardsEvent()),
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FlashcardStudyProgressBadge(
                              count: state.unlearnedCount,
                              color: Colors.red,
                              showPlusOne: _isDragging && _dragPosition.dx < -50,
                              isLeft: true,
                            ),
                            FlashcardStudyProgressBadge(
                              count: state.learnedCount,
                              color: Colors.green,
                              showPlusOne: _isDragging && _dragPosition.dx > 50,
                              isLeft: false,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: currentCard != null
                                ? TweenAnimationBuilder<Offset>(
                                    key: ValueKey(currentCard.id),
                                    tween: Tween<Offset>(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero,
                                    ),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, offset, child) =>
                                        FractionalTranslation(translation: offset, child: child),
                                    child: GestureDetector(
                                      onPanUpdate: _onPanUpdate,
                                      onPanEnd: _onPanEnd,
                                      onTap: _flipCard,
                                      child: AnimatedContainer(
                                        duration: _isDragging
                                            ? Duration.zero
                                            : const Duration(milliseconds: 300),
                                        curve: Curves.easeOutBack,
                                        transform: Matrix4.identity()
                                          ..translateByDouble(
                                            _dragPosition.dx,
                                            _dragPosition.dy,
                                            0.0,
                                            1.0,
                                          )
                                          ..rotateZ(_dragPosition.dx / 1500),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(begin: 0, end: _isFlipped ? 180 : 0),
                                          duration: const Duration(milliseconds: 300),
                                          builder: (context, value, child) {
                                            final isPhysicalFront = value < 90;
                                            final showDataFront = isPhysicalFront
                                                ? !state.showBackFirst
                                                : state.showBackFirst;

                                            return Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()
                                                ..setEntry(3, 2, 0.001)
                                                ..rotateY(value * pi / 180),
                                              child: isPhysicalFront
                                                  ? FlashcardStudyCardView(
                                                      card: currentCard,
                                                      isFront: showDataFront,
                                                      isDragging: _isDragging,
                                                      dragPosition: _dragPosition,
                                                    )
                                                  : Transform(
                                                      alignment: Alignment.center,
                                                      transform: Matrix4.identity()..rotateY(pi),
                                                      child: FlashcardStudyCardView(
                                                        card: currentCard,
                                                        isFront: showDataFront,
                                                        isDragging: _isDragging,
                                                        dragPosition: _dragPosition,
                                                      ),
                                                    ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                : CircularProgressIndicator(
                                    color: theme.colorScheme.primary,
                                    strokeWidth: 3,
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0, right: 32.0, top: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FloatingActionButton(
                            onPressed: state.canUndo ? _handleUndo : null,
                            backgroundColor: state.canUndo
                                ? theme.colorScheme.surface
                                : theme.colorScheme.surfaceContainerHighest,
                            elevation: state.canUndo ? 2 : 0,
                            shape: const CircleBorder(),
                            child: Icon(
                              Icons.replay_rounded,
                              color: state.canUndo
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.status == StudyStatus.submitting)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(child: CircularProgressIndicator()),
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
