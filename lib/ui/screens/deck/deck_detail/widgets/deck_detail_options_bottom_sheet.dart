import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_bloc.dart';
import 'package:mind_deck/ui/screens/deck/deck_detail/bloc/deck_detail_event.dart';

class DeckDetailOptionsBottomSheet {
  static Future<void> show(
    BuildContext parentContext, {
    required DeckModel deck,
    required String deckId,
    String? token,
    required bool isDeckOwner,
    required VoidCallback onDeleteDeck,
    required VoidCallback onCloneDeck,
  }) {
    final theme = Theme.of(parentContext);
    final deckDetailBloc = parentContext.read<DeckDetailBloc>();

    return showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: deckDetailBloc,
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Center(
                            child: Text(
                              'Tùy chọn Bộ thẻ',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBottomSheetItem(
                            context,
                            theme,
                            icon: Icons.edit_rounded,
                            text: 'Sửa thông tin bộ thẻ',
                            onTap: () {
                              context
                                  .pushNamed(
                                    AppRoute.deckEdit.name,
                                    pathParameters: {'id': deck.id},
                                    extra: deck,
                                  )
                                  .then((result) {
                                    if (result != null && context.mounted) {
                                      if (result is String) {
                                        CustomToast.show(
                                          context,
                                          CustomToast.success(message: result),
                                        );
                                      }
                                      context.read<DeckDetailBloc>().add(
                                        DeckDetailRefreshed(deckId),
                                      );
                                    }
                                  });
                            },
                          ),
                          if (deck.canClone)
                            _buildBottomSheetItem(
                              context,
                              theme,
                              icon: Icons.copy_all_rounded,
                              text: 'Nhân bản bộ thẻ (Clone)',
                              onTap: () {
                                context.pop();
                                onCloneDeck();
                              },
                            ),
                          _buildBottomSheetItem(
                            context,
                            theme,
                            icon: Icons.delete_outline_rounded,
                            text: 'Xóa bộ thẻ này',
                            color: theme.colorScheme.error,
                            onTap: () {
                              context.pop();
                              onDeleteDeck();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Widget _buildBottomSheetItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String text,
    Color? color,
    required VoidCallback onTap,
  }) {
    final itemColor = color ?? theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(color: itemColor, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
