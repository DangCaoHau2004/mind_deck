import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_event.dart';

import 'deck_detail_options_bottom_sheet.dart';
import 'share_deck_dialog.dart';

class DeckDetailOverlayAppBar extends StatelessWidget {
  final DeckModel deck;
  final DeckModel realDeck;
  final bool isDeckOwner;
  final bool canEditClassCopy;
  final bool canCloneClassCopy;
  final String deckId;
  final String? token;
  final VoidCallback onDeleteDeck;
  final VoidCallback onCloneDeck;

  const DeckDetailOverlayAppBar({
    super.key,
    required this.deck,
    required this.realDeck,
    required this.isDeckOwner,
    this.canEditClassCopy = false,
    this.canCloneClassCopy = false,
    required this.deckId,
    this.token,
    required this.onDeleteDeck,
    required this.onCloneDeck,
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
    final topPadding = MediaQuery.of(context).padding.top;
    const activeIconColor = Colors.white;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            _buildCircleButton(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: activeIconColor),
                iconSize: 18,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(9),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),

            // Action buttons (Star, Share & More Options)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bản sao lớp không gắn sao / chia sẻ được (BE từ chối).
                if (!deck.isClassCopy) ...[
                  _buildCircleButton(
                    child: IconButton(
                      icon: Icon(
                        deck.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: deck.isStarred ? Colors.amber : activeIconColor,
                      ),
                      iconSize: 22,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(7),
                      onPressed: () {
                        context.read<DeckDetailBloc>().add(
                          DeckDetailStarToggled(deck.id, isStarred: deck.isStarred),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: activeIconColor),
                      iconSize: 18,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(9),
                      onPressed: () {
                        ShareDeckDialog.show(context, deck: realDeck, isOwner: isDeckOwner);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildCircleButton(
                  child: IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, color: activeIconColor),
                    iconSize: 19,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(9),
                    onPressed: () => DeckDetailOptionsBottomSheet.show(
                      context,
                      deck: deck,
                      deckId: deckId,
                      token: token,
                      isDeckOwner: isDeckOwner,
                      canEditClassCopy: canEditClassCopy,
                      canCloneClassCopy: canCloneClassCopy,
                      onDeleteDeck: onDeleteDeck,
                      onCloneDeck: onCloneDeck,
                    ),
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
