import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/repositories/deck_repository.dart';
import 'package:mind_deck/data/repositories/folder_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';

/// Lưu (clone) một deck/folder công khai vào thư viện của người dùng rồi mở bản sao.
/// Dùng chung cho item thịnh hành và thẻ kết quả tìm kiếm.
class DiscoverSaveHelper {
  const DiscoverSaveHelper._();

  static Future<void> saveToLibrary(
    BuildContext context, {
    required String id,
    required bool isFolder,
  }) async {
    try {
      CustomToast.show(context, CustomToast.general(message: 'discover_saving'.tr));

      if (isFolder) {
        final response = await GetIt.instance<FolderRepository>().cloneFolder(id);
        if (!context.mounted) return;
        CustomToast.dismiss();
        if (response.success && response.data != null) {
          CustomToast.show(context, CustomToast.success(message: 'discover_saved_folder'.tr));
          context.pushNamed(AppRoute.folderDetail.name, pathParameters: {'id': response.data!.id});
        } else {
          CustomToast.show(
            context,
            CustomToast.danger(message: response.message ?? 'discover_save_folder_failed'.tr),
          );
        }
      } else {
        final response = await GetIt.instance<DeckRepository>().cloneDeck(id);
        if (!context.mounted) return;
        CustomToast.dismiss();
        if (response.success && response.data != null) {
          CustomToast.show(context, CustomToast.success(message: 'discover_saved_deck'.tr));
          context.pushNamed(AppRoute.deckDetail.name, pathParameters: {'id': response.data!.id});
        } else {
          CustomToast.show(
            context,
            CustomToast.danger(message: response.message ?? 'discover_save_deck_failed'.tr),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.dismiss();
        CustomToast.show(
          context,
          CustomToast.danger(message: 'discover_error_generic'.tr.replaceAll('{error}', '$e')),
        );
      }
    }
  }
}
