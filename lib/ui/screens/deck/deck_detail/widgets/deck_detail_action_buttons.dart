import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/utils/study_flow_helper.dart';

class DeckDetailActionButtons extends StatefulWidget {
  final DeckModel deck;
  final Color mainThemeColor;
  final String? classId;
  final String? assignmentId;

  const DeckDetailActionButtons({
    super.key,
    required this.deck,
    required this.mainThemeColor,
    this.classId,
    this.assignmentId,
  });

  @override
  State<DeckDetailActionButtons> createState() => _DeckDetailActionButtonsState();
}

class _DeckDetailActionButtonsState extends State<DeckDetailActionButtons> {
  bool _isLoadingFlashcard = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.mainThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
              ),
              onPressed: () {
                context.pushNamed(
                  AppRoute.testSetup.name,
                  extra: {"type": "deck", "data": widget.deck.toJson()},
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_rounded, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'KIỂM TRA',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                foregroundColor: widget.mainThemeColor,
                side: BorderSide(color: widget.mainThemeColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: _isLoadingFlashcard
                  ? null
                  : () async {
                      setState(() => _isLoadingFlashcard = true);
                      await StudyFlowHelper.start(context: context, deckId: widget.deck.id);
                      if (mounted) {
                        setState(() => _isLoadingFlashcard = false);
                      }
                    },
              child: _isLoadingFlashcard
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: widget.mainThemeColor,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.style_rounded, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'FLASHCARD',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
