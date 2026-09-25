import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
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

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    final name = event.name.trim();
    final email = event.email.trim();
    final password = event.password;
    final confirmPassword = event.confirmPassword;
    final dob = event.dob;

    // 1. Full name
    if (name.isEmpty) {
      emit(SignUpFailure(error: 'auth_fullname_empty'.tr));
      return;
    }
    if (name.length > 100) {
      emit(SignUpFailure(error: 'auth_fullname_too_long'.tr));
      return;
    }

    // 2. Email
    if (!Validators.isValidEmail(email)) {
      emit(SignUpFailure(error: 'auth_email_invalid'.tr));
      return;
    }

    // 3. Password
    if (password.length < 8 || password.length > 64) {
      emit(SignUpFailure(error: 'auth_password_length_invalid'.tr));
      return;
    }
    if (password.contains(' ')) {
      emit(SignUpFailure(error: 'auth_password_no_space'.tr));
      return;
    }
    if (!Validators.isValidPasswordCharacters(password)) {
      emit(SignUpFailure(error: 'auth_password_invalid_characters'.tr));
      return;
    }

    // 4. Confirm Password
    if (password != confirmPassword) {
      emit(SignUpFailure(error: 'new_password_not_match'.tr));
      return;
    }

    // 5. Date of Birth (kiểm tra nếu có truyền)
    if (dob.isNotEmpty) {
      try {
        final dobDate = DateTime.parse(dob);
        final currentYear = DateTime.now().year;
        final birthYear = dobDate.year;
        if (currentYear - birthYear < 1) {
          emit(SignUpFailure(error: 'auth_dob_underage'.tr));
          return;
        }
      } catch (_) {
        emit(SignUpFailure(error: 'auth_dob_invalid'.tr));
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
        await storageService.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        emit(SignUpSuccess(authResponse: authData));
      } else {
        emit(
          SignUpFailure(error: response.message ?? 'signup_failed'.tr),
        );
      }
    } catch (e) {
      emit(SignUpFailure(error: e.toString()));
    }
  }
}
