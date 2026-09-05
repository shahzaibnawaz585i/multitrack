import 'package:flutter_test/flutter_test.dart';
import 'package:multitrack/l10n/app_locale_controller.dart';
import 'package:multitrack/main.dart';
import 'package:multitrack/screens/time_screen.dart';
import 'package:multitrack/theme/app_theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    appThemeController = AppThemeController();
    appLocaleController = AppLocaleController();
    await appThemeController!.initialize();
    await appLocaleController!.initialize();
  });

  tearDown(() {
    appThemeController = null;
    appLocaleController = null;
  });

  testWidgets('MultiTrack app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppThemeController>.value(
            value: appThemeController!,
          ),
          ChangeNotifierProvider<AppLocaleController>.value(
            value: appLocaleController!,
          ),
        ],
        child: const MultiTrackApp(home: TimeScreen()),
      ),
    );

    await tester.pump();
    expect(find.text('Esay Tracking'), findsOneWidget);
  });
}
