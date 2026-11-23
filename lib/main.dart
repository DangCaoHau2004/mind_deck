import 'dart:async';
import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/extensions/failure_extension.dart';
import 'package:mind_deck/core/services/crashlytics_service.dart';
import 'package:mind_deck/core/services/localization_service.dart';
import 'package:mind_deck/core/theme/app_theme.dart';
import 'package:mind_deck/navigation/app_router.dart';
import 'package:mind_deck/services/ad_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mind_deck/configs/notification_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_bloc.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_event.dart';
import 'package:mind_deck/ui/screens/auth/bloc/auth_state.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Cấu hình Firebase lấy từ android/app/src/<flavor>/google-services.json.
  await Firebase.initializeApp();
  final ICrashlyticsService crashlyticsService = CrashlyticsService();
  await crashlyticsService.initialize();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    crashlyticsService.recordFlutterError(details, fatal: true);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    crashlyticsService.recordError(error, stack, fatal: true);
    return true;
  };
  await DI().init();
  // Không chờ AdMob khởi tạo xong mới mở app.
  unawaited(DI().sl<AdService>().initialize());
  await NotificationConfig.initialize();
  final goRouter = DI().sl<AppRouter>().router;
  DI().sl<NotificationConfig>().setupMessageHandlers((String fullPath) {
    try {
      final uri = Uri.parse(fullPath);
      final internalRoute = uri.path;
      if (internalRoute.isNotEmpty) {
        debugPrint("GoRouter đang push tới: $internalRoute");
        goRouter.push(internalRoute);
      }
    } catch (e) {
      debugPrint("Lỗi phân tích Deep Link từ Push Notification: $e");
    }
  });
  await LocalizationService().load('vi');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// Thời gian hiện toast lý do bị đăng xuất; do thiết kế chọn, chưa đo.
  static const _logoutReasonDuration = Duration(seconds: 10);

  @override
  Widget build(BuildContext context) {
    final goRouter = DI().sl<AppRouter>().router;
    return BlocProvider(
      create: (context) => DI().sl<AuthBloc>()..add(AppStarted()),
      lazy: false,
      // Báo lý do bị đăng xuất (ví dụ tài khoản bị khóa) ngay lúc xảy ra, ở bất kỳ màn nào;
      // và báo một lần khi vào app lúc chưa tải được hồ sơ (mất mạng, server lỗi).
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            (current is AuthUnauthenticated && current.failure != null) ||
            (current is AuthAuthenticatedOffline && previous is! AuthAuthenticatedOffline),
        listener: (_, state) {
          final failure = switch (state) {
            AuthUnauthenticated(:final failure) => failure,
            AuthAuthenticatedOffline(:final failure) => failure,
            _ => null,
          };
          if (failure == null) return;
          CustomToast.showOnOverlay(
            DI().sl<AppRouter>().rootNavigatorKey.currentState?.overlay,
            CustomToast.danger(message: failure.displayMessage),
            duration: state is AuthUnauthenticated
                ? _logoutReasonDuration
                : CustomToast.defaultDuration,
          );
        },
        child: MaterialApp.router(
          title: 'Mind Deck',
          theme: AppTheme.lightTheme,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          darkTheme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: goRouter,
          locale: LocalizationService().currentLocale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'GB'), Locale('en', 'US')],
        ),
      ),
    );
  }
}
