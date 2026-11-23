import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/ui/commons/custom_dialog.dart';
import 'package:mind_deck/data/models/folder_model.dart';

class FolderDialogHelper {
  /// Hộp xác nhận xóa thư mục. Xóa thư mục chỉ gỡ liên kết, các bộ thẻ bên trong luôn được giữ lại.
  static Future<bool?> showDeleteFolder(BuildContext context, {required FolderModel? folder}) {
    return CustomDialog.show<bool>(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'folder_delete_title'.tr.replaceAll('{count}', '1'),
      description: 'folder_delete_keep_decks'.tr,
      confirmText: 'library_delete'.tr,
      confirmButtonColor: Theme.of(context).colorScheme.error,
    );
  }

  /// Hiển thị Dialog xác nhận Nhân bản Thư mục
  static Future<bool?> showCloneFolder(BuildContext context, {required FolderModel folder}) {
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
  static Future<bool?> showRemoveDeckFromFolder(BuildContext context, {required String deckName}) {
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
