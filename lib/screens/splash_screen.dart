import 'package:flutter/material.dart';

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
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    final bool isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) {
      return;
    }

    final Widget nextScreen =
        isLoggedIn ? const DashboardScreen() : const TimeScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => nextScreen,
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
                  borderRadius: BorderRadius.circular(60),
                  child: Image.asset(
                    'assets/loginicon.png',
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                    cacheWidth: 220,
                    cacheHeight: 220,
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
    );
  }
}
