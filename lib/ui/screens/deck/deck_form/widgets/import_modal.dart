import 'package:flutter/material.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_dropdown.dart';

class ImportModal extends StatefulWidget {
  final ScrollController scrollController;
  final Function(List<Map<String, String>> parsedCards) onImport;

  const ImportModal({super.key, required this.scrollController, required this.onImport});

  @override
  State<ImportModal> createState() => _ImportModalState();
}

class _ImportModalState extends State<ImportModal> {
  final TextEditingController _rawTextController = TextEditingController();

  // Delimiter settings
  String _termSeparator = ','; // Default: Comma
  String _cardSeparator = '\n'; // Default: New Line

  final TextEditingController _customTermController = TextEditingController();
  final TextEditingController _customCardController = TextEditingController();

  bool _useCustomTerm = false;
  bool _useCustomCard = false;

  List<Map<String, String>> _parsedCards = [];

  @override
  void initState() {
    super.initState();

    // Raw text starts completely empty per user request (no mock data)
    _rawTextController.addListener(_updatePreview);
    _customTermController.addListener(_onCustomSeparatorChanged);
    _customCardController.addListener(_onCustomSeparatorChanged);
  }

  @override
  void dispose() {
    _rawTextController.dispose();
    _customTermController.dispose();
    _customCardController.dispose();
    super.dispose();
  }

  void _onCustomSeparatorChanged() {
    if (_useCustomTerm || _useCustomCard) {
      _updatePreview();
    }
  }

  void _updatePreview() {
    final text = _rawTextController.text;

    final termSep = _useCustomTerm ? _customTermController.text : _termSeparator;
    final cardSep = _useCustomCard ? _customCardController.text : _cardSeparator;

    if (termSep.isEmpty || cardSep.isEmpty) {
      setState(() {
        _parsedCards = [];
      });
      return;
    }

    // Replace literal escape sequences with actual whitespace characters
    String finalTermSep = termSep;
    if (finalTermSep == '\\t') finalTermSep = '\t';

    String finalCardSep = cardSep;
    if (finalCardSep == '\\n') finalCardSep = '\n';

    final List<String> segments = text.split(finalCardSep);
    final List<Map<String, String>> tempCards = [];

    for (final segment in segments) {
      if (segment.trim().isEmpty) continue;

      final parts = segment.split(finalTermSep);
      if (parts.length >= 2) {
        final front = parts[0].trim();
        final back = parts.sublist(1).join(finalTermSep).trim();

        if (front.isNotEmpty && back.isNotEmpty) {
          tempCards.add({'front': front, 'back': back});
        }
      }
    }

    setState(() {
      _parsedCards = tempCards;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Import Flashcard Hàng Loạt',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Delimiter settings section using CustomDropdown
                _buildSeparatorConfigSection(colorScheme, theme),
                const SizedBox(height: 20),

                // Paste Text Box
                _buildPasteRawTextSection(colorScheme, theme),
                const SizedBox(height: 24),

                // Preview Area
                _buildPreviewSection(colorScheme, theme),
              ],
            ),
          ),

          // Bottom Action buttons
          _buildBottomActionButtons(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildSeparatorConfigSection(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cấu hình phân tách dữ liệu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Term Separator (Front/Back) using CustomDropdown
              Expanded(
                child: CustomDropdown<String>(
                  value: _useCustomTerm ? 'custom' : _termSeparator,
                  items: const [',', '|', '\\t', 'custom'],
                  itemLabelBuilder: (val) {
                    switch (val) {
                      case ',':
                        return 'Dấu phẩy ( , )';
                      case '|':
                        return 'Gạch đứng ( | )';
                      case '\\t':
                        return 'Tab ( \\t )';
                      case 'custom':
                      default:
                        return 'Tùy chỉnh...';
                    }
                  },
                  isExpanded: true,
                  label: 'Mặt trước/Mặt sau',
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  onChanged: (val) {
                    if (val == 'custom') {
                      setState(() {
                        _useCustomTerm = true;
                      });
                    } else {
                      setState(() {
                        _termSeparator = val;
                        _useCustomTerm = false;
                      });
                    }
                    _updatePreview();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Card Separator (Card/Card) using CustomDropdown
              Expanded(
                child: CustomDropdown<String>(
                  value: _useCustomCard ? 'custom' : _cardSeparator,
                  items: const ['\n', ';', 'custom'],
                  itemLabelBuilder: (val) {
                    switch (val) {
                      case '\n':
                        return 'Xuống dòng';
                      case ';':
                        return 'Chấm phẩy ( ; )';
                      case 'custom':
                      default:
                        return 'Tùy chỉnh...';
                    }
                  },
                  isExpanded: true,
                  label: 'Giữa các thẻ',
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  onChanged: (val) {
                    if (val == 'custom') {
                      setState(() {
                        _useCustomCard = true;
                      });
                    } else {
                      setState(() {
                        _cardSeparator = val;
                        _useCustomCard = false;
                      });
                    }
                    _updatePreview();
                  },
                ),
              ),
            ],
          ),

          if (_useCustomTerm) ...[
            const SizedBox(height: 12),
            CustomTextField(
              controller: _customTermController,
              hintText: 'Ví dụ: - hoặc ->',
              label: 'Ký tự phân cách A/B tùy chỉnh',
            ),
          ],

          if (_useCustomCard) ...[
            const SizedBox(height: 12),
            CustomTextField(
              controller: _customCardController,
              hintText: 'Ví dụ: //',
              label: 'Ký tự phân cách Thẻ tùy chỉnh',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasteRawTextSection(ColorScheme colorScheme, ThemeData theme) {
    return CustomTextField(
      controller: _rawTextController,
      maxLines: 6,
      label: 'Dán văn bản thô:',
      hintText: 'Ví dụ:\nThuật ngữ 1, Định nghĩa 1\nThuật ngữ 2, Định nghĩa 2',
    );
  }

  Widget _buildPreviewSection(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Xem trước kết quả (Preview):',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _parsedCards.isNotEmpty
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_parsedCards.length} thẻ hợp lệ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _parsedCards.isNotEmpty ? colorScheme.primary : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: _parsedCards.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu preview.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: _parsedCards.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: colorScheme.outline.withValues(alpha: 0.1), height: 1),
                  itemBuilder: (context, index) {
                    final card = _parsedCards[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontSize: 15,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Mặt trước: ',
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: card['front'] ?? ''),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontSize: 15,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Mặt sau: ',
                                        style: TextStyle(
                                          color: colorScheme.primary.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: card['back'] ?? ''),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons(ColorScheme colorScheme, ThemeData theme) {
    final bool canImport = _parsedCards.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy bỏ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canImport
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.12),
                  foregroundColor: canImport
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: canImport
                    ? () {
                        widget.onImport(_parsedCards);
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  'Import ${_parsedCards.length} thẻ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: canImport
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
