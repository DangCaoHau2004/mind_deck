import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/constants/app_assets.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/input_screens/custom_text_field.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/auth/login/bloc/login_bloc.dart';
import 'package:mind_deck/ui/screens/auth/login/bloc/login_event.dart';
import 'package:mind_deck/ui/screens/auth/login/bloc/login_state.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DI().sl<LoginBloc>(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            context.read<AuthBloc>().add(
              LoggedIn(user: state.authResponse.user),
            );
          } else if (state is LoginCancelled) {
            CustomToast.show(context, CustomToast.warning(message: state.message));
          } else if (state is LoginFailure) {
            CustomToast.show(context, CustomToast.danger(message: state.error));
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final textTheme = theme.textTheme;

          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 24),
                      Text(
                        'login_title'.tr,
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'login_subtitle'.tr,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form Login
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'login_email_hint'.tr,
                        prefixIcon: Icon(
                          Icons.mail_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'login_password_hint'.tr,
                        obscureText: _obscurePassword,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),

                      // Nút Quên mật khẩu
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.pushNamed(AppRoute.forgotPassword.name);
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            'login_forgot_password'.tr,
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng nhập
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state is LoginLoading
                              ? null
                              : () {
                                  context.read<LoginBloc>().add(
                                    LoginSubmitted(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: state is LoginLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'login_button'.tr,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dải phân cách "Hoặc"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: colorScheme.outlineVariant),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'login_or'.tr,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: colorScheme.outlineVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng nhập bằng Google
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: state is LoginLoading
                              ? null
                              : () {
                                  context.read<LoginBloc>().add(
                                    LoginWithGoogleSubmitted(),
                                  );
                                },
                          icon: Image.asset(
                            AppAssets.googleIcon,
                            width: 24,
                            height: 24,
                          ),
                          label: Text(
                            'login_with_google'.tr,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: colorScheme.outlineVariant),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Chuyển sang Đăng ký
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'login_dont_have_account'.tr,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pushNamed(AppRoute.signup.name);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              'login_register_now'.tr,
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
            ),
          );
        },
      ),
    );
  }
}
