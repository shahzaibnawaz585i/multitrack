import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../constants/app_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme_tokens.dart';
import '../theme/app_themes.dart';
import 'dashboard_screen.dart';
import 'time_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _startNavigation();
  }

  static const Duration _splashDuration = Duration(seconds: 5);

  Future<void> _startNavigation() async {
    final Future<bool> loginFuture = AuthService.isLoggedIn();
    await Future<void>.delayed(_splashDuration);
    final bool isLoggedIn = await loginFuture;

    if (!mounted) {
      return;
    }

    final Widget nextScreen =
        isLoggedIn ? const DashboardScreen() : const TimeScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isHacking = context.isHackingTheme;
    final Color brandColor = isHacking
        ? AppThemes.hackAccent
        : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isHacking
          ? Colors.transparent
          : theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.asset(
                    'assets/appicon.png',
                    height: 72,
                    width: 72,
                    fit: BoxFit.cover,
                    cacheWidth: 144,
                    cacheHeight: 144,
                    filterQuality: FilterQuality.low,
                  ),
                ),
                const SizedBox(width: 1),
                Text(
                  'multiTrack',
                  style: TextStyle(
                    fontFamily: AppFonts.normalBold,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: brandColor,
                    height: 1,
                    letterSpacing: 0.2,
                    shadows: isHacking
                        ? <Shadow>[
                            Shadow(
                              color: AppThemes.hackAccent.withValues(alpha: 0.55),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: brandColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading…',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: brandColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
