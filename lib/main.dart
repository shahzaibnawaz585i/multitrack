import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/time_screen.dart';
import 'widgets/hacking_background.dart';
import 'widgets/screen_hack_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.loadTheme();
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: _themeProvider,
      child: ListenableBuilder(
        listenable: _themeProvider,
        builder: (context, _) {
          return MultiTrackApp(themeProvider: _themeProvider);
        },
      ),
    );
  }
}

class MultiTrackApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MultiTrackApp({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiTrack',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.resolvedTheme,
      home: const TimeScreen(),
      builder: (context, child) {
        final Widget content = child ?? const SizedBox.shrink();

        if (!themeProvider.usesHackBackground) {
          return content;
        }

        Widget layered = content;

        if (themeProvider.isScreenHackTheme) {
          layered = ScreenHackOverlay(child: layered);
        }

        return HackingBackground(child: layered);
      },
    );
  }
}
