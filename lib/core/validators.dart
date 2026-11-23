class Validators {
  Validators._();

  /// Regex email chuẩn cơ bản (khớp với backend EMAIL_REGEX)
  static final RegExp emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Regex ký tự mật khẩu được phép: không chứa dấu cách, không chứa chữ có dấu tiếng Việt.
  /// Độ dài kiểm tra riêng bằng [minPasswordLength] và [maxPasswordLength].
  static final RegExp passwordRegex = RegExp(
    r'''^[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+$''',
  );

  /// Cột `users.email` của BE là VARCHAR(255) nên email dài hơn bị coi là không hợp lệ.
  static const int maxEmailLength = 255;

  /// Độ dài mật khẩu BE cho phép (8-64).
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;

  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    return trimmed.length <= maxEmailLength && emailRegex.hasMatch(trimmed);
  }

  /// Kiểm tra mật khẩu mới (đăng ký, đặt lại mật khẩu).
  /// Trả về key `vi.json` của câu báo lỗi đầu tiên gặp phải, `null` nếu hợp lệ.
  static String? passwordError(String password) {
    if (password.length < minPasswordLength || password.length > maxPasswordLength) {
      return 'auth_password_length_invalid';
    }
    if (password.contains(' ')) return 'auth_password_no_space';
    if (!passwordRegex.hasMatch(password)) return 'auth_password_invalid_characters';
    return null;
  }
}
