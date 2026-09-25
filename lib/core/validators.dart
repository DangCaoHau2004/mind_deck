class Validators {
  Validators._();

  /// Regex email chuẩn cơ bản (khớp với backend EMAIL_REGEX)
  static final RegExp emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Regex mật khẩu: 8-64 ký tự, không chứa dấu cách, không chứa chữ có dấu tiếng Việt
  static final RegExp passwordRegex = RegExp(
    r'''^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+$''',
  );

  static bool isValidEmail(String email) {
    return emailRegex.hasMatch(email.trim());
  }

  static bool isValidPasswordCharacters(String password) {
    return passwordRegex.hasMatch(password);
  }
}
