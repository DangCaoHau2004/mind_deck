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
  final bool isLight;
  final Color contentColor;
  final bool isDeckOwner;
  final String deckId;
  final String? token;
  final VoidCallback onDeleteDeck;
  final VoidCallback onCloneDeck;

  const DeckDetailOverlayAppBar({
    super.key,
    required this.deck,
    required this.realDeck,
    required this.isLight,
    required this.contentColor,
    required this.isDeckOwner,
    required this.deckId,
    this.token,
    required this.onDeleteDeck,
    required this.onCloneDeck,
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
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      right: 16,
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
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

            // Action buttons (Star, Share & More Options)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCircleButton(
                  isLight: isLight,
                  child: IconButton(
                    icon: Icon(
                      deck.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: deck.isStarred ? Colors.amber : contentColor,
                    ),
                    iconSize: 32,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () {
                      context.read<DeckDetailBloc>().add(DeckDetailStarToggled(deck.id));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _buildCircleButton(
                  isLight: isLight,
                  child: IconButton(
                    icon: Icon(Icons.share_rounded, color: contentColor),
                    iconSize: 20,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
                    onPressed: () {
                      ShareDeckDialog.show(context, deck: realDeck, isOwner: isDeckOwner);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _buildCircleButton(
                  isLight: isLight,
                  child: IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: contentColor),
                    iconSize: 20,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
                    onPressed: () => DeckDetailOptionsBottomSheet.show(
                      context,
                      deck: deck,
                      deckId: deckId,
                      token: token,
                      isDeckOwner: isDeckOwner,
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
