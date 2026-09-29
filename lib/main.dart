import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

AppThemeController? appThemeController;

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

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

    GestureBinding.instance.resamplingEnabled = true;
    PaintingBinding.instance.imageCache.maximumSize = 300;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20;

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
        unawaited(VehicleService.getDevices(forceRefresh: false));
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 400),
            () => VehicleService.getDevices(forceRefresh: true),
          ),
        );
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
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
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
            final Widget navigator = child ?? const SizedBox.shrink();

            if (themeController.isHacking) {
              return AppThemes.wrapHackingContent(
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
                child: navigator,
              );
            }

            if (themeController.mode == AppThemeMode.aurora) {
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const IgnorePointer(child: AuroraBackdrop()),
                  navigator,
                ],
              );
            }

            return navigator;
          },
          home: home,
        );
      },
    );
  }
}

