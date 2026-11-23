import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/core/validators.dart';
import 'package:mind_deck/data/repositories/auth_repository.dart';
import 'package:mind_deck/services/storage_service.dart';
import 'sign_up_event.dart';
import 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final AuthRepository authRepository;
  final StorageService storageService;

  SignUpBloc({required this.authRepository, required this.storageService})
    : super(SignUpInitial()) {
    on<SignUpSubmitted>(_onSignUpSubmitted);
  }

  Future<void> _onSignUpSubmitted(SignUpSubmitted event, Emitter<SignUpState> emit) async {
    final name = event.name.trim();
    final email = event.email.trim();
    final password = event.password;
    final confirmPassword = event.confirmPassword;
    final dob = event.dob;

    // 1. Full name
    if (name.isEmpty) {
      emit(SignUpFailure(failure: ValidationFailure('auth_fullname_empty'.tr)));
      return;
    }
    if (name.length > 100) {
      emit(SignUpFailure(failure: ValidationFailure('auth_fullname_too_long'.tr)));
      return;
    }

    // 2. Email
    if (!Validators.isValidEmail(email)) {
      emit(SignUpFailure(failure: ValidationFailure('auth_email_invalid'.tr)));
      return;
    }

    // 3. Password
    final passwordError = Validators.passwordError(password);
    if (passwordError != null) {
      emit(SignUpFailure(failure: ValidationFailure(passwordError.tr)));
      return;
    }

    // 4. Confirm Password
    if (password != confirmPassword) {
      emit(SignUpFailure(failure: ValidationFailure('new_password_not_match'.tr)));
      return;
    }

    // 5. Date of Birth (kiểm tra nếu có truyền)
    if (dob.isNotEmpty) {
      try {
        final dobDate = DateTime.parse(dob);
        final currentYear = DateTime.now().year;
        final birthYear = dobDate.year;
        if (currentYear - birthYear < 1) {
          emit(SignUpFailure(failure: ValidationFailure('auth_dob_underage'.tr)));
          return;
        }
      } catch (_) {
        emit(SignUpFailure(failure: ValidationFailure('auth_dob_invalid'.tr)));
        return;
      }
    }

    emit(SignUpLoading());
    try {
      final response = await authRepository.register(
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
        fullName: event.name,
        dateOfBirth: event.dob,
      );
      if (response.success && response.data != null) {
        final authData = response.data!;
        if (authData.requireLogin) {
          emit(SignUpRequireLogin());
          return;
        }
        await storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        emit(SignUpSuccess(authResponse: authData));
      } else {
        emit(
          SignUpFailure(
            failure: UnknownFailure(
              message: AppErrorCodes.requestFailed.tr,
              errorCode: AppErrorCodes.requestFailed,
            ),
          ),
        );
      }
    } on Failure catch (f) {
      emit(SignUpFailure(failure: f));
    } catch (e) {
      emit(SignUpFailure(failure: UnknownFailure(message: e.toString())));
    }
  }
}
