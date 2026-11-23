import 'package:flutter/material.dart';
import 'package:mind_deck/core/theme/app_styles.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    colorScheme: AppStyles.blueLightColorScheme,
    scaffoldBackgroundColor: AppStyles.blueLightColorScheme.surfaceContainer,
    useMaterial3: true,
    textTheme: AppStyles.textTheme,
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => const Icon(Icons.arrow_back_ios_new, size: 22),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final darkTheme = ThemeData(
    colorScheme: AppStyles.blueDarkColorScheme,
    scaffoldBackgroundColor: AppStyles.blueDarkColorScheme.surfaceContainer,
    useMaterial3: true,
    textTheme: AppStyles.textTheme,
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => const Icon(Icons.arrow_back_ios_new, size: 22),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // --- PURPLE THEME (Dự phòng nếu bạn muốn đổi sang Tím) ---
  static final purpleLightTheme = ThemeData(
    colorScheme: AppStyles.purpleColorScheme,
    // scaffoldBackgroundColor: AppStyles.purpleColorScheme.surfaceContainer,
    scaffoldBackgroundColor: Colors.transparent,
    useMaterial3: true,
    textTheme: AppStyles.textTheme,
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => const Icon(Icons.arrow_back_ios_new, size: 22),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
