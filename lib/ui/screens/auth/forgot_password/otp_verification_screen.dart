import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/constants/app_assets.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/bloc/forgot_password_event.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/bloc/forgot_password_state.dart';
import 'package:mind_deck/ui/screens/auth/forgot_password/widgets/custom_otp_input.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isForForgotPassword;
  final int initialCooldown;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.isForForgotPassword,
    this.initialCooldown = 60,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _currentOtpCode = "";
  int _resendCooldown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer({int? seconds}) {
    _timer?.cancel();
    final startSeconds = seconds ?? widget.initialCooldown;
    if (startSeconds <= 0) {
      setState(() {
        _resendCooldown = 0;
        _canResend = true;
      });
      return;
    }
    setState(() {
      _resendCooldown = startSeconds;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            _canResend = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          if (state is ForgotPasswordOtpVerifySuccess) {
            context.pushReplacementNamed(
              AppRoute.resetPassword.name,
              extra: {'email': state.email, 'resetToken': state.resetToken},
            );
          } else if (state is ForgotPasswordFailure) {
            CustomToast.show(context, CustomToast.danger(message: state.failure.displayMessage));
          } else if (state is ForgotPasswordOtpSentSuccess) {
            CustomToast.show(context, CustomToast.success(message: 'otp_resent_success'.tr));
            _startTimer(seconds: state.cooldownRemaining);
          }
        },
        builder: (context, state) {
          void handleBack() {
            context.goNamed(AppRoute.login.name);
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              handleBack();
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: handleBack,
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Transform.scale(
                          scale: 1.3,
                          child: Image.asset(AppAssets.iconTransparent, width: 200, height: 200),
                        ),
                      ),
                      Text(
                        'otp_title'.tr,
                        style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'otp_subtitle'.tr,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 40),

                      CustomOtpInput(
                        length: 6,
                        onChanged: (code) {
                          setState(() {
                            _currentOtpCode = code;
                          });
                        },
                        onCompleted: (code) {
                          // Optional auto-submit
                        },
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state is ForgotPasswordLoading
                              ? null
                              : () {
                                  if (_currentOtpCode.length == 6) {
                                    context.read<ForgotPasswordBloc>().add(
                                      ForgotPasswordOtpSubmitted(
                                        email: widget.email,
                                        otp: _currentOtpCode,
                                      ),
                                    );
                                  } else {
                                    CustomToast.show(
                                      context,
                                      CustomToast.warning(message: 'otp_invalid'.tr),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: state is ForgotPasswordLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'otp_button'.tr,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: (!_canResend || state is ForgotPasswordLoading)
                            ? null
                            : () {
                                context.read<ForgotPasswordBloc>().add(
                                  ForgotPasswordEmailSubmitted(email: widget.email),
                                );
                              },
                        child: Text(
                          _canResend ? 'otp_resend'.tr : '${'otp_resend'.tr} (${_resendCooldown}s)',
                          style: textTheme.titleMedium?.copyWith(
                            color: (!_canResend || state is ForgotPasswordLoading)
                                ? Colors.grey
                                : colorScheme.primary,
                            fontWeight: FontWeight.bold,
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
