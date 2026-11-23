import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_bloc.dart';
import 'package:mind_deck/ui/screens/folder/folder_detail/bloc/folder_detail_event.dart';

/// Tiêu đề "Bộ thẻ trong thư mục", nút sắp xếp và ô tìm bộ thẻ (tìm qua BE sau khi ngừng gõ 300ms).
class FolderDetailDecksHeader extends StatefulWidget {
  final String sort;

  /// Đang chờ lâu (đã quá 300ms) kết quả tìm/sắp xếp: hiện vòng xoay trong ô tìm.
  final bool showSpinner;

  const FolderDetailDecksHeader({super.key, required this.sort, required this.showSpinner});

  @override
  State<FolderDetailDecksHeader> createState() => _FolderDetailDecksHeaderState();
}

class _FolderDetailDecksHeaderState extends State<FolderDetailDecksHeader> {
  static const _sorts = ['due', 'recent', 'name', 'created'];
  // Chiều mặc định của từng kiểu sắp xếp
  static const _defaultOrder = {'due': 'asc', 'recent': 'desc', 'name': 'asc', 'created': 'desc'};

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<FolderDetailBloc>().add(
        FolderDetailDecksFilterChanged(search: _controller.text.trim()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'folder_decks_title'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              CustomDropdown<String>(
                value: widget.sort,
                items: _sorts,
                itemLabelBuilder: (v) => 'sort_$v'.tr,
                trailing: Icon(Icons.expand_more_rounded, size: 22, color: colorScheme.primary),
                onChanged: (v) => context.read<FolderDetailBloc>().add(
                  FolderDetailDecksFilterChanged(sort: v, order: _defaultOrder[v]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'folder_decks_search_hint'.tr,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: mutedColor.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.showSpinner)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.cancel_rounded, color: mutedColor, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
