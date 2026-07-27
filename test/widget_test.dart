import 'package:flutter_test/flutter_test.dart';
import 'package:multitrack/main.dart';
import 'package:multitrack/theme/app_theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    appThemeController = AppThemeController();
    await appThemeController!.initialize();
  });

  tearDown(() {
    appThemeController = null;
  });

  testWidgets('MultiTrack app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppThemeController>.value(
        value: appThemeController!,
        child: const MultiTrackApp(),
      ),
    );

    await tester.pump();
    expect(find.text('multiTrack'), findsOneWidget);

    // Complete splash timer so no pending timers remain.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
