import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_locale_controller.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/general_settings_controller.dart';
import 'services/vehicle_service.dart';
import 'theme/app_theme_controller.dart';
import 'theme/app_theme_mode.dart';
import 'theme/app_themes.dart';
import 'theme/fast_page_transitions.dart';
import 'widgets/aurora_backdrop.dart';
import 'widgets/screen_hack_overlay.dart';
import 'screens/notifications_screen.dart';
import 'services/alert_polling_service.dart';
import 'services/app_lifecycle_gate.dart';
import 'services/local_notification_service.dart';
import 'navigation/root_navigator.dart';
import 'widgets/global_live_alert_overlay.dart';

AppThemeController? appThemeController;

Future<void> main() async {
  runZonedGuarded(() async {
    final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Display error — go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
            ),
          ),
        ),
      );
    };

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Uncaught Flutter Error: ${details.exception}');
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('Uncaught Platform Error: $error\n$stack');
      return true;
    };

    AppLifecycleGate.instance.ensureBound();
    GestureBinding.instance.resamplingEnabled = true;
    PaintingBinding.instance.imageCache.maximumSize = 200;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 80 << 20;

    final AppThemeController themeController = AppThemeController();
    final AppLocaleController localeController = AppLocaleController();
    final GeneralSettingsController generalSettingsController =
        GeneralSettingsController();
    appThemeController = themeController;
    appLocaleController = localeController;

    try {
      await Future.wait<void>(<Future<void>>[
        themeController.initialize(),
        localeController.initialize(),
        generalSettingsController.initialize(),
      ]);
      final bool isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        await VehicleService.restorePersistedFleet();
      }
    } catch (error, stackTrace) {
      debugPrint('Startup init error: $error');
      debugPrint('$stackTrace');
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppThemeController>.value(
            value: themeController,
          ),
          ChangeNotifierProvider<AppLocaleController>.value(
            value: localeController,
          ),
          ChangeNotifierProvider<GeneralSettingsController>.value(
            value: generalSettingsController,
          ),
        ],
        child: const MultiTrackApp(
          home: SplashScreen(),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        unawaited(
          LocalNotificationService.initialize(
            onNotificationTap: (_) {
              rootNavigatorKey.currentState?.push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ).then((_) => LocalNotificationService.warmUpPermissions()),
        );
      }
      AuthService.isLoggedIn().then((bool loggedIn) {
        if (loggedIn) {
          AlertPollingService.instance.start();
        }
      });
    });
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

class _AppRootWithAlertBanner extends StatelessWidget {
  const _AppRootWithAlertBanner({
    required this.isHacking,
    required this.isAurora,
    required this.child,
  });

  final bool isHacking;
  final bool isAurora;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (isHacking) {
      content = AppThemes.wrapHackingContent(
        background: const Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: AppThemes.hackBackground),
            Positioned.fill(
              child: IgnorePointer(
                child: ScreenHackOverlay(
                  child: SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
        child: content,
      );
    } else if (isAurora) {
      content = Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const IgnorePointer(child: AuroraBackdrop()),
          content,
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        content,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: GlobalLiveAlertOverlay(),
          ),
        ),
      ],
    );
  }
}

class MultiTrackApp extends StatelessWidget {
  final Widget home;

  const MultiTrackApp({
    super.key,
    required this.home,
  });

  AppThemeController _themeController(BuildContext context) {
    return appThemeController ??
        Provider.of<AppThemeController>(context, listen: false);
  }

  AppLocaleController _localeController(BuildContext context) {
    return appLocaleController ??
        Provider.of<AppLocaleController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeController themeController = _themeController(context);
    final AppLocaleController localeController = _localeController(context);

    return AnimatedBuilder(
      animation: Listenable.merge(
        <Listenable>[themeController, localeController],
      ),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'MultiTrack',
          debugShowCheckedModeBanner: false,
          locale: localeController.materialLocale,
          supportedLocales: <Locale>[
            localeController.materialLocale,
            const Locale('en'),
          ],
          localeResolutionCallback:
              (Locale? locale, Iterable<Locale> supported) {
            return localeController.materialLocale;
          },
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppThemes.themeFor(themeController.mode).copyWith(
            colorScheme: AppThemes.themeFor(themeController.mode)
                .colorScheme
                .copyWith(primary: themeController.customAccentColor),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FastPageTransitionsBuilder(),
                TargetPlatform.iOS: FastPageTransitionsBuilder(),
              },
            ),
          ),
          builder: (BuildContext context, Widget? child) {
            return _AppRootWithAlertBanner(
              isHacking: themeController.isHacking,
              isAurora: themeController.mode == AppThemeMode.aurora,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: home,
        );
      },
    );
  }
}

