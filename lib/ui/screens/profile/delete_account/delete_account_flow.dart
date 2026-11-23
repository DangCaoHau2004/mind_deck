import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/repositories/profile_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';

/// Xóa tài khoản: xác nhận, gửi `DELETE /profile`, rồi đăng xuất.
///
/// App không biết tài khoản có mật khẩu hay chỉ dùng Google nên gửi lần đầu không kèm mật khẩu;
/// BE trả 400 `AUTH_PASSWORD_CURRENT_EMPTY` thì mới hỏi mật khẩu (sai thì hỏi lại).
Future<void> startDeleteAccount(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('account_delete_confirm_title'.tr),
      content: Text('account_delete_confirm_body'.tr),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('common_cancel'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
          child: Text('account_delete_action'.tr),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final repository = DI().sl<ProfileRepository>();
  String? password;
  String? passwordError;
  while (true) {
    try {
      await repository.deleteAccount(password: password);
      break;
    } on Failure catch (f) {
      if (!context.mounted) return;
      final needsPassword =
          f.errorCode == AppErrorCodes.authPasswordCurrentEmpty ||
          f.errorCode == AppErrorCodes.authCurrentPasswordIncorrect;
      if (needsPassword) {
        passwordError = f.errorCode == AppErrorCodes.authCurrentPasswordIncorrect
            ? 'account_delete_password_wrong'.tr
            : null;
        password = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _PasswordDialog(error: passwordError),
        );
        if (password == null || !context.mounted) return;
        continue;
      }
      if (f.errorCode == AppErrorCodes.accountOwnsClasses) {
        await _showOwnedClasses(context, f.params?['classes']);
        return;
      }
      CustomToast.show(context, CustomToast.danger(message: f.displayMessage));
      return;
    }
  }

  if (!context.mounted) return;
  CustomToast.show(context, CustomToast.success(message: 'account_delete_done'.tr));
  context.read<AuthBloc>().add(const LoggedOut());
}

Future<void> _showOwnedClasses(BuildContext context, Object? rawClasses) {
  final classes = <({String id, String name})>[
    if (rawClasses is List)
      for (final c in rawClasses)
        if (c is Map) (id: c['id']?.toString() ?? '', name: c['name']?.toString() ?? ''),
  ];
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('account_delete_owns_classes_title'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('account_delete_owns_classes'.tr),
            const SizedBox(height: 8),
            for (final c in classes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_rounded),
                title: Text(c.name),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: c.id.isEmpty
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        context.pushNamed(
                          AppRoute.classroomDetail.name,
                          pathParameters: {'id': c.id},
                        );
                      },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common_close'.tr)),
      ],
    ),
  );
}

class _PasswordDialog extends StatefulWidget {
  final String? error;
  const _PasswordDialog({this.error});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _empty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    if (value.isEmpty) {
      setState(() => _empty = true);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final error = _empty ? 'account_delete_password_required'.tr : widget.error;
    return AlertDialog(
      title: Text('account_delete_password_title'.tr),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: 'account_delete_password_hint'.tr, errorText: error),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('common_cancel'.tr)),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text('account_delete_action'.tr),
        ),
      ],
    );
  }
}
