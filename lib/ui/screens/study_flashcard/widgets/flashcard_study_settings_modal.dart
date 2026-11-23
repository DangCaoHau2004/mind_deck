import 'package:flutter/material.dart';

class FlashcardStudySettingsModal extends StatelessWidget {
  final bool isShuffleMode;
  final bool showBackFirst;
  final ValueChanged<bool> onShuffleChanged;
  final ValueChanged<bool> onShowBackFirstChanged;
  final VoidCallback onResetCards;

  const FlashcardStudySettingsModal({
    super.key,
    required this.isShuffleMode,
    required this.showBackFirst,
    required this.onShuffleChanged,
    required this.onShowBackFirstChanged,
    required this.onResetCards,
  });

  static void show(
    BuildContext context, {
    required bool isShuffleMode,
    required bool showBackFirst,
    required ValueChanged<bool> onShuffleChanged,
    required ValueChanged<bool> onShowBackFirstChanged,
    required VoidCallback onResetCards,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return FlashcardStudySettingsModal(
                  isShuffleMode: isShuffleMode,
                  showBackFirst: showBackFirst,
                  onShuffleChanged: (val) {
                    onShuffleChanged(val);
                    setModalState(() {});
                  },
                  onShowBackFirstChanged: (val) {
                    onShowBackFirstChanged(val);
                    setModalState(() {});
                  },
                  onResetCards: () {
                    Navigator.pop(context);
                    onResetCards();
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentedTab({
    required String text,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primaryColor : Colors.black54,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0, top: 12.0),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Tùy chọn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(height: 24),

            // --- KHỐI 1: TRỘN THẺ ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: cardDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trộn thẻ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch.adaptive(
                    value: isShuffleMode,
                    activeTrackColor: primaryColor,
                    onChanged: onShuffleChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- KHỐI 2: MẶT TRƯỚC/SAU ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thiết lập thẻ ghi nhớ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentedTab(
                            text: 'Mặt trước',
                            isSelected: !showBackFirst,
                            primaryColor: primaryColor,
                            onTap: () => onShowBackFirstChanged(false),
                          ),
                        ),
                        Expanded(
                          child: _buildSegmentedTab(
                            text: 'Mặt sau',
                            isSelected: showBackFirst,
                            primaryColor: primaryColor,
                            onTap: () => onShowBackFirstChanged(true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- KHỐI 3: ĐẶT LẠI ---
            GestureDetector(
              onTap: onResetCards,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: cardDecoration,
                child: const Text(
                  'Học lại từ đầu',
                  style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
