import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/utils/study_flow_helper.dart';

class DeckDetailActionButtons extends StatefulWidget {
  final DeckModel deck;
  final String? classId;
  final String? assignmentId;

  /// Chủ deck cá nhân. Người khác chỉ được HỌC THỬ (không lưu tiến trình);
  /// bản sao lớp học bình thường nhưng không tạo đề cá nhân được (BE lọc sạch thẻ).
  final bool isOwner;

  const DeckDetailActionButtons({
    super.key,
    required this.deck,
    this.classId,
    this.assignmentId,
    this.isOwner = true,
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

    final isTrial = !widget.isOwner && !widget.deck.isClassCopy;
    final canMakePersonalTest = widget.isOwner && !widget.deck.isClassCopy;

    return Row(
      children: [
        if (canMakePersonalTest) ...[
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.5),
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
                    const Icon(Icons.fact_check_outlined, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'deck_action_test'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.35), width: 1.5),
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
                        color: colorScheme.primary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.style_rounded, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          (isTrial ? 'deck_action_trial' : 'deck_action_flashcard').tr,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
