import 'package:flutter/material.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/services/localization_service.dart';

/// Lớp tiện ích cung cấp DatePicker và TimePicker chuẩn hóa toàn ứng dụng:
/// - Tự động áp dụng ngôn ngữ hiện tại của app (vi_VN hoặc en_GB) để luôn giữ format dd/mm/yyyy.
/// - Đồng bộ giao diện Dark/Light theme với Theme của ứng dụng.
/// - Cung cấp sẵn 3 trường hợp: Ngày sinh (quá khứ), Hạn chót (ngày tương lai), Hạn chót (ngày + giờ).
class AppDatePicker {
  AppDatePicker._();

  /// Lấy Locale hiện tại từ LocalizationService:
  /// vi -> Locale('vi', 'VN') (format dd/mm/yyyy)
  /// en -> Locale('en', 'GB') (format dd/mm/yyyy)
  static Locale get currentLocale => LocalizationService().currentLocale;

  /// Hiển thị DatePicker cơ sở với locale chuẩn và theme đồng bộ
  static Future<DateTime?> showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
    String? cancelText,
    String? confirmText,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    TransitionBuilder? builder,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final defaultBuilder =
        builder ??
        (dialogContext, child) {
          return Theme(
            data: theme.copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: colorScheme.primary,
                      onPrimary: colorScheme.onPrimary,
                      surface: colorScheme.surface,
                      onSurface: colorScheme.onSurface,
                    )
                  : ColorScheme.light(
                      primary: colorScheme.primary,
                      onPrimary: colorScheme.onPrimary,
                      surface: colorScheme.surface,
                      onSurface: colorScheme.onSurface,
                    ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              ),
            ),
            child: child!,
          );
        };

    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: currentLocale,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      fieldHintText: 'dd/mm/yyyy',
      initialEntryMode: initialEntryMode,
      builder: defaultBuilder,
    );
  }

  /// 1. Chọn ngày sinh (Dành cho màn SignUp / Thông tin cá nhân)
  /// Giới hạn: Từ 1900 đến thời điểm hiện tại.
  static Future<DateTime?> pickDateOfBirth(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    TransitionBuilder? builder,
  }) async {
    final now = DateTime.now();
    return await showCustomDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(2000, 1, 1),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? now,
      helpText: 'signup_dob_hint'.tr,
      builder: builder,
    );
  }

  /// 2. Chọn Deadline ngày (Dành cho DeckFormScreen / Tạo học phần)
  /// Giới hạn: Từ hôm nay trở đi (mặc định tối đa 2 năm).
  static Future<DateTime?> pickDeadlineDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    int maxDays = 730,
    TransitionBuilder? builder,
  }) async {
    final now = DateTime.now();
    return await showCustomDatePicker(
      context: context,
      initialDate: initialDate ?? now.add(const Duration(days: 7)),
      firstDate: firstDate ?? now,
      lastDate: lastDate ?? now.add(Duration(days: maxDays)),
      builder: builder,
    );
  }

  /// 3. Chọn Deadline cả Ngày và Giờ (Dành cho CreateEditAssignmentScreen / Bài tập lớp học)
  /// Chọn ngày tương lai rồi tự động mở TimePicker để chọn giờ.
  static Future<DateTime?> pickDeadlineDateTime(
    BuildContext context, {
    DateTime? initialDateTime,
    DateTime? firstDate,
    DateTime? lastDate,
    int maxDays = 365,
    TransitionBuilder? builder,
  }) async {
    final now = DateTime.now();
    final pickedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDateTime ?? now.add(const Duration(days: 1)),
      firstDate: firstDate ?? now,
      lastDate: lastDate ?? now.add(Duration(days: maxDays)),
      builder: builder,
    );

    if (pickedDate == null || !context.mounted) return null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final timeBuilder =
        builder ??
        (dialogContext, child) {
          return Theme(
            data: theme.copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: colorScheme.primary,
                      onPrimary: colorScheme.onPrimary,
                      surface: colorScheme.surface,
                      onSurface: colorScheme.onSurface,
                    )
                  : ColorScheme.light(
                      primary: colorScheme.primary,
                      onPrimary: colorScheme.onPrimary,
                      surface: colorScheme.surface,
                      onSurface: colorScheme.onSurface,
                    ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              ),
            ),
            child: child!,
          );
        };

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime ?? now),
      builder: timeBuilder,
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}
