import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/folder_model.dart';

class FolderDialogHelper {
  /// Hiển thị Dialog xác nhận xóa Thư mục (trả về 0: chỉ xóa thư mục, 1: xóa thư mục & các bộ thẻ, null: Hủy)
  static Future<int?> showDeleteFolder(
    BuildContext context, {
    required FolderModel? folder,
    required int deckCount,
  }) {
    final folderName = folder?.name ?? '';

    if (deckCount == 0) {
      return showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Xóa thư mục'),
            content: Text(
              'Bạn có chắc chắn muốn xóa thư mục "$folderName" không? Thao tác này không thể hoàn tác.',
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xóa'),
              ),
            ],
          );
        },
      ).then((confirmed) => confirmed == true ? 0 : null);
    }

    int keepDecksOption = 0;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Xóa thư mục'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thư mục "$folderName" đang chứa $deckCount bộ thẻ. Bạn muốn xử lý như thế nào?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setDialogState(() => keepDecksOption = 0),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: keepDecksOption == 0
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: keepDecksOption == 0
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            keepDecksOption == 0
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: keepDecksOption == 0
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chỉ xóa thư mục',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Giữ lại các bộ thẻ trong thư viện',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setDialogState(() => keepDecksOption = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: keepDecksOption == 1
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: keepDecksOption == 1
                              ? Colors.redAccent
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            keepDecksOption == 1
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: keepDecksOption == 1 ? Colors.redAccent : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xóa thư mục và tất cả bộ thẻ',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: keepDecksOption == 1 ? Colors.redAccent : null,
                                  ),
                                ),
                                Text(
                                  'Xóa hoàn toàn các bộ thẻ thuộc thư mục này',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Xóa'),
                ),
              ],
            );
          },
        );
      },
    ).then((confirmed) => confirmed == true ? keepDecksOption : null);
  }

  /// Hiển thị Dialog xác nhận Nhân bản Thư mục
  static Future<bool?> showCloneFolder(
    BuildContext context, {
    required FolderModel folder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Nhân bản thư mục'),
          content: Text(
            'Bạn có chắc chắn muốn tạo bản sao của thư mục "${folder.name}" vào thư viện của bạn không?',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nhân bản'),
            ),
          ],
        );
      },
    );
  }

  /// Hiển thị Dialog xác nhận gỡ 1 bộ thẻ khỏi thư mục
  static Future<bool?> showRemoveDeckFromFolder(
    BuildContext context, {
    required String deckName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Gỡ bộ thẻ khỏi thư mục'),
          content: Text(
            'Bạn có chắc chắn muốn gỡ bộ thẻ "$deckName" khỏi thư mục này không?\n\n(Bộ thẻ vẫn sẽ được lưu giữ trong thư viện của bạn)',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Gỡ khỏi thư mục'),
            ),
          ],
        );
      },
    );
  }

  /// Hiển thị Dialog xác nhận gỡ hàng loạt bộ thẻ khỏi thư mục
  static Future<bool?> showRemoveMultipleDecksFromFolder(
    BuildContext context, {
    required int count,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Gỡ bộ thẻ đã chọn'),
          content: Text(
            'Bạn có chắc chắn muốn gỡ $count bộ thẻ đã chọn khỏi thư mục này không?\n\n(Các bộ thẻ vẫn sẽ được lưu giữ trong thư viện của bạn)',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Gỡ $count bộ thẻ'),
            ),
          ],
        );
      },
    );
  }
}
