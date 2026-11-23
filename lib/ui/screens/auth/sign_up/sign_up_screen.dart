import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/constants/app_assets.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/app_date_picker.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:mind_deck/ui/screens/auth/sign_up/bloc/sign_up_event.dart';
import 'package:mind_deck/ui/screens/auth/sign_up/bloc/sign_up_state.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
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
      create: (context) => GetIt.instance<SignUpBloc>(),
      child: BlocConsumer<SignUpBloc, SignUpState>(
        listener: (context, state) {
          if (state is SignUpSuccess) {
            context.read<AuthBloc>().add(LoggedIn(user: state.authResponse.user));
          } else if (state is SignUpRequireLogin) {
            CustomToast.show(context, CustomToast.success(message: 'signup_require_login'.tr));
            context.go(AppRoute.login.path);
          } else if (state is SignUpFailure) {
            CustomToast.show(context, CustomToast.danger(message: state.failure.displayMessage));
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => context.pop(),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Transform.scale(
                        scale: 1.3,
                        child: Image.asset(AppAssets.iconTransparent, width: 200, height: 200),
                      ),
                    ),
                    Text(
                      'signup_title'.tr,
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'signup_subtitle'.tr,
                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 40),

                    CustomTextField(
                      controller: _nameController,
                      hintText: 'signup_name_hint'.tr,
                      prefixIcon: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _dobController,
                      hintText: 'signup_dob_hint'.tr,
                      prefixIcon: Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
                      readOnly: true,
                      onTap: () async {
                        final picked = await AppDatePicker.pickDateOfBirth(
                          context,
                          initialDate: _selectedDob,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDob = picked;
                            _dobController.text =
                                "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'signup_email_hint'.tr,
                      prefixIcon: Icon(Icons.mail_outline, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'signup_password_hint'.tr,
                      obscureText: _obscurePassword,
                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'signup_confirm_password_hint'.tr,
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is SignUpLoading
                            ? null
                            : () {
                                final dobPayload = _selectedDob != null
                                    ? "${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}"
                                    : '';
                                context.read<SignUpBloc>().add(
                                  SignUpSubmitted(
                                    name: _nameController.text.trim(),
                                    dob: dobPayload,
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                    confirmPassword: _confirmPasswordController.text.trim(),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: state is SignUpLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'signup_button'.tr,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'signup_already_have_account'.tr,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'signup_login_now'.tr,
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
