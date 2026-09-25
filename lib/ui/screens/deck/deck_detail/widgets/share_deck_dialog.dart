import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/commons/widgets/share_qr_widget.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_event.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_state.dart';

class ShareDeckDialog extends StatelessWidget {
  final DeckModel deck;
  final bool isOwner;

  const ShareDeckDialog({super.key, required this.deck, required this.isOwner});

  static Future<void> show(BuildContext context, {required DeckModel deck, required bool isOwner}) {
    final bloc = context.read<DeckDetailBloc>();

    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ShareDeckDialog(deck: deck, isOwner: isOwner),
      ),
    );
  }

  static int getShareModeIndex(DeckModel deck) {
    final mode = deck.shareMode.toLowerCase();
    if (mode == 'private') {
      return 0; // Riêng tư
    }
    if (mode == 'restricted') {
      return 1; // Bất kỳ ai có liên kết
    }
    if (mode == 'public' || deck.isPublic) {
      return 2; // Công khai
    }
    if (deck.shareToken != null && deck.shareToken!.isNotEmpty) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeckDetailBloc, DeckDetailState>(
      builder: (context, state) {
        final currentDeck = state.deck ?? deck;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final selectedValue = getShareModeIndex(currentDeck);
        final showQrSection = currentDeck.shareToken != null && currentDeck.shareToken!.isNotEmpty;

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
                        'Chia sẻ học phần',
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
                    _ShareAccessOptions(currentDeck: currentDeck, selectedValue: selectedValue),
                    const SizedBox(height: 16),
                  ],

                  if (showQrSection)
                    _ShareQrSection(currentDeck: currentDeck)
                  else if (!isOwner)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Học phần này không có liên kết chia sẻ.',
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
  final DeckModel currentDeck;
  final int selectedValue;

  const _ShareAccessOptions({required this.currentDeck, required this.selectedValue});

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
              String accessLevel = 'private';
              bool newIsPublic = false;
              bool newGenerateLink = false;

              if (item.value == 1) {
                accessLevel = 'restricted';
                newIsPublic = false;
                newGenerateLink = true;
              } else if (item.value == 2) {
                accessLevel = 'public';
                newIsPublic = true;
                newGenerateLink = true;
              }

              context.read<DeckDetailBloc>().add(
                DeckShareUpdated(
                  id: currentDeck.id,
                  accessLevel: accessLevel,
                  isPublic: newIsPublic,
                  generateLink: newGenerateLink,
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
                  ? colorScheme.primary.withValues(alpha: 0.06)
                  : colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: isSelected ? 1.5 : 1.0,
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
                          fontSize: 11.5,
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
  final DeckModel currentDeck;

  const _ShareQrSection({required this.currentDeck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (currentDeck.shareToken == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Mã QR chia sẻ',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ShareQrWidget(
            targetType: 'deck',
            targetId: currentDeck.id,
            shareToken: currentDeck.shareToken!,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final String shareableLink =
                "minddeck://minddeck.com/library/deck/${currentDeck.id}?token=${currentDeck.shareToken}";

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
