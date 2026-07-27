import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/settings_screen/general_setting_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme_controller.dart';
import 'theme/app_themes.dart';

AppThemeController? appThemeController;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  appThemeController = AppThemeController();
  try {
    await appThemeController!.initialize();
  } catch (error, stackTrace) {
    debugPrint('Theme init error (fallback to light): $error');
    debugPrint('$stackTrace');
  }

  runApp(
    ChangeNotifierProvider<AppThemeController>.value(
      value: appThemeController!,
      child: const MultiTrackApp(),
    ),
  );
}

class MultiTrackApp extends StatelessWidget {
  const MultiTrackApp({super.key});

  AppThemeController _themeController(BuildContext context) {
    return appThemeController ??
        Provider.of<AppThemeController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeController themeController = _themeController(context);

    return AnimatedBuilder(
      animation: themeController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'MultiTrack',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.themeFor(themeController.mode),
          builder: (BuildContext context, Widget? child) {
            final Widget content = child ?? const SizedBox.shrink();

            if (!themeController.isHacking) {
              return content;
            }

            return AppThemes.wrapHackingContent(
              background: const Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: AppThemes.hackBackground),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: HackingOverlay(),
                    ),
                  ),
                ],
              ),
              child: content,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
