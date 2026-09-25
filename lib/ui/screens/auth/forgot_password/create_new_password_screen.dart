import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/constants/app_assets.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/bloc/forgot_password_event.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/bloc/forgot_password_state.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const CreateNewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocProvider(
      create: (context) => GetIt.instance<ForgotPasswordBloc>(),
      child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordResetSuccess) {
            CustomToast.show(
              context,
              CustomToast.success(message: 'new_password_success'.tr),
            );
            context.goNamed(AppRoute.login.name);
          } else if (state is ForgotPasswordFailure) {
            CustomToast.show(context, CustomToast.danger(message: state.error));
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              context.goNamed(AppRoute.login.name);
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => context.goNamed(AppRoute.login.name),
                ),
              ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Transform.scale(
                        scale: 1.3,
                        child: Image.asset(
                          AppAssets.iconTransparent,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                    Text(
                      'new_password_title'.tr,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'new_password_subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'new_password_hint'.tr,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'new_password_confirm_hint'.tr,
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is ForgotPasswordLoading
                            ? null
                            : () {
                                final password = _passwordController.text;
                                final confirmPassword =
                                    _confirmPasswordController.text;
                                context.read<ForgotPasswordBloc>().add(
                                  ForgotPasswordResetSubmitted(
                                    email: widget.email,
                                    resetToken: widget.resetToken,
                                    newPassword: password,
                                    confirmPassword: confirmPassword,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state is ForgotPasswordLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'new_password_button'.tr,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}
